{ lib, ... }:

let
  # Function to read and parse .env file at evaluation time
  readEnvFile = path:
    let
      envFile = builtins.readFile path;
      lines = lib.splitString "\n" envFile;
      
      # Parse a single line of the .env file
      parseLine = line:
        let
          # Skip empty lines and comments
          trimmed = lib.trim line;
          isComment = lib.hasPrefix "#" trimmed;
          isEmpty = trimmed == "";
        in
        if isComment || isEmpty then null
        else
          let
            # Match KEY=VALUE or KEY="VALUE" patterns
            match = builtins.match ''([A-Za-z_][A-Za-z0-9_]*)=(.*)'' trimmed;
          in
          if match != null then
            let
              key = builtins.elemAt match 0;
              rawValue = builtins.elemAt match 1;
              # Remove surrounding quotes if present
              value = 
                if lib.hasPrefix "\"" rawValue && lib.hasSuffix "\"" rawValue then
                  lib.substring 1 (lib.stringLength rawValue - 2) rawValue
                else if lib.hasPrefix "'" rawValue && lib.hasSuffix "'" rawValue then
                  lib.substring 1 (lib.stringLength rawValue - 2) rawValue
                else
                  rawValue;
            in
            { name = key; value = value; }
          else null;
      
      # Parse all lines and filter out nulls
      parsedLines = lib.filter (x: x != null) (map parseLine lines);
    in
    lib.listToAttrs parsedLines;
  
  # Try to read .env file, fallback to empty set if it doesn't exist
  envVars = 
    if builtins.pathExists /Users/angel/Projects/nix-project/.env then
      readEnvFile /Users/angel/Projects/nix-project/.env
    else if builtins.pathExists /Users/angel/.config/nix-project/.env then
      readEnvFile /Users/angel/.config/nix-project/.env
    else
      {};
  
in {
  # Export the parsed environment variables
  config.nix-project.envVars = envVars;
}