package.path = table.concat({
	"Contents/mods/DREAM/42/media/lua/shared/?.lua",
	"Contents/mods/DREAM/42/media/lua/shared/?/init.lua",
	package.path,
}, ";")

pcall(require, "DREAMBase/bootstrap")

describe("DREAM examples", function()
	it("loads the examples placeholder module", function()
		local mod = require("examples/dream_examples")
		assert.is_table(mod)
		assert.equals("DREAM examples placeholder", mod.name)
	end)
end)

