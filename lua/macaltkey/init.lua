local M = {}

-- TODO: profile this code, and if its slow try to remove lowerupper. this change will allow for multiple replacers at once. I can probably keep lowerupper around in case the modifier is a single char
-- Expose a force option

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
	M.modifier = opts.modifier or 'aA'
	M.double_set = opts.double_set or false
	M.os = M.get_os()
	M.default_pattern = M.pattern(M.modifier)
	M.flag = nil
	if opts.force ~= nil then
		M.flag = opts.force
	else
		M.flag = M.os == "darwin"
	end
end

M.lowerupper = function(modifier)
	modifier = modifier or M.modifier
	return string.lower(modifier) .. string.upper(modifier)
end

-- makes a lua pattern using modifier
M.pattern = function(modifier, ch)
	ch = ch or '.'
	modifier = modifier or M.modifier
	if string.len(M.modifier) == 1 then
		return "<[" .. M.lowerupper(modifier) .. "]--(" .. ch .. ")>"
	else
		return "<[" .. modifier .. "]--(" .. ch .. ")>"
	end
end

-- Do nothing if not using Mac OS
-- Otherwise, replace using M.pattern and M.replacer
M.convert = function(lhs, modifier, replacer)
	if not M.flag then return lhs end

	local pattern
	if modifier == nil then
		pattern = M.default_pattern
		modifier = M.modifier
	else
		pattern = M.pattern(modifier)
	end

	local out = string.gsub(lhs, pattern, replacer or M.dict)

	if M.language == 'en-GB' then
		-- INFO: additional handling required for the £ character.
		out = string.gsub(out, M.pattern(modifier, '£'), '‹')
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
		if opts2.double_set == true or (opts2.double_set == nil and M.double_set == true and M.os == "darwin") then
			vim.keymap.set(mode, lhs, rhs, opts)
		end
	end,
	-- simple wrapper around vim.keymap.del
	del = function(mode, lhs, opts, opts2)
		opts = opts or {}
		opts2 = opts2 or {}
		vim.keymap.del(mode, M.convert(lhs), opts)
		if opts2.double_set == true or (opts2.double_set == nil and M.double_set == true and M.os == "darwin") then
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
	if (opts2.double_set == true) or ((opts2.double_set == nil) and (M.double_set == true and M.os == "darwin")) then
		-- P('inside if')
		vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
	end
end

-- simple wrapper around vim.api.nvim_buf_set_keymap
M.nvim_buf_set_keymap = function(buffer, mode, lhs, rhs, opts, opts2)
	opts = opts or {}
	opts2 = opts2 or {}
	vim.api.nvim_buf_set_keymap(buffer, mode, M.convert(lhs), rhs, opts)
	if (opts2.double_set == true) or ((opts2.double_set == nil) and (M.double_set == true and M.os == "darwin")) then
		vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
	end
end

-- simple wrapper around vim.api.nvim_del_keymap
M.nvim_del_keymap = function(mode, lhs, opts)
	opts = opts or {}
	vim.api.nvim_del_keymap(mode, M.convert(lhs))
	if (opts.double_set == true) or ((opts.double_set == nil) and (M.double_set == true and M.os == "darwin")) then
		vim.api.nvim_del_keymap(mode, lhs)
	end
end

-- simple wrapper around vim.api.nvim_buf_del_keymap
M.nvim_buf_del_keymap = function(buffer, mode, lhs, opts)
	opts = opts or {}
	vim.api.nvim_buf_del_keymap(buffer, mode, M.convert(lhs))
	if (opts.double_set == true) or ((opts.double_set == nil) and (M.double_set == true and M.os == "darwin")) then
		vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
	end
end

-- function to make the reverse dict. Not called in setup to avoid making it if we don't want to
M.make_rev_dict = function(prefix, postfix)
	local new_d = {}
	for k, v in pairs(M.dict) do
		new_d[v] = prefix .. k .. postfix
	end
	return new_d
end

-- function to help converting vim.keymap to macaltkey convenience functions.
-- There is no default utf8 handling in Lua 5.1, so we make multiple passes:
-- once for single byte chars(#), once for multibytes chars(£).
M.deconvert = function(text, prefix, postfix)
	prefix = prefix or "<a-"
	postfix = postfix or ">"
	if M.reverse_dict == nil then
		M.reverse_dict = M.make_rev_dict(prefix, postfix)
	end
	local out = string.gsub(text, '.', M.reverse_dict)
	return string.gsub(out, '[\192-\255][\128-\191]*', M.reverse_dict)
	-- return out
end

return M
