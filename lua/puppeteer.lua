local M = {}

local ts = vim.treesitter

---@param node table
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
	vim.api.nvim_buf_set_text(0, startRow, startCol, endRow, endCol, lines)
end

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|table returns nil if no node or nvim version too old
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

	local strNode, isTemplateStr
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
	local quotationMark = '"' -- default value when no quotation mark has been deleted yet

	local isTaggedTemplate = node:parent():type() == "call_expression"
	local isMultilineString = ts.get_node_text(node, 0):find("[\n\r]")
	local hasBraces = text:find("${%w.-}")

	if not isTemplateStr and (hasBraces or isMultilineString) then
		quotationMark = text:sub(1, 1) -- remember the quotation mark
		text = "`" .. text:sub(2, -2) .. "`"
		replaceNodeText(strNode, text)
	elseif isTemplateStr and not (hasBraces or isMultilineString or isTaggedTemplate) then
		-- INFO taggedTemplate and multilineString have no ${}, but we still want
		-- to keep the template
		text = quotationMark .. text:sub(2, -2) .. quotationMark
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

function M.luaFormatStr()
	-- require explicit enabling by the user, since there are a few edge cases
	-- when for lua format strings because a "%s" in a lua string can either be
	-- a lua class pattern or a placeholder
	if not vim.g.puppeteer_lua_format_string then return end

	local node = getNodeAtCursor()
	if not node then return end

	local strNode
	if node:type() == "string" then
		strNode = node
	elseif node:type():find("string_content") then
		strNode = node:parent()
	elseif node:type() == "escape_sequence" then
		strNode = node:parent():parent()
	else
		return
	end

	-- GUARD: lua patterns (string.match, …) use `%s` as class patterns

	-- this works with string.match() as well as var:match()
	local stringMethod = strNode:parent()
		and strNode:parent():prev_sibling()
		and strNode:parent():prev_sibling():child(2)

	local methodText = stringMethod and ts.get_node_text(stringMethod, 0) or ""
	local isLuaPattern = methodText:find("g?match") or methodText == "find" or methodText == "gsub"
	if isLuaPattern or methodText == "format" then return end

	local text = ts.get_node_text(strNode, 0)
	local hasPlaceholder = text:find("%%s") or text:find("%%q")
	local isFormatString = strNode:parent():type() == "parenthesized_expression"

	if hasPlaceholder and not isFormatString then
		replaceNodeText(strNode, "(" .. text .. "):format()")
	end
end

--------------------------------------------------------------------------------
return M
