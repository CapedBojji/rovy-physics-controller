local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")
local worldInspector = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "world-inspector", "out")
local physicsController = require(ReplicatedStorage:WaitForChild("PhysicsController"))
local physicsControllerState = require(ReplicatedStorage:WaitForChild("PhysicsController"):WaitForChild("state"))
local tags = require(script.Parent:WaitForChild("tags"))

local rovy = core.rovy
local Collector = core.Collector
local WorldInspectorServerPlugin = worldInspector.WorldInspectorServerPlugin
local App = physicsController.App
local PhysicsControllerPlugin = physicsController.PhysicsControllerPlugin
local Update = physicsControllerState.Update
local PlaytestPlayer = tags.PlaytestPlayer

local CUBE_FOLDER_NAME = "PhysicsControllerPlaytestCubes"
local SPAWN_HEIGHT = 6
local SPAWN_SPACING = 10

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

local ServerPlayerLifecycleCollect = setmetatable({}, { __index = Collector })
ServerPlayerLifecycleCollect.__index = ServerPlayerLifecycleCollect

function ServerPlayerLifecycleCollect.new()
	local self = setmetatable({}, ServerPlayerLifecycleCollect)
	Collector.constructor(self)
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player)
		self:enqueue({ kind = "playerAdded", player = player })
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:enqueue({ kind = "playerRemoving", player = player })
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:enqueue({ kind = "playerAdded", player = player })
		end)
	end
	return self
end

local ServerPlaytestState = {}
ServerPlaytestState.__index = ServerPlaytestState

function ServerPlaytestState.new()
	return setmetatable({}, ServerPlaytestState)
end

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
			spawnCube(event.player)
		else
			cleanupCube(event.player)
			if playerEntity ~= nil then
				commands:despawn(playerEntity, { cleanupRefs = true })
			end
		end
	end
end

local function register()
	tags.register(rovy, PhysicsControllerPlugin)
	rovy:__collect(ServerPlayerLifecycleCollect, "playtest/server@ServerPlayerLifecycleCollect", { plugin = PhysicsControllerPlugin })
	rovy:__resource(ServerPlaytestState, "playtest/server@ServerPlaytestState", { plugin = PhysicsControllerPlugin })
	rovy:__system(ApplyServerPlayerLifecycle, {
		id = "playtest/server@ApplyServerPlayerLifecycle",
		plugin = PhysicsControllerPlugin,
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

local function startServer()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	Players.CharacterAutoLoads = false
	cubesFolder()

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
