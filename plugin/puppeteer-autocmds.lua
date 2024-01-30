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

		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = function()
				if vim.b.puppeteer_enabled ~= false then stringTransformFunc() end
			end,
		})
	end,
})

--------------------------------------------------------------------------------
-- USER COMMANDS


---@param mode "Enabled"|"Disabled"
local function notify(mode)
	vim.notify(mode .. " for current buffer.", vim.log.levels.INFO, { title = "nvim-puppeteer" })
end

vim.api.nvim_create_user_command("PuppeteerDisable", function()
	vim.b.puppeteer_enabled = false
	notify("Disabled")
end, { desc = "Disable puppeteer for the current buffer" })

vim.api.nvim_create_user_command("PuppeteerEnable", function()
	vim.b.puppeteer_enabled = true
	notify("Enabled")
end, { desc = "Enable puppeteer for the current buffer" })

vim.api.nvim_create_user_command("PuppeteerToggle", function()
	if vim.b.puppeteer_enabled == true or vim.b.puppeteer_enabled == nil then
		vim.b["puppeteer_enabled"] = false
		notify("Disabled")
	else
		vim.b["puppeteer_enabled"] = true
		notify("Enabled")
	end
end, {
	desc = "Toggle puppeteer for the current buffer",
})
