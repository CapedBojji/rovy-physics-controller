local ReplicatedStorage = script.Parent.Parent.Parent
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local physicsControllerComponents = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("components"))
local collects = require(script.Parent.Parent:WaitForChild("collects"))
local resources = require(script.Parent.Parent:WaitForChild("resources"))

local Update = physicsControllerState.Update
local PhysicsInput = physicsControllerComponents.PhysicsInput
local LocalPlaytestCollect = collects.LocalPlaytestCollect
local ClientPlaytestState = resources.ClientPlaytestState

local CollectCharacterPhysicsInput = {}
CollectCharacterPhysicsInput.__index = CollectCharacterPhysicsInput

function CollectCharacterPhysicsInput.new()
	return setmetatable({}, CollectCharacterPhysicsInput)
end

function CollectCharacterPhysicsInput:run(input, world, commands, state)
	if state.character == nil then
		return
	end
	local characterEntity = world:getRef(state.character)
	if characterEntity == nil or not world:has(characterEntity, PhysicsInput) then
		return
	end
	local facingDirection, movingDirection = input:readMoveDirection()
	commands:set(characterEntity, PhysicsInput, PhysicsInput.new(facingDirection, movingDirection))
end

local function register(rovy, plugin)
	rovy:__system(CollectCharacterPhysicsInput, {
		id = "playtest/systems/collect-character-physics-input@CollectCharacterPhysicsInput",
		plugin = plugin,
		schedule = Update,
		after = {},
		before = {},
		params = {
			{ kind = "collect", ctor = LocalPlaytestCollect },
			{ kind = "world" },
			{ kind = "commands" },
			{ kind = "res", ctor = ClientPlaytestState },
		},
	})
end

return {
	CollectCharacterPhysicsInput = CollectCharacterPhysicsInput,
	register = register,
}
