local M = {}
-- TODO: OS detector + potential to set both keymaps (name?) and ability to override
M.setup = function(opts)
	M.language = opts.language or "en-GB"
	M.dict = require('macaltkey.dicts')[M.language]
	M.convenience = true
	if not opts.convenience then M.convenience = false end
	M.modifier = opts.modifier or 'a'
	M.double_set = opts.double_set or false
end

M.lowerupper = function(modifier)
	modifier = modifier or M.modifier
	return string.lower(modifier) .. string.upper(modifier)
end
M.pattern = function(modifier)
	modifier = modifier or M.modifier
	return "<[" .. M.lowerupper(modifier) .. "]--(.)>"
end

M.replacer = function(match)
	return M.dict[match] or ("<" .. M.modifier .. "-" .. match .. ">")
end

M.convert = function(lhs, modifier, replacer)
	local out = string.gsub(lhs, M.pattern(modifier), replacer or M.replacer)
	if M.language == 'en-GB' then
		-- INFO: additional handling required for the £ character.
		out = string.gsub(out, '<[' .. M.lowerupper(modifier) .. ']--(\194\163)>', M.dict)
	end
	return out
end

if M.convenience then
	M.keymap = {
		set = function(mode, lhs, rhs, opts)
			vim.keymap.set(mode, M.convert(lhs), rhs, opts)
			if opts.double_set or M.double_set then
				vim.keymap.set(mode, lhs, rhs, opts)
			end
		end,
		del = function(mode, lhs, opts)
			vim.keymap.del(mode, M.convert(lhs), opts)
			if opts.double_set or M.double_set then
				vim.keymap.del(mode, lhs, opts)
			end
		end
	}

	M.nvim_set_keymap = function(mode, lhs, rhs, opts)
		vim.api.nvim_set_keymap(mode, M.convert(lhs), rhs, opts)
		if opts.double_set or M.double_set then
			vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
		end
	end

	M.nvim_buf_set_keymap = function(buffer, mode, lhs, rhs, opts)
		vim.api.nvim_buf_set_keymap(buffer, mode, M.convert(lhs), rhs, opts)
		if opts.double_set or M.double_set then
			vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
		end
	end

	M.nvim_del_keymap = function(mode, lhs, opts)
		vim.api.nvim_del_keymap(mode, M.convert(lhs))
		if opts.double_set or M.double_set then
			vim.api.nvim_del_keymap(mode, lhs)
		end
	end

	M.nvim_buf_del_keymap = function(buffer, mode, lhs, opts)
		vim.api.nvim_buf_del_keymap(buffer, mode, M.convert(lhs))
		if opts.double_set or M.double_set then
			vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
		end
	end
end
return M
