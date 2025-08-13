#!/bin/bash

# Claude Wrapper (claudew) - Enhanced Claude Code launcher
# Automatically configures Claude Code projects and launches Claude

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"
WIZARD_MODE=false
FORCE_SETUP=false

# Auto-install dependencies (fnm, node, claude)
install_dependencies() {
    echo "Checking system dependencies..."
    
    # Check and install curl if needed (Linux only - macOS has it built-in)
    if ! command -v curl >/dev/null 2>&1; then
        echo "Installing curl..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y curl
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y curl
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm curl
        else
            echo "Unable to install curl automatically. Please install curl manually."
            exit 1
        fi
    fi
    
    # Check and install fnm (Fast Node Manager)
    if ! command -v fnm >/dev/null 2>&1; then
        echo "Installing fnm (Fast Node Manager)..."
        curl -fsSL https://fnm.vercel.app/install | bash
        
        # Source the shell configuration to get fnm in PATH
        if [ -f "$HOME/.bashrc" ]; then
            source "$HOME/.bashrc" 2>/dev/null || true
        fi
        if [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc" 2>/dev/null || true
        fi
        
        # Ensure fnm is available for this session
        export PATH="$HOME/.fnm:$PATH"
        if command -v fnm >/dev/null 2>&1; then
            eval "$(fnm env --use-on-cd)" 2>/dev/null || true
        fi
    fi
    
    # Ensure fnm is in PATH for this session
    if [ -f "$HOME/.fnm/fnm" ]; then
        export PATH="$HOME/.fnm:$PATH"
        eval "$(fnm env --use-on-cd)" 2>/dev/null || true
    fi
    
    # Check and install Node.js via fnm
    if ! command -v node >/dev/null 2>&1; then
        echo "Installing Node.js (latest LTS)..."
        fnm install --lts
        fnm use lts-latest
        fnm default lts-latest
    fi
    
    # Check and install Claude Code
    if ! command -v claude >/dev/null 2>&1; then
        echo "Installing Claude Code..."
        if command -v npm >/dev/null 2>&1; then
            npm install -g @anthropic/claude-code
        else
            echo "npm not found after Node.js installation"
            exit 1
        fi
    fi
    
    echo "All dependencies verified"
}

# Install managed settings for Claude Code
install_managed_settings() {
    local settings_file="$SCRIPT_DIR/managed-settings.bedrock.json"
    
    # Check if managed settings file exists
    if [ ! -f "$settings_file" ]; then
        echo "managed-settings.bedrock.json not found, skipping managed settings installation"
        return 0
    fi
    
    echo "Installing Claude Code managed settings..."
    
    # Determine OS and set appropriate path
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local settings_dir="/Library/Application Support/ClaudeCode"
        local settings_path="$settings_dir/managed-settings.json"
        
        echo "Installing to macOS system location: $settings_path"
        
        # Create directory if it doesn't exist
        if sudo mkdir -p "$settings_dir"; then
            # Copy and rename file
            if sudo cp "$settings_file" "$settings_path"; then
                echo "Managed settings installed for macOS"
            else
                echo "Failed to copy managed settings to $settings_path"
            fi
        else
            echo "Failed to create directory $settings_dir"
        fi
        
    else
        # Linux/WSL
        local settings_dir="/etc/claude-code"
        local settings_path="$settings_dir/managed-settings.json"
        
        echo "Installing to Linux system location: $settings_path"
        
        # Create directory if it doesn't exist
        if sudo mkdir -p "$settings_dir"; then
            # Copy and rename file
            if sudo cp "$settings_file" "$settings_path"; then
                echo "Managed settings installed for Linux/WSL"
            else
                echo "Failed to copy managed settings to $settings_path"
            fi
        else
            echo "Failed to create directory $settings_dir"
        fi
    fi
}

# Prompt user to install claudew to PATH
prompt_path_installation() {
    local script_name="claudew"
    local script_path="$SCRIPT_DIR/claudew.sh"
    
    # Check if already on PATH
    if command -v "$script_name" >/dev/null 2>&1; then
        # Already on PATH, continue silently
        return 0
    fi
    
    echo ""
    echo "claudew is not in your PATH"
    echo "Would you like to install it globally so you can run 'claudew' from any directory?"
    echo ""
    read -p "Install claudew to PATH? [Y/n]: " -r INSTALL_PATH_CHOICE
    echo ""
    
    case "${INSTALL_PATH_CHOICE:-Y}" in
        [Yy]* )
            # Try /usr/local/bin first
            if [[ ":$PATH:" == *":/usr/local/bin:"* ]] && [ -d "/usr/local/bin" ]; then
                echo "Installing to /usr/local/bin..."
                if sudo ln -sf "$script_path" "/usr/local/bin/$script_name"; then
                    echo "claudew installed to /usr/local/bin"
                    echo "You can now run 'claudew' from any directory"
                    return 0
                else
                    echo "Failed to install to /usr/local/bin, trying user-local..."
                fi
            fi
            
            # Fallback: create ~/.local/bin and add to PATH
            local local_bin="$HOME/.local/bin"
            
            # Create ~/.local/bin if it doesn't exist
            if [ ! -d "$local_bin" ]; then
                echo "Creating $local_bin..."
                mkdir -p "$local_bin"
            fi
            
            # Install symlink
            echo "Creating symlink in $local_bin..."
            ln -sf "$script_path" "$local_bin/$script_name"
            echo "claudew installed to $local_bin"
            
            # Check if ~/.local/bin is already on PATH
            if [[ ":$PATH:" == *":$local_bin:"* ]]; then
                echo "$local_bin already in PATH"
                return 0
            fi
            
            # Add to PATH via .zshrc
            local zshrc="$HOME/.zshrc"
            local path_line="export PATH=\"$local_bin:\$PATH\""
            
            echo "Adding $local_bin to PATH in $zshrc..."
            
            # Check if line already exists
            if [ -f "$zshrc" ] && grep -Fq "$local_bin" "$zshrc"; then
                echo "PATH already configured in $zshrc"
            else
                echo "" >> "$zshrc"
                echo "# Added by claudew installer" >> "$zshrc"
                echo "$path_line" >> "$zshrc"
                echo "PATH updated in $zshrc"
            fi
            
            echo ""
            echo "claudew is now installed!"
            echo "Restart your terminal or run: source $zshrc"
            echo "Then you can run 'claudew' from any directory"
            echo ""
            ;;
        * )
            echo "Skipping PATH installation - you can run claudew using the full path"
            ;;
    esac
}

