# Editor Snippets for Inline Code Feedback

These snippets make it easy to add inline feedback comments to code and markdown files without typing the full template each time.

## Overview

The inline feedback workflow uses block-style comments:

```python
# FEEDBACK(@username, 2025-11-23):
# Your feedback here
# Can span multiple lines
# /FEEDBACK
```

These snippets auto-generate that format with:

- Your username (from git config in Vim version)
- Current date
- Placeholders for your feedback text

## Available Snippets

| Trigger | Description | Output |
|---------|-------------|--------|
| `fb` | Feedback block | `FEEDBACK(@user, date): ... /FEEDBACK` |
| `fbr` | Response block | `RESPONSE(@user, date): ... /RESPONSE` |
| `fbx` | Resolved block | `RESOLVED(@user, date): ... /RESOLVED` |
| `fbs` | Simple feedback | `FEEDBACK: ... /FEEDBACK` (no metadata) |

## Installation

### Helix Editor

#### Option 1: Global snippets

```bash
# Copy to Helix config directory
cp helix-feedback-snippets.toml ~/.config/helix/snippets/feedback.toml

# Or create language-specific snippets
cp helix-feedback-snippets.toml ~/.config/helix/snippets/python.toml
```

#### Option 2: Project-specific snippets

```bash
# Create .helix/snippets/ in your project
mkdir -p .helix/snippets
cp helix-feedback-snippets.toml .helix/snippets/feedback.toml
```

**Usage in Helix:**

1. Type `fb` and press `Tab`
2. Edit username placeholder
3. Press `Tab` to jump to date
4. Press `Tab` to jump to feedback text
5. Press `Tab` again to finish

### Vim/Neovim

#### Option 1: UltiSnips (Recommended)

```bash
# Install UltiSnips first
# vim-plug: Plug 'SirVer/ultisnips'
# Packer: use 'SirVer/ultisnips'

# Copy snippets to UltiSnips directory
mkdir -p ~/.vim/UltiSnips
# Extract UltiSnips section from vim-feedback-snippets.vim
# and save to ~/.vim/UltiSnips/all.snippets

# For language-specific snippets:
~/.vim/UltiSnips/python.snippets
~/.vim/UltiSnips/javascript.snippets
~/.vim/UltiSnips/markdown.snippets
```

#### Option 2: Native Vim Abbreviations (No plugins)

```bash
# Add to ~/.vimrc or ~/.config/nvim/init.vim
cat vim-feedback-snippets.vim >> ~/.vimrc

# Or source it
echo "source /path/to/vim-feedback-snippets.vim" >> ~/.vimrc
```

#### Option 3: Custom Functions (Auto git username)

```vim
" Add the custom functions section to ~/.vimrc
" Then use:
"   <leader>fb = Insert feedback
"   <leader>fr = Insert response
"   <leader>fx = Insert resolved
```

**Usage in Vim:**

*UltiSnips:*

```text
Type: fb<Tab>
Edit fields, Tab between them
```

*Abbreviations:*

```text
Python:   Type "fb#" then Space
JavaScript: Type "fb//" then Space
Markdown: Type "fb<!" then Space
```

*Custom functions:*

```text
Normal mode: \fb (or Space+fb if leader is Space)
Automatically uses git username
```

## Examples

### Python Feedback

**Type:** `fb` + Tab

**Output:**

```python
# FEEDBACK(@yourname, 2025-11-23):
# |cursor here|
# /FEEDBACK
```

### JavaScript Feedback

**Type:** `fb` + Tab (in .js file)

**Output:**

```javascript
// FEEDBACK(@yourname, 2025-11-23):
// |cursor here|
// /FEEDBACK
```

### Markdown Feedback

**Type:** `fb` + Tab (in .md file)

**Output:**

```markdown
<!-- FEEDBACK(@yourname, 2025-11-23):
|cursor here|
/FEEDBACK -->
```

## Workflow Integration

### 1. Start Feedback Session

