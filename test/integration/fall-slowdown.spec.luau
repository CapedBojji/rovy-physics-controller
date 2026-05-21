local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController fall slowdown", function()
		it("slows falling without changing horizontal velocity or causing lift", function()
			local disabledFixture = helpers.createFixture("FallSlowDisabled")
			local disabledApp = helpers.createControllerApp()
			disabledFixture.root.Position = Vector3.new(0, 20, 0)
			disabledFixture.root.AssemblyLinearVelocity = Vector3.new(7, -12, -4)

			disabledApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 0,
					maxHorizontalSpeed = 100,
				}, helpers.createDisabledBounceConfig()),
				pkg.PhysicsBody.new(disabledFixture.root)
			)

			helpers.setPhysicsDt(disabledApp, 1)
			disabledApp:runSchedule(pkg.PhysicsControllerUpdate)
			expect(disabledFixture.root.AssemblyLinearVelocity.X).to.equal(7)
			expect(disabledFixture.root.AssemblyLinearVelocity.Y).to.equal(-12)
			expect(disabledFixture.root.AssemblyLinearVelocity.Z).to.equal(-4)
			disabledFixture.destroy()

			local fallingFixture = helpers.createFixture("FallSlowAir")
			local fallingApp = helpers.createControllerApp()
			fallingFixture.root.Position = Vector3.new(0, 20, 0)
			fallingFixture.root.AssemblyLinearVelocity = Vector3.new(7, -12, -4)

			local fallingEntity = fallingApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 0,
					maxHorizontalSpeed = 100,
					fallSlowdown = {
						enabled = true,
						dragAcceleration = 5,
					},
				}, helpers.createDisabledBounceConfig()),
				pkg.PhysicsBody.new(fallingFixture.root)
			)

			helpers.setPhysicsDt(fallingApp, 1)
			fallingApp:runSchedule(pkg.PhysicsControllerUpdate)
			local fallingVelocity = fallingFixture.root.AssemblyLinearVelocity
			expect(fallingApp.world:has(fallingEntity, pkg.Airborne)).to.equal(true)
			expect(math.abs(fallingVelocity.X - 7) < 0.001).to.equal(true)
			expect(math.abs(fallingVelocity.Z + 4) < 0.001).to.equal(true)
			expect(fallingVelocity.Y > -12).to.equal(true)
			expect(fallingVelocity.Y <= 0).to.equal(true)
			print(string.format(
				"[physics trace] fall-slow y-before=%.2f y-after=%.2f x=%.2f z=%.2f",
				-12,
				fallingVelocity.Y,
				fallingVelocity.X,
				fallingVelocity.Z
			))
			expect(fallingVelocity.Y > -12).to.equal(true)
			fallingFixture.destroy()

			local risingFixture = helpers.createFixture("FallSlowRise")
			local risingApp = helpers.createControllerApp()
			risingFixture.root.Position = Vector3.new(0, 20, 0)
			risingFixture.root.AssemblyLinearVelocity = Vector3.new(7, 9, -4)

			risingApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 0,
					maxHorizontalSpeed = 100,
					fallSlowdown = {
						enabled = true,
						dragAcceleration = 50,
					},
				}, helpers.createDisabledBounceConfig()),
				pkg.PhysicsBody.new(risingFixture.root)
			)

			helpers.setPhysicsDt(risingApp, 1)
			risingApp:runSchedule(pkg.PhysicsControllerUpdate)
			local risingVelocity = risingFixture.root.AssemblyLinearVelocity
			expect(math.abs(risingVelocity.X - 7) < 0.001).to.equal(true)
			expect(math.abs(risingVelocity.Y - 9) < 0.001).to.equal(true)
			expect(math.abs(risingVelocity.Z + 4) < 0.001).to.equal(true)
			risingFixture.destroy()

			local groundedFixture = helpers.createFixture("FallSlowGround")
			local groundedApp = helpers.createControllerApp()
			groundedFixture.root.AssemblyLinearVelocity = Vector3.new(7, -12, -4)

			groundedApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 0,
					maxHorizontalSpeed = 100,
					fallSlowdown = {
						enabled = true,
						dragAcceleration = 5,
					},
				}, helpers.createDisabledBounceConfig()),
				pkg.PhysicsBody.new(groundedFixture.root)
			)

			helpers.setPhysicsDt(groundedApp, 1)
			groundedApp:runSchedule(pkg.PhysicsControllerUpdate)
			local groundedVelocity = groundedFixture.root.AssemblyLinearVelocity
			expect(math.abs(groundedVelocity.X - 7) < 0.001).to.equal(true)
			expect(math.abs(groundedVelocity.Y + 12) < 0.001).to.equal(true)
			expect(math.abs(groundedVelocity.Z + 4) < 0.001).to.equal(true)
			groundedFixture.destroy()

			local clampFixture = helpers.createFixture("FallSlowClamp")
			local clampApp = helpers.createControllerApp()
			clampFixture.root.Position = Vector3.new(0, 20, 0)
			clampFixture.root.AssemblyLinearVelocity = Vector3.new(1, -2, 3)

			clampApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 0,
					maxHorizontalSpeed = 100,
					fallSlowdown = {
						enabled = true,
						dragAcceleration = 9,
					},
				}, helpers.createDisabledBounceConfig()),
				pkg.PhysicsBody.new(clampFixture.root)
			)

			helpers.setPhysicsDt(clampApp, 1)
			clampApp:runSchedule(pkg.PhysicsControllerUpdate)
			local clampVelocity = clampFixture.root.AssemblyLinearVelocity
			expect(math.abs(clampVelocity.X - 1) < 0.001).to.equal(true)
			expect(math.abs(clampVelocity.Z - 3) < 0.001).to.equal(true)
			expect(math.abs(clampVelocity.Y) < 0.001).to.equal(true)
			clampFixture.destroy()
		end)
	end)
end
