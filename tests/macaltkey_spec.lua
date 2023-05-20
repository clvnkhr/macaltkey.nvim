local mak = require("macaltkey")

describe("macaltkey", function()
	it("can be required", function()
		require("macaltkey")
	end
	)

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
end
)
