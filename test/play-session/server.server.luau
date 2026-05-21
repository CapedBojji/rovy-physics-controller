local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PLAYTEST_FOLDER_NAME = "PhysicsControllerPlaytest"
local PLAYER_CUBES_FOLDER_NAME = "PlayerCubes"
local PLATFORM_FOLDER_NAME = "Platforms"
local CUBE_ATTRIBUTE_NAME = "PhysicsControllerCubeName"
local DEFAULT_JUMP_POWER = 320
local DEFAULT_AIR_STRAFE_ACCELERATION = 240
local DEFAULT_AIR_STRAFE_MAX_HORIZONTAL_SPEED = 120
local DEFAULT_AIR_FALL_DRAG_ACCELERATION = 180
local DEFAULT_GROUND_BOUNCE_STRENGTH = 18
local DEFAULT_CARRY_RETENTION_PER_BOUNCE = 0.92
local DEFAULT_BIG_JUMP_CARRY_SCALE = 0.45
local DEFAULT_MAX_CARRY_SPEED = 140
local DEFAULT_CARRY_STEER_FACTOR = 0.18
local DEFAULT_MIN_CARRY_BOUNCE_THRESHOLD = 1
local PLATFORM_COLOR = Color3.fromRGB(75, 75, 75)
local REMOTE_FOLDER_NAME = "PhysicsControllerPlaytestRemotes"
local RESPAWN_EVENT_NAME = "RespawnCube"
local PLAYTEST_ORIGIN = Vector3.new(1000, 0, 1000)

local function ensurePlatform(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3?
): Part
	local existing = parent:FindFirstChild(name)
	if existing ~= nil and existing:IsA("Part") then
		existing.Size = size
		existing.Position = position
		existing.Color = color or PLATFORM_COLOR
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Material = Enum.Material.Concrete
	part.Color = color or PLATFORM_COLOR
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function clearChildren(parent: Instance)
	for _, child in ipairs(parent:GetChildren()) do
		child:Destroy()
	end
end

local function atOrigin(offset: Vector3): Vector3
	return PLAYTEST_ORIGIN + offset
end

Players.CharacterAutoLoads = false

local rootFolder = Workspace:FindFirstChild(PLAYTEST_FOLDER_NAME)
if rootFolder == nil then
	rootFolder = Instance.new("Folder")
	rootFolder.Name = PLAYTEST_FOLDER_NAME
	rootFolder.Parent = Workspace
end

local cubesFolder = rootFolder:FindFirstChild(PLAYER_CUBES_FOLDER_NAME)
if cubesFolder == nil then
	cubesFolder = Instance.new("Folder")
	cubesFolder.Name = PLAYER_CUBES_FOLDER_NAME
	cubesFolder.Parent = rootFolder
end

local platformsFolder = rootFolder:FindFirstChild(PLATFORM_FOLDER_NAME)
if platformsFolder == nil then
	platformsFolder = Instance.new("Folder")
	platformsFolder.Name = PLATFORM_FOLDER_NAME
	platformsFolder.Parent = rootFolder
end

local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
if remotesFolder == nil then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTE_FOLDER_NAME
	remotesFolder.Parent = ReplicatedStorage
end

local respawnEvent = remotesFolder:FindFirstChild(RESPAWN_EVENT_NAME)
if respawnEvent == nil then
	respawnEvent = Instance.new("RemoteEvent")
	respawnEvent.Name = RESPAWN_EVENT_NAME
	respawnEvent.Parent = remotesFolder
end

clearChildren(platformsFolder)

ensurePlatform(platformsFolder, "Baseplate", Vector3.new(512, 1, 512), atOrigin(Vector3.new(0, 0, 0)))
ensurePlatform(platformsFolder, "CenterPad", Vector3.new(24, 1, 24), atOrigin(Vector3.new(0, 4, 0)), Color3.fromRGB(95, 95, 95))
ensurePlatform(platformsFolder, "NorthPad", Vector3.new(10, 1, 10), atOrigin(Vector3.new(0, 8, -22)), Color3.fromRGB(115, 115, 115))
ensurePlatform(platformsFolder, "SouthPad", Vector3.new(10, 1, 10), atOrigin(Vector3.new(0, 8, 22)), Color3.fromRGB(115, 115, 115))
ensurePlatform(platformsFolder, "EastPad", Vector3.new(10, 1, 10), atOrigin(Vector3.new(22, 8, 0)), Color3.fromRGB(115, 115, 115))
ensurePlatform(platformsFolder, "WestPad", Vector3.new(10, 1, 10), atOrigin(Vector3.new(-22, 8, 0)), Color3.fromRGB(115, 115, 115))
ensurePlatform(platformsFolder, "NorthEastHigh", Vector3.new(8, 1, 8), atOrigin(Vector3.new(18, 13, -18)), Color3.fromRGB(135, 135, 135))
ensurePlatform(platformsFolder, "NorthWestHigh", Vector3.new(8, 1, 8), atOrigin(Vector3.new(-18, 13, -18)), Color3.fromRGB(135, 135, 135))
ensurePlatform(platformsFolder, "SouthEastHigh", Vector3.new(8, 1, 8), atOrigin(Vector3.new(18, 13, 18)), Color3.fromRGB(135, 135, 135))
ensurePlatform(platformsFolder, "SouthWestHigh", Vector3.new(8, 1, 8), atOrigin(Vector3.new(-18, 13, 18)), Color3.fromRGB(135, 135, 135))
ensurePlatform(platformsFolder, "TopPerch", Vector3.new(12, 1, 12), atOrigin(Vector3.new(0, 19, 0)), Color3.fromRGB(155, 155, 155))

