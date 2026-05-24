local ReplicatedStorage = script.Parent.Parent.Parent
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local collects = require(script.Parent.Parent:WaitForChild("collects"))
local resources = require(script.Parent.Parent:WaitForChild("resources"))
local tags = require(script.Parent.Parent:WaitForChild("tags"))
local util = require(script.Parent.Parent:WaitForChild("util"))

local Update = physicsControllerState.Update
local ServerPlayerLifecycleCollect = collects.ServerPlayerLifecycleCollect
local ServerPlaytestState = resources.ServerPlaytestState
local PlaytestPlayer = tags.PlaytestPlayer

local ApplyServerPlayerLifecycle = {}
ApplyServerPlayerLifecycle.__index = ApplyServerPlayerLifecycle

function ApplyServerPlayerLifecycle.new()
	return setmetatable({}, ApplyServerPlayerLifecycle)
end

function ApplyServerPlayerLifecycle:run(input, world, commands, _state)
	for _, event in input:drain() do
		local playerEntity = world:getRef(event.player)
		if event.kind == "playerAdded" then
			local entity = playerEntity or world:ref(event.player)
			if not world:has(entity, PlaytestPlayer) then
				commands:insert(entity, PlaytestPlayer.new(event.player.UserId))
			end
			util.spawnCube(event.player)
		else
			util.cleanupCube(event.player)
			if playerEntity ~= nil then
				commands:despawn(playerEntity, { cleanupRefs = true })
			end
		end
	end
end

local function register(rovy, plugin)
	rovy:__system(ApplyServerPlayerLifecycle, {
		id = "playtest/systems/apply-server-player-lifecycle@ApplyServerPlayerLifecycle",
		plugin = plugin,
		schedule = Update,
		after = {},
		before = {},
		params = {
			{ kind = "collect", ctor = ServerPlayerLifecycleCollect },
			{ kind = "world" },
			{ kind = "commands" },
			{ kind = "resMut", ctor = ServerPlaytestState },
		},
	})
end

return {
	ApplyServerPlayerLifecycle = ApplyServerPlayerLifecycle,
	register = register,
}
