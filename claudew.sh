#!/bin/zsh -el
# Claude Wrapper (claudew) - Enhanced Claude Code launcher (zsh-compatible)

set -e

# Resolve script + dirs (zsh-native; works for symlinks too)
SCRIPT_PATH="${0:A}"
SCRIPT_DIR="${SCRIPT_PATH:h}"
CURRENT_DIR="$PWD"
FORCE_SETUP=false

_log() {
  printf "\033[33mclaudew:\033[0m %s\n" "$1"
}

# Auto-install dependencies (fnm, node, claude)
install_dependencies() {
  _log "Checking system dependencies..."

  # curl (Linux distros; macOS ships curl)
  if ! command -v curl >/dev/null 2>&1; then
    _log "Installing curl..."
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y curl
    elif command -v yum     >/dev/null 2>&1; then sudo yum install -y curl
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y curl
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm curl
    else
      _log "Unable to install curl automatically. Please install curl manually."; exit 1
    fi
  fi

  # fnm (Fast Node Manager)
  if ! command -v fnm >/dev/null 2>&1; then
    _log "Installing fnm (Fast Node Manager)..."
    curl -fsSL https://fnm.vercel.app/install | bash

    # Source common shells (if present)
    [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc" 2>/dev/null || true
    [ -f "$HOME/.zshrc"  ] && . "$HOME/.zshrc"  2>/dev/null || true

    export PATH="$HOME/.fnm:$PATH"
    command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd)" 2>/dev/null || true
  fi

  # Ensure fnm available in this session
  if [ -x "$HOME/.fnm/fnm" ]; then
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env --use-on-cd)" 2>/dev/null || true
  fi

  # Node.js via fnm
  if ! command -v node >/dev/null 2>&1; then
    _log "Installing Node.js (latest LTS)..."
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
  fi

  # Claude Code CLI
  if ! command -v claude >/dev/null 2>&1; then
    _log "Installing Claude Code..."
    if command -v npm >/dev/null 2>&1; then
      npm install -g @anthropic/claude-code
    else
      _log "npm not found after Node.js installation"; exit 1
    fi
  fi

  _log "All dependencies verified"
}

# Install managed settings for Claude Code
install_managed_settings() {
  local settings_file="$SCRIPT_DIR/managed-settings.bedrock.json"

  if [ ! -f "$settings_file" ]; then
    _log "managed-settings.bedrock.json not found, skipping managed settings installation"
    return 0
  fi

  _log "Installing Claude Code managed settings..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (system-wide)
    local settings_dir="/Library/Application Support/ClaudeCode"
    local settings_path="$settings_dir/managed-settings.json"
    _log "Installing to macOS system location: $settings_path"
    if sudo mkdir -p "$settings_dir"; then
      if sudo cp "$settings_file" "$settings_path"; then
        _log "Managed settings installed for macOS"
      else
        _log "Failed to copy managed settings to $settings_path"
      fi
    else
      _log "Failed to create directory $settings_dir"
    fi
  else
    # Linux/WSL
    local settings_dir="/etc/claude-code"
    local settings_path="$settings_dir/managed-settings.json"
    _log "Installing to Linux system location: $settings_path"
    if sudo mkdir -p "$settings_dir"; then
      if sudo cp "$settings_file" "$settings_path"; then
        _log "Managed settings installed for Linux/WSL"
      else
        _log "Failed to copy managed settings to $settings_path"
      fi
    else
      _log "Failed to create directory $settings_dir"
    fi
  fi
}

# zsh-native yes/no prompt (single key), honors AIDERW_NON_INTERACTIVE_RESPONSE
prompt_yes_no() (
  emulate -L zsh
  [[ $CLAUDEW_NON_INTERACTIVE_RESPONSE == "YES" ]] && return 0
  [[ $CLAUDEW_NON_INTERACTIVE_RESPONSE == "NO"  ]] && return 1

  local prompt_message="$1"
  local key
  while true; do
    printf "%s (y/n): " "$prompt_message"
    read -k 1 key
    printf "\n"
    case "$key" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      *) _log "Please answer yes or no." ;;
    esac
  done
)

