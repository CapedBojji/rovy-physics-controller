local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController runtime cleanup", function()
		it("cleans runtime when entity is gone", function()
			local fixture = helpers.createFixture("Cleanup")
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(16, nil, helpers.createDisabledBounceConfig()),
				pkg.PhysicsInput.new(),
				pkg.PhysicsBody.new(fixture.root)
			)

			app:runSchedule(pkg.PhysicsControllerUpdate)
			local store = app.world:resource(pkg.PhysicsRuntimeStore)
			expect(store.entries[entity]).to.be.ok()

			app.world:despawn(entity)
			app:runSchedule(pkg.PhysicsControllerUpdate)
			expect(store.entries[entity]).to.equal(nil)

			fixture.destroy()
		end)
	end)
end
