-- physics-controller integration test runner.
-- Placed in ServerScriptService by test.project.json (rojo).
-- Run with: pnpm test:integration  (builds place, opens in Studio)
--
-- Output format mirrors the rovy project conventions:
--   PASS  <test name>
--   FAIL  <test name>  →  <error>

local function runSuite(modulePath: string)
	local ok, result = pcall(require, script.Parent.Parent:WaitForChild(modulePath, 5))
	if not ok then
		warn("[integration] could not load suite '" .. modulePath .. "': " .. tostring(result))
		return 0, 1
	end

	local tests: { { name: string, fn: () -> () } } = result
	local passed = 0
	local failed = 0

	for _, entry in tests do
		local success, err = pcall(entry.fn)
		if success then
			print(string.format("  PASS  %s", entry.name))
			passed += 1
		else
			warn(string.format("  FAIL  %s  →  %s", entry.name, tostring(err)))
			failed += 1
		end
	end

	return passed, failed
end

-- ── run all suites ────────────────────────────────────────────────────────

print("\n── rovy-physics-controller integration tests ──")

local totalPassed = 0
local totalFailed = 0

local suites = {
	"ServerScriptService.TestRunner.spec_01_controller",
}

-- Specs live alongside the runner as sibling scripts.
-- Require them directly by script instance rather than by path string.

local function runScript(spec)
	local ok, result = pcall(require, spec)
	if not ok then
		warn("[integration] failed to load spec: " .. tostring(result))
		totalFailed += 1
		return
	end
	local tests: { { name: string, fn: () -> () } } = result
	for _, entry in tests do
		local success, err = pcall(entry.fn)
		if success then
			print(string.format("  PASS  %s", entry.name))
			totalPassed += 1
		else
			warn(string.format("  FAIL  %s  →  %s", entry.name, tostring(err)))
			totalFailed += 1
		end
	end
end

-- Find and run all spec_*.luau siblings
for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") and child.Name:match("^spec_") then
		print(string.format("\n  [ %s ]", child.Name))
		runScript(child)
	end
end

-- ── summary ───────────────────────────────────────────────────────────────

print(string.format(
	"\n── %d passed, %d failed ──\n",
	totalPassed, totalFailed
))

if totalFailed > 0 then
	error(string.format("integration tests failed: %d failure(s)", totalFailed), 0)
end
