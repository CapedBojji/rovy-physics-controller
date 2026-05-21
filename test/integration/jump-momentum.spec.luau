local RunService = game:GetService("RunService")

local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController jump momentum", function()
		it("keeps horizontal momentum through jump", function()
			local fixture = helpers.createFixture("Momentum")
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(22, nil, helpers.createDisabledBounceConfig()),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				helpers.runFrames(app, entity, fixture.root, 10, "momentum-ground")
				local groundedSpeed = helpers.horizontalSpeed(fixture.root)
				local startY = fixture.root.Position.Y
				local startZ = fixture.root.Position.Z

				app.commands:send(pkg.JumpEvent.new(entity, 40))
				app:flush()

				local peakY = startY
				local airborneSeen = false
				local maxAirborneHorizontalSpeed = 0
				local airborneStartZ = nil

				for frame = 1, 20 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					RunService.Heartbeat:Wait()

					local currentY = fixture.root.Position.Y
					if currentY > peakY then
						peakY = currentY
					end

					if app.world:has(entity, pkg.Airborne) then
						if not airborneSeen then
							airborneSeen = true
							airborneStartZ = fixture.root.Position.Z
						end
						local speed = helpers.horizontalSpeed(fixture.root)
						if speed > maxAirborneHorizontalSpeed then
							maxAirborneHorizontalSpeed = speed
						end
					end

					if frame % 10 == 0 then
						local grounded = app.world:has(entity, pkg.Grounded)
						local position = fixture.root.Position
						local velocity = fixture.root.AssemblyLinearVelocity
						print(string.format(
							"[physics trace] momentum-air f=%d pos=(%.2f,%.2f,%.2f) vel=(%.2f,%.2f,%.2f) grounded=%s",
							frame,
							math.round(position.X * 100) / 100,
							math.round(position.Y * 100) / 100,
							math.round(position.Z * 100) / 100,
							math.round(velocity.X * 100) / 100,
							math.round(velocity.Y * 100) / 100,
							math.round(velocity.Z * 100) / 100,
							tostring(grounded)
						))
					end
				end

				expect(groundedSpeed > 5).to.equal(true)
				expect(airborneSeen).to.equal(true)
				expect(peakY > startY + 0.1).to.equal(true)
				expect(maxAirborneHorizontalSpeed > groundedSpeed * 0.25).to.equal(true)
				expect(fixture.root.Position.Z < startZ - 1).to.equal(true)
				if airborneStartZ ~= nil then
					expect(fixture.root.Position.Z < airborneStartZ - 0.5).to.equal(true)
				end
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)
	end)
end
