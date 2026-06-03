#!/bin/bash
# Print a skin's banner to stdout — use from the skill or Bash tool context
# where /dev/tty is unavailable but stdout reaches the user.
# Usage: show-banner.sh <skin-name>

SKINS_DIR="$HOME/.claude/skins"
ENGINE_DIR="$SKINS_DIR/engine"

source "$ENGINE_DIR/parse-yaml.sh"

skin_name="${1:-$(cat "$ENGINE_DIR/current" 2>/dev/null || echo "default")}"
[[ "$skin_name" == "default" || -z "$skin_name" ]] && exit 0

skin_file="$SKINS_DIR/${skin_name}.yaml"
default_file="$SKINS_DIR/default.yaml"

[[ ! -f "$skin_file" ]] && exit 1

banner=$(get_yaml_block_with_default "$skin_file" "$default_file" "branding.banner")
hero=$(get_yaml_block_with_default "$skin_file" "$default_file" "branding.hero")
welcome=$(get_yaml_value_with_default "$skin_file" "$default_file" "branding.welcome")

echo ""
[[ -n "$hero" ]]    && echo -e "$hero"    && echo ""
[[ -n "$banner" ]]  && echo -e "$banner"  && echo ""
[[ -n "$welcome" ]] && echo -e "\033[2m$welcome\033[0m"
echo ""
echo ""
