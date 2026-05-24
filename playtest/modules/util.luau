local CUBE_FOLDER_NAME = "PhysicsControllerPlaytestCubes"
local SPAWN_HEIGHT = 6
local SPAWN_SPACING = 10

local function characterRoot(character)
	local root = character.PrimaryPart or character:FindFirstChild("RootPart")
	if root ~= nil and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function cubesFolder()
	local Workspace = game:GetService("Workspace")
	local folder = Workspace:FindFirstChild(CUBE_FOLDER_NAME)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = CUBE_FOLDER_NAME
		folder.Parent = Workspace
	end
	return folder
end

local function spawnPosition(index)
	return Vector3.new((index - 1) * SPAWN_SPACING, SPAWN_HEIGHT, 0)
end

local function destroyCharacter(player)
	if player.Character ~= nil then
		player.Character:Destroy()
	end
end

local function cleanupCube(player)
	local existing = cubesFolder():FindFirstChild(tostring(player.UserId))
	if existing ~= nil then
		existing:Destroy()
	end
end

local function spawnCube(player)
	local Players = game:GetService("Players")
	destroyCharacter(player)
	cleanupCube(player)

	local cubeModel = Instance.new("Model")
	cubeModel.Name = tostring(player.UserId)
	cubeModel.Parent = cubesFolder()

	local cube = Instance.new("Part")
	cube.Name = "RootPart"
	cube.Shape = Enum.PartType.Block
	cube.Size = Vector3.new(4, 4, 4)
	cube.Position = spawnPosition(#Players:GetPlayers())
	cube.Color = Color3.fromRGB(255, 170, 0)
	cube.Material = Enum.Material.SmoothPlastic
	cube.TopSurface = Enum.SurfaceType.Smooth
	cube.BottomSurface = Enum.SurfaceType.Smooth
	cube.Parent = cubeModel
	cube:SetNetworkOwner(player)
	cubeModel.PrimaryPart = cube

	player.Character = cubeModel
end

return {
	characterRoot = characterRoot,
	cleanupCube = cleanupCube,
	cubesFolder = cubesFolder,
	spawnCube = spawnCube,
}
