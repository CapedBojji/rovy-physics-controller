local ReplicatedStorage = script.Parent.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local physicsControllerComponents = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("components"))
local collects = require(script.Parent.Parent:WaitForChild("collects"))
local events = require(script.Parent.Parent:WaitForChild("events"))
local resources = require(script.Parent.Parent:WaitForChild("resources"))
local tags = require(script.Parent.Parent:WaitForChild("tags"))
local util = require(script.Parent.Parent:WaitForChild("util"))

local ChildOf = core.ChildOf
local Update = physicsControllerState.Update
local RigidBody = physicsControllerComponents.RigidBody
local PhysicsInput = physicsControllerComponents.PhysicsInput
local LocalPlaytestCollect = collects.LocalPlaytestCollect
local TogglePlaytestInspector = events.TogglePlaytestInspector
local ClientPlaytestState = resources.ClientPlaytestState
local PlaytestPlayer = tags.PlaytestPlayer
local PlaytestCharacter = tags.PlaytestCharacter

local WALK_SPEED = 16
local BASE_TURN_SPEED = 8
local GROUND_OFFSET = 2.5

local ApplyClientPlaytestIngress = {}
ApplyClientPlaytestIngress.__index = ApplyClientPlaytestIngress

function ApplyClientPlaytestIngress.new()
	return setmetatable({}, ApplyClientPlaytestIngress)
end

function ApplyClientPlaytestIngress:run(input, world, commands, state)
	for _, event in input:drain() do
		if event.kind == "player" then
			state.player = event.player
			local playerEntity = world:ref(event.player)
			if not world:has(playerEntity, PlaytestPlayer) then
				commands:insert(playerEntity, PlaytestPlayer.new(event.player.UserId))
			end
		elseif event.kind == "characterAdded" then
			state.character = event.character
			local root = util.characterRoot(event.character)
			if state.player == nil or root == nil then
				continue
			end

			local playerEntity = world:ref(state.player)
			local characterEntity = world:ref(event.character)
			if not world:has(characterEntity, PlaytestCharacter) then
				commands:insert(characterEntity, PlaytestCharacter.new())
			end
			commands:relate(characterEntity, ChildOf, playerEntity)
			if not world:has(characterEntity, RigidBody) then
				commands:insert(characterEntity, RigidBody.new({
					root_part = root,
					walk_speed = WALK_SPEED,
					base_turn_speed = BASE_TURN_SPEED,
					ground_offset = GROUND_OFFSET,
				}))
			end
			if not world:has(characterEntity, PhysicsInput) then
				commands:insert(characterEntity, PhysicsInput.new())
			end
		elseif event.kind == "characterRemoving" then
			if state.character == event.character then
				state.character = nil
			end
			local characterEntity = world:getRef(event.character)
			if characterEntity ~= nil then
				commands:despawn(characterEntity, { cleanupRefs = true })
			end
		else
			commands:trigger(TogglePlaytestInspector.new())
		end
	end
end

local function register(rovy, plugin)
	rovy:__system(ApplyClientPlaytestIngress, {
		id = "playtest/systems/apply-client-playtest-ingress@ApplyClientPlaytestIngress",
		plugin = plugin,
		schedule = Update,
		after = {},
		before = {},
		params = {
			{ kind = "collect", ctor = LocalPlaytestCollect },
			{ kind = "world" },
			{ kind = "commands" },
			{ kind = "resMut", ctor = ClientPlaytestState },
		},
	})
end

return {
	ApplyClientPlaytestIngress = ApplyClientPlaytestIngress,
	register = register,
}
