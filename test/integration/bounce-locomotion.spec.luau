local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController bounce locomotion", function()
		it("uses repeated mini-bounces for normal movement", function()
			local fixture = helpers.createFixture("BounceWalk")
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(14, nil, helpers.createBounceConfig({
					groundBounceStrength = 10,
					carryRetentionPerBounce = 0.8,
					bigJumpCarryScale = 0.2,
					maxCarrySpeed = 24,
					carrySteerFactor = 0.2,
				})),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				local startY = fixture.root.Position.Y
				local startZ = fixture.root.Position.Z
				local peakY = startY
				local minZ = startZ
				local airborneSeen = false

				for frame = 1, 30 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					game:GetService("RunService").Heartbeat:Wait()

					local currentY = fixture.root.Position.Y
					if currentY > peakY then
						peakY = currentY
					end
					if fixture.root.Position.Z < minZ then
						minZ = fixture.root.Position.Z
					end
					if app.world:has(entity, pkg.Airborne) then
						airborneSeen = true
					end
				end

				expect(peakY > startY + 0.25).to.equal(true)
				expect(airborneSeen).to.equal(true)
				expect(minZ < startZ - 1).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("does mostly vertical idle hops when no input and no carry", function()
			local fixture = helpers.createFixture("BounceIdle")
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(14, nil, helpers.createBounceConfig({
					groundBounceStrength = 9,
					carryRetentionPerBounce = 0.8,
					bigJumpCarryScale = 0.2,
					maxCarrySpeed = 24,
					carrySteerFactor = 0.2,
				})),
				pkg.PhysicsInput.new(),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				local start = fixture.root.Position
				local peakY = start.Y

				for _ = 1, 25 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					game:GetService("RunService").Heartbeat:Wait()
					if fixture.root.Position.Y > peakY then
						peakY = fixture.root.Position.Y
					end
				end

				expect(peakY > start.Y + 0.25).to.equal(true)
				expect(math.abs(fixture.root.Position.X - start.X) < 0.5).to.equal(true)
				expect(math.abs(fixture.root.Position.Z - start.Z) < 0.5).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("stops normal horizontal movement after input is released", function()
			local fixture = helpers.createFixture("BounceStop")
			local app = helpers.createControllerApp()
			local input = pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1))
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(14, nil, helpers.createBounceConfig({
					groundBounceStrength = 10,
					carryRetentionPerBounce = 0.8,
					bigJumpCarryScale = 0.2,
					maxCarrySpeed = 24,
					carrySteerFactor = 0.2,
				})),
				input,
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				helpers.runFrames(app, entity, fixture.root, 15, "bounce-stop-move")
				input.moveDirection = Vector3.zero
				input.facingDirection = Vector3.new(0, 0, -1)

				local lowestSpeedAfterRelease = math.huge
				for _ = 1, 40 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					game:GetService("RunService").Heartbeat:Wait()
					local speed = helpers.horizontalSpeed(fixture.root)
					if speed < lowestSpeedAfterRelease then
						lowestSpeedAfterRelease = speed
					end
				end

				expect(lowestSpeedAfterRelease < 1).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)
	end)
end
