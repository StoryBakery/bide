local typeof = game and typeof or require("../../tests/reactive-test/mock").typeof :: never

local cleanup = require("../Reactive/cleanup")
local flags = require("../Reactive/flags")
local implicit_effect = require("./implicit_effect")

type Array<V> = { V }
type Attachment = (Instance) -> unknown
type Map<K, V> = { [K]: V }
type EventInfo = {
	name: string,
	listener: () -> (),
}
type AttachmentQueue = Array<Attachment>
type NestedDebugByDepth = { [number]: Map<string, true> }

type Cache = {
	-- event listeners to connect after properties are set
	events: Array<EventInfo>,

	-- attachments to run after the node is parented
	attachments: AttachmentQueue,

	-- what to parent the instance to before running attachments
	parent: unknown,

	-- cache to detect duplicate property setting at same nesting depth
	nested_debug: NestedDebugByDepth,

	-- each nested layer occupies two indexes: 1. table ref 2. nested depth
	-- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
	nested_stack: { {} | number },
}

local free_cache: Cache?

local function getOrCreateNestedDepth(
	nestedDebug: NestedDebugByDepth,
	depth: number
): Map<string, true>
	local depthMap = nestedDebug[depth]
	if depthMap == nil then
		depthMap = {}
		nestedDebug[depth] = depthMap
	end

	return depthMap
end

local function borrow_cache(): Cache
	if free_cache then
		local cache = free_cache
		free_cache = nil
		return cache
	else
		return {
			events = {},
			attachments = {},
			parent = nil,
			nested_debug = {},
			nested_stack = {},
		}
	end
end

local function return_cache(cache: Cache)
	free_cache = cache
end

local function isLegacyAction(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end

	local callback = (value :: any).callback
	local priority = (value :: any).priority

	return type(callback) == "function" and type(priority) == "number"
end

local function appendAttachments(attachments: AttachmentQueue, value: unknown)
	if value == nil or value == false then
		return
	end

	local valueType = type(value)

	if valueType == "function" then
		attachments[#attachments + 1] = value :: Attachment
		return
	end

	if valueType ~= "table" then
		error(`invalid Attach value, expected function or array, got {valueType}`, 0)
	end

	for key, nestedValue in value :: Map<unknown, unknown> do
		if type(key) ~= "number" then
			error(`invalid Attach entry key "{tostring(key)}"`, 0)
		end

		appendAttachments(attachments, nestedValue)
	end
end

local function process_properties(
	properties: Map<unknown, unknown>,
	instance: Instance,
	cache: Cache,
	depth: number
)
	for property, value in properties do
		if type(property) == "string" then
			if flags.strict then -- check for duplicate property assignment at nesting depth
				local depthMap = getOrCreateNestedDepth(cache.nested_debug, depth)
				if depthMap[property] then
					error(`duplicate property {property} at depth {depth}`, 0)
				end
				depthMap[property] = true
			end

			if property == "Attach" then
				appendAttachments(cache.attachments, value)
				continue
			end

			if property == "Parent" then
				cache.parent = value
				continue
			end

			if type(value) == "function" then
				if typeof((instance :: any)[property]) == "RBXScriptSignal" then
					cache.events[#cache.events + 1] = {
						name = property,
						listener = value :: () -> (),
					}
				else
					implicit_effect.property(instance, property, value :: () -> ()) -- create implicit effect for property
				end
			else
				(instance :: any)[property] = value -- set property
			end
		elseif type(property) == "number" then
			if type(value) == "function" then
				implicit_effect.children(instance, value :: any) -- bind children
			elseif type(value) == "table" then
				if isLegacyAction(value) then
					error("numeric action children are no longer supported; use Attach = { ... }", 0)
				elseif flags.defer_nested_properties then
					cache.nested_stack[#cache.nested_stack + 1] = value :: {}
					cache.nested_stack[#cache.nested_stack + 1] = depth + 1 -- push table to stack for later processing
				else
					process_properties(value :: Map<unknown, unknown>, instance, cache, depth + 1)
				end
			elseif type(value) == "userdata" then
				(value :: Instance).Parent = instance -- parent child
			end
		end
	end
end

-- applies table of nested properties to an instance using full reactive semantics
local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
	if not properties then
		error "attempt to call a constructor returned by create() with no properties"
	end

	local caches = borrow_cache()
	local attachments = caches.attachments
	local events = caches.events
	local nested_debug = caches.nested_debug
	local nested_stack = caches.nested_stack

	-- process all properties
	local depth = 1
	repeat
		process_properties(properties, instance, caches, depth)
		local nextDepth = nested_stack[#nested_stack]
		nested_stack[#nested_stack] = nil

		local nextProperties = nested_stack[#nested_stack]
		nested_stack[#nested_stack] = nil

		if type(nextDepth) ~= "number" or type(nextProperties) ~= "table" then
			break
		end

		depth = nextDepth
		properties = nextProperties :: Map<unknown, unknown>
	until false

	for _, eventInfo in events do
		(instance :: any)[eventInfo.name]:Connect(eventInfo.listener)
	end

	local parent = caches.parent
	if parent then
		if type(parent) == "function" then
			implicit_effect.parent(instance, parent :: () -> Instance)
		else
			instance.Parent = parent :: Instance
		end
	end

	for index = 1, #attachments do
		local attachment = attachments[index]
		local result = attachment(instance)

		if result ~= nil then
			cleanup(result)
		end
	end

	table.clear(events)
	table.clear(attachments)
	caches.parent = nil
	if flags.strict then
		for _, depthMap in nested_debug do
			table.clear(depthMap)
		end
		table.clear(nested_debug)
	end
	table.clear(nested_stack :: any)

	return_cache(caches)

	return instance
end

return apply
