local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController movement and events", function()
		it("moves under physics and drains queued controller events", function()
			local fixture = helpers.createFixture("Trace")
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(22, nil, helpers.createDisabledBounceConfig()),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)
			local startPosition = fixture.root.Position

			helpers.startSimulation()

			local ok, err = pcall(function()
				app.commands:send(pkg.JumpEvent.new(entity, 40))
				app:flush()
				local peakY, jumpPosition = helpers.runFrames(app, entity, fixture.root, 30, "jump")
				expect(peakY > startPosition.Y + 0.1).to.equal(true)

				app.commands:send(pkg.ApplyImpulseEvent.new(entity, Vector3.new(0, 0, -120)))
				app:flush()
				local _, impulsePosition = helpers.runFrames(app, entity, fixture.root, 30, "impulse")
				expect(impulsePosition.Z < jumpPosition.Z - 0.1).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)
	end)
end
