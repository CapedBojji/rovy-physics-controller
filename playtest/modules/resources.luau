local ClientPlaytestState = {}
ClientPlaytestState.__index = ClientPlaytestState

function ClientPlaytestState.new()
	return setmetatable({}, ClientPlaytestState)
end

local ServerPlaytestState = {}
ServerPlaytestState.__index = ServerPlaytestState

function ServerPlaytestState.new()
	return setmetatable({}, ServerPlaytestState)
end

local function registerClient(rovy, plugin)
	rovy:__resource(ClientPlaytestState, "playtest/resources@ClientPlaytestState", { plugin = plugin })
end

local function registerServer(rovy, plugin)
	rovy:__resource(ServerPlaytestState, "playtest/resources@ServerPlaytestState", { plugin = plugin })
end

return {
	ClientPlaytestState = ClientPlaytestState,
	ServerPlaytestState = ServerPlaytestState,
	registerClient = registerClient,
	registerServer = registerServer,
}
