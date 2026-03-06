local Roblox = require("@lune/roblox")
local LuneInstance = Roblox.Instance

local Signal = {} :: any do
	Signal.__index = Signal
	Signal.__type = "RBXScriptSignal"

	local function newConnection(signal, listener)
		return {
			signal = signal,
			listener = listener,

			Disconnect = function(self)
				local index = table.find(signal.connections, self)
				if not index then
					return
				end

				table.remove(signal.connections, index)
			end,
		}
	end

	function Signal.new()
		return setmetatable({
			connections = {},
		}, Signal)
	end

	function Signal.Connect(self, listener)
		local connection = newConnection(self, listener)
		table.insert(self.connections, connection)
		return connection
	end

	function Signal.fire(self, ...)
		for index = #self.connections, 1, -1 do
			self.connections[index].listener(...)
		end
	end
end

local Instance = {} :: any do
	type Userdata = { __USERDATA: true }
	type Data = {
		type: "Instance",
		class: string,
		name: string,
		raw: any?,
		parent: Data?,
		children: { Data },
		properties: { [string]: unknown },
		changed: { [string]: RBXScriptSignal },
		destroying: RBXScriptSignal,
	}

	local proxies = {} :: { [Data]: Userdata? }
	setmetatable(proxies :: any, { __mode = "v" })

	local __index
	local __newindex

	local function getData(userdata: Userdata): Data
		return (getmetatable(userdata :: any) :: { data: Data }).data
	end

	local function getProxy(data: Data): Userdata
		local existing = proxies[data]
		if existing then
			return existing
		end

		local userdata = newproxy(true)
		local proxy = getmetatable(userdata)
		proxy.data = data
		proxy.__index = __index
		proxy.__newindex = __newindex
		proxies[data] = userdata
		return userdata
	end

	local function isInstance(value: unknown): boolean
		local mt = getmetatable(value :: any)
		return type(mt) == "table"
			and mt.data ~= nil
			and (mt.data :: any).type == "Instance"
	end

	local function reparent(data: Data, parent: Data?)
		local currentParent = data.parent
		if currentParent then
			data.parent = nil
			local currentIndex = table.find(currentParent.children, data)
			if currentIndex then
				table.remove(currentParent.children, currentIndex)
			end
		end

		if parent then
			data.parent = parent
			table.insert(parent.children, data)
		end
	end

	local function getRawProperty(data: Data, property: string): (boolean, unknown)
		if not data.raw then
			return false, nil
		end

		return pcall(function()
			return (data.raw :: any)[property]
		end)
	end

	local methods = {}

	__index = function(userdata: Userdata, property: string)
		local data = getData(userdata)
		local method = methods[property]
		if method then
			return method
		end

		if property == "Name" then
			local ok, value = getRawProperty(data, property)
			if ok and type(value) == "string" then
				data.name = value
			end
			return data.name
		end

		if property == "Parent" then
			return if data.parent then getProxy(data.parent) else nil
		end

		if property == "Destroying" then
			return data.destroying
		end

		local ok, value = getRawProperty(data, property)
		if ok then
			return value
		end

		return data.properties[property]
	end

	__newindex = function(userdata: Userdata, property: string, value: unknown)
		local data = getData(userdata)

		if property == "Name" then
			if type(value) ~= "string" then
				error("name must be a string", 2)
			end

			data.name = value
			if data.raw then
				pcall(function()
					data.raw.Name = value
				end)
			end
		elseif property == "Parent" then
			if value ~= nil and not isInstance(value) then
				error("attempt to set non-instance as parent", 2)
			end

			local parentData = if value == nil then nil else getData(value :: Userdata)
			reparent(data, parentData)

			if data.raw then
				local rawParent = if parentData then parentData.raw else nil
				pcall(function()
					data.raw.Parent = rawParent
				end)
			end
		else
			local setOnRaw = false
			if data.raw then
				setOnRaw = pcall(function()
					(data.raw :: any)[property] = value
				end)
			end

			if not setOnRaw then
				data.properties[property] = value
			end
		end

		local changedSignal = data.changed[property]
		if changedSignal then
			Signal.fire(changedSignal, value)
		end
	end

	function Instance.new(class: string): Instance
		local raw = nil
		local ok, value = pcall(function()
			return LuneInstance.new(class)
		end)
		if ok then
			raw = value
		end

		local name = "UNNAMED"
		if raw then
			local okName, rawName = pcall(function()
				return raw.Name
			end)

			if okName and type(rawName) == "string" then
				name = rawName
			end
		end

		local data: Data = {
			type = "Instance",
			class = class,
			name = name,
			raw = raw,
			parent = nil,
			children = {},
			properties = {},
			changed = {},
			destroying = Signal.new() :: any,
		}

		return getProxy(data) :: any
	end

	function Instance.is_instance(value: unknown): boolean
		return isInstance(value)
	end

	function methods.Clone(userdata: Userdata): Userdata
		local data = getData(userdata)
		local rawClone = nil
		if data.raw then
			local ok, clone = pcall(function()
				return data.raw:Clone()
			end)
			if ok then
				rawClone = clone
			end
		end

		local cloneData: Data = {
			type = "Instance",
			class = data.class,
			name = data.name,
			raw = rawClone,
			parent = nil,
			children = {},
			properties = table.clone(data.properties),
			changed = {},
			destroying = Signal.new() :: any,
		}

		if rawClone then
			local okName, rawName = pcall(function()
				return rawClone.Name
			end)
			if okName and type(rawName) == "string" then
				cloneData.name = rawName
			end
		end

		return getProxy(cloneData)
	end

	function methods.FindFirstChild(userdata: Userdata, target: string): Userdata?
		local data = getData(userdata)
		for _, child in data.children do
			if child.name == target then
				return getProxy(child)
			end
		end

		return nil
	end

	function methods.GetChildren(userdata: Userdata): { Userdata }
		local children = getData(userdata).children
		local proxiesByIndex = table.create(#children)

		for index, child in children do
			proxiesByIndex[index] = getProxy(child)
		end

		return proxiesByIndex
	end

	function methods.GetPropertyChangedSignal(userdata: Userdata, property: string): RBXScriptSignal
		local data = getData(userdata)
		local signal = data.changed[property]
		if signal == nil then
			signal = Signal.new() :: any
			data.changed[property] = signal
		end

		return signal
	end

	function methods.Destroy(userdata: Userdata)
		local data = getData(userdata)
		Signal.fire(data.destroying)

		reparent(data, nil)

		if data.raw then
			pcall(function()
				data.raw:Destroy()
			end)
		end

		local changedSignal = data.changed.Parent
		if changedSignal then
			Signal.fire(changedSignal)
		end
	end
end

local nativeTypeof = typeof or type
local function typeOf(value)
	local valueType = nativeTypeof(value)
	if valueType == "Instance" then
		return "Instance"
	end

	if Instance.is_instance(value) then
		return "Instance"
	end

	local mt = getmetatable(value :: any)
	if type(mt) == "table" and mt.__type ~= nil then
		return mt.__type
	end

	return valueType
end

return {
	Signal = Signal,
	Instance = Instance,
	Color3 = Roblox.Color3,
	Vector2 = Roblox.Vector2,
	UDim2 = Roblox.UDim2,
	Enum = Roblox.Enum,
	typeof = typeOf,
}
