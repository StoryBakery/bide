local typeof = game and typeof or require("../../tests/reactive-test/mock").typeof :: never

local graph = require("./graph")
local get_scope = graph.get_scope
local push_cleanup = graph.push_cleanup

local function helper(obj: any)
	local objectType = type(obj)
	return if typeof(obj) == "RBXScriptConnection"
		then function()
			obj:Disconnect()
		end
		elseif objectType == "thread" then function()
			task.cancel(obj)
		end
		elseif typeof(obj) == "Instance" then function()
			obj:Destroy()
		end
		elseif objectType == "table" and type(obj.destroy) == "function" then function()
			(obj :: any):destroy()
		end
		elseif objectType == "table" and type(obj.disconnect) == "function" then function()
			(obj :: any):disconnect()
		end
		elseif objectType == "table" and type(obj.Destroy) == "function" then function()
			(obj :: any):Destroy()
		end
		elseif objectType == "table" and type(obj.Disconnect) == "function" then function()
			(obj :: any):Disconnect()
		end
		else error "cannot cleanup given object"
end

local function cleanup(value: unknown)
	local scope = get_scope()

	if not scope then
		error "cannot cleanup outside a stable or reactive scope"
	end
	assert(scope)

	if type(value) == "function" then
		push_cleanup(scope, value :: () -> ())
	else
		push_cleanup(scope, helper(value))
	end
end

return cleanup
