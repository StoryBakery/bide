local flags = require("./flags")

export type SignalNode<T> = {
	cache: T,
	[number]: Node<T>,
}

export type Node<T> = {
	cache: any,
	effect: ((...any) -> any) | false,
	cleanups: { () -> () } | false,

	context: { [any]: unknown } | false,

	owned: { Node<T> } | false,
	owner: Node<T> | false,

	parents: { SignalNode<T> },
	[number]: Node<T>, -- children
}

local scopes = { n = 0 } :: { [number]: Node<any>, n: number } -- scopes stack

local function efn(err: string)
	local trace = debug.traceback(err, 2)

	if string.find(err, "^effect error stacktrace") then -- if effect error is nested
		trace = string.gsub("    " .. trace, "\n", function() -- indent entire error
			return "\n    "
		end)
	end

	trace ..= "\nsignal update stacktrace:"
	return trace
end

local function ycall(fn: (...any) -> any, arg: any): (boolean, any)
	local thread = coroutine.create(xpcall)
	--local function efn(err: string) return debug.traceback(err, 3) end
	local resume_ok, run_ok, result = coroutine.resume(thread, fn, efn, arg)

	assert(resume_ok)

	if coroutine.status(thread) ~= "dead" then
		return false, debug.traceback(thread, "attempt to yield in reactive scope")
	end

	return run_ok, result
end

local function get_scope(): Node<any>?
	return scopes[scopes.n]
end

local function assert_stable_scope(): Node<any>
	local scope = get_scope()

	if not scope then
		local caller_name = debug.info(2, "n")
		return error(`cannot use {caller_name}() outside a stable or reactive scope`, 0)
	end

	return scope
end