# Run dependency checks, managed settings, and PATH installation on startup
install_dependencies
install_managed_settings
prompt_path_installation

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
    echo "Claude Wrapper"
    echo "Current directory: $CURRENT_DIR"
    echo ""
    
    if [ "$FORCE_SETUP" = true ]; then
        echo "Force setup requested"
    else
        echo "This directory is not configured for Claude Code"
    fi
    
    echo ""
    echo "Would you like to configure this project for enhanced Claude Code workflows?"
    echo "This will set up CLAUDE.md, project structure, and optional dotfiles."
    echo ""
    read -p "Configure project? [Y/n]: " -r CONFIGURE_CHOICE
    echo ""
    
    case "${CONFIGURE_CHOICE:-Y}" in
        [Yy]* )
            echo "Configuring project for Claude Code..."
            ;;
        * )
            echo "Skipping configuration, launching Claude Code..."
            exec claude "$@"
            ;;
    esac
else
    echo "Claude Wrapper - launching Claude Code..."
    exec claude "$@"
fi

# Configuration setup begins here

# Copy CLAUDE.md template
if [ ! -f "CLAUDE.md" ] || [ "$FORCE_SETUP" = true ]; then
    cp "$SCRIPT_DIR/CLAUDE_TEMPLATE.md" "CLAUDE.md"
fi

# Copy PROJECT.md template if it doesn't exist
if [ ! -f "PROJECT.md" ] || [ "$FORCE_SETUP" = true ]; then
    cp "$SCRIPT_DIR/PROJECT.md" "PROJECT.md"
fi

# Copy agent planning structure
if [ ! -d ".agent_planning" ] || [ "$FORCE_SETUP" = true ]; then
    cp -r "$SCRIPT_DIR/agent_planning" ".agent_planning"
fi

# Add project setup wizard if requested
if [ "$WIZARD_MODE" = true ]; then
    cp "$SCRIPT_DIR/agent_planning/PROJECT_SETUP.md" "PROJECT_SETUP.md"
fi

# Install Claude dotfiles if not present
if [ ! -d "$HOME/.claude/agents" ] && [ ! -d ".claude/agents" ]; then
    read -p "Install Claude dotfiles? [G]lobal, [L]ocal, [S]kip: " -n 1 -r DOTFILES_CHOICE
    echo ""
    
    case "${DOTFILES_CHOICE:-G}" in
        [Gg]* )
            mkdir -p "$HOME/.claude"
            cp -r "$SCRIPT_DIR/claude-dotfiles/agents" "$HOME/.claude/"
            cp -r "$SCRIPT_DIR/claude-dotfiles/commands" "$HOME/.claude/"
            ;;
        [Ll]* )
            mkdir -p ".claude"
            cp -r "$SCRIPT_DIR/claude-dotfiles/agents" ".claude/"
            cp -r "$SCRIPT_DIR/claude-dotfiles/commands" ".claude/"
            ;;
    esac
fi

# Launch Claude Code
exec claude "$@"
