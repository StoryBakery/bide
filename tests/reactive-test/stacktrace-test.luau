local reactive = require("../../src/Reactive")

local function source<T>(initialValue: T, options: { equals: boolean | ((T, T) -> boolean)? }?)
	local value, setValue = reactive.signal(initialValue, options)

	return function(...): T
		if select("#", ...) == 0 then
			return value()
		end

		return setValue((... :: any) :: T)
	end
end

do
	print "============================================================="

	local a = source(1)

	local cause_error = false

	local function try_error()
		if cause_error then
			error("uh oh")
		end
	end

	reactive.root(function()
		reactive.effect(function()
			a()
			try_error()
		end)
	end)

	cause_error = true

	local ok, result = pcall(function()
		a(2)
	end)
	print(result)

	print "============================================================="
end

do
	print "============================================================="

	local a = source(1)
	local b = source(1)
	local c = source(1)

	local cause_error = false

	local function try_error()
		if cause_error then
			error("uh oh")
		end
	end

	reactive.root(function()
		reactive.effect(function()
			a()
			b(reactive.untrack(b) + 1)
		end)

		reactive.effect(function()
			b()
			c(reactive.untrack(c) + 1)
		end)

		reactive.effect(function()
			c()
			try_error()
		end)
	end)

	cause_error = true

	local ok, result = pcall(function()
		a(2)
	end)
	print(result)

	print "============================================================="
end

do
	print "============================================================="

	local a = source(1)
	local b = source(1)
	local c = source(1)

	local cause_error = false

	local function try_error()
		if cause_error then
			error("uh oh")
		end
	end

	reactive.root(function()
		reactive.effect(function()
			a()
			reactive.untrack(function() -- todo: this trace appearing twice
				b(b() + 1)
				return nil
			end)
		end)

		reactive.effect(function()
			b()
			reactive.batch(function()
				c(reactive.untrack(c) + 1)
			end)
		end)

		reactive.effect(function()
			c()
			try_error()
		end)
	end)

	cause_error = true

	local ok, result = pcall(function()
		a(2)
	end)
	print(result)

	print "============================================================="
end
