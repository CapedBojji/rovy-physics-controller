local PlaytestPlayer = {}
PlaytestPlayer.__index = PlaytestPlayer

function PlaytestPlayer.new(user_id)
	return setmetatable({
		user_id = user_id,
	}, PlaytestPlayer)
end

local PlaytestCharacter = {}
PlaytestCharacter.__index = PlaytestCharacter

function PlaytestCharacter.new()
	return setmetatable({}, PlaytestCharacter)
end

local registered = false

local function register(rovy, plugin)
	if registered then
		return
	end
	registered = true

	rovy:__component(PlaytestPlayer, "playtest/tags@PlaytestPlayer", {
		plugin = plugin,
		editor = {
			fields = {
				{
					key = "user_id",
					typeLabel = "number",
					validator = function()
						return true
					end,
				},
			},
			constructorValidator = function()
				return true
			end,
		},
	})

	rovy:__component(PlaytestCharacter, "playtest/tags@PlaytestCharacter", {
		plugin = plugin,
		editor = {
			fields = {},
			constructorValidator = function()
				return true
			end,
		},
	})
end

return {
	PlaytestPlayer = PlaytestPlayer,
	PlaytestCharacter = PlaytestCharacter,
	register = register,
}
