local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

local function createCeiling(name, y)
	local ceiling = Instance.new("Part")
	ceiling.Name = name .. "_Ceiling"
	ceiling.Anchored = true
	ceiling.Size = Vector3.new(256, 1, 256)
	ceiling.Position = Vector3.new(0, y, 0)
	ceiling.Parent = Workspace
	return ceiling
end

return function()
	describe("PhysicsController bounce carry", function()
		it("adds temporary carry from big jumps and decays it over later bounces", function()
			local fixture = helpers.createFixture("BounceCarry")
			local app = helpers.createControllerApp()
				local entity = app.world:spawn(
					pkg.PhysicsControllerConfig.new(12, nil, helpers.createBounceConfig({
						groundBounceStrength = 8,
						carryRetentionPerBounce = 0.35,
						bigJumpCarryScale = 0.45,
						maxCarrySpeed = 50,
						carrySteerFactor = 0.15,
						minCarryBounceThreshold = 0.25,
				})),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				helpers.runFrames(app, entity, fixture.root, 15, "bounce-base")
				local baseSpeed = helpers.horizontalSpeed(fixture.root)
				expect(helpers.sendGroundedJump(app, entity, fixture.root, 20)).to.equal(true)

				local peakSpeed = baseSpeed
				local lateMinimumSpeed = math.huge
				for frame = 1, 180 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					RunService.Heartbeat:Wait()
					local speed = helpers.horizontalSpeed(fixture.root)
					if speed > peakSpeed then
						peakSpeed = speed
					end
					if frame >= 120 and speed < lateMinimumSpeed then
						lateMinimumSpeed = speed
					end
					if frame == 15 then
						print(string.format("[physics trace] carry-peak speed=%.2f", peakSpeed))
					end
				end

				print(string.format(
					"[physics trace] carry-window base=%.2f peak=%.2f late-min=%.2f",
					baseSpeed,
					peakSpeed,
					lateMinimumSpeed
				))
				expect(peakSpeed > baseSpeed + 4).to.equal(true)
				expect(lateMinimumSpeed < peakSpeed).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("keeps carry at first then gradually biases toward reversed input", function()
			local fixture = helpers.createFixture("BounceReverse")
			local app = helpers.createControllerApp()
			local input = pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1))
					local entity = app.world:spawn(
						pkg.PhysicsControllerConfig.new(12, nil, helpers.createBounceConfig({
							groundBounceStrength = 8,
							carryRetentionPerBounce = 0.8,
							bigJumpCarryScale = 1.1,
							maxCarrySpeed = 80,
							carrySteerFactor = 0.15,
							minCarryBounceThreshold = 0.25,
					})),
				input,
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				helpers.runFrames(app, entity, fixture.root, 10, "bounce-reverse-base")
				expect(helpers.sendGroundedJump(app, entity, fixture.root, 40)).to.equal(true)

				for _ = 1, 8 do
					helpers.runOneFrame(app)
				end

				input.moveDirection = Vector3.new(0, 0, 1)
				input.facingDirection = Vector3.new(0, 0, 1)

				local earlyZVelocity = nil
				local bestLateZVelocity = -math.huge
				for frame = 1, 180 do
					app:runSchedule(pkg.PhysicsControllerUpdate)
					RunService.Heartbeat:Wait()
					if frame == 5 then
						earlyZVelocity = fixture.root.AssemblyLinearVelocity.Z
					end
					if frame >= 30 and fixture.root.AssemblyLinearVelocity.Z > bestLateZVelocity then
						bestLateZVelocity = fixture.root.AssemblyLinearVelocity.Z
					end
				end

				print(string.format(
					"[physics trace] carry-reverse early-z=%.2f best-late-z=%.2f",
					earlyZVelocity or 0,
					bestLateZVelocity
				))
				expect(earlyZVelocity ~= nil and earlyZVelocity < 0).to.equal(true)
				expect(bestLateZVelocity > earlyZVelocity).to.equal(true)
			end)

			helpers.stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("preserves horizontal carry after bonking a ceiling", function()
			local fixture = helpers.createFixture("BounceBonk")
			local ceiling = createCeiling("BounceBonk", 5.5)
			local app = helpers.createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(12, nil, helpers.createBounceConfig({
					groundBounceStrength = 8,
					carryRetentionPerBounce = 0.75,
					bigJumpCarryScale = 0.45,
					maxCarrySpeed = 45,
					carrySteerFactor = 0.2,
					minCarryBounceThreshold = 0.25,
				})),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.startSimulation()

			local ok, err = pcall(function()
				helpers.resetRootToGround(fixture.root)
				app.commands:send(pkg.JumpEvent.new(entity, 110))
				app:flush()

				local peakY = fixture.root.Position.Y
				local peakHorizontalSpeed = 0

				for _ = 1, 35 do
					helpers.runOneFrame(app)
					if fixture.root.Position.Y > peakY then
						peakY = fixture.root.Position.Y
					end
					local speed = helpers.horizontalSpeed(fixture.root)
					if speed > peakHorizontalSpeed then
						peakHorizontalSpeed = speed
					end
				end

				print(string.format(
					"[physics trace] carry-bonk peak-y=%.2f ceiling-y=%.2f peak-speed=%.2f",
					peakY,
					ceiling.Position.Y,
					peakHorizontalSpeed
				))
				expect(peakY < ceiling.Position.Y).to.equal(true)
				expect(peakHorizontalSpeed > 8).to.equal(true)
			end)

			helpers.stopSimulation()
			ceiling:Destroy()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)
	end)
end