local function destroyCharacter(player: Player)
	if player.Character ~= nil then
		player.Character:Destroy()
	end
end

local function getSpawnPosition(index: number): Vector3
	return atOrigin(Vector3.new((index - 1) * 8, 6, 0))
end

local function respawnCubeForPlayer(player: Player)
	local cube = cubesFolder:FindFirstChild(tostring(player.UserId))
	if cube == nil or not cube:IsA("BasePart") then
		return
	end

	local playerCount = #Players:GetPlayers()
	cube.AssemblyLinearVelocity = Vector3.zero
	cube.AssemblyAngularVelocity = Vector3.zero
	cube.CFrame = CFrame.new(getSpawnPosition(playerCount))
end

local function createCubeForPlayer(player: Player)
	local existing = cubesFolder:FindFirstChild(tostring(player.UserId))
	if existing ~= nil then
		existing:Destroy()
	end

	local playerCount = #Players:GetPlayers()
	local cube = Instance.new("Part")
	cube.Name = tostring(player.UserId)
	cube.Shape = Enum.PartType.Block
	cube.Size = Vector3.new(4, 4, 4)
	cube.Position = getSpawnPosition(playerCount)
	cube.Color = Color3.fromRGB(255, 170, 0)
	cube.Material = Enum.Material.SmoothPlastic
	cube.TopSurface = Enum.SurfaceType.Smooth
	cube.BottomSurface = Enum.SurfaceType.Smooth
	cube.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
	cube.Parent = cubesFolder
	cube:SetNetworkOwner(player)

	local jumpPowerValue = Instance.new("NumberValue")
	jumpPowerValue.Name = "JumpPower"
	jumpPowerValue.Value = DEFAULT_JUMP_POWER
	jumpPowerValue.Parent = cube

	local airStrafeAccelerationValue = Instance.new("NumberValue")
	airStrafeAccelerationValue.Name = "AirStrafeAcceleration"
	airStrafeAccelerationValue.Value = DEFAULT_AIR_STRAFE_ACCELERATION
	airStrafeAccelerationValue.Parent = cube

	local airStrafeMaxHorizontalSpeedValue = Instance.new("NumberValue")
	airStrafeMaxHorizontalSpeedValue.Name = "AirStrafeMaxHorizontalSpeed"
	airStrafeMaxHorizontalSpeedValue.Value = DEFAULT_AIR_STRAFE_MAX_HORIZONTAL_SPEED
	airStrafeMaxHorizontalSpeedValue.Parent = cube

	local airFallDragAccelerationValue = Instance.new("NumberValue")
	airFallDragAccelerationValue.Name = "AirFallDragAcceleration"
	airFallDragAccelerationValue.Value = DEFAULT_AIR_FALL_DRAG_ACCELERATION
	airFallDragAccelerationValue.Parent = cube

	local groundBounceStrengthValue = Instance.new("NumberValue")
	groundBounceStrengthValue.Name = "GroundBounceStrength"
	groundBounceStrengthValue.Value = DEFAULT_GROUND_BOUNCE_STRENGTH
	groundBounceStrengthValue.Parent = cube

	local carryRetentionPerBounceValue = Instance.new("NumberValue")
	carryRetentionPerBounceValue.Name = "CarryRetentionPerBounce"
	carryRetentionPerBounceValue.Value = DEFAULT_CARRY_RETENTION_PER_BOUNCE
	carryRetentionPerBounceValue.Parent = cube

	local bigJumpCarryScaleValue = Instance.new("NumberValue")
	bigJumpCarryScaleValue.Name = "BigJumpCarryScale"
	bigJumpCarryScaleValue.Value = DEFAULT_BIG_JUMP_CARRY_SCALE
	bigJumpCarryScaleValue.Parent = cube

	local maxCarrySpeedValue = Instance.new("NumberValue")
	maxCarrySpeedValue.Name = "MaxCarrySpeed"
	maxCarrySpeedValue.Value = DEFAULT_MAX_CARRY_SPEED
	maxCarrySpeedValue.Parent = cube

	local carrySteerFactorValue = Instance.new("NumberValue")
	carrySteerFactorValue.Name = "CarrySteerFactor"
	carrySteerFactorValue.Value = DEFAULT_CARRY_STEER_FACTOR
	carrySteerFactorValue.Parent = cube

	local minCarryBounceThresholdValue = Instance.new("NumberValue")
	minCarryBounceThresholdValue.Name = "MinCarryBounceThreshold"
	minCarryBounceThresholdValue.Value = DEFAULT_MIN_CARRY_BOUNCE_THRESHOLD
	minCarryBounceThresholdValue.Parent = cube

	player:SetAttribute(CUBE_ATTRIBUTE_NAME, cube.Name)
	respawnCubeForPlayer(player)
end

local function cleanupPlayer(player: Player)
	local cube = cubesFolder:FindFirstChild(tostring(player.UserId))
	if cube ~= nil then
		cube:Destroy()
	end
	player:SetAttribute(CUBE_ATTRIBUTE_NAME, nil)
end

local function onPlayerAdded(player: Player)
	destroyCharacter(player)
	player.CharacterAdded:Connect(function()
		destroyCharacter(player)
	end)
	createCubeForPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(cleanupPlayer)
respawnEvent.OnServerEvent:Connect(function(player)
	respawnCubeForPlayer(player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
