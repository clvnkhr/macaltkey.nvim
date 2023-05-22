local mak = require("macaltkey")

-- taken from teejdv and bash's video
local find_map = function(maps, lhs)
	for _, map in ipairs(maps) do
		if map.lhs == lhs then
			return map
		end
	end
end

local printmaplhs = function(maps)
	for _, map in ipairs(maps) do
		print(map.lhs)
	end
end


describe("macaltkey", function()
	it("can correctly map chars with en-US dict", function()
		mak.setup({ language = "en-US" })
		local hand_typed_string =
		'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`,./;\'\\[]~<>?:"|{}1234567890-=!@#$%^&*()_+'
		local hand_typed_expected =
		'å∫ç∂´ƒ©˙ˆ∆˚¬µ˜øπœ®ß†¨√∑≈¥ΩÅıÇÎ´Ï˝ÓˆÔÒÂ˜Ø∏Œ‰Íˇ¨◊„˛Á¸`≤≥÷…æ«“‘`¯˘¿ÚÆ»”’¡™£¢∞§¶•ªº–≠⁄€‹›ﬁﬂ‡°·‚—±'
		local replaced = string.gsub(hand_typed_string, '.', mak.dict)

		assert.are.same(hand_typed_expected, replaced)
	end
	)

	it("can correctly map chars with en-GB dict", function()
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
		mak.os = "darwin" --INFO: allow tests to pass on non-macs

		assert.are.same("hello å‹ß<leader>", mak.convert("hello <a-a><a-£><A-s><leader>"))
	end
	)

	it("won't convert illegal commands", function()
		mak.setup({ language = "en-GB" })
		mak.os = "darwin"

		assert.are.same("<a-⦿>", mak.convert("<a-⦿>"))
	end
	)

	it("can set commands", function()
		mak.setup({ language = "en-GB" })
		mak.os = "darwin"

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1")
		mak.keymap.set("n", "test2<a-b>", "rhs2")
		-- WARN: I don't know how nvim_buf_set_keymap works
		-- but it is similarly wrapped, so should also work if this test passes
		-- similarly with del below

		local maps = vim.api.nvim_get_keymap("n")

		local found1 = find_map(maps, mak.convert("test1<a-a>"))
		local found2 = find_map(maps, mak.convert("test2<a-b>"))

		assert.are.same("rhs1", found1.rhs)
		assert.are.same("rhs2", found2.rhs)
		-- INFO: verify that extra commands are not set
		local notfound1 = find_map(maps, "test1<M-a>")
		local notfound2 = find_map(maps, "test2<M-b>")
		assert.are.same(nil, notfound1)
		assert.are.same(nil, notfound2)
		--INFO: cleanup for next test
		mak.keymap.del("n", "test1<a-a>")
		mak.keymap.del("n", "test2<a-b>")
		maps = vim.api.nvim_get_keymap("n")
	end
	)
	it("can del commands", function()
		mak.setup({ language = "en-GB" })

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1")
		mak.keymap.set("n", "test2<a-b>", "rhs2")
		local maps = vim.api.nvim_get_keymap("n")

		local found1 = find_map(maps, mak.convert("test1<a-a>"))

		local found2 = find_map(maps, mak.convert("test2<a-b>"))
		assert.are.same("rhs1", found1.rhs) -- INFO: verify they exist before deleting
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
	-- TODO: test double_set and what happens if OS is not set. And actually run the mac test
	it("can double set keymaps when option passed to function", function()
		mak.setup({ language = "en-GB" })
		mak.os = "darwin"

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1", {}, { double_set = true })
		mak.keymap.set("n", "test2<a-b>", "rhs2", {}, { double_set = true })

		local maps = vim.api.nvim_get_keymap("n")

		local found1a = find_map(maps, mak.convert("test1<a-a>"))
		-- NOTE: <a-x> is converted to <M-x>
		local found1b = find_map(maps, "test1<M-a>")
		local found2a = find_map(maps, mak.convert("test2<a-b>"))
		local found2b = find_map(maps, "test2<M-b>")
		assert.are.same("rhs1", found1a.rhs)
		assert.are.same("rhs1", found1b.rhs)
		assert.are.same("rhs2", found2a.rhs)
		assert.are.same("rhs2", found2b.rhs)

		--INFO: cleanup for next test
		mak.keymap.del("n", "test1<a-a>", {}, { double_set = true })
		mak.keymap.del("n", "test2<a-b>", {}, { double_set = true })
	end
	)

	it("can double set keymaps when option passed to setup", function()
		mak.setup({ language = "en-GB", double_set = true })
		mak.os = "darwin"

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1")
		mak.keymap.set("n", "test2<a-b>", "rhs2")

		local maps = vim.api.nvim_get_keymap("n")
		local found1a = find_map(maps, mak.convert("test1<a-a>"))
		-- NOTE: <a-x> is converted to <M-x>
		local found1b = find_map(maps, "test1<M-a>")
		local found2a = find_map(maps, mak.convert("test2<a-b>"))
		local found2b = find_map(maps, "test2<M-b>")
		assert.are.same("rhs1", found1a.rhs)
		assert.are.same("rhs1", found1b.rhs)
		assert.are.same("rhs2", found2a.rhs)
		assert.are.same("rhs2", found2b.rhs)

		--INFO: cleanup for next test
		mak.keymap.del("n", "test1<a-a>", {}, { double_set = true })
		mak.keymap.del("n", "test2<a-b>", {}, { double_set = true })
	end
	)

	it("won't double set keymaps when option passed to function overrides setup", function()
		mak.setup({ language = "en-GB", double_set = true })
		mak.os = "darwin"

		mak.nvim_set_keymap("n", "test1<a-a>", "rhs1", {}, { double_set = false })
		mak.keymap.set("n", "test2<a-b>", "rhs2", {}, { double_set = false })
		local maps = vim.api.nvim_get_keymap("n")
		-- printmaplhs(maps)
		local found1a = find_map(maps, mak.convert("test1<a-a>"))
		-- NOTE: <a-x> is converted to <M-x>
		local found1b = find_map(maps, "test1<M-a>")
		local found2a = find_map(maps, mak.convert("test2<a-b>"))
		local found2b = find_map(maps, "test2<M-b>")
		assert.are.same("rhs1", found1a.rhs)
		assert.are.same(nil, found1b)
		assert.are.same("rhs2", found2a.rhs)
		assert.are.same(nil, found2b)
		--INFO: cleanup for next test
		mak.keymap.del("n", "test1<a-a>", {}, { double_set = false })
		mak.keymap.del("n", "test2<a-b>", {}, { double_set = false })
	end
	)
end
)
