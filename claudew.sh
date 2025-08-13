#!/bin/bash

# Claude Wrapper (claudew) - Enhanced Claude Code launcher
# Automatically configures Claude Code projects and launches Claude

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"
WIZARD_MODE=false
FORCE_SETUP=false

# Check if script is on PATH and auto-install if needed
check_and_install_to_path() {
    local script_name="claudew"
    local script_path="$SCRIPT_DIR/claudew.sh"
    
    # Check if already on PATH
    if command -v "$script_name" >/dev/null 2>&1; then
        # Already on PATH, continue
        return 0
    fi
    
    echo "🔧 Setting up claudew in PATH for global access..."
    
    # Check if /usr/local/bin exists and is on PATH
    if [[ ":$PATH:" == *":/usr/local/bin:"* ]] && [ -d "/usr/local/bin" ]; then
        echo "📂 Installing to /usr/local/bin..."
        if sudo ln -sf "$script_path" "/usr/local/bin/$script_name"; then
            echo "✅ claudew installed to /usr/local/bin"
            echo "💡 You can now run 'claudew' from any directory"
            return 0
        else
            echo "⚠️  Failed to install to /usr/local/bin"
        fi
    fi
    
    # Fallback: create ~/.local/bin and add to PATH
    local local_bin="$HOME/.local/bin"
    
    # Create ~/.local/bin if it doesn't exist
    if [ ! -d "$local_bin" ]; then
        echo "📁 Creating $local_bin..."
        mkdir -p "$local_bin"
    fi
    
    # Install symlink
    echo "🔗 Creating symlink in $local_bin..."
    ln -sf "$script_path" "$local_bin/$script_name"
    echo "✅ claudew installed to $local_bin"
    
    # Check if ~/.local/bin is already on PATH
    if [[ ":$PATH:" == *":$local_bin:"* ]]; then
        echo "✅ $local_bin already in PATH"
        return 0
    fi
    
    # Add to PATH via .zshrc
    local zshrc="$HOME/.zshrc"
    local path_line="export PATH=\"$local_bin:\$PATH\""
    
    echo "🔧 Adding $local_bin to PATH in $zshrc..."
    
    # Check if line already exists
    if [ -f "$zshrc" ] && grep -Fq "$local_bin" "$zshrc"; then
        echo "✅ PATH already configured in $zshrc"
    else
        echo "" >> "$zshrc"
        echo "# Added by claudew installer" >> "$zshrc"
        echo "$path_line" >> "$zshrc"
        echo "✅ PATH updated in $zshrc"
    fi
    
    echo ""
    echo "🚀 claudew is now installed!"
    echo "💡 Restart your terminal or run: source $zshrc"
    echo "💡 Then you can run 'claudew' from any directory"
    echo ""
}

# Run PATH check on startup
check_and_install_to_path

# Check for flags
for arg in "$@"; do
    case "$arg" in
        --wizard)
            WIZARD_MODE=true
            ;;
        --setup)
            FORCE_SETUP=true
            ;;
        --help|-h)
            echo "Claude Wrapper (claudew) - Enhanced Claude Code launcher"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --wizard    Include project setup wizard"
            echo "  --setup     Force configuration setup even if already configured"
            echo "  --help, -h  Show this help message"
            echo ""
            echo "If run in an unconfigured project directory, will prompt to configure."
            echo "After configuration (or if already configured), launches Claude Code."
            exit 0
            ;;
    esac
done

# Check if current directory needs configuration
NEEDS_CONFIG=false

if [ ! -f "CLAUDE.md" ] || [ "$FORCE_SETUP" = true ]; then
    NEEDS_CONFIG=true
fi

