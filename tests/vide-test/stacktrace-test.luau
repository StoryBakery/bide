local vide = require("../../src/vide")

local function source<T>(initialValue: T, options: { equals: boolean | ((T, T) -> boolean)? }?)
	local value, setValue = vide.signal(initialValue, options)

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

	vide.root(function()
		vide.effect(function()
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

	vide.root(function()
		vide.effect(function()
			a()
			b(vide.untrack(b) + 1)
		end)

		vide.effect(function()
			b()
			c(vide.untrack(c) + 1)
		end)

		vide.effect(function()
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

	vide.root(function()
		vide.effect(function()
			a()
			vide.untrack(function() -- todo: this trace appearing twice
				b(b() + 1)
				return nil
			end)
		end)

		vide.effect(function()
			b()
			vide.batch(function()
				c(vide.untrack(c) + 1)
			end)
		end)

		vide.effect(function()
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
