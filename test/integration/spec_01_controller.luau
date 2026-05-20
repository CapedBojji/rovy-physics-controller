-- Integration spec: PhysicsController — runs inside Roblox (server context).
-- Required by runner.server.luau. Returns a list of { name, fn } test cases.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The compiled package is placed at ReplicatedStorage.PhysicsController
-- by test.project.json (via rojo). WaitForChild guards against load order.
local pkg = require(ReplicatedStorage:WaitForChild("PhysicsController", 10))

local tests = {}

local function test(name: string, fn: () -> ())
	table.insert(tests, { name = name, fn = fn })
end

-- ── spec ──────────────────────────────────────────────────────────────────

test("PhysicsController.new() returns an instance", function()
	local ctrl = pkg.PhysicsController.new()
	assert(ctrl ~= nil, "expected non-nil controller")
end)

test("PhysicsController.new(options) returns an instance", function()
	local ctrl = pkg.PhysicsController.new({})
	assert(ctrl ~= nil, "expected non-nil controller with options")
end)

test("PhysicsController instances are distinct", function()
	local a = pkg.PhysicsController.new()
	local b = pkg.PhysicsController.new()
	assert(a ~= b, "expected distinct instances")
end)

-- ─────────────────────────────────────────────────────────────────────────

return tests
