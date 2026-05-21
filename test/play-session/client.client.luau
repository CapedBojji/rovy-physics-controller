local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local PLAYTEST_FOLDER_NAME = "PhysicsControllerPlaytest"
local PLAYER_CUBES_FOLDER_NAME = "PlayerCubes"
local CUBE_ATTRIBUTE_NAME = "PhysicsControllerCubeName"
local TRACE_EVERY_N_FRAMES = 30
local REMOTE_FOLDER_NAME = "PhysicsControllerPlaytestRemotes"
local RESPAWN_EVENT_NAME = "RespawnCube"
local RESPAWN_FALL_Y = -20

local pkg = require(ReplicatedStorage:WaitForChild("PhysicsController"))
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local respawnEvent = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME):WaitForChild(RESPAWN_EVENT_NAME)

local function flattenOrFallback(vector: Vector3, fallback: Vector3): Vector3
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude <= 1e-4 then
		return fallback
	end
	return flat.Unit
end

local function resolveCube(): BasePart
	local rootFolder = Workspace:WaitForChild(PLAYTEST_FOLDER_NAME)
	local cubesFolder = rootFolder:WaitForChild(PLAYER_CUBES_FOLDER_NAME)
	local cubeName = player:GetAttribute(CUBE_ATTRIBUTE_NAME)
	while cubeName == nil do
		player:GetAttributeChangedSignal(CUBE_ATTRIBUTE_NAME):Wait()
		cubeName = player:GetAttribute(CUBE_ATTRIBUTE_NAME)
	end
	return cubesFolder:WaitForChild(cubeName)
end

local function readJumpPower(rootPart: BasePart): number?
	local jumpPowerValue = rootPart:FindFirstChild("JumpPower")
	if jumpPowerValue ~= nil and jumpPowerValue:IsA("NumberValue") then
		return jumpPowerValue.Value
	end
	return nil
end

local function readNumberValue(rootPart: BasePart, name: string, fallback: number): number
	local value = rootPart:FindFirstChild(name)
	if value ~= nil and value:IsA("NumberValue") then
		return value.Value
	end
	return fallback
end

local function resetControllerState(app, entity, input, airStrafeIntent, rootPart)
	input.moveDirection = Vector3.zero
	input.facingDirection = flattenOrFallback(camera.CFrame.LookVector, Vector3.zAxis * -1)
	airStrafeIntent.direction = Vector3.zero
	airStrafeIntent.strength = 0
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local store = app.world:resource(pkg.PhysicsRuntimeStore)
	local runtime = store.entries[entity]
	if runtime ~= nil then
		runtime.carryVelocity = Vector3.zero
		runtime.lastMoveDirection = Vector3.zero
		runtime.lastFacingDirection = input.facingDirection
		runtime.lastAppliedImpulse = Vector3.zero
		runtime.lastJumpImpulse = Vector3.zero
		runtime.airborneSinceLastBounce = true
		runtime.wasGroundedLastFrame = false
	end
end

local function buildMoveDirection(): Vector3
	local moveX = 0
	local moveZ = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		moveX -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		moveX += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		moveZ -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		moveZ += 1
	end

	local raw = Vector3.new(moveX, 0, moveZ)
	if raw.Magnitude <= 1e-4 then
		return Vector3.zero
	end

	local look = flattenOrFallback(camera.CFrame.LookVector, Vector3.zAxis * -1)
	local right = flattenOrFallback(camera.CFrame.RightVector, Vector3.xAxis)
	local worldMove = right * raw.X - look * raw.Z
	if worldMove.Magnitude <= 1e-4 then
		return Vector3.zero
	end
	return worldMove.Unit
end

local rootPart = resolveCube()
camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = rootPart

local app = pkg.App.new()
pkg.configurePhysicsController(app)
app:start()

local input = pkg.PhysicsInput.new()
local airStrafeIntent = pkg.AirStrafeIntent.new()
local config = pkg.PhysicsControllerConfig.new(22, {
	enabled = true,
	acceleration = 240,
	maxHorizontalSpeed = 120,
	fallSlowdown = {
		enabled = true,
		dragAcceleration = 180,
	},
}, {
	enabled = true,
	groundBounceStrength = 18,
	carryRetentionPerBounce = 0.92,
	bigJumpCarryScale = 0.45,
	maxCarrySpeed = 140,
	carrySteerFactor = 0.18,
	minCarryBounceThreshold = 1,
})
local entity = app.world:spawn(
	config,
	input,
	airStrafeIntent,
	pkg.PhysicsBody.new(rootPart)
)

local jumpQueued = false
local respawnQueued = false
local frame = 0

UserInputService.InputBegan:Connect(function(inputObject, processed)
	if processed then
		return
	end
	if inputObject.KeyCode == Enum.KeyCode.Space then
		jumpQueued = true
	elseif inputObject.KeyCode == Enum.KeyCode.R then
		respawnQueued = true
	end
end)

RunService.RenderStepped:Connect(function()
	local moveDirection = buildMoveDirection()
	local lookFallback = flattenOrFallback(camera.CFrame.LookVector, Vector3.zAxis * -1)

	input.moveDirection = moveDirection
	input.facingDirection = if moveDirection.Magnitude > 1e-4 then moveDirection else lookFallback
	config.airStrafe.acceleration = readNumberValue(rootPart, "AirStrafeAcceleration", 240)
	config.airStrafe.maxHorizontalSpeed = readNumberValue(rootPart, "AirStrafeMaxHorizontalSpeed", 120)
	config.airStrafe.fallSlowdown.dragAcceleration = readNumberValue(rootPart, "AirFallDragAcceleration", 180)
	config.bounce.groundBounceStrength = readNumberValue(rootPart, "GroundBounceStrength", 18)
	config.bounce.carryRetentionPerBounce = readNumberValue(rootPart, "CarryRetentionPerBounce", 0.92)
	config.bounce.bigJumpCarryScale = readNumberValue(rootPart, "BigJumpCarryScale", 0.45)
	config.bounce.maxCarrySpeed = readNumberValue(rootPart, "MaxCarrySpeed", 140)
	config.bounce.carrySteerFactor = readNumberValue(rootPart, "CarrySteerFactor", 0.18)
	config.bounce.minCarryBounceThreshold = readNumberValue(rootPart, "MinCarryBounceThreshold", 1)
	airStrafeIntent.direction = moveDirection
	airStrafeIntent.strength = if moveDirection.Magnitude > 1e-4 then 1 else 0

	if jumpQueued then
		app.commands:send(pkg.JumpEvent.new(entity, readJumpPower(rootPart)))
		jumpQueued = false
	end

	if rootPart.Position.Y < RESPAWN_FALL_Y then
		respawnQueued = true
	end

	if respawnQueued then
		resetControllerState(app, entity, input, airStrafeIntent, rootPart)
		jumpQueued = false
		respawnEvent:FireServer()
		respawnQueued = false
	end

	app:runSchedule(pkg.PhysicsControllerUpdate)
	frame += 1

	if frame % TRACE_EVERY_N_FRAMES == 0 then
		local grounded = app.world:has(entity, pkg.Grounded)
		local position = rootPart.Position
		local velocity = rootPart.AssemblyLinearVelocity
		print(string.format(
			"[playtest trace] f=%d pos=(%.2f,%.2f,%.2f) vel=(%.2f,%.2f,%.2f) grounded=%s",
			frame,
			position.X,
			position.Y,
			position.Z,
			velocity.X,
			velocity.Y,
			velocity.Z,
			tostring(grounded)
		))
	end
end)
