local M = {}
--------------------------------------------------------------------------------

---@param node TSNode
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
	vim.cmd.undojoin() -- make undos ignore the next change, see issue #8
	vim.api.nvim_buf_set_text(0, startRow, startCol, endRow, endCol, lines)
end

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|TSNode nil if no node or nvim version too old
local function getNodeAtCursor()
	if vim.treesitter.get_node == nil then
		vim.notify("nvim-puppeteer requires at least nvim 0.9.", vim.log.levels.WARN)
		return nil
	end
	return vim.treesitter.get_node()
end

---@param node TSNode
---@return string
local function getNodeText(node) return vim.treesitter.get_node_text(node, 0) end

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

	local text = getNodeText(strNode)
	if text == "" then return end -- don't convert empty strings, user might want to enter sth

	local quotationMark = '"' -- default value when no quotation mark has been deleted yet

	local isTaggedTemplate = node:parent():type() == "call_expression"
	local isMultilineString = getNodeText(strNode):find("[\n\r]")
	local hasBraces = text:find("${.-}")

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

	local text = getNodeText(strNode)
	if text == "" then return end -- don't convert empty strings, user might want to enter sth

	-- rf -> raw-formatted-string
	local isFString = text:find("^f") or text:find("^rf")
	-- braces w/ non-digit (not matching regex `{3,}`), see #12
	local hasBraces = text:find("{.-[^%d,].-}")

	if not isFString and hasBraces then
		text = "f" .. text
		replaceNodeText(strNode, text)
	elseif isFString and not hasBraces then
		text = text:sub(2)
		replaceNodeText(strNode, text)
	end
end

--------------------------------------------------------------------------------

local luaFormattingActive = false
function M.luaFormatStr()
	-- GUARD require explicit enabling by the user, since there are a few edge cases
	-- when for lua format strings because a "%s" in a lua string can either be
	-- a lua class pattern or a placeholder
	if not vim.g.puppeteer_lua_format_string then return end

	-- get string node
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
	local methodText = stringMethod and getNodeText(stringMethod) or ""
	local isLuaPattern = methodText:find("g?match") or methodText == "find" or methodText == "gsub"
	if isLuaPattern or methodText == "format" then return end

	local text = getNodeText(strNode)
	if text == "" then return end -- don't convert empty strings, user might want to enter sth

	-- replace text
	-- DOCS https://www.lua.org/manual/5.4/manual.html#pdf-string.format
	-- https://www.lua.org/manual/5.4/manual.html#6.4.1
	local hasPlaceholder = text:find("%%[sq]")
	local likelyLuaPattern = text:find("%%[waudglpfb]") or text:find("%%s[*+-]")
	local isFormatString = strNode:parent():type() == "parenthesized_expression"

	if hasPlaceholder and not (isFormatString or likelyLuaPattern) then
		-- HACK `luaFormattingActive` is used to prevent weird unexplainable
		-- duplicate triggering. Not sure why it happens, the conditions should
		-- prevent it.
		if luaFormattingActive then return end
		luaFormattingActive = true

		replaceNodeText(strNode, "(" .. text .. "):format()")
		-- move cursor so user can insert there directly
		local row, col = strNode:end_()
		vim.api.nvim_win_set_cursor(0, { row + 1, col + 1 })
		vim.cmd.startinsert()

		vim.defer_fn(function() luaFormattingActive = false end, 100)
	elseif not hasPlaceholder and isFormatString then
		local formatCall = strNode:parent():parent():parent()
		local removedFormat = getNodeText(formatCall):gsub("%((.*)%):format%(.*%)", "%1")
		replaceNodeText(formatCall, removedFormat)
	end
end

--------------------------------------------------------------------------------
return M
