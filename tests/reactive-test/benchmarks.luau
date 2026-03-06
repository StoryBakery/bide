--!nonstrict
local testkit = require("./testkit")
local BENCH, START = testkit.benchmark()

local Instance = require("../../src/Instance")
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

local memo = reactive.memo
local effect = reactive.effect
local indexes = reactive.indexes
local values = reactive.values
local batch = reactive.batch
local cleanup = reactive.cleanup
local untrack = reactive.untrack
local createContext = reactive.createContext
local useContext = reactive.useContext
local create = Instance.create
local derive = memo

local function context<T>(defaultValue: T?)
	local contextObject = createContext(defaultValue)

	return function(...): any
		local argumentCount = select("#", ...)

		if argumentCount == 0 then
			return useContext(contextObject :: any)
		end

		local value = select(1, ...)
		local children = select(2, ...)
		if type(children) ~= "function" then
			error("attempt to set context without a children callback", 0)
		end

		return contextObject.Provider({
			value = value,
			children = children,
		})
	end
end

assert(not reactive.strict)

local function TITLE(name: string)
	print()
	print(testkit.color.white(name))
end

local function ROOT_BENCH(name: string, fn: () -> ())
	reactive.root(function(destroy)
		BENCH(name, fn)
		return destroy
	end)()
end

local N = 2 ^ 20

TITLE "sources"

BENCH("create source", function()
	local cache = table.create(N)

	for i = 1, START(N) do
		cache[i] = source(1)
	end
end)

BENCH("get value", function()
	local src = source(1)

	for i = 1, START(N) do
		src()
	end
end)

BENCH("set value", function()
	local src = source(1)

	for i = 1, START(N) do
		src(i)
	end
end)

ROOT_BENCH("derive 1 source", function()
	local cache = table.create(N)
	local src = source(1)

	for i = 1, START(N) do
		cache[i] = derive(function()
			return src()
		end)
	end
end)

ROOT_BENCH("derive 4 sources", function()
	local cache = table.create(N)
	local src = source(1)
	local src2 = source(2)
	local src3 = source(3)
	local src4 = source(4)

	for i = 1, START(N) do
		cache[i] = derive(function()
			return src() + src2() + src3() + src4()
		end)
	end
end)

TITLE "graphs"

ROOT_BENCH("update 1->1 graph", function()
	local src = source(1)

	local _derived = derive(function()
		return src()
	end)

	for i = 1, START(N) do
		src(i)
	end
end)

ROOT_BENCH("update 1->1 graph with cleanup", function()
	local src = source(1)

	derive(function()
		cleanup(function() end)
		return src()
	end)

	for i = 1, START(N) do
		src(i)
	end
end)

ROOT_BENCH("update 1->1000 graph", function()
	local src = source(-1)

	for i = 1, 1000 do
		derive(function()
			return src()
		end)
	end

	src(0)

	for i = 1, START(10) do
		src(i)
	end
end)

ROOT_BENCH("update 1->1->1->1...1000 graph", function()
	local src = source(-1)

	local last = src
	for i = 1, 1000 do
		local l = last
		last = derive(function()
			return l()
		end)
	end

	src(0)

	for i = 1, START(10) do
		src(i)
	end
end)

-- todo: why does it hang at 1k? it didn't before
ROOT_BENCH("update 500->1 graph", function()
	local srcs = {}
	for i = 1, 500 do
		srcs[i] = source(0)
	end

	derive(function()
		for i = 1, 500 do
			srcs[i]()
		end
		return false
	end)

	for i = 1, START(1) do
		for idx = 1, 500 do
			srcs[idx](i)
		end
	end
end)

ROOT_BENCH("update 1000->1 graph (batched)", function()
	local srcs = {}
	for i = 1, 1000 do
		srcs[i] = source(0)
	end

	derive(function()
		for i = 1, 1000 do
			srcs[i]()
		end
		return false
	end)

	for i = 1, START(1) do
		batch(function()
			for idx = 1, 1000 do
				srcs[idx](i)
			end
		end)
	end
end)

-- todo: optimize this case
ROOT_BENCH("update 1000 1->1 common extern. graph", function()
	local ext = source(-1)

	local srcs = {}
	for i = 1, 1000 do
		srcs[i] = source(0)
		derive(function()
			return srcs[i]() + ext()
		end)
	end

	ext(0)

	for i = 1, START(10) do
		for idx = 1, 1000 do
			srcs[idx](i)
		end
	end
end)

TITLE "property apply"

ROOT_BENCH("apply 0 properties", function()
	local apply = require("../../src/Instance/apply")
	local instance = create("Frame") {}

	for i = 1, START(N) do
		apply(instance, {})
	end
end)

