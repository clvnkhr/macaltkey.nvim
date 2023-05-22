local M = {}

-- taken from f-person/auto-dark-mode.nvim
---@return 'win'|'darwin'|'linux'
M.get_os = function()
	if package.config:sub(1, 1) == "\\" then
		return "win"
	elseif (io.popen("uname -s"):read("*a")):match("Darwin") then
		return "darwin"
	else
		return "linux"
	end
end

-- Call this function before using the plugin. Sets the dict, modifier, double_set, and gets the os.
-- supported options:
-- language = "en-GB" | "en-US", defaults to "en-GB"
-- modifier = str, defaults to "a" for alt
-- double_set = bool, defaults to false
M.setup = function(opts)
	opts = opts or {}
	M.language = opts.language or "en-GB"
	M.dict = require('macaltkey.dicts')[M.language]
	M.modifier = opts.modifier or 'a'
	M.double_set = opts.double_set or false
	M.os = M.get_os()
end

local lowerupper = function(modifier)
	modifier = modifier or M.modifier
	return string.lower(modifier) .. string.upper(modifier)
end

-- makes a lua pattern using modifier
M.pattern = function(modifier)
	modifier = modifier or M.modifier
	return "<[" .. lowerupper(modifier) .. "]--(.)>"
end

-- function to be passed into string.gsub.
M.replacer = function(match)
	return M.dict[match] or ("<" .. M.modifier .. "-" .. match .. ">")
end

-- Do nothing if not using Mac OS
-- Otherwise, replace using M.pattern and M.replacer
M.convert = function(lhs, modifier, replacer)
	if M.os ~= "darwin" then return lhs end

	local out = string.gsub(lhs, M.pattern(modifier), replacer or M.replacer)

	if M.language == 'en-GB' then
		-- INFO: additional handling required for the £ character.
		out = string.gsub(out, '<[' .. lowerupper(modifier) .. ']--(\194\163)>', M.dict)
	end
	return out
end

-- convenience functions
M.keymap = {
	-- simple wrapper around vim.keymap.set
	set = function(mode, lhs, rhs, opts, opts2)
		opts = opts or {}
		opts2 = opts2 or {}
		vim.keymap.set(mode, M.convert(lhs), rhs, opts)
		if opts2.double_set == true or (opts2.double_set == nil and M.double_set == true) then
			vim.keymap.set(mode, lhs, rhs, opts)
		end
	end,
	-- simple wrapper around vim.keymap.del
	del = function(mode, lhs, opts, opts2)
		opts = opts or {}
		opts2 = opts2 or {}
		vim.keymap.del(mode, M.convert(lhs), opts)
		if opts2.double_set == true or (opts2.double_set == nil and M.double_set == true) then
			vim.keymap.del(mode, lhs, opts)
		end
	end
}

-- simple wrapper around vim.api.nvim_set_keymap.
M.nvim_set_keymap = function(mode, lhs, rhs, opts, opts2)
	opts = opts or {}
	opts2 = opts2 or {}
	vim.api.nvim_set_keymap(mode, M.convert(lhs), rhs, opts)
	-- P(opts2.double_set)
	-- P((opts2.double_set == nil) and (M.double_set == true))
	if (opts2.double_set == true) or ((opts2.double_set == nil) and (M.double_set == true)) then
		-- P('inside if')
		vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
	end
end

-- simple wrapper around vim.api.nvim_buf_set_keymap
M.nvim_buf_set_keymap = function(buffer, mode, lhs, rhs, opts, opts2)
	opts = opts or {}
	opts2 = opts2 or {}
	vim.api.nvim_buf_set_keymap(buffer, mode, M.convert(lhs), rhs, opts)
	if opts2.double_set == true or (opts2.double_set == nil and M.double_set == true) then
		vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
	end
end

-- simple wrapper around vim.api.nvim_del_keymap
M.nvim_del_keymap = function(mode, lhs, opts)
	opts = opts or {}
	vim.api.nvim_del_keymap(mode, M.convert(lhs))
	if opts.double_set == true or (opts.double_set == nil and M.double_set == true) then
		vim.api.nvim_del_keymap(mode, lhs)
	end
end

-- simple wrapper around vim.api.nvim_buf_del_keymap
M.nvim_buf_del_keymap = function(buffer, mode, lhs, opts)
	opts = opts or {}
	vim.api.nvim_buf_del_keymap(buffer, mode, M.convert(lhs))
	if opts.double_set == true or (opts.double_set == nil and M.double_set == true) then
		vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
	end
end

return M
