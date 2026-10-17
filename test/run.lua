-- nvim -l test/run.lua
vim.opt.rtp:prepend(".")
local verse = require("escandir.verse")

local total, failed = 0, 0
for _, f in ipairs({ "test/fixtures/edge-cases.jsonl", "test/fixtures/poems.jsonl" }) do
  for row in io.lines(f) do
    local line, scansion, p1, p2 = unpack(vim.json.decode(row))
    local r = verse.scan(line)
    total = total + 1
    if r.scansion ~= scansion or r.poetical1 ~= p1 or r.poetical2 ~= p2 then
      failed = failed + 1
      print(("%q: expected %d (%d) %s, got %d (%d) %s"):format(line, p1, p2, scansion, r.poetical1, r.poetical2, r.scansion))
    end
  end
end
print(("%d/%d passed"):format(total - failed, total))
os.exit(failed == 0 and 0 or 1)
