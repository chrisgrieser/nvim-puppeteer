-- PERF the function names are saved as string so the main module is only loaded
-- when needed
local supportedFiletypes = {
	python = "pythonFStr",
	javascript = "templateStr",
	typescript = "templateStr",
	javascriptreact = "templateStr",
	typescriptreact = "templateStr",
	vue = "templateStr",
	astro = "templateStr",
	svelte = "templateStr",
	lua = "luaFormatStr",
}

for _, ft in pairs(vim.g.puppeteer_disabled_filetypes or {}) do
	supportedFiletypes[ft] = nil
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(supportedFiletypes),
	callback = function(ctx)
		local ft = ctx.match
		local stringTransformFunc = require("puppeteer")[supportedFiletypes[ft]]
		local performTransform = function()
			if vim.b.puppeteer_enabled == false then return end
			stringTransformFunc()
		end

		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = performTransform,
		})
	end,
})

vim.api.nvim_create_user_command("PuppeteerDisable", "lua vim.b.puppeteer_enabled = false", {
	desc = "Enable puppeteer for the current buffer.",
})
vim.api.nvim_create_user_command("PuppeteerEnable", "lua vim.b.puppeteer_enabled = true", {
	desc = "Enable puppeteer for the current buffer.",
})
vim.api.nvim_create_user_command("PuppeteerToggle", function()
	if vim.b.puppeteer_enabled == nil then
		vim.b.puppeteer_enabled = false
	else
		vim.b.puppeteer_enabled = not vim.b.puppeteer_enabled
	end
end, {
	desc = "Toggle puppeteer for the current buffer.",
})
