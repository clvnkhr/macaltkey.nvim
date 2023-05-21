local mak = require("macaltkey")

local find_map = function(maps, lhs)
	for _, map in ipairs(maps) do
		if map.lhs == lhs then
			return map
		end
	end
end

describe("macaltkey", function()
	it("can correctly maps chars with en-US dict", function()
		mak.setup({ language = "en-US" })
		print(mak.language)
		local hand_typed_string =
		'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`,./;\'\\[]~<>?:"|{}1234567890-=!@#$%^&*()_+'
		local hand_typed_expected =
		'å∫ç∂´ƒ©˙ˆ∆˚¬µ˜øπœ®ß†¨√∑≈¥ΩÅıÇÎ´Ï˝ÓˆÔÒÂ˜Ø∏Œ‰Íˇ¨◊„˛Á¸`≤≥÷…æ«“‘`¯˘¿ÚÆ»”’¡™£¢∞§¶•ªº–≠⁄€‹›ﬁﬂ‡°·‚—±'
		local replaced = string.gsub(string.gsub(hand_typed_string, '.', mak.dict), '\194\163', mak.dict)
		-- NOTE: the double gsub is required to deal with £ which is not a signle 8-byte char.

		assert.are.same(hand_typed_expected, replaced)
	end
	)

	it("can correctly maps chars with en-GB dict", function()
		mak.setup({ language = "en-GB" })
		local hand_typed_string = -- NOTE: the # symbol is typed via opt-3. shift-3 gives £.
		'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`,./;\'\\[]~<>?:"|{}1234567890-=!@£$%^&*()_+'
		local hand_typed_expected =
		'å∫ç∂´ƒ©˙^∆˚¬µ~øπœ®ß†¨√∑≈¥ΩÅıÇÎ‰ÏÌÓÈÔÒ˜ˆØ∏ŒÂÍÊË◊„ÙÁÛ`≤≥÷…æ«“‘Ÿ¯˘¿ÚÆ»”’¡€#¢∞§¶•ªº–≠⁄™‹›ﬁﬂ‡°·‚—±'
		local replaced = string.gsub(string.gsub(hand_typed_string, '.', mak.dict), '\194\163', mak.dict)
		-- NOTE: the double gsub is required to deal with £ which is not a signle 8-byte char.

		assert.are.same(hand_typed_expected, replaced)
	end
	)

	it("can convert legal commands", function()
		mak.setup({ language = "en-GB" })
		assert.are.same("hello å‹ß<leader>", mak.convert("hello <a-a><a-£><A-s><leader>"))
	end
	)
	it("won't convert illegal commands", function()
		mak.setup({ language = "en-GB" })
		assert.are.same("<a-⦿>", mak.convert("<a-⦿>"))
	end
	)
	-- TODO: test the setter and dellers
	--
	it("can set commands", function()
		mak.setup({ language = "en-GB" })

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1", {})
		mak.keymap.set("n", "test2<a-b>", "rhs2", {})
		-- TODO: I don't know how nvim_buf_set_keymap works but it is similarly wrapped so should also work
		local maps = vim.api.nvim_get_keymap("n")

		local found1 = find_map(maps, mak.convert("test1<a-a>"))
		local found2 = find_map(maps, mak.convert("test2<a-b>"))

		assert.are.same("rhs1", found1.rhs)
		assert.are.same("rhs2", found2.rhs)
	end
	)
	it("can del commands", function()
		mak.setup({ language = "en-GB" })

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1")
		mak.keymap.set("n", "test2<a-b>", "rhs2")
		local maps = vim.api.nvim_get_keymap("n")

		local found1 = find_map(maps, mak.convert("test1<a-a>"))

		local found2 = find_map(maps, mak.convert("test2<a-b>"))
		assert.are.same("rhs1", found1.rhs)
		assert.are.same("rhs2", found2.rhs)

		mak.keymap.del("n", "test1<a-a>")
		mak.nvim_del_keymap("n", "test2<a-b>")

		maps = vim.api.nvim_get_keymap("n")
		found1 = find_map(maps, mak.convert("test1<a-a>"))
		found2 = find_map(maps, mak.convert("test2<a-b>"))
		assert.are.same(nil, found1)
		assert.are.same(nil, found2)
	end
	)
end
)
