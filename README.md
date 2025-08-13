# Claude Config Templates

A comprehensive template system for configuring Claude Code as an autonomous development agent. This repository provides structured workflows, requirements analysis protocols, and project management templates that transform Claude into a systematic software development partner.

## What This Provides

- **CLAUDE.md Template**: Complete agent workflow configuration for Claude Code
- **Project Structure Templates**: Organized file hierarchy for multi-project management  
- **Setup Scripts**: Automated tools to quickly configure new projects
- **Requirements Analysis**: Protocols to prevent implementation misalignment

## Quick Start

### Setup and Launch Claude
```bash
# Clone this repository
git clone <repository-url> claude-config
cd claude-config

# Launch Claude with automatic project configuration
./claudew.sh

# Or configure a specific project directory
cd /path/to/your/project
/path/to/claude-config/claudew.sh

# Include project setup wizard
./claudew.sh --wizard
```

### Create Sub-Projects
```bash
# Create a new feature/component project
./new-project.sh my-feature-name
```

## Files Overview

### Core Templates
- **`CLAUDE_TEMPLATE.md`**: Master template for CLAUDE.md agent configuration
- **`PROJECT.md`**: High-level project description template
- **`AGENT.md`**: Agent-specific workflow and rules

### Project Structure
- **`.agent_projects/_template/`**: Template files for sub-projects
  - `PROJECT.md`: Individual project goals and requirements
  - `BACKLOG.md`: Story backlog for the project  
  - `TODO.md`: Active task list
  - `STATUS.md`: Completion log and progress tracking
  - `RFCs.md`: Architectural decisions and designs
- **`.agent_projects/CONVENTIONS.md`**: Code style and technical conventions

### Setup Scripts
- **`claudew.sh`**: Claude wrapper that auto-configures projects and launches Claude Code
- **`new-project.sh`**: Creates new sub-project from templates

## How It Works

### Agent Workflow Loop
1. **Plan** → Select highest-priority backlog task
2. **Implement** → Build the selected feature/fix
3. **Test** → Run tests and fix any regressions  
4. **Refactor** → Improve code quality and reduce complexity
5. **Validate** → Ensure user experience is intuitive
6. **Track** → Update progress and project status

### Requirements Analysis
Prevents costly rework by detecting common conflict patterns:
- Existing code vs. new specifications
- Technology stack mismatches  
- Vague requirements vs. detailed specs

### Multi-Project Management
Organize complex software projects with:
- Repository-level tracking (`BACKLOG.md`, `TODO.md`, `PROGRESS.md`)
- Project-specific documentation (`.agent_projects/<project>/`)
- Cross-project milestone coordination

## Best Practices

1. **Place CLAUDE.md in project root** - Provides context for all Claude interactions
2. **Customize for your stack** - Update environment and testing sections
3. **Use project templates** - Maintain consistency across features/components
4. **Follow the workflow loops** - Let Claude systematically work through tasks
5. **Leverage requirements analysis** - Always clarify conflicts before implementing

## Usage Examples

### Setting Up a New Web App
```bash
cd ~/my-web-app
/path/to/claude-config/claudew.sh --wizard
# Answer wizard questions to generate PROJECT.md
# Claude Code launches automatically with full configuration
```

### Adding a New Feature
```bash
./new-project.sh user-authentication
# Edit .agent_projects/user-authentication/PROJECT.md
# Add stories to .agent_projects/user-authentication/BACKLOG.md
```

### Working with Claude
The `claudew.sh` wrapper provides:
- **Automatic detection**: Identifies unconfigured projects and offers setup
- **Smart configuration**: Only installs missing components, preserves existing setup
- **Seamless launch**: Configures then immediately launches Claude Code
- **Enhanced workflows**: Claude automatically follows structured development loops
- **Requirements analysis**: Built-in conflict detection prevents implementation misalignment

## Repository Contents

This repository contains everything needed to transform Claude Code into a structured, autonomous development agent that can manage complex multi-project software development with minimal human intervention.
