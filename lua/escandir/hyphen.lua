-- Port of reference/hyphen.js (Liang) as configured by hyphen-softcatala.js,
-- plus its adjustHyphenatedText.
local M = {}

local SEP = "_"

M.lower = {
  ["À"] = "à", ["Á"] = "á", ["È"] = "è", ["É"] = "é", ["Ì"] = "ì", ["Í"] = "í",
  ["Ò"] = "ò", ["Ó"] = "ó", ["Ù"] = "ù", ["Ú"] = "ú", ["Ä"] = "ä", ["Ë"] = "ë",
  ["Ï"] = "ï", ["Ö"] = "ö", ["Ü"] = "ü", ["Ç"] = "ç", ["Ñ"] = "ñ", ["Ŀ"] = "ŀ",
  ["Â"] = "â", ["Ê"] = "ê", ["Î"] = "î", ["Ô"] = "ô", ["Û"] = "û",
}
for c in ("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):gmatch(".") do
  M.lower[c] = c:lower()
end

local letter = {}
for c in ("abcdefghijklmnopqrstuvwxyzàáèéìíòóùúäëïöüç·ñ'’ŀâêîôû"):gmatch("[%z\1-\255][\128-\191]*") do
  letter[c] = true
end

function M.chars(s)
  local t = {}
  for c in s:gmatch("[%z\1-\255][\128-\191]*") do
    t[#t + 1] = c
  end
  return t
end

-- Keyed by pattern text with "." marking word edges, which is what the JS
-- stickToLeft/stickToRight checks amount to. Duplicate texts merge by max.
local patterns, maxlen
local function load()
  patterns, maxlen = {}, 0
  for _, p in ipairs(require("escandir.patterns")) do
    local text, levels, prev_digit = {}, {}, false
    local left, right = false, false
    for i, c in ipairs(M.chars(p)) do
      local d = tonumber(c:match("^%d$"))
      if c == "." then
        left, right = left or i == 1, right or i > 1
      elseif d then
        levels[#levels + 1] = d
      else
        if not prev_digit then
          levels[#levels + 1] = 0
        end
        text[#text + 1] = c
      end
      prev_digit = d ~= nil
    end
    if left then
      table.insert(text, 1, ".")
      table.insert(levels, 1, 0)
    end
    if right then
      text[#text + 1] = "."
    end
    local key = table.concat(text)
    local old = patterns[key]
    if old then
      for i = 1, math.max(#old, #levels) do
        levels[i] = math.max(levels[i] or 0, old[i] or 0)
      end
    end
    patterns[key] = levels
    maxlen = math.max(maxlen, #text)
  end
end

local function hyphenate_word(word)
  local cs = M.chars(word)
  local n = #cs
  local dotted = { "." }
  for i, c in ipairs(cs) do
    dotted[i + 1] = M.lower[c] or c
  end
  dotted[n + 2] = "."

  -- levels[k] is the level before cs[k]; dotted[k + 1] == cs[k]
  local levels = {}
  for i = 1, n + 2 do
    local key = ""
    for j = i, math.min(n + 2, i + maxlen - 1) do
      key = key .. dotted[j]
      local pat = patterns[key]
      if pat then
        for k, l in ipairs(pat) do
          local pos = i + k - 2
          if l > (levels[pos] or 0) then
            levels[pos] = l
          end
        end
      end
    end
  end

  local out = {}
  for k = 1, n do
    if k > 1 and (levels[k] or 0) % 2 == 1 then
      out[#out + 1] = SEP
    end
    out[#out + 1] = cs[k]
  end
  return table.concat(out)
end

local cache = {}

function M.hyphenate(text)
  if not patterns then
    load()
  end
  local out, word = {}, {}
  local function flush()
    if #word == 0 then
      return
    end
    local w = table.concat(word)
    cache[w] = cache[w] or hyphenate_word(w)
    out[#out + 1] = cache[w]
    word = {}
  end
  for _, c in ipairs(M.chars(text)) do
    if letter[M.lower[c] or c] then
      word[#word + 1] = c
    else
      flush()
      out[#out + 1] = c
    end
  end
  flush()
  return table.concat(out)
end

function M.adjust(s)
  return (
    s:gsub("l·", "l")
      :gsub("ŀ", "l")
      :gsub("L·", "L")
      :gsub("Ŀ", "L")
      :gsub("%f[A-Za-z0-9_]Pius%f[^A-Za-z0-9_]", "Pi_us")
      :gsub("à_cid pe_ri_ò_dic", "à_cid per_iò_dic")
  )
end

return M
