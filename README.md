# escandir

Neovim plugin that shows Catalan syllable counts (with sinalefa/elision) at the end of each line in markdown poems.

```lua
{ "bernatGene/escandir" }
```

`:Escandir` toggles counts in the current buffer. When two scansions are possible it shows both, e.g. `10 (11)`.

Tests: `nvim -l test/run.lua`

## Acknowledgements

A Lua port of the [Softcatalà syllable separator](https://www.softcatala.org/sillabes/) ([source](https://github.com/Softcatala/separador-sillabes)), which builds on:

- [ytiurin/hyphen](https://github.com/ytiurin/hyphen) — Liang hyphenation algorithm (MIT)
- [jaumeortola/hyphen-ca](https://github.com/jaumeortola/hyphen-ca) — Catalan hyphenation patterns (GPL-3.0)

Original sources are kept in `reference/`.
