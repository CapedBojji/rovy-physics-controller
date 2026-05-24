--!nocheck

return function(TS, t)
	local lib = TS.loadPath("out/init")
	local core = TS.loadPath("node_modules/@rovy/core/out")
	local components = TS.loadPath("out/components")
	local playtestTags = TS.loadPath("playtest/modules/tags")
	local state = TS.loadPath("out/state")

	t.describe("Update schedule", function()
		t.it("stays runnable after the plugin helper is installed", function()
			local app = lib.App.new()
			app:addPlugin(lib.PhysicsControllerPlugin.new())
			app:start()

			local ok, err = pcall(function()
				app:runSchedule(state.Update)
			end)

			t.expect(ok).toBe(true)
			t.expect(err).toBeNil()
		end)

		t.it("uses built-in refs and ChildOf relation from rovy core", function()
			local app = lib.App.new()
			app:addPlugin(lib.PhysicsControllerPlugin.new())
			app:start()

			local world = app.world
			local root = { name = "Root" }
			local child = { name = "Child" }

			local rootEntity = world:ref(root)
			local rootEntityAgain = world:ref(root)
			local childEntity = world:ref(child)

			t.expect(rootEntityAgain).toBe(rootEntity)
			t.expect(world:getRef(root)).toBe(rootEntity)
			t.expect(world:hasRef(child)).toBe(true)

			world:relate(childEntity, core.ChildOf, rootEntity)

			t.expect(world:parent(childEntity)).toBe(rootEntity)

			local children = {}
			for entity in world:children(rootEntity) do
				table.insert(children, entity)
			end

			t.expect(#children).toBe(1)
			t.expect(children[1]).toBe(childEntity)
		end)

		t.it("can attach client character refs under player refs with physics input", function()
			playtestTags.register(core.rovy, lib.PhysicsControllerPlugin)

			local app = lib.App.new()
			app:addPlugin(lib.PhysicsControllerPlugin.new())
			app:start()

			local world = app.world
			local player = { UserId = 101 }
			local character = { Name = "Character" }

			local playerEntity = world:ref(player)
			local characterEntity = world:ref(character)

			world:insert(playerEntity, playtestTags.PlaytestPlayer.new(player.UserId))
			world:insert(characterEntity, playtestTags.PlaytestCharacter.new())
			world:insert(characterEntity, components.PhysicsInput.new({}, {}))
			world:relate(characterEntity, core.ChildOf, playerEntity)

			t.expect(world:getRef(player)).toBe(playerEntity)
			t.expect(world:getRef(character)).toBe(characterEntity)
			t.expect(world:parent(characterEntity)).toBe(playerEntity)
			t.expect(world:has(characterEntity, components.PhysicsInput)).toBe(true)
		end)

		t.it("keeps the server playtest contract player-only", function()
			playtestTags.register(core.rovy, lib.PhysicsControllerPlugin)

			local app = lib.App.new()
			app:addPlugin(lib.PhysicsControllerPlugin.new())
			app:start()

			local world = app.world
			local player = { UserId = 202 }
			local character = { Name = "ServerCharacter" }

			local playerEntity = world:ref(player)
			world:insert(playerEntity, playtestTags.PlaytestPlayer.new(player.UserId))

			t.expect(world:getRef(player)).toBe(playerEntity)
			t.expect(world:getRef(character)).toBeNil()
		end)
	end)
end
