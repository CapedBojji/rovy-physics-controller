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
		end)

		test("applies provided walk speed", function()
			local controller = components.PhysicsControllerConfig.new(24)
			expect(controller).never.toBeUndefined()
			expect(controller.walkSpeed).toBe(24)
		end)

		test("constructs input and body-facing components", function()
			local input = components.PhysicsInput.new()
			expect(input).never.toBeUndefined()
			expect(input.facingDirection.Z).toBe(-1)
			expect(input.moveDirection.X).toBe(0)
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
