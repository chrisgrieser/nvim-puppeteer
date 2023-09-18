vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "javascript", "typescript" },
	callback = function(ctx)
		local ft = ctx.match
		local func
		if ft == "python" then func = require("puppeteer").pythonFStr end
		if ft == "javascript" or ft == "typescript" then func = require("puppeteer").templateStr end
		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = func,
		})
	end,
})
