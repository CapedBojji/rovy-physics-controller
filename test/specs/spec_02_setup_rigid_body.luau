--!nocheck

return function(TS, t)
	local lib = TS.loadPath("out/init")

	t.describe("Update schedule", function()
		t.it("stays runnable after the plugin helper is installed", function()
			local app = lib.App.new()
			lib.configurePhysicsController(app)
			app:start()

			local ok, err = pcall(function()
				app:runSchedule(lib.Update)
			end)

			t.expect(ok).toBe(true)
			t.expect(err).toBeNil()
		end)
	end)
end
