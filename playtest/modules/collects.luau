local ReplicatedStorage = script.Parent.Parent
local TS = require(ReplicatedStorage:WaitForChild("include"):WaitForChild("RuntimeLib"))
local core = TS.import(script, ReplicatedStorage, "include", "node_modules", "@rovy", "core", "out")

local Collector = core.Collector

local LocalPlaytestCollect = setmetatable({}, { __index = Collector })
LocalPlaytestCollect.__index = LocalPlaytestCollect

function LocalPlaytestCollect.new()
	local self = setmetatable({}, LocalPlaytestCollect)
	Collector.constructor(self)

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
		end
	end)

	return self
end

local PlaytestInputCollect = setmetatable({}, { __index = Collector })
PlaytestInputCollect.__index = PlaytestInputCollect

function PlaytestInputCollect.new()
	local self = setmetatable({}, PlaytestInputCollect)
	Collector.constructor(self)

	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		self:enqueue({ kind = "keyChanged", key = input.KeyCode, held = true })
	end)
	UserInputService.InputEnded:Connect(function(input)
		self:enqueue({ kind = "keyChanged", key = input.KeyCode, held = false })
	end)

	return self
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
	rovy:__collect(PlaytestInputCollect, "playtest/collects@PlaytestInputCollect", { plugin = plugin })
end

local function registerServer(rovy, plugin)
	rovy:__collect(ServerPlayerLifecycleCollect, "playtest/collects@ServerPlayerLifecycleCollect", { plugin = plugin })
end

return {
	LocalPlaytestCollect = LocalPlaytestCollect,
	PlaytestInputCollect = PlaytestInputCollect,
	ServerPlayerLifecycleCollect = ServerPlayerLifecycleCollect,
	registerClient = registerClient,
	registerServer = registerServer,
}
