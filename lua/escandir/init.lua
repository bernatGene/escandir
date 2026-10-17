local verse = require("escandir.verse")

local M = {}

local ns = vim.api.nvim_create_namespace("escandir")
local group = vim.api.nvim_create_augroup("escandir", { clear = false })

local function render(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local frontmatter, fence = lines[1] == "---", nil
  for i, line in ipairs(lines) do
    if frontmatter then
      frontmatter = i == 1 or line ~= "---"
      goto continue
    end
    local marker = line:match("^%s*([`~][`~][`~])")
    if marker then
      fence = not fence and marker or nil
      goto continue
    end
    if fence or line:match("^#") then
      goto continue
    end
    local r = verse.scan(line)
    if r.graphical > 0 then
      local text = r.poetical1 == r.poetical2 and tostring(r.poetical1) or ("%d (%d)"):format(r.poetical1, r.poetical2)
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { virt_text = { { text, "Comment" } }, virt_text_pos = "right_align" })
    end
    ::continue::
  end
end

function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.b[buf].escandir then
    vim.b[buf].escandir = false
    vim.api.nvim_clear_autocmds({ group = group, buffer = buf })
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    return
  end
  if vim.bo[buf].filetype ~= "markdown" then
    vim.notify("escandir: only markdown buffers", vim.log.levels.WARN)
    return
  end
  vim.b[buf].escandir = true
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      render(buf)
    end,
  })
  render(buf)
end

return M