# Offer to symlink this script into PATH as `claudew`
prompt_path_installation() {
  local script_name="claudew"
  local script_path="$SCRIPT_PATH"            # resolved absolute path
  local script_real="${script_path:A}"

  if command -v "$script_name" >/dev/null 2>&1; then
    return 0
  fi

  _log ""
  _log "claudew is not in your PATH"
  _log "Would you like to install it globally so you can run 'claudew' from any directory?"
  _log ""

  if prompt_yes_no "Install claudew to PATH?"; then
    if [[ ":$PATH:" == *":/usr/local/bin:"* ]] && [ -d "/usr/local/bin" ]; then
      _log "Installing to /usr/local/bin..."
      if sudo ln -sf "$script_real" "/usr/local/bin/$script_name"; then
        _log "claudew installed to /usr/local/bin"
        _log "You can now run 'claudew' from any directory"
        return 0
      else
        _log "Failed to install to /usr/local/bin, trying user-local..."
      fi
    fi

    local local_bin="$HOME/.local/bin"
    [ -d "$local_bin" ] || { _log "Creating $local_bin..."; mkdir -p "$local_bin"; }
    _log "Creating symlink in $local_bin..."
    ln -sf "$script_real" "$local_bin/$script_name"
    _log "claudew installed to $local_bin"

    if [[ ":$PATH:" == *":$local_bin:"* ]]; then
      _log "$local_bin already in PATH"
      return 0
    fi

    local zshrc="$HOME/.zshrc"
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    _log "Adding $local_bin to PATH in $zshrc..."
    if [ -f "$zshrc" ] && grep -Fq "$local_bin" "$zshrc"; then
      _log "PATH already configured in $zshrc"
    else
      {
        printf "\n# Added by claudew installer\n"
        printf "%s\n" "$path_line"
      } >> "$zshrc"
      _log "PATH updated in $zshrc"
    fi

    _log ""
    _log "claudew is now installed!"
    _log "Restart your terminal or run: source $zshrc"
    _log "Then you can run 'claudew' from any directory"
    _log ""
  else
    _log "Skipping PATH installation - you can run claudew using the full path"
  fi
}

pulse_claudew_sine() {
  emulate -L zsh
  zmodload zsh/mathfunc 2>/dev/null
  zmodload zsh/datetime  2>/dev/null

  local letters=(c l a u d e w)
  local n=${#letters}
  local -F base_speed=${1:-10.0}
  local dir=${2:-1}; (( dir = dir >= 0 ? 1 : -1 ))
  local -F span_frac=${3:-0.6666666667}
  local -F timeout=${4:-0}

  : ${EPOCHREALTIME:=${EPOCHSECONDS}.0}
  local -F start_time=$EPOCHREALTIME

  local hid_cursor=0
  if [[ -t 1 ]]; then printf '\e[?25l'; hid_cursor=1; fi
  trap '((hid_cursor)) && printf "\e[0m\e[?25h\n"' EXIT
  trap 'STOP=1' INT
  local STOP=0

  local -F t=0.0 two_pi=6.283185307179586 pi=3.141592653589793
  local -F span=$(( two_pi * span_frac ))
  local -F phase phi r g b
  local -F now_time
  local R G B buf
  local i
  local -a R0 G0 B0

  # MAIN WHEEL
  while (( ! STOP )); do
    if (( timeout > 0 )); then
      now_time=$EPOCHREALTIME
      (( now_time - start_time >= timeout )) && break
    fi

    buf=$'\r\033[K'
    for i in {1..$n}; do
      phi=$(( (i-1) * span / (n-1) ))
      phase=$(( t/base_speed - dir * phi ))
      r=$(( (sin(phase      ) + 1.0) * 127 ))
      g=$(( (sin(phase + 2.0) + 1.0) * 127 ))
      b=$(( (sin(phase + 4.0) + 1.0) * 127 ))
      R=$(( int(r) )); G=$(( int(g) )); B=$(( int(b) ))
      R0[i]=$R; G0[i]=$G; B0[i]=$B
      buf+=$(printf '\e[1m\e[38;2;%d;%d;%dm%s\e[22m\e[0m ' $R $G $B "${letters[i]}")
    done
    print -nr -- "$buf"
    t=$(( t + 1.0 ))
    sleep 0.03 || break
  done

  # SEQUENTIAL FADE — faster: from color to black in half a sine wave period
  if (( ! STOP )); then
    local -F fade_start=$EPOCHREALTIME
    # local -F letter_delay=$(( base_speed * span / (n-1) )) 
    local -F letter_delay=$(( 0.15 ))      # spacing between letters
    local -F fade_duration=$(( letter_delay ))             # time from full color to black
    local -F step=0.03
    local -F elapsed factor start_i end_i
    local j idx done=0

    local -a order
    if (( dir > 0 )); then
      for i in {1..$n}; do order+=$i; done
    else
      for i in {$n..1}; do order+=$i; done
    fi

    while (( ! done )); do
      now_time=$EPOCHREALTIME
      elapsed=$(( now_time - fade_start ))
      buf=$'\r\033[K'
      done=1

      for j in {1..$#order}; do
        idx=${order[j]}
        start_i=$(( (j-1) * letter_delay ))
        end_i=$(( start_i + fade_duration ))

        if (( elapsed <= start_i )); then
          factor=1.0
          done=0
        elif (( elapsed >= end_i )); then
          factor=0.0
        else
          factor=$(( 1.0 - (elapsed - start_i) / fade_duration ))
          done=0
        fi

        R=$(( int(R0[idx] * factor) ))
        G=$(( int(G0[idx] * factor) ))
        B=$(( int(B0[idx] * factor) ))
        buf+=$(printf '\e[1m\e[38;2;%d;%d;%dm%s\e[22m\e[0m ' $R $G $B "${letters[idx]}")
      done

      print -nr -- "$buf"
      (( done )) || sleep $step || break
    done
  fi

  print -nr -- $'\r\033[K'
}

launch_claude() {  
  # continues drawing in the current TTY while the script proceeds
  pulse_claudew_sine 4 1 .3 4 > /dev/tty &

  # Launch Claude Code
  mkdir -p "${SETUP_DONE_FILE:h}"
  : > "${SETUP_DONE_FILE}"
  exec claude "$@"
  exit $?
}


#######################################################################################

install_dependencies
prompt_path_installation
# install_managed_settings   # Uncomment if you want managed settings applied automatically

FORCE_SETUP=false
USE_BEDROCK=false
SETUP_DONE_FILE=".agent_planning/.claudeplusplus.setupdone"

# Flags
for arg in "$@"; do
  case "$arg" in
    --force|-f)
      rm -f "${SETUP_DONE_FILE}"
      FORCE_SETUP=true
      ;;
    --bedrock|-b)
      USE_BEDROCK=true
      ;;
    --help|-h)
      cat <<'EOF'
