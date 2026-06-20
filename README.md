# entire-fzf

Zsh helpers for working with Entire CLI sessions through `fzf`.

![Demo](demo/demo.gif)

## Requirements

- `zsh`
- `entire`
- `fzf`
- `jq`
- `git`

## Install

### Without a plugin manager

Clone the repository and source the plugin from your `.zshrc`:

```sh
git clone https://github.com/Syati/entire-fzf.git ~/.zsh/entire-fzf
```

```zsh
# ~/.zshrc
source ~/.zsh/entire-fzf/entire-fzf.plugin.zsh
```

### With Sheldon

```toml
[plugins.entire-fzf]
github = "Syati/entire-fzf"
```

Sheldon automatically matches `entire-fzf.plugin.zsh` from the plugin name `entire-fzf`.

Then reload your shell or run:

```sh
eval "$(sheldon source)"
```

## Commands

- `etf`: pick an Entire session, then run an action: resume, explain latest checkpoint, pick checkpoint to explain, info, stop, or clean.
- `etfc`: pick a checkpoint from the active session in the current worktree, then explain it.
