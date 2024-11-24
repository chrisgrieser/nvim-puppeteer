local supportedFiletypes = {
	python = "pythonFStr",
	lua = "luaFormatStr",
	javascript = "templateStr",
	typescript = "templateStr",
	javascriptreact = "templateStr",
	typescriptreact = "templateStr",
	vue = "templateStr",
	astro = "templateStr",
	svelte = "templateStr",
}

-- disable puppeteer for certain filetypes based on user config
for _, ft in pairs(vim.g.puppeteer_disabled_filetypes or {}) do
	supportedFiletypes[ft] = nil
end

--------------------------------------------------------------------------------
local activeFiletypes = vim.tbl_keys(supportedFiletypes)
vim.api.nvim_create_autocmd("FileType", {
	pattern = activeFiletypes,
	callback = function(ctx)
		local ft = ctx.match
		local stringTransformFunc = require("puppeteer")[supportedFiletypes[ft]]

		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = function(ctx2)
				local bufnr = ctx2.buf

				-- if buffer changed ft, disable this autocmd see #19
				-- (returning `true` deletes an autocmd)
				if vim.tbl_contains(activeFiletypes, vim.bo[bufnr].ft) then return true end

				if
					vim.b[bufnr].puppeteer_enabled == false
					or vim.bo[bufnr].buftype ~= ""
					or not (vim.api.nvim_buf_is_valid(bufnr))
				then
					return
				end
				-- deferred to prevent race conditions with other autocmds
				vim.defer_fn(stringTransformFunc, 1)
			end,
		})
	end,
})

--------------------------------------------------------------------------------
-- USER COMMANDS

---@param mode "Enabled"|"Disabled"
local function notify(mode) vim.notify(mode .. " for current buffer.", nil, { title = "nvim-puppeteer" }) end

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
		vim.b.puppeteer_enabled = false
		notify("Disabled")
	else
		vim.b.puppeteer_enabled = true
		notify("Enabled")
	end
end, { desc = "Toggle puppeteer for the current buffer" })
