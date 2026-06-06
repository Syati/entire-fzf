# entire-zsh

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
[plugins.entire]
local = "/Users/mizuki-y/Projects/me/entire-zsh"
use = ["entire-zsh.zsh"]
```

After publishing the repository to GitHub, use:

```toml
[plugins.entire]
github = "mizuki-y/entire-zsh"
use = ["entire-zsh.zsh"]
```

Then reload your shell or run:

```sh
eval "$(sheldon source)"
```

## Commands

- `es`: pick an Entire session, then run an action such as explain, checkpoints, info, stop, or clean.
- `esd`: run `entire dispatch --local`.
- `esr`: pick a Git branch, then run `entire session resume <branch>`.
