--!nocheck
-- rovy-physics-controller spec runner.
-- Builds the package, then runs every test/specs/*.luau against the compiled `out/`.
-- Usage: `pnpm test`  or  `zune test test/run`

local runner = require("./harness/spec_runner")

runner.run({
	runtimeModule = "./harness/runtime",
	loadPath = "out/init",
	specsDir = "test/specs",
	specsRequirePrefix = "./specs/",
	successMessage = "ok  harness loaded out/init",
})
