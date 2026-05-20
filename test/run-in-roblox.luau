local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local rbxtsInclude = ReplicatedStorage:WaitForChild("rbxts_include", 10)
local nodeModules = rbxtsInclude:WaitForChild("node_modules", 10)
local rbxtsPackages = nodeModules:WaitForChild("@rbxts", 10)
local testezPackage = rbxtsPackages:WaitForChild("testez", 10)
local TestEZ = require(testezPackage:WaitForChild("src", 10))

local results = TestEZ.TestBootstrap:run({ ServerScriptService }, TestEZ.Reporters.TextReporter)
if results.failureCount > 0 then
	error(string.format("integration tests failed: %d failure(s)", results.failureCount), 0)
end

print("integration tests completed successfully")