# If configuration is needed, prompt user
if [ "$NEEDS_CONFIG" = true ]; then
    echo "🤖 Claude Wrapper"
    echo "Current directory: $CURRENT_DIR"
    echo ""
    
    if [ "$FORCE_SETUP" = true ]; then
        echo "⚙️  Force setup requested"
    else
        echo "📋 This directory is not configured for Claude Code"
    fi
    
    echo ""
    echo "Would you like to configure this project for enhanced Claude Code workflows?"
    echo "This will set up CLAUDE.md, project structure, and optional dotfiles."
    echo ""
    read -p "Configure project? [Y/n]: " -r CONFIGURE_CHOICE
    echo ""
    
    case "${CONFIGURE_CHOICE:-Y}" in
        [Yy]* )
            echo "🚀 Configuring project for Claude Code..."
            ;;
        * )
            echo "⏭️  Skipping configuration, launching Claude Code..."
            exec claude "$@"
            ;;
    esac
else
    echo "🤖 Claude Wrapper - launching Claude Code..."
    exec claude "$@"
fi

# Configuration setup begins here

# Copy CLAUDE.md template
if [ ! -f "CLAUDE.md" ] || [ "$FORCE_SETUP" = true ]; then
    echo "📝 Creating CLAUDE.md..."
    cp "$SCRIPT_DIR/CLAUDE_TEMPLATE.md" "CLAUDE.md"
    echo "✅ CLAUDE.md created"
else
    echo "⚠️  CLAUDE.md already exists, skipping..."
fi

# Copy PROJECT.md template if it doesn't exist
if [ ! -f "PROJECT.md" ] || [ "$FORCE_SETUP" = true ]; then
    echo "📋 Creating PROJECT.md template..."
    cp "$SCRIPT_DIR/PROJECT.md" "PROJECT.md"
    echo "✅ PROJECT.md template created"
else
    echo "⚠️  PROJECT.md already exists, skipping..."
fi

# Create .agent_projects directory structure
echo "📁 Setting up .agent_projects structure..."
mkdir -p ".agent_projects"

# Copy template files
if [ ! -d ".agent_projects/_template" ]; then
    cp -r "$SCRIPT_DIR/agent_projects/_template" ".agent_projects/_template"
    echo "✅ Project template structure created"
else
    echo "⚠️  Template directory already exists, skipping..."
fi

# Copy CONVENTIONS.md and remove example content
if [ ! -f ".agent_projects/CONVENTIONS.md" ]; then
    # Copy file and remove everything below the divider line
    sed '/^##############################################################################$/,$d' "$SCRIPT_DIR/agent_projects/CONVENTIONS.md" > ".agent_projects/CONVENTIONS.md"
    echo "✅ CONVENTIONS.md copied (example content removed)"
else
    echo "⚠️  CONVENTIONS.md already exists, skipping..."
fi

# Create repository-level files if they don't exist
echo "📄 Creating repository-level tracking files..."

files_to_create=(
    "BACKLOG.md:Project roadmap (names/descriptions only)."
    "TODO.md:Active TODO list"
    "PROGRESS.md:Cross-project milestones, stability metrics, architectural health."
    "DEPRECATED.md:Auto-updated list of deprecated components."
)

for file_info in "${files_to_create[@]}"; do
    filename="${file_info%%:*}"
    description="${file_info#*:}"

    if [ ! -f "$filename" ]; then
        echo "$description" > "$filename"
        echo "✅ Created $filename"
    else
        echo "⚠️  $filename already exists, skipping..."
    fi
done

# Add project setup wizard if requested
if [ "$WIZARD_MODE" = true ]; then
    echo "🧙 Adding project setup wizard..."
    cp "$SCRIPT_DIR/PROJECT_SETUP.md" "PROJECT_SETUP.md"
    echo "✅ Project setup wizard included"
fi

# Check for and optionally install Claude dotfiles (agents and commands)
echo "🔧 Checking Claude dotfiles configuration..."

# Check if dotfiles exist globally or locally
GLOBAL_AGENTS_EXIST=false
GLOBAL_COMMANDS_EXIST=false
LOCAL_AGENTS_EXIST=false
LOCAL_COMMANDS_EXIST=false

if [ -d "$HOME/.claude/agents" ] && [ "$(ls -A "$HOME/.claude/agents" 2>/dev/null)" ]; then
    GLOBAL_AGENTS_EXIST=true
fi

