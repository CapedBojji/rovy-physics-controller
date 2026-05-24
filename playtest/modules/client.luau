local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")
local worldInspector = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "world-inspector", "out")
local physicsController = require(ReplicatedStorage:WaitForChild("PhysicsController"))
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local physicsControllerComponents = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("components"))
local tags = require(script.Parent:WaitForChild("tags"))

local rovy = core.rovy
local Collector = core.Collector
local ChildOf = core.ChildOf
local WorldInspectorPlugin = worldInspector.WorldInspectorPlugin
local WorldInspectorState = worldInspector.WorldInspectorState
local ToggleWorldInspector = worldInspector.ToggleWorldInspector
local App = physicsController.App
local PhysicsControllerPlugin = physicsController.PhysicsControllerPlugin
local Update = physicsControllerState.Update
local RigidBody = physicsControllerComponents.RigidBody
local PhysicsInput = physicsControllerComponents.PhysicsInput
local PlaytestPlayer = tags.PlaytestPlayer
local PlaytestCharacter = tags.PlaytestCharacter

local WALK_SPEED = 16
local BASE_TURN_SPEED = 8
local GROUND_OFFSET = 2.5

local function characterRoot(character)
	local root = character.PrimaryPart or character:FindFirstChild("RootPart")
	if root ~= nil and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function cameraPlanarBasis()
	local camera = game:GetService("Workspace").CurrentCamera
	local forward = if camera ~= nil then Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z) else Vector3.zAxis
	forward = if forward.Magnitude > 0 then forward.Unit else Vector3.zAxis
	local right = Vector3.new(forward.Z, 0, -forward.X)
	return forward, right
end

local LocalPlaytestCollect = setmetatable({}, { __index = Collector })
LocalPlaytestCollect.__index = LocalPlaytestCollect

function LocalPlaytestCollect.new()
	local self = setmetatable({}, LocalPlaytestCollect)
	Collector.constructor(self)
	self.forward_held = false
	self.backward_held = false
	self.left_held = false
	self.right_held = false

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	if player == nil then
		return self
	end

	self:enqueue({ kind = "player", player = player })
	if player.Character ~= nil then
		self:enqueue({ kind = "characterAdded", character = player.Character })
	end
	player.CharacterAdded:Connect(function(character)
		self:enqueue({ kind = "characterAdded", character = character })
	end)
	player.CharacterRemoving:Connect(function(character)
		self:enqueue({ kind = "characterRemoving", character = character })
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F2 then
			self:enqueue({ kind = "toggleInspector" })
			return
		end
		self:setKey(input.KeyCode, true)
	end)
	UserInputService.InputEnded:Connect(function(input)
		self:setKey(input.KeyCode, false)
	end)

	return self
end

function LocalPlaytestCollect:readMoveDirection()
	local forward, right = cameraPlanarBasis()
	local move = Vector3.zero
	if self.forward_held then
		move += forward
	end
	if self.backward_held then
		move -= forward
	end
	if self.right_held then
		move += right
	end
	if self.left_held then
		move -= right
	end
	move = if move.Magnitude > 1 then move.Unit else move
	return if move.Magnitude > 0 then move.Unit else forward, move
end

function LocalPlaytestCollect:setKey(key, held)
	if key == Enum.KeyCode.W then
		self.forward_held = held
	end
	if key == Enum.KeyCode.S then
		self.backward_held = held
	end
	if key == Enum.KeyCode.A then
		self.left_held = held
	end
	if key == Enum.KeyCode.D then
		self.right_held = held
	end
end

local ClientPlaytestState = {}
ClientPlaytestState.__index = ClientPlaytestState

function ClientPlaytestState.new()
	return setmetatable({}, ClientPlaytestState)
end

local TogglePlaytestInspector = {}
TogglePlaytestInspector.__index = TogglePlaytestInspector

function TogglePlaytestInspector.new()
	return setmetatable({}, TogglePlaytestInspector)
end

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
			local root = characterRoot(event.character)
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
	local root = characterRoot(state.character)
	local camera = game:GetService("Workspace").CurrentCamera
	if root == nil or camera == nil then
		return
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = root
end

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

local function register()
	tags.register(rovy, PhysicsControllerPlugin)
	rovy:__collect(LocalPlaytestCollect, "playtest/client@LocalPlaytestCollect", { plugin = PhysicsControllerPlugin })
	rovy:__resource(ClientPlaytestState, "playtest/client@ClientPlaytestState", { plugin = PhysicsControllerPlugin })
	rovy:__event(TogglePlaytestInspector, { plugin = PhysicsControllerPlugin })
	rovy:__system(ApplyClientPlaytestIngress, {
		id = "playtest/client@ApplyClientPlaytestIngress",
		plugin = PhysicsControllerPlugin,
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
	rovy:__system(CollectCharacterPhysicsInput, {
		id = "playtest/client@CollectCharacterPhysicsInput",
		plugin = PhysicsControllerPlugin,
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
	rovy:__system(FollowPlaytestCharacterCamera, {
		id = "playtest/client@FollowPlaytestCharacterCamera",
		plugin = PhysicsControllerPlugin,
		schedule = Update,
		after = {},
		before = {},
		params = {
			{ kind = "world" },
			{ kind = "res", ctor = ClientPlaytestState },
		},
	})
	rovy:__observer(TogglePlaytestInspectorObserver, {
		plugin = PhysicsControllerPlugin,
		event = TogglePlaytestInspector,
		priority = 0,
		params = {
			{ kind = "event" },
			{ kind = "world" },
			{ kind = "resMut", ctor = WorldInspectorState },
		},
	})
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