local function push_child(parent: SignalNode<any>, child: Node<any>)
	parent[#parent + 1] = child
	child.parents[#child.parents + 1] = parent
end

local function push_scope(node: Node<any>)
	local n = scopes.n + 1
	scopes.n = n
	scopes[n] = node
end

local function pop_scope()
	local n = scopes.n
	scopes.n = n - 1
	scopes[n] = nil
end

local function is_scope_active(node: Node<any>): boolean
	for index = 1, scopes.n do
		if scopes[index] == node then
			return true
		end
	end

	return false
end

local function push_cleanup(node: Node<any>, cleanup: () -> ())
	if node.cleanups then
		node.cleanups[#node.cleanups + 1] = cleanup
	else
		node.cleanups = { cleanup }
	end
end

local function flush_cleanups(node: Node<any>)
	if node.cleanups then
		for _, fn in node.cleanups do
			local result = { pcall(fn) }
			local ok = result[1]
			local err = result[2]
			if not ok then
				error(`cleanup error: {tostring(err)}`, 0)
			end
		end

		table.clear(node.cleanups)
	end
end

local function find_and_swap_pop<T>(t: { T }, v: T)
	local i = table.find(t, v)
	if i == nil then
		return
	end
	local n = #t
	t[i] = t[n]
	t[n] = nil
end

local function unparent(node: Node<any>)
	local parents = node.parents

	for i, parent in parents do
		find_and_swap_pop(parent :: { Node<any> }, node)
		parents[i] = nil
	end
end

local function destroy(node: Node<any>)
	if flags.strict and is_scope_active(node) then
		error("attempt to destroy an active scope", 0)
	end

	flush_cleanups(node)
	unparent(node)

	if node.owner then
		find_and_swap_pop(node.owner.owned :: { Node<any> }, node)
		node.owner = false
	end

	if node.owned then
		local owned = node.owned
		while owned[1] do
			destroy(owned[1])
		end
	end
end

local function destroy_owned(node: Node<any>)
	if node.owned then
		local owned = node.owned
		while owned[1] do
			destroy(owned[1])
		end
	end
end

local update_queue = { n = 0 } :: { n: number, [number]: Node<any> }

local function evaluate_node(node: Node<any>)
	if flags.strict then
		if is_scope_active(node) then
			error("a scope, that should rerun due to the update of a signal, is already active", 0)
		end

		local initial_value = node.cache
		local cur_value = node.cache

		flush_cleanups(node)
		destroy_owned(node)

		push_scope(node)
		local ok, new_value = ycall(node.effect :: (...any) -> any, cur_value)
		pop_scope()

		if not ok then
			table.clear(update_queue)
			update_queue.n = 0
			error(`effect error stacktrace\n{new_value :: string}`, 0)
		end

		node.cache = new_value

		return initial_value ~= node.cache
	else
		local cur_value = node.cache

		flush_cleanups(node)
		destroy_owned(node)

		push_scope(node)
		local ok, new_value = pcall(node.effect :: (...any) -> any, node.cache)
		pop_scope()

		if not ok then
			table.clear(update_queue)
			update_queue.n = 0
			error(`effect error:\n{new_value}\n`, 0)
		end

		node.cache = new_value
		return cur_value ~= new_value
	end
end

local function queue_children_for_update(node: SignalNode<any>)
	local i = update_queue.n
	while node[1] do
		i += 1
		update_queue[i] = node[1]
		unparent(node[1])
	end
	update_queue.n = i
end

local function get_update_queue_length()
	return update_queue.n
end

local function flush_update_queue(from: number)
	local i = from + 1
	while i <= update_queue.n do
		local node = update_queue[i]
		--assert(node.effect)

		if node.owner and evaluate_node(node) then
			queue_children_for_update(node)
		end

		update_queue[i] = false :: any
		i += 1
	end

	update_queue.n = from
end

local function update_descendants(root: SignalNode<any>)
	local n0 = update_queue.n
	queue_children_for_update(root)

	if flags.batch then
		return
	end

	local i = n0 + 1
	while i <= update_queue.n do
		local node = update_queue[i]
		--assert(node.effect)

		-- check if node is still owned in case destroyed after queued
		if node.owner and evaluate_node(node) then
			queue_children_for_update(node)
		end

		update_queue[i] = false :: any -- false instead of nil to avoid sparse
		i += 1
	end

	update_queue.n = n0
end

local function push_scope_as_child_of(node: SignalNode<any>)
	local scope = get_scope()
	if scope and scope.effect then -- do not track nodes with no effect
		push_child(node, scope)
	end
end

local function create_node(
	owner: false | Node<any>,
	effect: false | ((...any) -> any),
	value: any
): Node<any>
	local node: Node<any> = {
		cache = value,
		effect = effect,
		cleanups = false,

		context = false,

		owner = owner,
		owned = false,

		parents = {},
	}

	if owner then
		if owner.owned then
			owner.owned[#owner.owned + 1] = node
		else
			owner.owned = { node }
		end
	end

	return node
end

local function create_signal_node(value: any): SignalNode<any>
	return { cache = value } :: SignalNode<any>
end

local function get_children(node: Node<any>): { Node<any> }
	local children = table.create(#node) :: { Node<any> }
	for index = 1, #node do
		children[index] = node[index] :: Node<any>
	end

	return children
end

local function set_context(node: Node<any>, key: any, value: unknown)
	if node.context then
		node.context[key] = value
	else
		node.context = { [key] = value }
	end
end

return table.freeze {
	push_scope = push_scope,
	pop_scope = pop_scope,
	evaluate_node = evaluate_node,
	get_scope = get_scope,
	assert_stable_scope = assert_stable_scope,
	push_cleanup = push_cleanup,
	destroy = destroy,
	flush_cleanups = flush_cleanups,
	push_scope_as_child_of = push_scope_as_child_of,
	update_descendants = update_descendants,
	push_child = push_child,
	create_node = create_node,
	create_signal_node = create_signal_node,
	get_children = get_children,
	flush_update_queue = flush_update_queue,
	get_update_queue_length = get_update_queue_length,
	set_context = set_context,
	scopes = scopes,

	q = update_queue,
}