if [ -d "$HOME/.claude/commands" ] && [ "$(ls -A "$HOME/.claude/commands" 2>/dev/null)" ]; then
    GLOBAL_COMMANDS_EXIST=true
fi

if [ -d ".claude/agents" ] && [ "$(ls -A ".claude/agents" 2>/dev/null)" ]; then
    LOCAL_AGENTS_EXIST=true
fi

if [ -d ".claude/commands" ] && [ "$(ls -A ".claude/commands" 2>/dev/null)" ]; then
    LOCAL_COMMANDS_EXIST=true
fi

# Determine if we need to install dotfiles
NEED_AGENTS=true
NEED_COMMANDS=true

if [ "$GLOBAL_AGENTS_EXIST" = true ] || [ "$LOCAL_AGENTS_EXIST" = true ]; then
    NEED_AGENTS=false
    if [ "$GLOBAL_AGENTS_EXIST" = true ]; then
        echo "✅ Claude agents found globally (~/.claude/agents)"
    else
        echo "✅ Claude agents found locally (.claude/agents)"
    fi
fi

if [ "$GLOBAL_COMMANDS_EXIST" = true ] || [ "$LOCAL_COMMANDS_EXIST" = true ]; then
    NEED_COMMANDS=false
    if [ "$GLOBAL_COMMANDS_EXIST" = true ]; then
        echo "✅ Claude commands found globally (~/.claude/commands)"
    else
        echo "✅ Claude commands found locally (.claude/commands)"
    fi
fi

# Install dotfiles if needed
if [ "$NEED_AGENTS" = true ] || [ "$NEED_COMMANDS" = true ]; then
    echo ""
    echo "📁 Claude dotfiles (agents and commands) not found."
    echo "These provide enhanced workflow automation for Claude Code."
    echo ""
    echo "Install location options:"
    echo "  [G] Global - ~/.claude/ (recommended, available to all projects)"
    echo "  [L] Local - ./.claude/ (project-specific)"
    echo "  [S] Skip installation"
    echo ""
    read -p "Install Claude dotfiles? [G/l/s]: " -n 1 -r DOTFILES_CHOICE
    echo ""
    
    case "${DOTFILES_CHOICE:-G}" in
        [Gg]* )
            echo "🏠 Installing Claude dotfiles globally..."
            mkdir -p "$HOME/.claude"
            if [ "$NEED_AGENTS" = true ]; then
                cp -r "$SCRIPT_DIR/claude-dotfiles/agents" "$HOME/.claude/"
                echo "✅ Agents installed to ~/.claude/agents"
            fi
            if [ "$NEED_COMMANDS" = true ]; then
                cp -r "$SCRIPT_DIR/claude-dotfiles/commands" "$HOME/.claude/"
                echo "✅ Commands installed to ~/.claude/commands"
            fi
            ;;
        [Ll]* )
            echo "📂 Installing Claude dotfiles locally..."
            mkdir -p ".claude"
            if [ "$NEED_AGENTS" = true ]; then
                cp -r "$SCRIPT_DIR/claude-dotfiles/agents" ".claude/"
                echo "✅ Agents installed to .claude/agents"
            fi
            if [ "$NEED_COMMANDS" = true ]; then
                cp -r "$SCRIPT_DIR/claude-dotfiles/commands" ".claude/"
                echo "✅ Commands installed to .claude/commands"
            fi
            ;;
        * )
            echo "⏭️  Skipping Claude dotfiles installation"
            ;;
    esac
else
    echo "✅ Claude dotfiles already configured"
fi

# Configuration complete, launch Claude
echo ""
echo "🎉 Claude Config setup complete!"
echo ""

if [ "$WIZARD_MODE" = true ]; then
    echo "💡 Project setup wizard included - Claude will run it automatically"
else
    echo "💡 Edit PROJECT.md to customize your project description"
fi

echo "📁 Use ./new-project.sh <name> to create feature projects"
echo ""
echo "🚀 Launching Claude Code..."
echo ""

# Hand off to Claude Code
exec claude "$@"
