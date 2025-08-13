# CLAUDE.md

## Setup Check
If `setup/project-setup.md` exists, run the project setup wizard first.

## Autonomous Agent Mode
Follow the workflows defined in `AGENT.md` for autonomous development cycles.

## Project Management Files
- `PROJECT.md`: High-level goals and architecture
- `BACKLOG.md`: Feature roadmap  
- `TODO.md`: Active task list
- `PROGRESS.md`: Cross-project milestones

## Environment
- Use `uv` for Python virtual environments
- Explicitly use `python3`
- Follow `templates/conventions.md` for coding standards

## Quality Rules
- No fake demo data in production features
- Use actual data sources and APIs
- Show proper empty states when no data exists
- Run tests before marking tasks complete

## Repository Structure
- `projects/`: Active development projects
- `templates/`: Project templates and conventions
- `agents/`: Agent behavior definitions
- `commands/`: Workflow command implementations