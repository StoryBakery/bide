local branch = require("./branch")
local effect = require("./effect")
local flags = require("./flags")
local signal = require("./signal")
local timeout = require("./timeout")

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type SignalAccessor<T> = signal.SignalAccessor<T>
type SignalSetter<T> = signal.SignalSetter<T>

local function values<K, V, Obj>(
	input: SignalAccessor<Map<K, V>>,
	component: (
		V,
		SignalAccessor<K>,
		SignalAccessor<boolean>
	) -> (Obj, ...number)
): SignalAccessor<Array<Obj>>
	type Scope = {
		destroy: () -> (),
		object: Obj,
		value: V,
		index: K?,
		setIndex: SignalSetter<K>,
		count: number,
		delay: number,
		present: SignalAccessor<boolean>,
		setPresent: SignalSetter<boolean>,
		timeout: { cancel: boolean }?,
	}

	local updateCount = 0
	local scopes = {} :: Array<Scope>

	local output, setOutput = signal({} :: Array<Obj>)
	local function updateOutput()
		local objects = table.create(#scopes) :: Array<Obj>

		for i, scope in scopes do
			objects[i] = scope.object
		end

		setOutput(objects)
	end

	local function removeScope(scopeToRemove: Scope)
		for i, scope in scopes do
			if scope == scopeToRemove then
				table.remove(scopes, i)
				return
			end
		end
	end

	effect(function()
		local data = input()

		local count = updateCount
		updateCount += 1

		local childrenNeedUpdate = false -- set to true if a scope is created or destroyed
		local previousScopes = scopes

		if flags.strict then -- check for duplicate values
			local map = {}
			for _, v in data do
				if map[v] then
					error("input passed to `values()` contains duplicate values", 0)
				end
				map[v] = true
			end
		end

		local reusableScopeListsByValue = {} :: Map<V, Array<Scope>>
		for _, scope in previousScopes do
			local reusableScopes = reusableScopeListsByValue[scope.value]
			if reusableScopes == nil then
				reusableScopes = {}
				reusableScopeListsByValue[scope.value] = reusableScopes
			end

			reusableScopes[#reusableScopes + 1] = scope
		end

		local reusableScopeIndexesByValue = {} :: Map<V, number>
		local nextActiveScopes = table.create(4) :: Array<Scope>

		-- create or update scopes
		for i, v in data do
			local reusableScopes = reusableScopeListsByValue[v]
			local scope = nil :: Scope?
			if reusableScopes ~= nil then
				local reusableScopeIndex = (reusableScopeIndexesByValue[v] or 0) + 1
				reusableScopeIndexesByValue[v] = reusableScopeIndex
				scope = reusableScopes[reusableScopeIndex]
			end

			if scope == nil then -- create new scope and create component
				local index, setIndex = signal(i)
				local present, setPresent = signal(false)

				local delaySeconds = nil :: number?
				local destroy, object = branch(function()
					local childObject, childDelay = component(v, index, present)
					delaySeconds = childDelay
					return childObject
				end)

				setPresent(true)

				childrenNeedUpdate = true

				scope = {
					destroy = destroy,
					object = object,
					value = v,
					index = i,
					setIndex = setIndex,
					count = count,
					delay = delaySeconds or 0,
					present = present,
					setPresent = setPresent,
					timeout = nil,
				}
			else -- update scope
				scope.count = count

				if scope.timeout then -- value is in input table again; cancel destruction
					scope.timeout.cancel = true
					scope.timeout = nil
					scope.setPresent(true)
				end

				if (scope.index :: any) ~= (i :: any) then
					scope.index = i
					scope.setIndex(i)
				end
			end

			nextActiveScopes[#nextActiveScopes + 1] = scope :: Scope
		end

		-- destroy scopes
		for _, scope in previousScopes do
			if scope.count < count then -- if count is not latest then value is no longer in the input table
				scope.setPresent(false)

				if scope.delay == 0 then
					scope.destroy()
					childrenNeedUpdate = true
				else
					scope.index = nil -- set to nil for the `scope.index ~= i` check
					if scope.timeout == nil then
						scope.timeout = timeout(
							scope.delay,
							function() -- todo: possible redundant updates
								scope.destroy()
								removeScope(scope)
								updateOutput()
							end
						)
					end
				end
			end
		end

		local nextScopes = table.create(#nextActiveScopes) :: Array<Scope>
		for _, scope in nextActiveScopes do
			nextScopes[#nextScopes + 1] = scope
		end

		for _, scope in previousScopes do
			if scope.timeout ~= nil then
				nextScopes[#nextScopes + 1] = scope
			end
		end

		local orderChanged = #previousScopes ~= #nextScopes
		if not orderChanged then
			for i, scope in previousScopes do
				if nextScopes[i] ~= scope then
					orderChanged = true
					break
				end
			end
		end

		scopes = nextScopes

		if childrenNeedUpdate or orderChanged then
			updateOutput()
		end
	end)

	return output
end

return values
