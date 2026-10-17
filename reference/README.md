Unmodified copies of the JS behind https://www.softcatala.org/sillabes/, fetched
2026-10-15 from `/themes/wp-softcatala/static/js/sep-sillabes/`. Same logic as
https://github.com/Softcatala/separador-sillabes (b6d270b); the site copy only
differs in HTML markup.

- `hyphen.js`: Liang hyphenator, ytiurin/hyphen, MIT.
- `sillabes-ca.js`: Catalan patterns from https://github.com/jaumeortola/hyphen-ca, GPL-3.0.
- `hyphen-softcatala.js`: sinalefa/elision and stress rules. No license declared upstream.

`node scripts/generate.mjs` builds the Lua data and `test/fixtures/` from these.
