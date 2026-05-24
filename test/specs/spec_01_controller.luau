--!nocheck
-- plugin: placeholder spec — fill in as the physics controller is implemented.

return function(TS, t)
	local lib = TS.loadPath("out/init")
	local state = TS.loadPath("out/state")

	t.describe("PhysicsControllerPlugin", function()
		t.it("can be created", function()
			local plugin = lib.PhysicsControllerPlugin.new()
			t.expect(plugin).toBeDefined()
		end)

		t.it("installs into an app through the helper", function()
			local app = lib.App.new()
			local ok, err = pcall(function()
				app:addPlugin(lib.PhysicsControllerPlugin.new())
				app:start()
				app:runSchedule(state.Update)
			end)

			t.expect(ok).toBe(true)
			t.expect(err).toBeNil()
		end)
	end)
end
