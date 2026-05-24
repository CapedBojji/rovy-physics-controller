local ReplicatedStorage = script.Parent.Parent.Parent
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local resources = require(script.Parent.Parent:WaitForChild("resources"))
local tags = require(script.Parent.Parent:WaitForChild("tags"))
local util = require(script.Parent.Parent:WaitForChild("util"))

local Update = physicsControllerState.Update
local ClientPlaytestState = resources.ClientPlaytestState
local PlaytestCharacter = tags.PlaytestCharacter

local FollowPlaytestCharacterCamera = {}
FollowPlaytestCharacterCamera.__index = FollowPlaytestCharacterCamera

function FollowPlaytestCharacterCamera.new()
	return setmetatable({}, FollowPlaytestCharacterCamera)
end

function FollowPlaytestCharacterCamera:run(world, state)
	if state.character == nil then
		return
	end
	local characterEntity = world:getRef(state.character)
	if characterEntity == nil or not world:has(characterEntity, PlaytestCharacter) then
		return
	end
	local root = util.characterRoot(state.character)
	local camera = game:GetService("Workspace").CurrentCamera
	if root == nil or camera == nil then
		return
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = root
end

local function register(rovy, plugin)
	rovy:__system(FollowPlaytestCharacterCamera, {
		id = "playtest/systems/follow-playtest-character-camera@FollowPlaytestCharacterCamera",
		plugin = plugin,
		schedule = Update,
		after = {},
		before = {},
		params = {
			{ kind = "world" },
			{ kind = "res", ctor = ClientPlaytestState },
		},
	})
end

return {
	FollowPlaytestCharacterCamera = FollowPlaytestCharacterCamera,
	register = register,
}
