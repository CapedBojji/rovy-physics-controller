local ReplicatedStorage = script.Parent.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local worldInspector = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "world-inspector", "out")
local events = require(script.Parent.Parent:WaitForChild("events"))

local WorldInspectorState = worldInspector.WorldInspectorState
local ToggleWorldInspector = worldInspector.ToggleWorldInspector
local TogglePlaytestInspector = events.TogglePlaytestInspector

local TogglePlaytestInspectorObserver = {}
TogglePlaytestInspectorObserver.__index = TogglePlaytestInspectorObserver

function TogglePlaytestInspectorObserver.new()
	return setmetatable({}, TogglePlaytestInspectorObserver)
end

function TogglePlaytestInspectorObserver:run(_event, world, state)
	state.selectedTargetKey = "server"
	state:queueTargetList()
	state:queueSnapshot("server")
	world:trigger(ToggleWorldInspector.new())
end

local function register(rovy, plugin)
	rovy:__observer(TogglePlaytestInspectorObserver, {
		plugin = plugin,
		event = TogglePlaytestInspector,
		priority = 0,
		params = {
			{ kind = "event" },
			{ kind = "world" },
			{ kind = "resMut", ctor = WorldInspectorState },
		},
	})
end

return {
	TogglePlaytestInspectorObserver = TogglePlaytestInspectorObserver,
	register = register,
}
