--!nocheck
-- RuntimeLib emulation for rovy-physics-controller specs under Zune.
-- Loads compiled roblox-ts output from out/ and emulates the TS module system.

local fs = zune.fs
local luau = zune.luau
local task = zune.task
local process = zune.process

local function kind(path: string): string?
	local ok, stat = pcall(fs.stat, path)
	if ok and stat ~= nil then
		return stat.kind
	end
	return nil
end

local function isFile(path: string): boolean
	return kind(path) == "file"
end

local function isDir(path: string): boolean
	return kind(path) == "directory"
end

local function readDir(path: string): { string }
	local names = {}
	for _, entry in fs.entries(path) do
		table.insert(names, entry.name)
	end
	return names
end

local ROOT = (process.cwd() :: string):gsub("[/\\]+$", "")

local TS = {}
local moduleCache: { [string]: { value: any } } = {}

local Node = {}

local function newNode(path: string)
	return setmetatable({ __path = path, __file = nil, children = {} }, Node)
end

local function scan(path: string): any
	local node = newNode(path)
	if isFile(path) then
		node.__file = path
		return node
	end
	if not isDir(path) then
		return node
	end
	for _, entry in readDir(path) do
		local childPath = path .. "/" .. entry
		if isDir(childPath) then
			local child = scan(childPath)
			node.children[entry] = child
			if entry == "include" and node.children["rbxts_include"] == nil then
				node.children["rbxts_include"] = child
			end
		elseif isFile(childPath) then
			local child = node.children[entry] or newNode(childPath)
			child.__file = childPath
			node.children[entry] = child
			local stem = entry:match("^(.*)%.luau$") or entry:match("^(.*)%.lua$")
			if stem and not node.children[stem] then
				local sn = newNode(childPath)
				sn.__file = childPath
				node.children[stem] = sn
			end
		end
	end
	local init = node.children["init"]
	if init and init.__file then
		node.__file = init.__file
	end
	return node
end

Node.__index = function(self, key: string)
	local m = rawget(Node, key)
	if m ~= nil then
		return m
	end
	local kids = rawget(self, "children")
	if kids and kids[key] ~= nil then
		return kids[key]
	end
	if key == "Name" then
		local path = rawget(self, "__path") :: string
		return path:match("([^/\\]+)$")
	end
	if key == "ClassName" then
		local file = rawget(self, "__file")
		return if file ~= nil then "ModuleScript" else "Folder"
	end
	if key == "Parent" then
		local p = (rawget(self, "__path") :: string):match("^(.*)[/\\][^/\\]+$")
		return p and (treeIndex(p) :: any) or nil
	end
	return nil
end

function Node.FindFirstChild(self, name: string)
	return rawget(self, "children")[name]
end

function Node.WaitForChild(self, name: string)
	return rawget(self, "children")[name]
end

function Node.GetFullName(self)
	return (rawget(self, "__path") :: string):gsub("^" .. ROOT .. "[/\\]?", ""):gsub("[/\\]", ".")
end

function Node.FindFirstAncestorWhichIsA(_self, _className: string)
	return nil
end

local nodeByPath: { [string]: any } = {}
local function indexTree(node)
	nodeByPath[node.__path] = node
	for _, c in node.children do
		indexTree(c)
	end
end
function treeIndex(path: string)
	return nodeByPath[path]
end

local roots: { [string]: any } = {}
local function ensureRoot(absPath: string)
	if not roots[absPath] then
		local n = scan(absPath)
		roots[absPath] = n
		indexTree(n)
	end
	return roots[absPath]
end

local rootNode = ensureRoot(ROOT)
local outNode = ensureRoot(ROOT .. "/out")
local localRovyPackagesNode = ensureRoot(ROOT .. "/../rovy/packages")

if rootNode.children["node_modules"] == nil then
	rootNode.children["node_modules"] = newNode(ROOT .. "/node_modules")
end

local nodeModulesNode = rootNode.children["node_modules"]
if nodeModulesNode.children["@rovy"] == nil then
	nodeModulesNode.children["@rovy"] = newNode(ROOT .. "/node_modules/@rovy")
end

local rovyScopeNode = nodeModulesNode.children["@rovy"]
if localRovyPackagesNode.children["core"] ~= nil then
	rovyScopeNode.children["core"] = localRovyPackagesNode.children["core"]
