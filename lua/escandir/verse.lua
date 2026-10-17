-- Port of getResultLine/classifyWord/isErraSensible/removeApostrophe from
-- reference/hyphen-softcatala.js. Each JS regex is spelled out by hand; "/i"
-- there means plain upper-casing (no "u" flag), which the sets below mirror.
local hyphen = require("escandir.hyphen")
local chars = hyphen.chars

local M = {}

local function set(...)
  local s = {}
  for _, str in ipairs({ ... }) do
    for _, c in ipairs(chars(str)) do
      s[c] = true
    end
  end
  return s
end

local LOWER = "abcdefghijklmnopqrstuvwxyzàáèéìíòóùúäëïöüç·ñŀâêîôû"
local UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÈÉÌÍÒÓÙÚÄËÏÖÜÇÑĿÂÊÎÔÛ"
local APOS = set("'’")
local LETTER_NOAPOS = set(LOWER, UPPER)
local LETTER = set(LOWER, UPPER, "'’")
local WORD = set(LOWER, UPPER, "'’_-")
local SCAN = set(LOWER, UPPER, "'’‿")
local V5 = set("aeiouAEIOU")
local V5_LOWER = set("aeiou")
local VOWEL = set("aeiouàèìòùáéíóúïüAEIOUÀÈÌÒÙÁÉÍÓÚÏÜ")
local ACCENT = set("àáèéìíòóùúÀÁÈÉÌÍÒÓÙÚ")
local H = set("hH")
local IU = set("iuIU")
local IO = set("ioIO")
local AEO = set("aeoAEO")
local AEIO = set("aeioAEIO")
local PLAIN_N = set("eiïEIÏ")
local PLAIN_V = set("aeiouïAEIOUÏ")
local H_CI = { H, IO, set("eiïaEIÏA"), V5 }
local H_CS = { set("h"), set("io"), set("eiïa"), V5_LOWER }

local erra = {}
for _, w in ipairs(require("escandir.erra")) do
  erra[w] = true
end

-- [suffix] = removes a syllable
local enclitics = {}
for _, s in ipairs({ "l", "ls", "m", "n", "ns", "s", "t" }) do
  enclitics["'" .. s], enclitics["’" .. s] = false, false
end
for _, s in ipairs({ "en", "hi", "ho" }) do
  enclitics["'" .. s], enclitics["’" .. s] = true, true
end
for _, s in ipairs({ "l", "m", "n", "s", "t" }) do
  enclitics["-" .. s] = false
end
for _, s in ipairs({ "el", "els", "em", "en", "ens", "hi", "ho", "la", "les", "li", "lo", "los", "me", "ne", "nos", "se", "te", "us", "vos" }) do
  enclitics["-" .. s] = true
end

local function runs(cs, class)
  local n, inside = 0, false
  for _, c in ipairs(cs) do
    if class[c] and not inside then
      n = n + 1
    end
    inside = class[c] or false
  end
  return n
end

