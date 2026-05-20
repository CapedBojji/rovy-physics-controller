local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PLAYTEST_FOLDER_NAME = "PhysicsControllerPlaytest"
local PLAYER_CUBES_FOLDER_NAME = "PlayerCubes"
local CUBE_ATTRIBUTE_NAME = "PhysicsControllerCubeName"
local DEFAULT_JUMP_POWER = 32
local PLATFORM_COLOR = Color3.fromRGB(75, 75, 75)
local REMOTE_FOLDER_NAME = "PhysicsControllerPlaytestRemotes"
local RESPAWN_EVENT_NAME = "RespawnCube"

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

ensurePlatform(rootFolder, "StartPlatform", Vector3.new(32, 1, 32), Vector3.new(0, 0, 0))
ensurePlatform(rootFolder, "GapRunA", Vector3.new(18, 1, 18), Vector3.new(28, 0, 0))
ensurePlatform(rootFolder, "GapRunB", Vector3.new(18, 1, 18), Vector3.new(52, 0, 0))
ensurePlatform(rootFolder, "RaisedStepA", Vector3.new(16, 1, 16), Vector3.new(74, 3, 0), Color3.fromRGB(100, 100, 100))
ensurePlatform(rootFolder, "RaisedStepB", Vector3.new(16, 1, 16), Vector3.new(94, 6, 0), Color3.fromRGB(120, 120, 120))
ensurePlatform(rootFolder, "MomentumLanding", Vector3.new(24, 1, 24), Vector3.new(122, 6, 0), Color3.fromRGB(90, 110, 90))
ensurePlatform(rootFolder, "LateralGapLeft", Vector3.new(14, 1, 14), Vector3.new(122, 6, -22), Color3.fromRGB(110, 90, 90))
ensurePlatform(rootFolder, "LateralGapRight", Vector3.new(14, 1, 14), Vector3.new(122, 6, 22), Color3.fromRGB(90, 90, 110))
ensurePlatform(rootFolder, "HighPerch", Vector3.new(12, 1, 12), Vector3.new(150, 10, 0), Color3.fromRGB(130, 130, 130))
ensurePlatform(rootFolder, "DropCatch", Vector3.new(18, 1, 18), Vector3.new(176, 4, 0), Color3.fromRGB(80, 100, 120))

local function destroyCharacter(player: Player)
	if player.Character ~= nil then
		player.Character:Destroy()
	end
end

local function getSpawnPosition(index: number): Vector3
	return Vector3.new((index - 1) * 8, 6, 0)
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
