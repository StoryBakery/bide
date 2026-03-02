local typeof = game and typeof or require("../../tests/vide-test/mock").typeof :: never

local flags = require("./flags")
local implicit_effect = require("./implicit_effect")
local _, is_action = require("./action")()
local graph = require("./graph")
type Node<T> = graph.Node<T>

type Array<V> = { V }
type Map<K, V> = { [K]: V }
type EventInfo = {
	name: string,
	listener: () -> (),
}
type ActionQueueByPriority = { [number]: Array<(Instance) -> ()> }
type NestedDebugByDepth = { [number]: Map<string, true> }

type Cache = {
	-- event listeners to connect after properties are set
	events: Array<EventInfo>,

	-- actions to run after events are connected
	actions: ActionQueueByPriority,

	-- what to parent the instance to after running actions
	parent: unknown,

	-- cache to detect duplicate property setting at same nesting depth
	nested_debug: NestedDebugByDepth,

	-- each nested layer occupies two indexes: 1. table ref 2. nested depth
	-- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
	nested_stack: { {} | number },
}

local free_cache: Cache?

local function getOrCreateActionQueue(actions: ActionQueueByPriority, priority: number): Array<(Instance) -> ()>
	local queue = actions[priority]
	if queue == nil then
		queue = {}
		actions[priority] = queue
	end

	return queue
end

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
			actions = {},
			parent = nil,
			nested_debug = {},
			nested_stack = {},
		}
	end
end

local function return_cache(cache: Cache)
	free_cache = cache
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
				if is_action(value) then
					local queued = getOrCreateActionQueue(cache.actions, (value :: any).priority)
					queued[#queued + 1] = (value :: any).callback :: (Instance) -> () -- add action to buffer
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

-- applies table of nested properties to an instance using full vide semantics
local function apply<T>(instance: T & Instance, properties: { [unknown]: unknown }): T
	if not properties then
		error "attempt to call a constructor returned by create() with no properties"
	end

	local caches = borrow_cache()
	local events = caches.events
	local actions = caches.actions
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

	local priorities = table.create(4)
	for priority in actions do
		priorities[#priorities + 1] = priority
	end
	table.sort(priorities)

	for _, priority in priorities do
		local queued = actions[priority]
		if queued then
			for _, callback in queued do
				callback(instance)
			end
		end
	end

	local parent = caches.parent
	if parent then
		if type(parent) == "function" then
			implicit_effect.parent(instance, parent :: () -> Instance)
		else
			instance.Parent = parent :: Instance
		end
	end

	table.clear(events)
	for _, queued in actions do
		table.clear(queued)
	end
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
