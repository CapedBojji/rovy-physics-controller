--!nocheck
-- plugin: placeholder spec — fill in as the physics controller is implemented.

return function(TS, t)
	local lib = TS.loadPath("out/init")
	local pluginLib = TS.loadPath("out/runtime/plugin")

	t.describe("PhysicsControllerPlugin", function()
		t.it("can be created", function()
			local plugin = pluginLib.createPhysicsControllerPlugin()
			t.expect(plugin).toBeDefined()
		end)

		t.it("installs into an app through the helper", function()
			local app = lib.App.new()
			local ok, err = pcall(function()
				lib.configurePhysicsController(app)
				app:start()
				app:runSchedule(lib.Update)
			end)

			t.expect(ok).toBe(true)
			t.expect(err).toBeNil()
		end)
	end)
end
