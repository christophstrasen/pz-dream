local function readAll(path)
	local f = assert(io.open(path, "r"))
	local content = f:read("*a")
	f:close()
	return content
end

describe("DREAM mod.info", function()
	it("declares DREAMBase as a required mod", function()
		local content = readAll("Contents/mods/DREAM/42/mod.info")
		assert.is_truthy(content:find("\\DREAMBase", 1, true))
	end)
end)

