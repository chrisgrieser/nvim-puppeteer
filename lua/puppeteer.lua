local M = {}

local ts = vim.treesitter

---@param node object
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
	vim.api.nvim_buf_set_text(0, startRow, startCol, endRow, endCol, lines)
end

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|object returns nil if no node or nvim version too old
local function getNodeAtCursor()
	if ts.get_node == nil then
		vim.notify("nvim-puppeteer requires at least nvim 0.9.", vim.log.levels.WARN)
		return nil
	end
	return ts.get_node()
end

--------------------------------------------------------------------------------

-- auto-convert string to template string and back
function M.templateStr()
	local node = getNodeAtCursor()
	if not node then return end

	local strNode
	local isTemplateStr
	if node:type() == "string" then
		strNode = node
		isTemplateStr = false
	elseif node:type() == "string_fragment" or node:type() == "escape_sequence" then
		strNode = node:parent()
		isTemplateStr = false
	elseif node:type() == "template_string" then
		strNode = node
		isTemplateStr = true
	else
		return
	end

	local text = ts.get_node_text(strNode, 0)
	local hasBraces = text:find("${%w.-}")

	if not isTemplateStr and hasBraces then
		text = "`" .. text:sub(2, -2) .. "`"
		replaceNodeText(strNode, text)
	elseif isTemplateStr and not hasBraces then
		text = '"' .. text:sub(2, -2) .. '"'
		replaceNodeText(strNode, text)
	end
end

-- auto-convert string to f-string and back
function M.pythonFStr()
	local node = getNodeAtCursor()
	if not node then return end

	local strNode
	if node:type() == "string" then
		strNode = node
	elseif node:type():find("^string_") then
		strNode = node:parent()
	elseif node:type() == "escape_sequence" then
		strNode = node:parent():parent()
	else
		return
	end

	local text = ts.get_node_text(strNode, 0)
	local isFString = text:find("^f")
	local hasBraces = text:find("{%w.-}")

	if not isFString and hasBraces then
		text = "f" .. text
		replaceNodeText(strNode, text)
	elseif isFString and not hasBraces then
		text = text:sub(2)
		replaceNodeText(strNode, text)
	end
end

--------------------------------------------------------------------------------
return M
