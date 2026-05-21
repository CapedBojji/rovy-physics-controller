local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController runtime registration", function()
		it("registers rovy-decorated controller runtime and tags", function()
			local fixture = helpers.createFixture("Attach")
			local app = helpers.createControllerApp()

			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(20, nil, helpers.createDisabledBounceConfig()),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			app:runSchedule(pkg.PhysicsControllerUpdate)

			local store = app.world:resource(pkg.PhysicsRuntimeStore)
			local runtime = store.entries[entity]
			expect(runtime).to.be.ok()
			expect(runtime.manager.RootPart).to.equal(fixture.root)
			expect(runtime.manager.BaseMoveSpeed).to.equal(20)
			expect(app.world:has(entity, pkg.Grounded)).to.equal(true)
			expect(app.world:has(entity, pkg.Airborne)).to.equal(false)

			fixture.destroy()
		end)
	end)
end
