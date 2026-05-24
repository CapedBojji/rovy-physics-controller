local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")

local Collector = core.Collector

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

local function registerClient(rovy, plugin)
	rovy:__collect(LocalPlaytestCollect, "playtest/collects@LocalPlaytestCollect", { plugin = plugin })
end

local function registerServer(rovy, plugin)
	rovy:__collect(ServerPlayerLifecycleCollect, "playtest/collects@ServerPlayerLifecycleCollect", { plugin = plugin })
end

return {
	LocalPlaytestCollect = LocalPlaytestCollect,
	ServerPlayerLifecycleCollect = ServerPlayerLifecycleCollect,
	registerClient = registerClient,
	registerServer = registerServer,
}