```bash
# Optional: Create checkpoint
/feedback-add
```

### 2. Add Feedback Manually

```python
# Open file in your editor
# Navigate to line needing feedback
# Type: fb<Tab>
# Fill in feedback text
# Save file
```

### 3. Review Feedback

```bash
/feedback-review
```

### 4. Clean Up

```bash
/feedback-clean
```

## Tips

### Custom Severity Levels

Add severity to opening tag:

```python
# FEEDBACK [CRITICAL] (@security, 2025-11-23):
# SQL injection vulnerability here
# /FEEDBACK
```

Create custom snippets for each severity:

- `fbc` → `FEEDBACK [CRITICAL]`
- `fbm` → `FEEDBACK [MAJOR]`
- `fbn` → `FEEDBACK [MINOR]`

### Git Integration (Vim)

The Vim custom functions automatically pull your username from git config:

```bash
git config user.name "Alice"
# In Vim: <leader>fb
# Generates: FEEDBACK(@Alice, 2025-11-23):
```

### Multi-line Feedback

All snippets support multi-line feedback:

```python
# FEEDBACK(@alice, 2025-11-23):
# This function has several issues:
# 1. Missing input validation
# 2. No error handling
# 3. Potential memory leak
# /FEEDBACK
```

### Date Format

Default format: `YYYY-MM-DD`

To change in Vim:

```vim
" In vim-feedback-snippets.vim, change:
let l:date = strftime("%Y-%m-%d")
" To:
let l:date = strftime("%d/%m/%Y")  " Or any format
```

For Helix, edit the `${2:date}` placeholder in the TOML file.

## Customization

### Change Default Username

**Vim:**
Edit the `InsertFeedback()` function:

```vim
let l:username = system('git config user.name | tr -d "\n"')
" Change to:
let l:username = 'alice'
```

**Helix:**
Edit `${1:username}` in TOML snippets:

```toml
body = """
# FEEDBACK(@alice, ${2:2025-11-23}):
```

### Add Project-Specific Snippets

Create variations for your project conventions:

```python
# FEEDBACK [@alice] (2025-11-23) [PRIORITY:HIGH]:
# Your feedback
# /FEEDBACK
```

## Language Support

Current snippet files support:

- **Python** - `# FEEDBACK ... /FEEDBACK`
- **Shell/Bash** - `# FEEDBACK ... /FEEDBACK`
- **Ruby** - `# FEEDBACK ... /FEEDBACK`
- **YAML** - `# FEEDBACK ... /FEEDBACK`
- **JavaScript** - `// FEEDBACK ... /FEEDBACK`
- **TypeScript** - `// FEEDBACK ... /FEEDBACK`
- **C/C++** - `// FEEDBACK ... /FEEDBACK`
- **Go** - `// FEEDBACK ... /FEEDBACK`
- **Java** - `// FEEDBACK ... /FEEDBACK`
- **Rust** - `// FEEDBACK ... /FEEDBACK`
- **Markdown** - `<!-- FEEDBACK ... /FEEDBACK -->`
- **HTML** - `<!-- FEEDBACK ... /FEEDBACK -->`

Add more by copying the pattern for your language's comment syntax.

## Troubleshooting

### Helix: Snippets not working

- Check `~/.config/helix/snippets/` directory exists
- Verify TOML syntax is valid
- Check Helix documentation for snippet configuration

### Vim: UltiSnips not expanding

- Ensure UltiSnips is installed: `:echo exists('g:did_plugin_ultisnips')`
- Check trigger key: `:echo g:UltiSnipsExpandTrigger`
- Try `:UltiSnipsEdit` to debug

### Vim: Abbreviations not working

- Check abbreviations loaded: `:iabbrev`
- Ensure FileType autocmds ran: `:set filetype?`
- Try `:source ~/.vimrc` to reload

### Date not auto-filling

- **Helix**: Manually edit date placeholder
- **Vim**: Check `strftime()` works: `:echo strftime("%Y-%m-%d")`
