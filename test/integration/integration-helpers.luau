local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local pkg = require(ReplicatedStorage:WaitForChild("PhysicsController", 10))
local App = pkg.App

local function createFixture(name)
	local floor = Instance.new("Part")
	floor.Name = name .. "_Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(256, 1, 256)
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

local function setPhysicsDt(app, dt)
	local time = app.world:resource(pkg.PhysicsControllerTime)
	time.lastClock = os.clock() - dt
end

local function createBounceConfig(overrides)
	local config = {
		enabled = true,
		groundBounceStrength = 12,
		carryRetentionPerBounce = 0.82,
		bigJumpCarryScale = 0.25,
		maxCarrySpeed = 28,
		carrySteerFactor = 0.2,
		minCarryBounceThreshold = 0.5,
	}

	if overrides ~= nil then
		for key, value in pairs(overrides) do
			config[key] = value
		end
	end

	return config
end

local function createDisabledBounceConfig()
	return createBounceConfig({
		enabled = false,
	})
end

local function runOneFrame(app)
	app:runSchedule(pkg.PhysicsControllerUpdate)
	RunService.Heartbeat:Wait()
end

local function resetRootToGround(root)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = CFrame.new(root.Position.X, 2.49, root.Position.Z)
end

local function sendGroundedJump(app, entity, root, jumpPower)
	resetRootToGround(root)
	app.commands:send(pkg.JumpEvent.new(entity, jumpPower))
	app:flush()
	runOneFrame(app)
	return root.AssemblyLinearVelocity.Y > 0.5
end

local function triggerJumpOnLandingWindow(app, entity, root, jumpPower)
	for _ = 1, 180 do
		local velocity = root.AssemblyLinearVelocity
		if root.Position.Y <= 2.8 and velocity.Y <= 0 then
			return sendGroundedJump(app, entity, root, jumpPower)
		end
		runOneFrame(app)
	end

	return false
end

return {
	pkg = pkg,
	createFixture = createFixture,
	startSimulation = startSimulation,
	stopSimulation = stopSimulation,
	createControllerApp = createControllerApp,
	runFrames = runFrames,
	horizontalSpeed = horizontalSpeed,
	setPhysicsDt = setPhysicsDt,
	createBounceConfig = createBounceConfig,
	createDisabledBounceConfig = createDisabledBounceConfig,
	runOneFrame = runOneFrame,
	resetRootToGround = resetRootToGround,
	sendGroundedJump = sendGroundedJump,
	triggerJumpOnLandingWindow = triggerJumpOnLandingWindow,
}
