# entire-fzf

Zsh helpers for working with Entire CLI sessions through `fzf`.

## Requirements

- `zsh`
- `entire`
- `fzf`
- `jq`
- `git`

## Install with Sheldon

For local development, add this repository to `~/.config/sheldon/plugins.toml`:

```toml
[plugins.entire-fzf]
local = "/Users/mizuki-y/Projects/me/entire-fzf"
```

After publishing the repository to GitHub, use:

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

- `etf`: pick an Entire session, then run an action such as explain latest checkpoint, pick checkpoint to explain, info, stop, or clean.
- `etfd`: run `entire dispatch --local`.
- `etfr`: pick a Git branch, then run `entire session resume <branch>`.

## Test

```sh
zsh -n entire-fzf.plugin.zsh
zsh test/run.zsh
```
