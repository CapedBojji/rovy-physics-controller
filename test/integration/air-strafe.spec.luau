local helpers = require(script.Parent["integration-helpers"])
local pkg = helpers.pkg

return function()
	describe("PhysicsController air strafe", function()
		it("applies air strafe only while airborne", function()
			local fixture = helpers.createFixture("AirStrafe")
			local app = helpers.createControllerApp()
			fixture.root.Position = Vector3.new(0, 20, 0)
			fixture.root.AssemblyLinearVelocity = Vector3.new(2, 17, 0)

			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 10,
					maxHorizontalSpeed = 100,
				}, helpers.createDisabledBounceConfig()),
				pkg.AirStrafeIntent.new(Vector3.new(1, 99, 0), 1),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.setPhysicsDt(app, 1)
			app:runSchedule(pkg.PhysicsControllerUpdate)

			local velocity = fixture.root.AssemblyLinearVelocity
			expect(app.world:has(entity, pkg.Airborne)).to.equal(true)
			expect(velocity.X > 11).to.equal(true)
			expect(math.abs(velocity.Y - 17) < 0.001).to.equal(true)
			expect(math.abs(velocity.Z) < 0.001).to.equal(true)

			fixture.destroy()
		end)

		it("does not air strafe when disabled or grounded", function()
			local defaultDisabled = helpers.createFixture("AirStrafeDefaultDisabled")
			local defaultApp = helpers.createControllerApp()
			defaultDisabled.root.Position = Vector3.new(0, 20, 0)
			defaultDisabled.root.AssemblyLinearVelocity = Vector3.new(3, 12, 4)
			defaultApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, nil, helpers.createDisabledBounceConfig()),
				pkg.AirStrafeIntent.new(Vector3.new(1, 0, 0), 1),
				pkg.PhysicsBody.new(defaultDisabled.root)
			)
			helpers.setPhysicsDt(defaultApp, 1)
			defaultApp:runSchedule(pkg.PhysicsControllerUpdate)
			expect(defaultDisabled.root.AssemblyLinearVelocity.X).to.equal(3)
			expect(defaultDisabled.root.AssemblyLinearVelocity.Y).to.equal(12)
			expect(defaultDisabled.root.AssemblyLinearVelocity.Z).to.equal(4)
			defaultDisabled.destroy()

			local disabled = helpers.createFixture("AirStrafeDisabled")
			local disabledApp = helpers.createControllerApp()
			disabled.root.Position = Vector3.new(0, 20, 0)
			disabled.root.AssemblyLinearVelocity = Vector3.new(3, 12, 4)
			disabledApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = false,
					acceleration = 50,
					maxHorizontalSpeed = 100,
				}, helpers.createDisabledBounceConfig()),
				pkg.AirStrafeIntent.new(Vector3.new(1, 0, 0), 1),
				pkg.PhysicsBody.new(disabled.root)
			)
			helpers.setPhysicsDt(disabledApp, 1)
			disabledApp:runSchedule(pkg.PhysicsControllerUpdate)
			expect(disabled.root.AssemblyLinearVelocity.X).to.equal(3)
			expect(disabled.root.AssemblyLinearVelocity.Y).to.equal(12)
			expect(disabled.root.AssemblyLinearVelocity.Z).to.equal(4)
			disabled.destroy()

			local grounded = helpers.createFixture("AirStrafeGrounded")
			local groundedApp = helpers.createControllerApp()
			grounded.root.AssemblyLinearVelocity = Vector3.new(3, 0, 4)
			groundedApp.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 50,
					maxHorizontalSpeed = 100,
				}, helpers.createDisabledBounceConfig()),
				pkg.AirStrafeIntent.new(Vector3.new(1, 0, 0), 1),
				pkg.PhysicsBody.new(grounded.root)
			)
			helpers.setPhysicsDt(groundedApp, 1)
			groundedApp:runSchedule(pkg.PhysicsControllerUpdate)
			expect(grounded.root.AssemblyLinearVelocity.X).to.equal(3)
			expect(grounded.root.AssemblyLinearVelocity.Y).to.equal(0)
			expect(grounded.root.AssemblyLinearVelocity.Z).to.equal(4)
			grounded.destroy()
		end)

		it("clamps air strafe strength and horizontal speed", function()
			local fixture = helpers.createFixture("AirStrafeClamp")
			local app = helpers.createControllerApp()
			fixture.root.Position = Vector3.new(0, 20, 0)
			fixture.root.AssemblyLinearVelocity = Vector3.new(9, -6, 0)

			app.world:spawn(
				pkg.PhysicsControllerConfig.new(0, {
					enabled = true,
					acceleration = 50,
					maxHorizontalSpeed = 10,
				}, helpers.createDisabledBounceConfig()),
				pkg.AirStrafeIntent.new(Vector3.new(1, 0, 0), 5),
				pkg.PhysicsBody.new(fixture.root)
			)

			helpers.setPhysicsDt(app, 1)
			app:runSchedule(pkg.PhysicsControllerUpdate)

			local velocity = fixture.root.AssemblyLinearVelocity
			expect(math.abs(helpers.horizontalSpeed(fixture.root) - 10) < 0.001).to.equal(true)
			expect(math.abs(velocity.Y + 6) < 0.001).to.equal(true)

			fixture.destroy()
		end)
	end)
end
