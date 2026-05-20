local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local pkg = require(ReplicatedStorage:WaitForChild("PhysicsController", 10))

local App = pkg.App

local function createFixture(name)
	local floor = Instance.new("Part")
	floor.Name = name .. "_Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(32, 1, 32)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Parent = Workspace

	local model = Instance.new("Model")
	model.Name = name .. "_Model"
	model.Parent = Workspace

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 2)
	root.Position = Vector3.new(0, 3, 0)
	root.Parent = model
	model.PrimaryPart = root

	return {
		model = model,
		root = root,
		floor = floor,
		destroy = function()
			model:Destroy()
			floor:Destroy()
		end,
	}
end

local function round2(value)
	return math.round(value * 100) / 100
end

local function printCompactTrace(label, frame, root, grounded)
	local position = root.Position
	local velocity = root.AssemblyLinearVelocity
	print(string.format(
		"[physics trace] %s f=%d pos=(%.2f,%.2f,%.2f) vel=(%.2f,%.2f,%.2f) grounded=%s",
		label,
		frame,
		round2(position.X),
		round2(position.Y),
		round2(position.Z),
		round2(velocity.X),
		round2(velocity.Y),
		round2(velocity.Z),
		tostring(grounded)
	))
end

local function startSimulation()
	if RunService:IsEdit() then
		RunService:Run()
		RunService.Heartbeat:Wait()
	end
end

local function stopSimulation()
	if not RunService:IsEdit() then
		RunService:Stop()
	end
end

local function createControllerApp()
	local app = App.new()
	pkg.configurePhysicsController(app)
	app:start()
	return app
end

local function runFrames(app, entity, root, totalFrames, label)
	local peakY = root.Position.Y
	for frame = 1, totalFrames do
		app:runSchedule(pkg.PhysicsControllerUpdate)
		RunService.Heartbeat:Wait()
		local currentY = root.Position.Y
		if currentY > peakY then
			peakY = currentY
		end
		if frame % 10 == 0 then
			printCompactTrace(label, frame, root, app.world:has(entity, pkg.Grounded))
		end
	end
	return peakY, root.Position
end

local function horizontalSpeed(root)
	local velocity = root.AssemblyLinearVelocity
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

return function()
	describe("PhysicsController", function()
		it("registers rovy-decorated controller runtime and tags", function()
			local fixture = createFixture("Attach")
			local app = createControllerApp()

			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(20),
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

		it("moves under physics and drains queued controller events", function()
			local fixture = createFixture("Trace")
			local app = createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(22),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)
			local startPosition = fixture.root.Position

			startSimulation()

			local ok, err = pcall(function()
				app.commands:send(pkg.JumpEvent.new(entity, 40))
				app:flush()
				local peakY, jumpPosition = runFrames(app, entity, fixture.root, 30, "jump")
				expect(peakY > startPosition.Y + 0.1).to.equal(true)

				app.commands:send(pkg.ApplyImpulseEvent.new(entity, Vector3.new(0, 0, -120)))
				app:flush()
				local _, impulsePosition = runFrames(app, entity, fixture.root, 30, "impulse")
				expect(impulsePosition.Z < jumpPosition.Z - 0.1).to.equal(true)
			end)

			stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("keeps horizontal momentum through jump", function()
			local fixture = createFixture("Momentum")
			local app = createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(22),
				pkg.PhysicsInput.new(Vector3.new(0, 0, -1), Vector3.new(0, 0, -1)),
				pkg.PhysicsBody.new(fixture.root)
			)

			startSimulation()

			local ok, err = pcall(function()
				runFrames(app, entity, fixture.root, 10, "momentum-ground")
				local groundedSpeed = horizontalSpeed(fixture.root)
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
						local speed = horizontalSpeed(fixture.root)
						if speed > maxAirborneHorizontalSpeed then
							maxAirborneHorizontalSpeed = speed
						end
					end

					if frame % 10 == 0 then
						printCompactTrace("momentum-air", frame, fixture.root, app.world:has(entity, pkg.Grounded))
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

			stopSimulation()
			fixture.destroy()
			if not ok then
				error(err)
			end
		end)

		it("cleans runtime when entity is gone", function()
			local fixture = createFixture("Cleanup")
			local app = createControllerApp()
			local entity = app.world:spawn(
				pkg.PhysicsControllerConfig.new(16),
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
