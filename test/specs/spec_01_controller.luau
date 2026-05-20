-- PhysicsController specs.
-- Uses Zune's native testing API (zune.testing).

local testing = zune.testing
local describe = testing.describe
local test = testing.test
local expect = testing.expect

-- The compiled roblox-ts output lives at out/init.luau after `rbxtsc`.
-- Require it from the project root (zune test is run from the repo root).
local lib = require("./out/init")

describe("PhysicsController", function()
	test("can be constructed with no arguments", function()
		local controller = lib.PhysicsController.new()
		expect(controller).toBeDefined()
	end)

	test("can be constructed with options", function()
		local controller = lib.PhysicsController.new({})
		expect(controller).toBeDefined()
	end)
end)
