local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CUBE_FOLDER_NAME = "PhysicsControllerPlaytestCubes"
local CUBE_ATTRIBUTE_NAME = "PhysicsControllerPlaytestCube"
local SPAWN_HEIGHT = 6
local SPAWN_SPACING = 10

Players.CharacterAutoLoads = false

local cubesFolder = Workspace:FindFirstChild(CUBE_FOLDER_NAME)
if cubesFolder == nil then
	cubesFolder = Instance.new("Folder")
	cubesFolder.Name = CUBE_FOLDER_NAME
	cubesFolder.Parent = Workspace
end

local function getSpawnPosition(index: number): Vector3
	return Vector3.new((index - 1) * SPAWN_SPACING, SPAWN_HEIGHT, 0)
end

local function destroyCharacter(player: Player)
	if player.Character ~= nil then
		player.Character:Destroy()
	end
end

local function createCube(player: Player)
	local existing = cubesFolder:FindFirstChild(tostring(player.UserId))
	if existing ~= nil then
		existing:Destroy()
	end

	local cube = Instance.new("Part")
	cube.Name = tostring(player.UserId)
	cube.Shape = Enum.PartType.Block
	cube.Size = Vector3.new(4, 4, 4)
	cube.Position = getSpawnPosition(#Players:GetPlayers())
	cube.Color = Color3.fromRGB(255, 170, 0)
	cube.Material = Enum.Material.SmoothPlastic
	cube.TopSurface = Enum.SurfaceType.Smooth
	cube.BottomSurface = Enum.SurfaceType.Smooth
	cube.Parent = cubesFolder
	cube:SetNetworkOwner(player)

	player:SetAttribute(CUBE_ATTRIBUTE_NAME, cube.Name)
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
	createCube(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(cleanupPlayer)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
