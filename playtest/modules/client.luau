local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")
local worldInspector = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "world-inspector", "out")
local physicsController = require(ReplicatedStorage:WaitForChild("PhysicsController"))
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))

local collects = require(script.Parent:WaitForChild("collects"))
local events = require(script.Parent:WaitForChild("events"))
local resources = require(script.Parent:WaitForChild("resources"))
local tags = require(script.Parent:WaitForChild("tags"))

local applyClientPlaytestIngress = require(script.Parent:WaitForChild("systems"):WaitForChild("apply-client-playtest-ingress"))
local collectCharacterPhysicsInput = require(script.Parent:WaitForChild("systems"):WaitForChild("collect-character-physics-input"))
local followPlaytestCharacterCamera = require(script.Parent:WaitForChild("systems"):WaitForChild("follow-playtest-character-camera"))
local togglePlaytestInspectorObserver = require(script.Parent:WaitForChild("systems"):WaitForChild("toggle-playtest-inspector-observer"))

local rovy = core.rovy
local WorldInspectorPlugin = worldInspector.WorldInspectorPlugin
local WorldInspectorState = worldInspector.WorldInspectorState
local App = physicsController.App
local PhysicsControllerPlugin = physicsController.PhysicsControllerPlugin
local Update = physicsControllerState.Update

local function register()
	tags.register(rovy, PhysicsControllerPlugin)
	collects.registerClient(rovy, PhysicsControllerPlugin)
	resources.registerClient(rovy, PhysicsControllerPlugin)
	events.registerClient(rovy, PhysicsControllerPlugin)
	applyClientPlaytestIngress.register(rovy, PhysicsControllerPlugin)
	collectCharacterPhysicsInput.register(rovy, PhysicsControllerPlugin)
	followPlaytestCharacterCamera.register(rovy, PhysicsControllerPlugin)
	togglePlaytestInspectorObserver.register(rovy, PhysicsControllerPlugin)
end

local function createInspectorGui(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "PhysicsControllerWorldInspector"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 1000
	gui.Parent = playerGui
	return gui
end

local function startClient()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer
	if player == nil then
		return
	end

	register()

	local app = App.new()
	app:addPlugin(PhysicsControllerPlugin.new())
	app:addPlugin(WorldInspectorPlugin.new({
		uiRoot = createInspectorGui(player),
		renderSchedule = Update,
		networkSchedule = Update,
	}))
	app:start()

	local inspectorState = app.world:resource(WorldInspectorState)
	inspectorState.selectedTargetKey = "server"

	RunService.RenderStepped:Connect(function(deltaTime)
		app:runSchedule(Update, deltaTime)
	end)
end

return {
	startClient = startClient,
}