end

local includeNode = rootNode.children["rbxts_include"]
if includeNode ~= nil and includeNode.children["node_modules"] == nil and rootNode.children["node_modules"] ~= nil then
	includeNode.children["node_modules"] = rootNode.children["node_modules"]
end
if rootNode.children["rbxts_include"] ~= nil and outNode.children["rbxts_include"] == nil then
	outNode.children["rbxts_include"] = rootNode.children["rbxts_include"]
end

local sharedG = setmetatable({}, { __index = _G })

local function makeVector3(x: number, y: number, z: number)
	local magnitude = math.sqrt(x * x + y * y + z * z)
	local vector = {
		X = x,
		Y = y,
		Z = z,
		Magnitude = magnitude,
	}

	function vector.div(self, scalar: number)
		return makeVector3(self.X / scalar, self.Y / scalar, self.Z / scalar)
	end

	function vector.mul(self, scalar: number)
		return makeVector3(self.X * scalar, self.Y * scalar, self.Z * scalar)
	end

	return vector
end

rawset(sharedG, "Vector3", {
	new = makeVector3,
	zero = makeVector3(0, 0, 0),
	yAxis = makeVector3(0, 1, 0),
})

rawset(sharedG, "game", {
	GetService = function(_, serviceName)
		if serviceName == "RunService" then
			return {
				Heartbeat = {
					Wait = function()
						return 0
					end,
				},
			}
		end
		return {}
	end,
})

local function loadModule(node): any
	local fsPath = rawget(node, "__file")
	assert(fsPath, "physics-controller test harness: not a requirable module: " .. tostring(rawget(node, "__path")))
	local cached = moduleCache[fsPath]
	if cached ~= nil then
		return cached.value
	end
	moduleCache[fsPath] = { value = nil }

	local src = fs.readFile(fsPath)

	local scriptNode = node
	if fsPath:match("[/\\]init%.luau$") or fsPath:match("[/\\]init%.lua$") then
		local dir = fsPath:match("^(.*)[/\\]init%.lua[u]?$")
		scriptNode = (dir and treeIndex(dir)) or node
	end
	rawset(sharedG, scriptNode, TS)

	local env = setmetatable({
		script = scriptNode,
		_G = sharedG,
		game = rawget(sharedG, "game"),
		task = task,
		require = function(target)
			if type(target) == "string" then
				local base = (fsPath:match("^(.*)[/\\][^/\\]+$")) or ROOT
				local p = base
				for seg in target:gmatch("[^/]+") do
					if seg == ".." then
						p = p:match("^(.*)[/\\][^/\\]+$") or p
					elseif seg ~= "." then
						p = p .. "/" .. seg
					end
				end
				local n = treeIndex(p) or treeIndex(p:gsub("%.luau$", ""):gsub("%.lua$", ""))
				if not n then
					n = scan(p)
					indexTree(n)
				end
				return loadModule(n)
			end
			return loadModule(target)
		end,
	}, { __index = sharedG })

	local chunk = luau.load(luau.compile(src), { chunk_name = fsPath, env = env })
	local value = chunk()
	moduleCache[fsPath] = { value = value }
	return value
end

function TS.getModule(_context, scope: string, moduleName: string)
	local dir = ROOT .. "/node_modules/" .. scope .. "/" .. moduleName
	local node = ensureRoot(dir)
	if rawget(node, "__file") == nil and node.children["out"] ~= nil then
		return node.children["out"]
	end
	return node
end

function TS.import(_context, module, ...)
	local target = module
	for _, name in { ... } do
		target = (target :: any)[name]
		assert(target ~= nil, "physics-controller test harness: import miss at '" .. tostring(name) .. "'")
	end
	return loadModule(target)
end

TS.instanceof = function(obj, class)
	if type(class) == "table" and type((class :: any).instanceof) == "function" then
		return (class :: any).instanceof(obj)
	end
	local mt = type(obj) == "table" and getmetatable(obj) or nil
	while mt do
		if mt == class then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end

function TS.loadPath(relPath: string)
	local n = treeIndex(ROOT .. "/" .. relPath) or treeIndex(ROOT .. "/" .. relPath .. ".luau")
	assert(n, "physics-controller test harness: no module at " .. relPath)
	return loadModule(n)
end

return TS
