local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")
local worldInspector = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "world-inspector", "out")
local physicsController = require(ReplicatedStorage:WaitForChild("PhysicsController"))
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))

local collects = require(script.Parent:WaitForChild("collects"))
local resources = require(script.Parent:WaitForChild("resources"))
local tags = require(script.Parent:WaitForChild("tags"))
local util = require(script.Parent:WaitForChild("util"))
local applyServerPlayerLifecycle = require(script.Parent:WaitForChild("systems"):WaitForChild("apply-server-player-lifecycle"))

local rovy = core.rovy
local WorldInspectorServerPlugin = worldInspector.WorldInspectorServerPlugin
local App = physicsController.App
local PhysicsControllerPlugin = physicsController.PhysicsControllerPlugin
local Update = physicsControllerState.Update

local function register()
	tags.register(rovy, PhysicsControllerPlugin)
	collects.registerServer(rovy, PhysicsControllerPlugin)
	resources.registerServer(rovy, PhysicsControllerPlugin)
	applyServerPlayerLifecycle.register(rovy, PhysicsControllerPlugin)
end

local function startServer()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	Players.CharacterAutoLoads = false
	util.cubesFolder()

	register()

	local app = App.new()
	app:addPlugin(PhysicsControllerPlugin.new())
	app:addPlugin(WorldInspectorServerPlugin.new({
		schedule = Update,
		access = function()
			return true
		end,
	}))
	app:start()

	RunService.Heartbeat:Connect(function(deltaTime)
		app:runSchedule(Update, deltaTime)
	end)
end

return {
	startServer = startServer,
}
