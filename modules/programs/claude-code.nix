{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code;
  
  # Command definitions
  commands = {
    "remotion.md" = ''
# About Remotion

Remotion is a framework that can create videos programmatically.
It is based on React.js. All output should be valid React code and be written in TypeScript.

# Project structure

A Remotion Project consists of an entry file, a Root file and any number of React component files.
A project can be scaffolded using the "npx create-video@latest --blank" command.
The entry file is usually named "src/index.ts" and looks like this:

```ts
import {registerRoot} from 'remotion';
import {Root} from './Root';

registerRoot(Root);
```

The Root file is usually named "src/Root.tsx" and looks like this:

```tsx
import {Composition} from 'remotion';
import {MyComp} from './MyComp';

export const Root: React.FC = () => {
    return (
        <>
            <Composition
                id="MyComp"
                component={MyComp}
                durationInFrames={120}
                width={1920}
                height={1080}
                fps={30}
                defaultProps={{}}
            />
        </>
    );
};
```

A `<Composition>` defines a video that can be rendered. It consists of a React "component", an "id", a "durationInFrames", a "width", a "height" and a frame rate "fps".
The default frame rate should be 30.
The default height should be 1080 and the default width should be 1920.
The default "id" should be "MyComp".
The "defaultProps" must be in the shape of the React props the "component" expects.

Inside a React "component", one can use the "useCurrentFrame()" hook to get the current frame number.
Frame numbers start at 0.

```tsx
export const MyComp: React.FC = () => {
    const frame = useCurrentFrame();
    return <div>Frame {frame}</div>;
};
```

# Component Rules

Inside a component, regular HTML and SVG tags can be returned.
There are special tags for video and audio.
Those special tags accept regular CSS styles.

If a video is included in the component it should use the "<OffthreadVideo>" tag.

```tsx
import {OffthreadVideo} from 'remotion';

export const MyComp: React.FC = () => {
    return (
        <div>
            <OffthreadVideo
                src="https://remotion.dev/bbb.mp4"
                style={{width: '100%'}}
            />
        </div>
    );
};
```

OffthreadVideo has a "startFrom" prop that trims the left side of a video by a number of frames.
OffthreadVideo has a "endAt" prop that limits how long a video is shown.
OffthreadVideo has a "volume" prop that sets the volume of the video. It accepts values between 0 and 1.

If an non-animated image is included In the component it should use the "<Img>" tag.

```tsx
import {Img} from 'remotion';

export const MyComp: React.FC = () => {
    return <Img src="https://remotion.dev/logo.png" style={{width: '100%'}} />;
};
```

If an animated GIF is included, the "@remotion/gif" package should be installed and the "<Gif>" tag should be used.

```tsx
import {Gif} from '@remotion/gif';

export const MyComp: React.FC = () => {
    return (
        <Gif
            src="https://media.giphy.com/media/l0MYd5y8e1t0m/giphy.gif"
            style={{width: '100%'}}
        />
    );
};
```

If audio is included, the "<Audio>" tag should be used.

```tsx
import {Audio} from 'remotion';

export const MyComp: React.FC = () => {
    return <Audio src="https://remotion.dev/audio.mp3" />;
};
```

Asset sources can be specified as either a Remote URL or an asset that is referenced from the "public/" folder of the project.
If an asset is referenced from the "public/" folder, it should be specified using the "staticFile" API from Remotion

```tsx
import {Audio, staticFile} from 'remotion';

export const MyComp: React.FC = () => {
    return <Audio src={staticFile('audio.mp3')} />;
};
```

Audio has a "startFrom" prop that trims the left side of a audio by a number of frames.
Audio has a "endAt" prop that limits how long a audio is shown.
Audio has a "volume" prop that sets the volume of the audio. It accepts values between 0 and 1.

If two elements should be rendered on top of each other, they should be layered using the "AbsoluteFill" component from "remotion".

```tsx
import {AbsoluteFill} from 'remotion';

export const MyComp: React.FC = () => {
    return (
        <AbsoluteFill>
            <AbsoluteFill style={{background: 'blue'}}>
                <div>This is in the back</div>
            </AbsoluteFill>
            <AbsoluteFill style={{background: 'blue'}}>
                <div>This is in front</div>
            </AbsoluteFill>
        </AbsoluteFill>
    );
};
```

Any Element can be wrapped in a "Sequence" component from "remotion" to place the element later in the video.

```tsx
import {Sequence} from 'remotion';

export const MyComp: React.FC = () => {
    return (
        <Sequence from={10} durationInFrames={20}>
            <div>This only appears after 10 frames</div>
        </Sequence>
    );
};
```

A Sequence has a "from" prop that specifies the frame number where the element should appear.
The "from" prop can be negative, in which case the Sequence will start immediately but cut off the first "from" frames.

A Sequence has a "durationInFrames" prop that specifies how long the element should appear.

If a child component of Sequence calls "useCurrentFrame()", the enumeration starts from the first frame the Sequence appears and starts at 0.

```tsx
import {Sequence} from 'remotion';

export const Child: React.FC = () => {
    const frame = useCurrentFrame();

    return <div>At frame 10, this should be 0: {frame}</div>;
};

export const MyComp: React.FC = () => {
    return (
        <Sequence from={10} durationInFrames={20}>
            <Child />
        </Sequence>
    );
};
```

For displaying multiple elements after another, the "Series" component from "remotion" can be used.

```tsx
import {Series} from 'remotion';

export const MyComp: React.FC = () => {
    return (
        <Series>
            <Series.Sequence durationInFrames={20}>
                <div>This only appears immediately</div>
            </Series.Sequence>
            <Series.Sequence durationInFrames={30}>
                <div>This only appears after 20 frames</div>
            </Series.Sequence>
            <Series.Sequence durationInFrames={30} offset={-8}>
                <div>This only appears after 42 frames</div>
            </Series.Sequence>
        </Series>
    );
};
```

The "Series.Sequence" component works like "Sequence", but has no "from" prop.
Instead, it has a "offset" prop shifts the start by a number of frames.

For displaying multiple elements after another another and having a transition inbetween, the "TransitionSeries" component from "@remotion/transitions" can be used.

```tsx
import {
    linearTiming,
    springTiming,
    TransitionSeries,
} from '@remotion/transitions';

import {fade} from '@remotion/transitions/fade';
import {wipe} from '@remotion/transitions/wipe';

export const MyComp: React.FC = () => {
    return (
        <TransitionSeries>
            <TransitionSeries.Sequence durationInFrames={60}>
                <Fill color="blue" />
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
                timing={springTiming({config: {damping: 200}})}
                presentation={fade()}
            />
            <TransitionSeries.Sequence durationInFrames={60}>
                <Fill color="black" />
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
                timing={linearTiming({durationInFrames: 30})}
                presentation={wipe()}
            />
            <TransitionSeries.Sequence durationInFrames={60}>
                <Fill color="white" />
            </TransitionSeries.Sequence>
        </TransitionSeries>
    );
};
```

"TransitionSeries.Sequence" works like "Series.Sequence" but has no "offset" prop.
The order of tags is important, "TransitionSeries.Transition" must be inbetween "TransitionSeries.Sequence" tags.

Remotion needs all of the React code to be deterministic. Therefore, it is forbidden to use the Math.random() API.
If randomness is requested, the "random()" function from "remotion" should be used and a static seed should be passed to it.
The random function returns a number between 0 and 1.

```tsx twoslash
import {random} from 'remotion';

export const MyComp: React.FC = () => {
    return <div>Random number: {random('my-seed')}</div>;
};
```

Remotion includes an interpolate() helper that can animate values over time.

```tsx
import {interpolate} from 'remotion';

export const MyComp: React.FC = () => {
    const frame = useCurrentFrame();
    const value = interpolate(frame, [0, 100], [0, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
    });
    return (
        <div>
            Frame {frame}: {value}
        </div>
    );
};
```

The "interpolate()" function accepts a number and two arrays of numbers.
The first argument is the value to animate.
The first array is the input range, the second array is the output range.
The fourth argument is optional but code should add "extrapolateLeft: 'clamp'" and "extrapolateRight: 'clamp'" by default.
The function returns a number between the first and second array.

If the "fps", "durationInFrames", "height" or "width" of the composition are required, the "useVideoConfig()" hook from "remotion" should be used.

```tsx
import {useVideoConfig} from 'remotion';

export const MyComp: React.FC = () => {
    const {fps, durationInFrames, height, width} = useVideoConfig();
    return (
        <div>
            fps: {fps}
            durationInFrames: {durationInFrames}
            height: {height}
            width: {width}
        </div>
    );
};
```

Remotion includes a "spring()" helper that can animate values over time.
Below is the suggested default usage.

```tsx
import {spring} from 'remotion';

export const MyComp: React.FC = () => {
    const frame = useCurrentFrame();
    const {fps} = useVideoConfig();

    const value = spring({
        fps,
        frame,
        config: {
            damping: 200,
        },
    });
    return (
        <div>
            Frame {frame}: {value}
        </div>
    );
};
```

## Rendering

To render a video, the CLI command "npx remotion render [id]" can be used.
The composition "id" should be passed, for example:

$ npx remotion render MyComp

To render a still image, the CLI command "npx remotion still [id]" can be used.
For example:

$ npx remotion still MyComp

## Rendering on Lambda

Videos can be rendered in the cloud using AWS Lambda.
The setup described under https://www.remotion.dev/docs/lambda/setup must be completed.

Rendering requires a Lambda function and a site deployed on S3.

If the user is using the CLI:

- A Lambda function can be deployed using `npx remotion lambda functions deploy`: https://www.remotion.dev/docs/lambda/cli/functions/deploy
- A site can be deployed using `npx remotion lambda sites create`: https://www.remotion.dev/docs/lambda/cli/sites/create. The first argument must refer to the entry point.
- A video can be rendered using `npx remotion lambda render [comp-id]`. The composition ID must be referenced.

If the user is using the Node.js APIs:

- A Lambda function can be deployed using `deployFunction()`: https://www.remotion.dev/docs/lambda/deployfunction
- A site can be deployed using `deploySite()`: https://www.remotion.dev/docs/lambda/deploysite
- A video can be rendered using `renderMediaOnLambda()`: https://www.remotion.dev/docs/lambda/rendermediaonlambda.
- If a video is rendered, the progress must be polled using `getRenderProgress()`: https://www.remotion.dev/docs/lambda/getrenderprogress
    '';
  };
  
  # Agent definitions
  agents = {
    "code-cleanup-specialist.md" = ''
---
name: code-cleanup-specialist
description: Use this agent when you need to identify and eliminate code redundancy, remove unused files, detect duplicated code patterns, or improve the overall cleanliness and modularity of a codebase. This agent excels at finding dead code, suggesting file consolidations, and ensuring adherence to clean architecture principles.
color: pink
---

You are a code cleanup specialist with an obsessive dedication to clean, modular codebases. You have deep expertise in identifying technical debt, code smells, and architectural violations. Your mission is to ruthlessly eliminate waste and enforce pristine code organization.

Your core competencies:
- Detecting unused imports, variables, functions, and entire files
- Identifying duplicated code patterns across files and modules
- Recognizing violations of separation of concerns and clean architecture principles
- Spotting overly complex functions that should be broken down
- Finding redundant or obsolete configuration files
- Identifying circular dependencies and suggesting refactoring strategies
    '';
    "code-reviewer.md" = ''
---
name: code-reviewer
description: Use this agent when you need to review code for adherence to DRY (Don't Repeat Yourself) and KISS (Keep It Simple, Stupid) principles, identify code duplication, assess file length and complexity, or get recommendations for refactoring.
color: blue
---

You are a code review specialist focused on maintaining clean, efficient codebases through rigorous application of DRY and KISS principles.
    '';
    "coding-teacher.md" = ''
---
name: coding-teacher
description: Use this agent when you need to learn programming concepts, understand code patterns, debug issues through guided discovery, or build stronger mental models of how code works.
color: green
---

You are a patient and knowledgeable coding teacher who guides through understanding rather than just providing solutions.
    '';
    "deep-research-specialist.md" = ''
---
name: deep-research-specialist
description: Use this agent when you need comprehensive, multi-source research on complex topics that requires thorough investigation across web sources and internal knowledge bases.
color: purple
---

You are a deep research specialist capable of conducting thorough investigations across multiple sources to provide comprehensive analysis.
    '';
    "pair-programmer.md" = ''
---
name: pair-programmer
description: Use this agent when you need collaborative problem-solving for programming challenges, want to explore multiple solution approaches before coding, or need guidance on choosing the best implementation strategy.
color: orange
---

You are an experienced pair programmer who excels at collaborative problem-solving and exploring multiple approaches to find optimal solutions.
    '';
    "strategic-planner.md" = ''
---
name: strategic-planner
description: Use this agent when you need to create comprehensive, detailed plans for complex projects, initiatives, or problem-solving scenarios.
color: red
---

You are a strategic planning expert who creates comprehensive, actionable plans for complex projects and initiatives.
    '';
  };
  
  # MCP server configurations for Claude Code CLI
  mcpServers = {
    puppeteer = {
      command = "npx";
      args = [ "-y" "@puppeteer/mcp-server" ];
    };
    playwright = {
      command = "npx";
      args = [ "-y" "@michaeltliu/mcp-server-playwright" ];
    };
    "mcp-omnisearch" = {
      command = "npx";
      args = [ "-y" "mcp-omnisearch" ];
      env = {
        TAVILY_API_KEY = "\${TAVILY_API_KEY}";
        BRAVE_API_KEY = "\${BRAVE_API_KEY}";
        KAGI_API_KEY = "\${KAGI_API_KEY}";
        PERPLEXITY_API_KEY = "\${PERPLEXITY_API_KEY}";
        JINA_AI_API_KEY = "\${JINA_AI_API_KEY}";
        FIRECRAWL_API_KEY = "\${FIRECRAWL_API_KEY}";
      };
    };
    "claude-flow" = {
      command = "/Users/angel/Projects/claude-flow/bin/claude-flow";
      args = [ "mcp" "start" "--transport" "stdio" ];
      env = {
        NODE_ENV = "production";
      };
    };
    "ruv-swarm" = {
      command = "npx";
      args = [ "-y" "ruv-swarm" "mcp" "start" ];
      env = {
        NODE_ENV = "production";
      };
    };
    "sequential-thinking" = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
    memory = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-memory" ];
    };
    filesystem = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-filesystem" "/Users/angel/Projects" "/Users/angel/Documents" "/Users/angel/.claude" "/tmp" ];
    };
  };


  # Claude Code settings configuration
  # Note: settings.json should only contain valid fields like env
  # MCP servers should be configured in ~/.claude.json for Claude Code CLI
  claudeSettings = {
    env = {
      DISABLE_TELEMETRY = "1";
      DISABLE_ERROR_REPORTING = "1";
      ANTHROPIC_API_KEY = "";
    };
  };