Claude Wrapper (claudew) - Enhanced Claude Code launcher

Usage: claudew [options]

Options:
  --bedrock, -b   Configure Claude to use AWS Bedrock
  --force,  -f    Force configuration setup even if already configured
  --help,   -h    Show this help message

The first time you run this in a project directory, it will attempt to configure the project using
an autonomous agentic workflow. It will only prompt once. To get prompted again, use --force/-f or:
  rm -f .agent_planning/.claudeplusplus.setupdone

Note: using --force will also reset the content of any planning files this repo creates.
EOF
      exit 0
      ;;
  esac
done

# Determine if configuration is needed
NEEDS_CONFIG=false
[ -f "${SETUP_DONE_FILE}" ] || NEEDS_CONFIG=true

# Prompt for initial configuration
if [[ "$NEEDS_CONFIG" == true ]]; then
  printf "Claude Wrapper\nCurrent directory: %s\n\n" "$CURRENT_DIR"
  printf "Would you like to configure this project with an enhanced Claude Code workflow?\n"
  printf "This will set up a CLAUDE.md file and more structured planning for the agent.\n"
  printf "It's recommended to try it; you can always modify it later.\n\n"
  if ! prompt_yes_no "Configure enhanced workflow?"; then
    printf "Skipping configuration, launching Claude Code...\n"
    NEEDS_CONFIG=false
  fi
fi

if [[ "$NEEDS_CONFIG" == false ]]; then
  launch_claude "$@"
fi

# Configuration setup
[ -f "CLAUDE.md" ] && [[ "$FORCE_SETUP" != true ]] || cp "$SCRIPT_DIR/CLAUDE_TEMPLATE.md" "CLAUDE.md"

if [ -d ".agent_planning" ] && [[ "$FORCE_SETUP" != true ]]; then
  :
else
  cp -r "$SCRIPT_DIR/agent_planning" ".agent_planning"
fi

cp "$SCRIPT_DIR/agent_planning/PROJECT_SETUP.md" "PROJECT_SETUP.md"

# Install Claude dotfiles if not present
if [ ! -d "$HOME/.claude/agents" ] && [ ! -d ".claude/agents" ]; then
  printf "Install Claude Code custom prompts and agents?\n"
  printf "Install Claude ? [G]lobal, [L]ocal, [S]kip: "
  read -k 1 DOTFILES_CHOICE
  printf "\n"
  case "${DOTFILES_CHOICE:-G}" in
    [Gg])
      mkdir -p "$HOME/.claude"
      cp -r "$SCRIPT_DIR/claude-dotfiles/agents"   "$HOME/.claude/"
      cp -r "$SCRIPT_DIR/claude-dotfiles/commands" "$HOME/.claude/"
      ;;
    [Ll])
      mkdir -p ".claude"
      cp -r "$SCRIPT_DIR/claude-dotfiles/agents"   ".claude/"
      cp -r "$SCRIPT_DIR/claude-dotfiles/commands" ".claude/"
      ;;
    *) : ;;
  esac
fi

launch_claude "$@"
