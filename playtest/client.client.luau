local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CUBE_FOLDER_NAME = "PhysicsControllerPlaytestCubes"
local CUBE_ATTRIBUTE_NAME = "PhysicsControllerPlaytestCube"

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local cubesFolder = Workspace:WaitForChild(CUBE_FOLDER_NAME)

local function resolveCube(): BasePart
	local cubeName = player:GetAttribute(CUBE_ATTRIBUTE_NAME)
	while cubeName == nil do
		player:GetAttributeChangedSignal(CUBE_ATTRIBUTE_NAME):Wait()
		cubeName = player:GetAttribute(CUBE_ATTRIBUTE_NAME)
	end
	return cubesFolder:WaitForChild(cubeName)
end

local cube = resolveCube()
camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = cube
