local typeof = game and typeof or require("../../tests/vide-test/mock").typeof :: never
local Instance = game and Instance or require("../../tests/vide-test/mock").Instance :: never

local apply = require("./apply")
local defaults = require("./defaults")
local flags = require("./flags")

type AnyProps = { [any]: any }

local ctor_cache = {} :: { [string]: (AnyProps) -> Instance }
local function lazy_init(_, class: string)
	local function ctor(properties: AnyProps): Instance
		local ok, instance: Instance = pcall(Instance.new, class :: any)
		if not ok then
			error(`invalid class name {class}`, 0)
		end

		if flags.defaults then
			local default: { [string]: unknown }? = (defaults :: any)[class]
			if default then
				for i, v in default do
					(instance :: any)[i] = v
				end
			end
		end

		return apply(instance, properties)
	end

	ctor_cache[class] = ctor
	return ctor
end
setmetatable(ctor_cache, { __index = lazy_init })

local function create(class_or_instance: string | Instance, properties: AnyProps?): any
	if type(class_or_instance) ~= "string" and typeof(class_or_instance) ~= "Instance" then
		error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
	end

	local ctor: (AnyProps) -> Instance = if type(class_or_instance) == "string"
		then ctor_cache[class_or_instance]
		else function(properties)
			local clone = class_or_instance:Clone()
			if not clone then
				error "attempt to clone a non-archivable instance"
			end
			return apply(clone, properties)
		end

	return if properties then ctor(properties) else ctor
end
return create :: any
