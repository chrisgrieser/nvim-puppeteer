local jsLikeFiletypes = {
	"javascript",
	"typescript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", unpack(jsLikeFiletypes) },
	callback = function(ctx)
		local ft = ctx.match
		local func
		if ft == "python" then func = require("puppeteer").pythonFStr end
		if vim.tbl_contains(jsLikeFiletypes, ft) then func = require("puppeteer").templateStr end
		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
			buffer = 0,
			callback = func,
		})
	end,
})
