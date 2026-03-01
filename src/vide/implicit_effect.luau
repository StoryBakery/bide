local graph = require("./graph")
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local assert_stable_scope = graph.assert_stable_scope
local get_scope = graph.get_scope
local evaluate_node = graph.evaluate_node
local push_cleanup = graph.push_cleanup

type Child = any

local function update_property_effect(p: {
	instance: Instance,
	property: string,
	source: () -> unknown,
})
	(p.instance :: any)[p.property] = p.source()
	return p
end

local function update_parent_effect(p: {
	instance: Instance,
	source: () -> Instance,
})
	p.instance.Parent = p.source()
	return p
end

-- todo: investigate if "count" method used in indexes() and values() can improve performance here
local function update_children_effect(p: {
	instance: Instance,
	cur_children_set: { [Instance]: true },
	new_children_set: { [Instance]: true },
	source: () -> Child,
})
	local cur_children_set: { [Instance]: true } = p.cur_children_set -- cache of all children parented before update
	local new_children_set: { [Instance]: true } = p.new_children_set -- cache of all children parented after update

	local new_children = p.source() -- all (and only) children that should be parented after this update

	local function process_child(child: Child)
		if type(child) == "userdata" then
			local childInstance = child :: Instance

			if new_children_set[childInstance] then
				return
			end -- stops redundant reparenting

			new_children_set[childInstance] = true -- record child set from this update

			if not cur_children_set[childInstance] then
				childInstance.Parent = p.instance -- if child wasn't already parented then parent it
			else
				cur_children_set[childInstance] = nil -- remove child from cache if it was already in cache
			end
		elseif type(child) == "table" then
			for _, nestedChild in child :: { any } do
				process_child(nestedChild)
			end
		elseif type(child) == "function" then
			local childSource = child :: () -> Child
			local node = create_node(assert(get_scope()), update_children_effect :: any, {
				instance = p.instance,
				cur_children_set = {},
				new_children_set = {},
				source = childSource,
			})

			evaluate_node(node)

			push_cleanup(assert(get_scope()), function()
				local cache = node.cache :: { cur_children_set: { [Instance]: true } }
				for child in cache.cur_children_set do
					child.Parent = nil
				end
			end)
		end
	end

	process_child(new_children)

	for child in cur_children_set do
		child.Parent = nil -- unparent all children that weren't in the new children set
	end

	table.clear(cur_children_set) -- clear cache, preserve capacity
	p.cur_children_set, p.new_children_set = new_children_set, cur_children_set

	return p
end

return {
	property = function(instance, property, source)
		local node = create_node(assert_stable_scope(), update_property_effect :: any, {
			instance = instance,
			property = property,
			source = source,
		})

		evaluate_node(node)

		return node
	end,

	parent = function(instance, parent)
		local node = create_node(assert_stable_scope(), update_parent_effect :: any, {
			instance = instance,
			source = parent,
		})

		evaluate_node(node)

		return node
	end,

	children = function(instance, children)
		local node = create_node(assert_stable_scope(), update_children_effect :: any, {
			instance = instance,
			cur_children_set = {},
			new_children_set = {},
			source = children,
		})

		evaluate_node(node)

		push_cleanup(assert_stable_scope(), function()
			local cache = node.cache :: { cur_children_set: { [Instance]: true } }
			for child in cache.cur_children_set do
				child.Parent = nil
			end
		end)

		return node
	end,
}
