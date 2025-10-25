# ExHelp

ExHelp lets you browse your elixir docs swiftly in the terminal.

Enables fuzzy search and paging capabilities to browse documentation.

## Dependencies

ExHelp depends on [fzf](https://github.com/junegunn/fzf?tab=readme-ov-file#installation).
## Installation
### System-wide installation (requires sudo)
```sh
git clone https://github.com/isaias-dias-machado/exhelp
cd exhelp
make compile
sudo make install
```

### User-local installation (no sudo required)
```sh
git clone https://github.com/isaias-dias-machado/exhelp
cd exhelp
make compile
make install PREFIX=~/.local
```

Then ensure `~/.local/bin` is in your PATH:
```sh
export PATH="$HOME/.local/bin:$PATH"
```

### Uninstalling
```sh
sudo make uninstall  # for system-wide install
# or
make uninstall PREFIX=~/.local  # for user-local install
```

## Usage

Navigate to your Mix project's directory and run fetch to cache your docs:
```sh
exh fetch
```
Run the CLI with no arguments to trigger `fzf`:
```sh
exh
```
To clear the cache stored at `~/.cache/exh` run:
```sh
exh clear
```
`exh` will use the pager set in the `PAGER` environment variable, if it is not
set, defaults to `less` with the `-R` option.

## Why ExHelp

The `h` macro in IEx is a good tool, but it lacks a pager and pressing
tab to find what you are looking for is just slow. Also, the module you are
looking for might just not be loaded, which is annoying.

Following the UNIX philosophy, ExHelp solves these issues by dropping to your OS shell and integrating with Mix.

## Alternative Approach

I have tried to make the project IEx native using Ports, check it out in the
`less-in-iex` branch.
To run the code lauch the IEx and run `exh fetch` and `exh`
I gave up on this alternative because I couldn't find a way to make the BEAM
fully yield the control of the terminal, resulting in race conditions for input
between the BEAM and the TUI.

## License
MIT (see LICENSE file)

## Contributing
Issues and PRs welcome!
