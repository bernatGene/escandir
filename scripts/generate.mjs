// Regenerates lua/escandir/{patterns,erra}.lua and test/fixtures/ from reference/.
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const root = path.resolve(import.meta.dirname, "..");
const context = vm.createContext({
  document: { getElementById: () => ({ value: "", style: {} }) },
  console: { log() {} },
});
for (const f of ["hyphen.js", "sillabes-ca.js", "hyphen-softcatala.js"]) {
  vm.runInContext(fs.readFileSync(path.join(root, "reference", f), "utf8"), context);
}

const lua = (list) => `return {\n${list.map((s) => `  ${JSON.stringify(s)},`).join("\n")}\n}\n`;
fs.writeFileSync(path.join(root, "lua/escandir/patterns.lua"), lua(context.hyphenationPatternsCa.patterns.filter(Boolean)));
const erra = fs.readFileSync(path.join(root, "reference/hyphen-softcatala.js"), "utf8").match(/var erraSensible = (\[[^\]]*\]);/)[1];
fs.writeFileSync(path.join(root, "lua/escandir/erra.lua"), lua(JSON.parse(erra)));

// Per-line path of getMessageMultipleLines; must run inside the context for its String.prototype extensions.
const verse = vm.runInContext(`(function (line) {
  var r = getResultLine(hyphenate(line.replace(/_/g, " ")).adjustHyphenatedText());
  return [line, r.hyphenated_line.replace(/&nbsp; /g, " "), r.count_poetical1, r.count_poetical2];
})`, context);
for (const name of ["edge-cases", "poems"]) {
  const lines = fs.readFileSync(path.join(root, `test/corpus/${name}.txt`), "utf8").split("\n").filter((l) => l && !l.startsWith("# "));
  fs.writeFileSync(path.join(root, `test/fixtures/${name}.jsonl`), lines.map((l) => JSON.stringify(verse(l))).join("\n") + "\n");
}
