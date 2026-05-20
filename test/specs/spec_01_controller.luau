--!nocheck
-- controller: placeholder spec — fill in as the physics controller is implemented.

return function(TS, t)
	local lib = TS.loadPath("out/init")

	t.describe("PhysicsController", function()
		t.it("can be constructed", function()
			local controller = lib.PhysicsController.new()
			t.expect(controller).toBeDefined()
		end)
	end)
end
