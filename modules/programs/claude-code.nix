{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code;
  
  # Command definitions
  commands = {
    "workflow.md" = ''
---
allowed-tools: Task, TodoRead, TodoWrite, Read, Grep, Bash(git:*), Bash(npm:*), WebFetch, mcp__claude-flow__swarm_init, mcp__claude-flow__agent_spawn, mcp__claude-flow__task_orchestrate, mcp__claude-flow__memory_usage, mcp__claude-flow__memory_search, mcp__claude-flow__memory_namespace, mcp__claude-flow__memory_persist, mcp__claude-flow__memory_backup, mcp__claude-flow__memory_restore, mcp__claude-flow__memory_compress, mcp__claude-flow__memory_sync, mcp__claude-flow__neural_train, mcp__claude-flow__neural_predict, mcp__claude-flow__neural_patterns, mcp__claude-flow__neural_status, mcp__claude-flow__cognitive_analyze, mcp__claude-flow__learning_adapt, mcp__claude-flow__pattern_recognize, mcp__claude-flow__workflow_create, mcp__claude-flow__workflow_execute, mcp__claude-flow__workflow_export, mcp__claude-flow__automation_setup, mcp__claude-flow__pipeline_create, mcp__claude-flow__scheduler_manage, mcp__claude-flow__trigger_setup, mcp__claude-flow__performance_report, mcp__claude-flow__bottleneck_analyze, mcp__claude-flow__token_usage, mcp__claude-flow__benchmark_run, mcp__claude-flow__metrics_collect, mcp__claude-flow__health_check, mcp__claude-flow__batch_process, mcp__claude-flow__parallel_execute, mcp__claude-flow__swarm_status, mcp__claude-flow__swarm_monitor, mcp__claude-flow__agent_list, mcp__claude-flow__agent_metrics, mcp__claude-flow__load_balance, mcp__claude-flow__coordination_sync, mcp__claude-flow__swarm_scale, mcp__claude-flow__sparc_mode
description: Execute advanced multi-agent workflows with SPARC methodology and Claude-Flow MCP integration for enhanced orchestration, neural intelligence, and memory-driven development
---

# Workflow Orchestrator with SPARC Methodology & Claude-Flow MCP

Execute intelligent workflows using Claude-Flow's SPARC methodology and advanced MCP tools for swarm coordination, neural optimization, memory-driven context, and specialized agent orchestration.

## Workflow: $ARGUMENTS

## SPARC Methodology Integration

You can operate in any of these specialized SPARC modes from Claude Flow:

### Primary Development Modes
- **orchestrator** - Multi-agent task orchestration and coordination
- **coder** - Autonomous code generation and implementation  
- **researcher** - Deep research and comprehensive analysis
- **tdd** - Test-driven development methodology
- **architect** - System design and architecture planning
- **reviewer** - Code review and quality optimization
- **debugger** - Debug and fix issues systematically
- **tester** - Comprehensive testing and validation
- **analyst** - Code and data analysis specialist
- **optimizer** - Performance optimization specialist
- **documenter** - Documentation generation and maintenance

### Specialized Modes
- **designer** - UI/UX design and user experience
- **innovator** - Creative problem solving and innovation
- **swarm-coordinator** - Swarm coordination and management
- **memory-manager** - Memory and knowledge management
- **batch-executor** - Parallel task execution specialist
- **workflow-manager** - Workflow automation and process management

Use `mcp__claude-flow__sparc_mode` to run specific SPARC development modes (dev, api, ui, test, refactor) with task-specific optimization.

## Core Principles

1. **No bullshit** - Be direct, honest, and avoid unnecessary complexity or fluff
2. **Always ask questions** - Clarify requirements, assumptions, and edge cases before proceeding
3. **Absolutely no mocks whatsoever** - Use real implementations, real data, and real integrations only
4. **Reuse code from the repo** - Always check for existing implementations before creating new ones
5. **Edit existing files and use existing folders** - Modify what's there before creating new structures
6. **Use ultrathink and omnisearch** - Leverage advanced planning and research capabilities
7. **Create short, efficient, and modular code** - Focus on clarity and maintainability
8. **Always separate concerns** - Each module should have a single, clear responsibility
9. **Execute plans in parallel** - Use Claude-Flow MCP tools for enhanced parallelism
10. **Prevent agent collisions** - Use swarm coordination for conflict-free execution
11. **Follow order of operations** - Respect sequential dependencies with task orchestration
12. **Leverage persistent memory** - Use memory system for context and pattern reuse

## Enhanced Execution Strategy

### Phase 1: Memory Context Loading
First, check memory for previous patterns and successful implementations using the memory system. Search for relevant patterns, load context from previous sessions, and identify reusable components.

### Phase 2: Swarm Initialization
Initialize Claude-Flow swarm with appropriate topology based on task complexity. Choose hierarchical for clear delegation, mesh for peer collaboration, star for centralized control, or ring for sequential processing.

### Phase 3: Workflow Definition
Create workflow using Claude-Flow's workflow tools with parallel capabilities where appropriate. Define clear steps with dependencies and enable concurrent execution for independent tasks.

### Phase 4: Agent Spawning
Deploy specialized agents based on workflow requirements. Use researcher agents for information gathering, coder agents for implementation, tester agents for validation, and coordinator agents for orchestration.

### Phase 5: Task Orchestration
Orchestrate tasks with intelligent scheduling and dependency management. Execute independent tasks in parallel while respecting sequential dependencies. Monitor progress and handle failures gracefully.

### Phase 6: Memory-Enhanced Processing
Store successful patterns, decisions, and learnings in memory for future use. Query memory for similar problems and solutions. Maintain namespace organization for different types of data.

### Phase 7: Neural Pattern Application
Train neural models on successful patterns and apply predictions to optimize workflow execution. Learn from past performance to improve future runs.

### Phase 8: Performance Monitoring
Monitor workflow performance, identify bottlenecks, and optimize execution strategies. Generate reports and adjust based on metrics.

## Key MCP Tool Guidelines

### Advanced Memory System Operations
- Use `memory_usage` to store and retrieve context, patterns, and learnings with TTL and namespacing
- Use `memory_search` to find relevant patterns from previous workflows with advanced pattern matching
- Use `memory_namespace` to organize data by project, feature, or type with hierarchical structure
- Use `memory_persist` for cross-session persistence and continuity
- Use `memory_backup` and `memory_restore` for data protection and recovery
- Use `memory_compress` to optimize storage efficiency
- Use `memory_sync` to synchronize memory across instances
- Always check memory first before implementing new solutions

### Advanced Swarm Coordination
- Use `swarm_init` with appropriate topology for task complexity (hierarchical, mesh, ring, star)
- Use `swarm_status` to monitor swarm health and performance in real-time
- Use `swarm_monitor` for continuous real-time monitoring and alerts
- Use `swarm_scale` to auto-scale agent count based on workload
- Use `agent_list` to track active agents and their capabilities
- Use `agent_metrics` to analyze individual agent performance
- Use `load_balance` to distribute tasks efficiently across agents
- Use `coordination_sync` to synchronize agent coordination and prevent conflicts
- Choose topology based on workflow needs (hierarchical, mesh, star, ring)

### Task Orchestration
- Use `task_orchestrate` to manage dependencies and execution order
- Use `parallel_execute` for independent tasks to maximize throughput
- Use `batch_process` for bulk operations on similar items
- Monitor task progress and handle failures appropriately

### Neural Intelligence & Cognitive Patterns
- Use `neural_train` to learn from successful patterns with WASM SIMD acceleration
- Use `neural_predict` to optimize future executions
- Use `neural_patterns` to analyze cognitive patterns for workflow optimization
- Use `neural_status` to monitor neural network health and performance
- Use `cognitive_analyze` for advanced behavioral pattern analysis
- Use `learning_adapt` for adaptive learning based on feedback
- Use `pattern_recognize` for identifying optimal workflow patterns
- Train on coordination patterns, code patterns, and performance data
- Apply predictions to improve workflow efficiency

### Comprehensive Performance Optimization
- Use `performance_report` to generate comprehensive performance reports with real-time metrics
- Use `bottleneck_analyze` to identify and resolve performance bottlenecks systematically
- Use `token_usage` to analyze and optimize token consumption patterns
- Use `benchmark_run` to execute performance benchmarks and comparisons
- Use `metrics_collect` to gather system-wide performance metrics
- Use `health_check` for continuous system health monitoring
- Regular monitoring prevents performance degradation
- Adjust strategies based on performance data and trend analysis

### Advanced Workflow & Automation Management
- Use `workflow_create` to define reusable workflow templates with dependencies
- Use `workflow_execute` to run workflows with parameters and context
- Use `workflow_export` to export workflow definitions for sharing and version control
- Use `automation_setup` to create intelligent automation rules and triggers
- Use `pipeline_create` to design CI/CD pipelines with workflow integration
- Use `scheduler_manage` to handle complex task scheduling and timing
- Use `trigger_setup` to configure event-driven workflow execution
- Store successful workflows in memory for reuse and pattern learning
- Evolve workflows based on performance outcomes and neural insights

## Enhanced Workflow Best Practices with SPARC Integration

1. **SPARC Mode Selection** - Choose appropriate SPARC mode based on task type and complexity
2. **Memory-First Approach** - Always check memory for existing patterns, solutions, and learnings
3. **Early Swarm Initialization** - Set up coordination topology before spawning specialized agents
4. **Neural Pattern Learning** - Train on successful patterns and apply cognitive insights
5. **Clear Dependency Definition** - Use task orchestration to prevent agent conflicts and ensure proper sequencing
6. **Continuous Performance Monitoring** - Real-time health checks and bottleneck analysis
7. **Comprehensive Data Storage** - Save patterns, decisions, learnings, and performance metrics
8. **Aggressive Parallelization** - Maximize concurrent execution for independent tasks
9. **Adaptive Learning Integration** - Use neural networks and cognitive analysis for continuous improvement
10. **Hierarchical Memory Organization** - Maintain organized namespaces for different contexts and projects
11. **Automated Workflow Evolution** - Use triggers and automation to refine workflows based on outcomes
12. **Cross-Session Persistence** - Leverage memory backup/restore for continuity across sessions
13. **Performance-Driven Optimization** - Regular benchmarking and metric-based improvements
14. **Agent Specialization** - Deploy task-specific agents (coder, researcher, tester, etc.) for optimal results
15. **Intelligent Load Balancing** - Distribute workload efficiently across swarm agents

## SPARC-Enhanced Execution Example

```
# 1. Select SPARC mode and initialize swarm
mcp__claude-flow__sparc_mode(mode="orchestrator", task_description="Multi-component system implementation")
mcp__claude-flow__swarm_init(topology="hierarchical", strategy="adaptive")

# 2. Check memory for patterns and spawn specialized agents
mcp__claude-flow__memory_search(pattern="system implementation patterns")
mcp__claude-flow__agent_spawn(type="architect", capabilities=["system_design", "documentation"])
mcp__claude-flow__agent_spawn(type="coder", capabilities=["implementation", "testing"])
mcp__claude-flow__agent_spawn(type="reviewer", capabilities=["code_review", "optimization"])

# 3. Orchestrate with neural optimization
mcp__claude-flow__neural_patterns(action="analyze")
mcp__claude-flow__task_orchestrate(task="Implementation with testing and review", strategy="adaptive", priority="high")

# 4. Monitor and optimize throughout execution
mcp__claude-flow__swarm_monitor(interval=5)
mcp__claude-flow__performance_report(format="detailed")
mcp__claude-flow__bottleneck_analyze()

# 5. Store learnings and patterns for future use
mcp__claude-flow__memory_usage(action="store", key="successful_implementation_pattern", value="execution_results")
mcp__claude-flow__neural_train(pattern_type="coordination", training_data="workflow_results")
```

This enhanced orchestrator leverages Claude-Flow's complete MCP toolkit with SPARC methodology integration, including advanced memory systems, neural pattern recognition, cognitive analysis, and intelligent swarm coordination for maximum efficiency and continuous learning across sessions.
    '';
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
  
  # MCP servers are now configured globally in the mcp.nix module
  # This allows MCP servers to be shared across all projects


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
      # Node.js is managed by NVM, not included here
      jq         # For updating JSON configuration
    ];

    # Create Claude Code configuration files
    system.activationScripts.claudeCodeSetup = {
      text = ''
        echo "Setting up Claude Code configuration..."
        
        # Get the primary user
        PRIMARY_USER="${config.system.primaryUser}"
        USER_HOME="/Users/$PRIMARY_USER"
        
        # Create full directory structure with proper ownership
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/agents
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/commands
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/commands/frontend
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/commands/backend
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/projects
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/statsig
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/todos
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/shell-snapshots
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/ide
        sudo -u $PRIMARY_USER mkdir -p $USER_HOME/.claude/scripts
        
        # Create settings.json for Claude Code CLI
        cat > ${cfg.configDir}/settings.json << 'EOF'
        ${builtins.toJSON claudeSettings}
        EOF
        
        # MCP servers are now configured globally via the mcp.nix module
        
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
        
        # Load NVM for Node.js access
        echo "Loading NVM for npm configuration..."
        export NVM_DIR="$USER_HOME/.nvm"
        if [ -s "$NVM_DIR/nvm.sh" ]; then
          # Run as the primary user to ensure proper environment
          sudo -u $PRIMARY_USER bash -c "
            export NVM_DIR='$NVM_DIR'
            [ -s '\$NVM_DIR/nvm.sh' ] && \\. '\$NVM_DIR/nvm.sh'
            
            # Use default node version if available
            if [ -f '\$NVM_DIR/alias/default' ] && command -v nvm >/dev/null 2>&1; then
              DEFAULT_VERSION=\$(cat '\$NVM_DIR/alias/default')
              echo 'Setting NVM default version to: '\$DEFAULT_VERSION
              nvm use \"\$DEFAULT_VERSION\" --silent 2>/dev/null || echo 'Note: Using system Node.js version'
            else
              echo 'Note: No default NVM version set or nvm command not available'
            fi
            
            # Check if Node.js is available
            if command -v node >/dev/null 2>&1; then
              echo 'Using Node.js version: '\$(node --version 2>/dev/null)
              echo 'Using npm version: '\$(npm --version 2>/dev/null)
            else
              echo 'Warning: Node.js not found in PATH'
            fi
          "
        else
          echo "Warning: NVM not found, skipping npm configuration"
        fi
        
        # Clean up any existing npm global installation of claude-code
        echo "Cleaning up any existing npm global installation of @anthropic-ai/claude-code..."
        sudo -u $PRIMARY_USER bash -c "
          export NVM_DIR='$NVM_DIR'
          [ -s '\$NVM_DIR/nvm.sh' ] && \\. '\$NVM_DIR/nvm.sh'
          npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
          npm uninstall -g claude 2>/dev/null || true
        "
        
        # Set proper permissions
        chmod -R 755 ${cfg.configDir}
        chmod 644 ${cfg.configDir}/settings.json
        chmod 644 ${cfg.configDir}/agents/*.md
        chmod 644 ${cfg.configDir}/commands/*.md
        
        # Note: claude-flow should be installed separately, not during system activation
        if [ -d "/Users/angel/Projects/claude-flow" ]; then
          echo "claude-flow found at /Users/angel/Projects/claude-flow"
        else
          echo "Note: claude-flow not found. Install it manually if needed:"
          echo "  cd /Users/angel/Projects"
          echo "  git clone https://github.com/Angleito/claude-flow.git"
          echo "  cd claude-flow && npm install"
        fi
        
        # Claude Code is now installed via nix package
        echo "Claude Code CLI is installed via nix package"
        
        # Verify no global npm installation of claude-code exists
        sudo -u $PRIMARY_USER bash -c "
          export NVM_DIR='$NVM_DIR'
          [ -s '\$NVM_DIR/nvm.sh' ] && \\. '\$NVM_DIR/nvm.sh'
          if npm list -g @anthropic-ai/claude-code 2>/dev/null | grep -q '@anthropic-ai/claude-code'; then
            echo 'WARNING: Found global npm installation of @anthropic-ai/claude-code, removing...'
            npm uninstall -g @anthropic-ai/claude-code --force
          fi
        "
        
        # Install required MCP servers globally (always latest versions)
        echo "Installing MCP servers..."
        sudo -u $PRIMARY_USER bash -c "
          export NVM_DIR='$NVM_DIR'
          [ -s '\$NVM_DIR/nvm.sh' ] && \\. '\$NVM_DIR/nvm.sh'
          
          if command -v npm &> /dev/null; then
            # First uninstall existing versions to ensure we get latest
            npm uninstall -g @modelcontextprotocol/server-filesystem \
                             @modelcontextprotocol/server-memory \
                             @modelcontextprotocol/server-sequential-thinking \
                             @cloudflare/mcp-server-puppeteer \
                             @puppeteer/mcp-server \
                             @michaeltliu/mcp-server-playwright \
                             mcp-omnisearch \
                             ruv-swarm 2>/dev/null || true
            
            # Install latest versions
            npm install -g @modelcontextprotocol/server-filesystem@latest \
                           @modelcontextprotocol/server-memory@latest \
                           @modelcontextprotocol/server-sequential-thinking@latest \
                           @puppeteer/mcp-server@latest \
                           @michaeltliu/mcp-server-playwright@latest \
                           mcp-omnisearch@latest \
                           ruv-swarm@latest --force || echo 'Some MCP servers failed to install'
          else
            echo 'npm not found, skipping MCP server installation'
          fi
        "
        
        echo "Claude Code configuration complete!"
      '';
    };
    
    # Claude Code is managed by Nix, not npm
    # The nix package provides the 'claude' command directly
  };
}