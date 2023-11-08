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
	lua = "luaFormatStr",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(supportedFiletypes),
	callback = function(ctx)
		local ft = ctx.match
		local stringTransformFunc = require("puppeteer")[supportedFiletypes[ft]]
		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = stringTransformFunc,
		})
	end,
})
