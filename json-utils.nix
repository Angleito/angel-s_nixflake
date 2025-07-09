{ lib ? import <nixpkgs/lib> }:

rec {
  # Function to safely escape strings for JSON
  # Handles special characters according to JSON specification
  escapeJsonString = str:
    let
      # Define escape mappings for special characters
      escapeMap = {
        "\\" = "\\\\";
        "\"" = "\\\"";
        "\n" = "\\n";
        "\r" = "\\r";
        "\t" = "\\t";
        "\b" = "\\b";
        "\f" = "\\f";
      };
      
      # Helper to escape a single character
      escapeChar = char:
        escapeMap.${char} or char;
      
      # Convert string to list of characters and escape each
      chars = lib.stringToCharacters str;
      escapedChars = map escapeChar chars;
    in
      lib.concatStrings escapedChars;

  # Function to validate JSON structure
  # Returns true if the value can be serialized to valid JSON
  isValidJson = value:
    let
      type = builtins.typeOf value;
    in
      # Check primitive types
      if type == "null" then true
      else if type == "bool" then true
      else if type == "int" then true
      else if type == "float" then true
      else if type == "string" then true
      # Check complex types recursively
      else if type == "list" then
        builtins.all isValidJson value
      else if type == "set" then
        # For attribute sets, check all values
        builtins.all isValidJson (builtins.attrValues value)
      else
        # Other types (functions, etc.) are not valid JSON
        false;

  # Convert a Nix value to JSON string
  toJson = value:
    let
      type = builtins.typeOf value;
    in
      if type == "null" then "null"
      else if type == "bool" then if value then "true" else "false"
      else if type == "int" then toString value
      else if type == "float" then toString value
      else if type == "string" then "\"${escapeJsonString value}\""
      else if type == "list" then
        "[${lib.concatMapStringsSep "," toJson value}]"
      else if type == "set" then
        let
          # Convert each attribute to "key": value format
          pairToJson = name: value: "\"${escapeJsonString name}\":${toJson value}";
          pairs = lib.mapAttrsToList pairToJson value;
        in
          "{${lib.concatStringsSep "," pairs}}"
      else
        throw "Cannot convert type '${type}' to JSON";

  # Helper function to build JSON objects programmatically
  # Filters out null values by default
  buildJsonObject = { filterNull ? true, ... }@attrs:
    let
      # Remove the filterNull attribute from the actual data
      dataAttrs = removeAttrs attrs [ "filterNull" ];
      
      # Filter function to remove null values if requested
      filterFn = name: value:
        if filterNull && value == null then false else true;
      
      # Apply filter
      filteredAttrs = lib.filterAttrs filterFn dataAttrs;
    in
      filteredAttrs;

  # Helper to create a JSON array
  buildJsonArray = elements:
    # Filter out null elements by default
    lib.filter (e: e != null) elements;

  # Safe getter for environment variables with JSON-friendly null handling
  # Returns null if the environment variable is not set or empty
  getEnvJson = varName: default:
    let
      value = builtins.getEnv varName;
    in
      if value == "" then
        if default == null then null
        else default
      else value;

  # Build a JSON object from environment variables
  # Handles missing/empty environment variables gracefully
  buildJsonFromEnv = spec:
    let
      # Process each specification entry
      processEntry = name: config:
        let
          envVar = config.env or name;
          default = config.default or null;
          transform = config.transform or (x: x);
          value = getEnvJson envVar default;
        in
          if value == null then null
          else transform value;
      
      # Build the object with processed entries
      rawObject = lib.mapAttrs processEntry spec;
    in
      # Filter out null values
      lib.filterAttrs (n: v: v != null) rawObject;

  # Merge multiple JSON objects, with later objects overriding earlier ones
  # Null values in later objects remove the key
  mergeJsonObjects = objects:
    let
      # Helper to merge two objects
      merge2 = obj1: obj2:
        let
          allKeys = lib.unique ((lib.attrNames obj1) ++ (lib.attrNames obj2));
          getValue = key:
            if lib.hasAttr key obj2 then
              obj2.${key}
            else if lib.hasAttr key obj1 then
              obj1.${key}
            else
              null;
        in
          lib.filterAttrs (n: v: v != null) (lib.genAttrs allKeys getValue);
    in
      lib.foldl' merge2 {} objects;

  # Pretty-print JSON with indentation
  toPrettyJson = value:
    let
      # Helper for indentation
      indent = level: lib.concatStrings (lib.genList (x: "  ") level);
      
      # Recursive pretty printer
      toPrettyJsonRec = level: value:
        let
          type = builtins.typeOf value;
          nextLevel = level + 1;
        in
          if type == "null" then "null"
          else if type == "bool" then if value then "true" else "false"
          else if type == "int" then toString value
          else if type == "float" then toString value
          else if type == "string" then "\"${escapeJsonString value}\""
          else if type == "list" then
            if value == [] then "[]"
            else
              let
                elements = map (v: "${indent nextLevel}${toPrettyJsonRec nextLevel v}") value;
              in
                "[\n${lib.concatStringsSep ",\n" elements}\n${indent level}]"
          else if type == "set" then
            if value == {} then "{}"
            else
              let
                pairToJson = name: value:
                  "${indent nextLevel}\"${escapeJsonString name}\": ${toPrettyJsonRec nextLevel value}";
                pairs = lib.mapAttrsToList pairToJson value;
              in
                "{\n${lib.concatStringsSep ",\n" pairs}\n${indent level}}"
          else
            throw "Cannot convert type '${type}' to JSON";
    in
      toPrettyJsonRec 0 value;

  # Validate and convert a string to JSON-safe format
  # Returns null if the string is invalid
  sanitizeJsonString = str:
    if builtins.isString str then
      escapeJsonString str
    else
      null;

  # Deep merge for JSON objects with custom merge strategy
  deepMergeJson = strategy: obj1: obj2:
    let
      # Merge strategies
      strategies = {
        # Replace strategy: obj2 values always win
        replace = key: val1: val2: val2;
        
        # Combine strategy: arrays are concatenated, objects are merged
        combine = key: val1: val2:
          let
            type1 = builtins.typeOf val1;
            type2 = builtins.typeOf val2;
          in
            if type1 == "list" && type2 == "list" then
              val1 ++ val2
            else if type1 == "set" && type2 == "set" then
              deepMergeJson strategy val1 val2
            else
              val2;
        
        # Keep strategy: obj1 values are kept if they exist
        keep = key: val1: val2: val1;
      };
      
      mergeFn = strategies.${strategy} or strategies.replace;
      
      allKeys = lib.unique ((lib.attrNames obj1) ++ (lib.attrNames obj2));
      
      mergeKey = key:
        if lib.hasAttr key obj1 && lib.hasAttr key obj2 then
          mergeFn key obj1.${key} obj2.${key}
        else if lib.hasAttr key obj2 then
          obj2.${key}
        else
          obj1.${key};
    in
      lib.genAttrs allKeys mergeKey;

  # Example usage function showing how to use these utilities
  example = {
    # Example of escaping strings
    escapedString = escapeJsonString "Hello \"World\"\nNew line";
    
    # Example of building JSON object
    configObject = buildJsonObject {
      name = "My App";
      version = "1.0.0";
      debug = true;
      port = 8080;
      emptyValue = null;  # This will be filtered out
      filterNull = true;  # This controls filtering
    };
    
    # Example of environment-based JSON
    envConfig = buildJsonFromEnv {
      database_url = {
        env = "DATABASE_URL";
        default = "sqlite:memory:";
      };
      api_key = {
        env = "API_KEY";
        default = null;  # Will be omitted if not set
      };
      port = {
        env = "PORT";
        default = "3000";
        transform = builtins.fromJSON;  # Convert string to number
      };
    };
    
    # Example of pretty JSON
    prettyOutput = toPrettyJson {
      users = [
        { id = 1; name = "Alice"; active = true; }
        { id = 2; name = "Bob"; active = false; }
      ];
      settings = {
        theme = "dark";
        notifications = true;
      };
    };
  };
}
