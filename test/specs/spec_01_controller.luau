return function(TS, t)
	local describe = t.describe
	local test = t.it
	local expect = t.expect

	local lib = TS.loadPath("out/init")
	local components = TS.loadPath("out/components")
	local events = TS.loadPath("out/events")

	describe("PhysicsController", function()
		test("uses sane default settings", function()
			local controller = components.PhysicsControllerConfig.new()
			expect(controller).never.toBeUndefined()
			expect(controller.walkSpeed).toBe(16)
			expect(controller.bounce.enabled).toBe(true)
		end)

		test("applies provided walk speed", function()
			local controller = components.PhysicsControllerConfig.new(24)
			expect(controller).never.toBeUndefined()
			expect(controller.walkSpeed).toBe(24)
		end)

		test("accepts optional air strafe config", function()
			local controller = components.PhysicsControllerConfig.new(24, {
				enabled = true,
				acceleration = 80,
				maxHorizontalSpeed = 32,
				fallSlowdown = {
					enabled = true,
					dragAcceleration = 18,
				},
			})
			expect(controller.airStrafe.enabled).toBe(true)
			expect(controller.airStrafe.acceleration).toBe(80)
			expect(controller.airStrafe.maxHorizontalSpeed).toBe(32)
			expect(controller.airStrafe.fallSlowdown.enabled).toBe(true)
			expect(controller.airStrafe.fallSlowdown.dragAcceleration).toBe(18)
		end)

		test("accepts bounce locomotion config", function()
			local controller = components.PhysicsControllerConfig.new(24, nil, {
				enabled = true,
				groundBounceStrength = 14,
				carryRetentionPerBounce = 0.9,
				bigJumpCarryScale = 0.4,
				maxCarrySpeed = 55,
				carrySteerFactor = 0.3,
				minCarryBounceThreshold = 1.5,
			})
			expect(controller.bounce.enabled).toBe(true)
			expect(controller.bounce.groundBounceStrength).toBe(14)
			expect(controller.bounce.carryRetentionPerBounce).toBe(0.9)
			expect(controller.bounce.bigJumpCarryScale).toBe(0.4)
			expect(controller.bounce.maxCarrySpeed).toBe(55)
			expect(controller.bounce.carrySteerFactor).toBe(0.3)
			expect(controller.bounce.minCarryBounceThreshold).toBe(1.5)
		end)

		test("constructs input and body-facing components", function()
			local input = components.PhysicsInput.new()
			expect(input).never.toBeUndefined()
			expect(input.facingDirection.Z).toBe(-1)
			expect(input.moveDirection.X).toBe(0)
		end)

		test("constructs air strafe intent defaults", function()
			local intent = components.AirStrafeIntent.new()
			expect(intent).never.toBeUndefined()
			expect(intent.direction.X).toBe(0)
			expect(intent.direction.Y).toBe(0)
			expect(intent.direction.Z).toBe(0)
			expect(intent.strength).toBe(1)
		end)

		test("constructs queued controller events", function()
			local jump = events.JumpEvent.new(7)
			local customJump = events.JumpEvent.new(8, 48)
			local impulse = events.ApplyImpulseEvent.new(7, {
				X = 0,
				Y = 4,
				Z = 8,
			})
			expect(jump.target).toBe(7)
			expect(jump.jumpPower).toBe(nil)
			expect(customJump.jumpPower).toBe(48)
			expect(impulse.impulse.Y).toBe(4)
			expect(impulse.impulse.Z).toBe(8)
		end)

		test("exports rovy schedule and set helpers", function()
			expect(lib.configurePhysicsController).never.toBeUndefined()
			expect(lib.PhysicsControllerUpdate).never.toBeUndefined()
			expect(lib.PhysicsRuntimeAttachSet).never.toBeUndefined()
			expect(lib.PhysicsRuntimeCleanupSet).never.toBeUndefined()
		end)
	end)
end