in {
  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code configuration management";
    
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.claude";
      description = "Directory for Claude Code configuration";
    };
    
    scriptsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.claude/scripts";
      description = "Directory for Claude Code scripts";
    };
    
    
    enableMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP server configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure required packages are available
    environment.systemPackages = with pkgs; [
      python3
      python3Packages.pip
      nodejs_20  # For npx and MCP servers
      jq         # For updating JSON configuration
    ];

    # Create Claude Code configuration files
    system.activationScripts.claudeCodeSetup = {
      text = ''
        echo "Setting up Claude Code configuration..."
        
        # Create full directory structure
        mkdir -p ${cfg.configDir}
        mkdir -p ${cfg.configDir}/agents
        mkdir -p ${cfg.configDir}/commands
        mkdir -p ${cfg.configDir}/commands/frontend
        mkdir -p ${cfg.configDir}/commands/backend
        mkdir -p ${cfg.configDir}/projects
        mkdir -p ${cfg.configDir}/statsig
        mkdir -p ${cfg.configDir}/todos
        mkdir -p ${cfg.configDir}/shell-snapshots
        mkdir -p ${cfg.configDir}/ide
        mkdir -p ${cfg.scriptsDir}
        
        # Create settings.json for Claude Code CLI
        cat > ${cfg.configDir}/settings.json << 'EOF'
        ${builtins.toJSON claudeSettings}
        EOF
        
        # Update claude.json to add MCP servers globally
        # This preserves existing configuration while adding MCP servers
        if [ -f "$HOME/.claude.json" ]; then
          # Use jq to update the existing file, preserving all other settings
          # Add MCP servers globally for all projects
          jq '.mcpServers = ${builtins.toJSON mcpServers}' \
              "$HOME/.claude.json" > "$HOME/.claude.json.tmp" && \
              mv "$HOME/.claude.json.tmp" "$HOME/.claude.json"
        else
          # Create new file if it doesn't exist
          cat > $HOME/.claude.json << 'EOF'
          {
            "mcpServers": ${builtins.toJSON mcpServers}
          }
          EOF
        fi
        
        # Create agent files
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: content: ''
          cat > ${cfg.configDir}/agents/${name} << 'AGENT_EOF'
          ${content}
          AGENT_EOF
        '') agents)}
        
        # Create command files
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: content: ''
          cat > ${cfg.configDir}/commands/${name} << 'COMMAND_EOF'
          ${content}
          COMMAND_EOF
        '') commands)}
        
        # Configure npm for global installations
        echo "Configuring npm..."
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"
        export PATH="$HOME/.npm-global/bin:$PATH"
        
        # Set proper permissions
        chmod -R 755 ${cfg.configDir}
        chmod 644 ${cfg.configDir}/settings.json
        chmod 644 ${cfg.configDir}/agents/*.md
        chmod 644 ${cfg.configDir}/commands/*.md
        
        # Install claude-flow if not already installed
        if [ ! -d "/Users/angel/Projects/claude-flow" ]; then
          echo "Installing claude-flow..."
          cd /Users/angel/Projects
          git clone https://github.com/Angleito/claude-flow.git || echo "Failed to clone claude-flow"
          cd claude-flow
          npm install || echo "Failed to install claude-flow dependencies"
        else
          echo "claude-flow already installed at /Users/angel/Projects/claude-flow"
        fi
        
        # Install Claude Code CLI globally (always latest version)
        echo "Installing Claude Code CLI..."
        npm install -g @anthropic-ai/claude-code || echo "Failed to install Claude Code"
        
        # Install required MCP servers globally
        echo "Installing MCP servers..."
        npm install -g @modelcontextprotocol/server-filesystem \
                       @modelcontextprotocol/server-memory \
                       @modelcontextprotocol/server-sequential-thinking \
                       @cloudflare/mcp-server-puppeteer \
                       @michaeltliu/mcp-server-playwright \
                       mcp-omnisearch \
                       ruv-swarm || echo "Some MCP servers failed to install"
        
        echo "Claude Code configuration complete!"
      '';
    };
    
    # Claude is already available via npm global install
    # No need to add wrapper alias
  };
}