vim.api.nvim_create_autocmd("InsertLeave", {
	buffer = 0,
	callback = require("puppeteer").templateStr,
})