local function split(cs, class)
  local out, cur = {}, nil
  for _, c in ipairs(cs) do
    if class[c] then
      cur = cur or {}
      cur[#cur + 1] = c
    elseif cur then
      out[#out + 1], cur = cur, nil
    end
  end
  out[#out + 1] = cur
  return out
end

local function remove_apostrophe(cs)
  if APOS[cs[1]] then
    table.remove(cs, 1)
  end
  if APOS[cs[#cs]] then
    table.remove(cs)
  end
  for k = 1, #cs - 2 do
    if not LETTER_NOAPOS[cs[k]] and APOS[cs[k + 1]] and not LETTER_NOAPOS[cs[k + 2]] then
      table.remove(cs, k + 1)
      break
    end
  end
  return cs
end

local function is_erra_sensible(w)
  local s = {}
  for i, c in ipairs(w) do
    s[i] = hyphen.lower[c] or c
  end
  if s[1] and s[1]:match("^[lsdtmn]$") and APOS[s[2]] then
    table.remove(s, 1)
    table.remove(s, 1)
  end
  return erra[table.concat(s)] or false
end

-- /([_-][^aeiou]*[eiïa])(-h[io])$/ on t[1..n], ci = case-insensitive
local function hyphen_h_suffix(t, n, ci)
  local hs, io, ea, vowels = unpack(ci and H_CI or H_CS)
  if not (io[t[n]] and hs[t[n - 1]] and t[n - 2] == "-" and ea[t[n - 3]]) then
    return false
  end
  for k = n - 4, 1, -1 do
    if t[k] == "_" or t[k] == "-" then
      return true
    end
    if vowels[t[k]] then
      return false
    end
  end
  return false
end

local function sinalefa(w, nxt)
  local n = #w
  local mute_r = n >= 2 and (w[n] == "r" or w[n] == "R") and V5[w[n - 1]] and not is_erra_sensible(w)
  local open = VOWEL[w[n]] or H[w[n]] and VOWEL[w[n - 1]]
  if open then
    local diphthong = AEIO[w[n - 1]] and IU[w[n]]
    if not diphthong and (w[n] == "i" or w[n] == "I") and (w[n - 1] == "u" or w[n - 1] == "U") then
      diphthong = true
      for _, c in ipairs(w) do
        if c == "q" or c == "Q" then
          diphthong = false
          break
        end
      end
    end
    open = not diphthong
  end
  if not (mute_r or open) then
    return false
  end
  if not (VOWEL[nxt[1]] or H[nxt[1]] and VOWEL[nxt[2]]) then
    return false
  end
  return not (IU[nxt[1]] and VOWEL[nxt[2]] or H[nxt[1]] and IU[nxt[2]] and VOWEL[nxt[3]])
end

local function stress(word)
  local w = word
  local removed = 0
  while true do
    local hit
    for suffix, syllabic in pairs(enclitics) do
      if #w >= #suffix and w:sub(-#suffix) == suffix then
        hit = suffix
        removed = removed + (syllabic and 1 or 0)
        break
      end
    end
    if not hit then
      break
    end
    w = w:sub(1, -#hit - 1)
  end

  local parts, ns = {}, 0
  for part in (w .. "_"):gmatch("(.-)_") do
    parts[#parts + 1] = chars(part)
    ns = ns + (part ~= "" and 1 or 0)
  end
  if ns == 0 then
    return 0
  end

  local function accented(p)
    for _, c in ipairs(p or {}) do
      if ACCENT[c] then
        return true
      end
    end
    return false
  end

  local last = parts[ns]
  local n = #last
  local r = 0
  if ns == 1 then
    r = 0
  elseif ns > 2 and accented(parts[ns - 2]) then
    r = -2
  elseif accented(parts[ns - 1]) then
    r = -1
  elseif accented(last) then
    r = 0
  else
    local k = n
    while k > 0 and not V5[last[k]] do
      k = k - 1
    end
    if k > 1 and IU[last[k]] and AEO[last[k - 1]] then
      r = 0
    elseif (last[n] == "n" or last[n] == "N") and PLAIN_N[last[n - 1]]
      or PLAIN_V[last[n]]
      or (last[n] == "s" or last[n] == "S") and PLAIN_V[last[n - 1]]
    then
      r = -1
    end
  end
  return r - removed
end

local function rules(hyphenated)
  local ss = remove_apostrophe(chars(hyphenated))
  local words = split(ss, WORD)
  local wl = #words
  if wl == 0 then
    return { scansion = "", graphical = 0, poetical1 = 0, poetical2 = 0 }
  end

  local t = {}
  local function push(cs)
    for _, c in ipairs(cs) do
      t[#t + 1] = c
    end
  end
  for i = 1, wl - 1 do
    push(words[i])
    if sinalefa(words[i], words[i + 1]) then
      local n = #t
      if IO[t[n]] and (t[n - 1] == "‿" or H[t[n - 1]] and t[n - 2] == "‿") then
        t[t[n - 1] == "‿" and n - 1 or n - 2] = " "
      end
      t[#t + 1] = "‿"
    else
      t[#t + 1] = " "
    end
    local n = #t
    if hyphen_h_suffix(t, n - 1, true) then
      table.insert(t, n - 3, "‿")
      n = n + 1
    end
    if t[n] == "‿" and IO[t[n - 1]] and H[t[n - 2]] and t[n - 3] == "-" and t[n - 4] == "‿" then
      t[n] = " "
    end
  end
  push(words[wl])
  if hyphen_h_suffix(t, #t, true) then
    table.insert(t, #t - 2, "‿")
  end

  local last = words[wl]
  local offset = stress(table.concat(last))
  local final = hyphen_h_suffix(last, #last, false) and 1 or 0

  local text = table.concat(t)
  local graphical = runs(ss, LETTER)
  local phonetical = runs(chars((text:gsub("‿%-", "‿", 1))), SCAN)

  return {
    scansion = text:gsub("_", "|"),
    graphical = graphical,
    poetical1 = graphical + offset,
    poetical2 = phonetical + offset + final,
  }
end

function M.scan(line)
  return rules(hyphen.adjust(hyphen.hyphenate((line:gsub("_", " ")))))
end

return M
