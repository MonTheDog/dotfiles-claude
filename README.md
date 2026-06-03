# Claude Code Config

Portable Claude Code configuration: hooks, skins, and custom skills.

## What's included

| Path | Purpose |
|------|---------|
| `settings.json` | Hooks (SessionStart banner, PostToolUse sounds), status line, tool permissions |
| `skins/` | Visual themes — terminal colors, ASCII banners, personalities, sounds |
| `skins/engine/config.yaml` | Default skin preference |
| `skills/` | Custom slash commands (`/skin`, etc.) |
| `bin/` | Executable wrappers (e.g. `altair` — Claude with Altair identity) |
| `CLAUDE.md` *(optional)* | User-level instructions applied to every project |
| `keybindings.json` *(optional)* | Custom keyboard shortcuts |

## Installation on a new machine

### 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. Run once to initialize `~/.claude/`

```bash
claude
# Then immediately quit with /exit
```

### 3. Clone and apply this config

```bash
git clone https://github.com/MonTheDog/dotfiles-claude.git /tmp/claude-config

cp /tmp/claude-config/settings.json ~/.claude/
cp /tmp/claude-config/CLAUDE.md ~/.claude/ 2>/dev/null || true
cp /tmp/claude-config/keybindings.json ~/.claude/ 2>/dev/null || true
cp -r /tmp/claude-config/skins ~/.claude/
cp -r /tmp/claude-config/skills ~/.claude/
cp -r /tmp/claude-config/bin ~/.claude/

chmod +x ~/.claude/skins/engine/*.sh
chmod +x ~/.claude/bin/*

# Symlink bin commands into PATH
mkdir -p ~/.local/bin
for cmd in ~/.claude/bin/*; do
  ln -sf "$cmd" ~/.local/bin/
done

rm -rf /tmp/claude-config
```

### 4. Start Claude Code

```bash
claude
```

The SessionStart hook will fire and show the configured skin banner automatically.

---

## Adding a new skin

1. Create `skins/yourname.yaml` (copy an existing one as template)
2. Create `skins/personalities/yourname.md` (optional — Claude voice for this skin)
3. Test it: `/skin yourname`
4. Commit and push:

```bash
git -C ~/.claude add skins/yourname.yaml skins/personalities/yourname.md
git -C ~/.claude commit -m "Add yourname skin"
git -C ~/.claude push
```

## Adding a new skill

1. Create `skills/yourcommand/SKILL.md` with instructions for Claude
2. Invoke it with `/yourcommand`
3. Commit and push:

```bash
git -C ~/.claude add skills/yourcommand/
git -C ~/.claude commit -m "Add /yourcommand skill"
git -C ~/.claude push
```

## Adding user-level Claude instructions

Create `~/.claude/CLAUDE.md` with your preferences (coding style, language, tone, etc.):

```bash
# Edit the file
$EDITOR ~/.claude/CLAUDE.md

# Then add to repo
git -C ~/.claude add CLAUDE.md
git -C ~/.claude commit -m "Add user CLAUDE.md"
git -C ~/.claude push
```

## Adding a new command to `bin/`

1. Create `bin/yourcommand` as a bash script
2. `chmod +x ~/.claude/bin/yourcommand`
3. `ln -sf ~/.claude/bin/yourcommand ~/.local/bin/yourcommand`
4. Commit and push — the install step will symlink it on other machines automatically

## Syncing changes across machines

```bash
# Push from current machine
git -C ~/.claude add -u && git -C ~/.claude commit -m "update config" && git -C ~/.claude push

# Pull on another machine
git -C ~/.claude pull
chmod +x ~/.claude/skins/engine/*.sh ~/.claude/bin/*
for cmd in ~/.claude/bin/*; do ln -sf "$cmd" ~/.local/bin/; done
```

## Setting a different default skin per machine

The active skin (`skins/engine/current`) is intentionally not synced — each machine can run a different skin.
To set the default skin for a machine, activate it and run:

```
/skin <name>
/skin default
```
