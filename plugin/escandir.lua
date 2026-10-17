vim.api.nvim_create_user_command("Escandir", function()
  require("escandir").toggle()
end, { desc = "Toggle syllable counts in this markdown buffer" })