ROOT_BENCH("apply 8 properties", function()
	local apply = require("../../src/Instance/apply")
	local instance = create("Frame") {}

	for i = 1, START(N) do
		apply(instance, {
			Text = i,
			Text2 = i,
			Text3 = i,
			Text4 = i,
			Text5 = i,
			Text6 = i,
			Text7 = i,
			Text8 = i,
		})
	end
end)

ROOT_BENCH("bind property", function()
	local apply = require("../../src/Instance/apply")

	local instance = create("Frame") {}
	local src = source(1)

	for i = 1, START(N) do
		apply(instance, {
			Text = src,
		})
	end

	return nil
end)

ROOT_BENCH("update binding", function()
	local apply = require("../../src/Instance/apply")

	local instance = create("Frame") {}
	local src = source(1)

	apply(instance, {
		Text = src,
	})

	for i = 1, START(N) do
		src(i)
	end

	return nil
end)

TITLE "switch()"

ROOT_BENCH("switch()", function()
	local M = 2 ^ 8

	local map = {}
	for i = 1, M do
		map[i] = function()
			return i
		end
	end

	local input = source(0)
	reactive.switch(input)(map)

	for i = 1, START(N) do
		input(bit32.band(i, M - 1) + 1) -- i % m + 1
	end
end)

TITLE "indexes()"

N /= 1024

ROOT_BENCH("indexes() all new", function()
	local data = {}

	for i = 1, N do
		data[i] = i
	end

	local src = source(data)

	START(N)

	local _list = indexes(src, function(v, i)
		return {}
	end)

	return nil
end)

ROOT_BENCH("indexes() no change", function()
	local data = {}

	for i = 1, N do
		data[i] = i
	end

	local src = source(data)

	local _list = indexes(src, function(v, i)
		return {}
	end)

	START(N)

	src(data)

	return nil
end)

ROOT_BENCH("indexes() all change", function()
	local data = {}

	for i = 1, N do
		data[i] = i
	end

	local src = source(data)

	local _list = indexes(src, function(v, i)
		return {}
	end)

	--src(src()) -- fill double buffer

	for i, v in data do
		data[i] = v + 1
	end

	START(N)

	src(data)
end)

ROOT_BENCH("indexes() all remove", function()
	local data = {}

	for i = 1, N do
		data[i] = i
	end

	local src = source(data)

	local _list = indexes(src, function(v, i)
		return {}
	end)

	table.clear(data)

	START(N)

	src(data)

	return nil
end)

TITLE "values()"

ROOT_BENCH("values() all new", function()
	local data = {}

	for i = 1, N do
		data[i] = {}
	end

	local src = source(data)

	START(N)

	local _list = values(src, function(v, i)
		return {}
	end)

	return nil
end)

ROOT_BENCH("values() no change", function()
	local data = {}

	for i = 1, N do
		data[i] = {}
	end

	local src = source(data)

	local _list = values(src, function(v, i)
		return {}
	end)

	src(src()) -- fill double buffer

	START(N)

	src(data)
end)

ROOT_BENCH("values() all change", function()
	local data = {}

	for i = 1, N do
		data[i] = {}
	end

	local src = source(data)

	local _list = values(src, function(v, i)
		return {}
	end)

	src(src()) -- fill double buffer

	for i = 1, N do
		local r = math.random(1, #data)
		data[i], data[r] = data[r], data[i]
	end

	START(N)

	src(data)
end)

ROOT_BENCH("values() all remove", function()
	local data = {}

	for i = 1, N do
		data[i] = {}
	end

	local src = source(data)

	local _list = values(src, function(v, i)
		return {}
	end)

	table.clear(data)

	START(N)

	src(data)
end)

TITLE "context()"

ROOT_BENCH("set context", function()
	local ctx = context()

	for i = 1, START(N) do
		ctx(i, function() end)
	end
end)

ROOT_BENCH("get context (depth=1)", function()
	local ctx = context()

	local function run()
		for i = 1, START(N) do
			ctx()
		end
	end

	ctx(1, function()
		run()
	end)
end)

local depth = 10
ROOT_BENCH(`get context (depth={depth})`, function()
	local ctx = context()

	local function run()
		for i = 1, START(N) do
			ctx()
		end
	end

	local function nest_effect(fn)
		untrack(function()
			effect(fn)
			return nil
		end)
	end

	local f = run
	for i = 1, depth - 1 do
		local f_inner = f
		f = function()
			nest_effect(f_inner)
		end
	end

	ctx(1, function()
		f()
	end)
end)

return nil
