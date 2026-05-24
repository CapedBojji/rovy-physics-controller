local TogglePlaytestInspector = {}
TogglePlaytestInspector.__index = TogglePlaytestInspector

function TogglePlaytestInspector.new()
	return setmetatable({}, TogglePlaytestInspector)
end

local function registerClient(rovy, plugin)
	rovy:__event(TogglePlaytestInspector, { plugin = plugin })
end

return {
	TogglePlaytestInspector = TogglePlaytestInspector,
	registerClient = registerClient,
}
