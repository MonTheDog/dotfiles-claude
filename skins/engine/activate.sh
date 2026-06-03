#!/bin/bash
# Claude Skins — activate a skin
# Usage: activate.sh <skin-name>
# Called by SessionStart hook or /skin command

set -euo pipefail

SKINS_DIR="$HOME/.claude/skins"
ENGINE_DIR="$SKINS_DIR/engine"
RESTORE_FILE="/tmp/claude-skin-restore"

# Load pure-bash YAML parser
# shellcheck source=engine/parse-yaml.sh
source "$ENGINE_DIR/parse-yaml.sh"

# Finds a writable terminal device even when /dev/tty is inaccessible
# (e.g. Claude Code hook context where controlling terminal is detached).
# Walks the process tree from PPID upward looking for a /dev/pts/* fd.
_find_tty() {
  local pid=$PPID
  local seen="::"
  while [[ $pid -gt 1 ]]; do
    [[ "$seen" == *":$pid:"* ]] && break
    seen="${seen}${pid}:"
    local target
    for fd_link in /proc/$pid/fd/0 /proc/$pid/fd/1 /proc/$pid/fd/2; do
      target=$(readlink "$fd_link" 2>/dev/null) || continue
      if [[ "$target" == /dev/pts/* ]] && [[ -w "$target" ]] 2>/dev/null; then
        echo "$target"
        return 0
      fi
    done
    local ppid
    ppid=$(awk '/^PPid:/{print $2}' "/proc/$pid/status" 2>/dev/null) || break
    pid=$ppid
  done
  return 1
}

# Resolve terminal: prefer /dev/tty, fall back to pts lookup
_resolve_tty() {
  if { > /dev/tty; } 2>/dev/null; then
    echo "/dev/tty"
  else
    _find_tty
  fi
}

skin_name="${1:-}"

# If no name given, check env override then config
if [[ -z "$skin_name" ]]; then
  if [[ -n "${CLAUDE_SKIN_OVERRIDE:-}" ]]; then
    skin_name="$CLAUDE_SKIN_OVERRIDE"
  elif [[ -f "$ENGINE_DIR/config.yaml" ]]; then
    skin_name=$(get_yaml_value "$ENGINE_DIR/config.yaml" "default_skin" 2>/dev/null || echo "default")
    [[ -z "$skin_name" ]] && skin_name="default"
  else
    skin_name="default"
  fi
fi

# Skip activation for default skin
[[ "$skin_name" == "default" ]] && exit 0

skin_file="$SKINS_DIR/${skin_name}.yaml"
default_file="$SKINS_DIR/default.yaml"

if [[ ! -f "$skin_file" ]]; then
  echo "Skin not found: $skin_name"
  echo "Available skins:"
  for f in "$SKINS_DIR"/*.yaml; do
    [[ "$(basename "$f")" == "default.yaml" ]] && continue
    basename "$f" .yaml
  done
  exit 1
fi

# Helper: get value with fallback to default.yaml
yval() {
  get_yaml_value_with_default "$skin_file" "$default_file" "$1"
}

# Helper: get block scalar with fallback to default.yaml
yblock() {
  get_yaml_block_with_default "$skin_file" "$default_file" "$1"
}

# --- Save terminal state marker for restore ---
echo "reset" > "$RESTORE_FILE"

# --- Apply terminal colors via /dev/tty (reaches actual terminal) ---
bg=$(yval "terminal.background")
fg=$(yval "terminal.foreground")
cursor=$(yval "terminal.cursor")

TTY=$(_resolve_tty 2>/dev/null || true)
if [[ -n "$TTY" ]]; then
  {
    [[ -n "$bg" ]] && printf '\033]11;%s\007' "$bg"
    [[ -n "$fg" ]] && printf '\033]10;%s\007' "$fg"
    [[ -n "$cursor" ]] && printf '\033]12;%s\007' "$cursor"

    # Apply palette colors (ANSI 0-7)
    palette_colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
    for i in "${!palette_colors[@]}"; do
      color=$(get_yaml_value "$skin_file" "terminal.palette.${palette_colors[$i]}")
      [[ -n "$color" ]] && printf '\033]4;%d;%s\007' "$i" "$color"
    done

    # Set terminal title
    printf '\033]0;Claude ◆ %s\007' "$skin_name"
  } > "$TTY" 2>/dev/null || true
fi

# --- Write active skin ---
echo "$skin_name" > "$ENGINE_DIR/current"

# --- Inject personality into stdout (becomes Claude system instructions) ---
personality_file="$SKINS_DIR/personalities/${skin_name}.md"
if [[ -f "$personality_file" ]]; then
  # Strip YAML frontmatter, print only the body
  awk 'BEGIN{d=0;skip=1} /^---$/{d++;if(d<=2)next} d>=2{skip=0} !skip{print}' "$personality_file"
fi

# --- Print banner ---
# Only attempt /dev/tty (direct terminal invocations); skip when running
# from Claude Code's Bash tool where /dev/tty is inaccessible.
# The skill calls show-banner.sh separately so the banner reaches the user
# via the Bash tool's stdout channel.
banner=$(yblock "branding.banner")
hero=$(yblock "branding.hero")
welcome=$(yval "branding.welcome")

_print_banner() {
  echo ""
  [[ -n "$hero" ]] && echo -e "$hero" && echo ""
  [[ -n "$banner" ]] && echo -e "$banner" && echo ""
  [[ -n "$welcome" ]] && echo -e "\033[2m$welcome\033[0m"
  echo ""
}

if [[ -n "${TTY:-}" ]]; then
  { printf '\033[2J\033[H'; _print_banner; } > "$TTY"
fi
