local M = {}
--------------------------------------------------------------------------------

---@param node TSNode
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
	pcall(vim.cmd.undojoin) -- make undos ignore the next change, see #8
	vim.api.nvim_buf_set_text(0, startRow, startCol, endRow, endCol, lines)
end

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|TSNode nil if no node or nvim version too old
local function getNodeAtCursor()
	if vim.treesitter.get_node == nil then
		vim.notify("nvim-puppeteer requires at least nvim 0.9.", vim.log.levels.WARN)
		return
	end
	return vim.treesitter.get_node()
end

---@param node TSNode
---@return string
local function getNodeText(node) return vim.treesitter.get_node_text(node, 0) end

--------------------------------------------------------------------------------

-- CONFIG
-- safeguard to prevent converting invalid code
local maxCharacters = 200

--------------------------------------------------------------------------------

-- auto-convert string to template string and back
function M.templateStr()
	local node = getNodeAtCursor()
	if not node then return end
	if node:type() == "string_fragment" or node:type() == "escape_sequence" then node = node:parent() end
	if not node then return end
	local text = getNodeText(node)

	if
		not (node:type() == "string" or node:type() == "template_string")
		or text == "" -- user might want to enter sth
		or #text > maxCharacters -- safeguard against converting invalid code
	then
		return
	end

	-- not checking via node-type, since treesitter sometimes does not update that in time
	local isTemplateStr = text:find("^`.*`$")
	local isTaggedTemplate = node:parent():type() == "call_expression"
	local isMultilineString = text:find("[\n\r]")
	local hasBraces = text:find("%${.-}")

	if not isTemplateStr and (hasBraces or isMultilineString) then
		text = "`" .. text:sub(2, -2) .. "`"
		replaceNodeText(node, text)
	elseif isTemplateStr and not (hasBraces or isMultilineString or isTaggedTemplate) then
		local quote = vim.g.puppeteer_js_quotation_mark == "'" and "'" or '"'
		text = quote .. text:sub(2, -2) .. quote
		replaceNodeText(node, text)
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
	if not strNode then return end
	local text = getNodeText(strNode)

	-- GUARD
	if text == "" then return end -- don't convert empty strings, user might want to enter sth
	if #text > maxCharacters then return end -- safeguard on converting invalid code

	local isFString = text:find("^r?f") -- rf -> raw-formatted-string
	local hasBraces = text:find("{.-[^%d,%s].-}") -- nonRegex-braces, see #12 and #15

	if not isFString and hasBraces then
		text = "f" .. text
		replaceNodeText(strNode, text)
	elseif isFString and not hasBraces then
		text = text:sub(2)
		replaceNodeText(strNode, text)
	end
end

--------------------------------------------------------------------------------

function M.luaFormatStr()
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
	if not strNode then return end
	local text = getNodeText(strNode)

	-- GUARD
	-- lua patterns (string.match, …) use `%s` as class patterns
	-- this works with string.match() as well as var:match()
	local stringMethod = strNode:parent()
		and strNode:parent():prev_sibling()
		and strNode:parent():prev_sibling():child(2)
	local methodText = stringMethod and getNodeText(stringMethod) or ""
	local isLuaPattern = vim.tbl_contains({ "match", "gmatch", "find", "gsub" }, methodText)
	local likelyLuaPattern = text:find("%%[waudglpfb]") or text:find("%%s[*+-]")
	if isLuaPattern or likelyLuaPattern then return end
	if text == "" then return end -- don't convert empty strings, user might want to enter sth
	if #text > maxCharacters then return end -- safeguard on converting invalid code

	-- REPLACE TEXT
	-- string format: https://www.lua.org/manual/5.4/manual.html#pdf-string.format
	-- patterns: https://www.lua.org/manual/5.4/manual.html#6.4.1
	local hasPlaceholder = (text:find("%%[sq]") and not text:find("%%s[*+-]")) or text:find("%%06[Xx]")
	local isFormatString = strNode:parent():type() == "parenthesized_expression"

	if hasPlaceholder and not isFormatString then
		replaceNodeText(strNode, "(" .. text .. "):format()")
		-- move cursor so user can insert there directly
		local row, col = strNode:end_()
		vim.api.nvim_win_set_cursor(0, { row + 1, col - 1 })
		vim.cmd.startinsert()
	elseif isFormatString and not hasPlaceholder then
		local formatCall = strNode:parent():parent():parent()
		if not formatCall then return end
		local removedFormat = getNodeText(formatCall):gsub("%((.*)%):format%(.*%)", "%1")
		replaceNodeText(formatCall, removedFormat)
	end
end

--------------------------------------------------------------------------------
return M
