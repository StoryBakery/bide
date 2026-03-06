--[=[
	@class Props

	props table에서 owned props와 forward props를 분리하는 유틸리티입니다.
]=]

local RunService = game:GetService("RunService")

local Props = {}
local ENABLE_SCHEMA_VALIDATION = RunService:IsStudio()

type SchemaDescriptor = {
	_isPropsSchemaDescriptor: true,
	Required: boolean,
}

local function createSchemaDescriptor(required: boolean): SchemaDescriptor
	return {
		_isPropsSchemaDescriptor = true,
		Required = required,
	}
end

local function isSchemaDescriptor(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	return (value)._isPropsSchemaDescriptor == true
end

local function validateSchemaProp(key: string, descriptor: SchemaDescriptor, value: any)
	if value == nil then
		if descriptor.Required then
			error(`Missing required prop "{key}"`)
		end

		return
	end
end

--[=[
	owned key 검색을 위한 Set을 생성합니다.
]=]
function Props.keySet(keys: { string }): { [string]: true }
	local set: { [string]: true } = {}
	for _, key in keys do
		set[key] = true
	end
	return set
end

--[=[
	required mixed prop (정적 값 또는 Accessor) 스키마 엔트리를 생성합니다.
]=]
function Props.required<T>(): T | (() -> T)
	return createSchemaDescriptor(true)
end

--[=[
	optional mixed prop (정적 값 또는 Accessor) 스키마 엔트리를 생성합니다.
]=]
function Props.optional<T>(): (T | (() -> T))?
	return createSchemaDescriptor(false)
end

--[=[
	props에서 owned/forward/children을 분리합니다.
	owned: owned table에 포함된 string key props
	forward: 나머지 string key props
	children: 숫자 인덱스 자식들
]=]
function Props.splitProps(
	props: { [any]: any },
	ownedKeySet: { [string]: any }
): ({ [string]: any }, { [any]: any }, { any })
	local owned: { [string]: any } = {}
	local forward: { [any]: any } = {}
	local children = table.create(#props)
	local schemaDescriptorByKey = {} :: { [string]: SchemaDescriptor }

	for key, value in props do
		if type(key) == "number" then
			continue
		elseif type(key) == "string" then
			if ownedKeySet[key] ~= nil then
				owned[key] = value

				if ENABLE_SCHEMA_VALIDATION then
					local descriptor = ownedKeySet[key]
					if isSchemaDescriptor(descriptor) then
						schemaDescriptorByKey[key] = descriptor
						validateSchemaProp(key, descriptor, value)
					end
				end
			else
				forward[key] = value
			end
		else
			forward[key] = value
		end
	end

	if ENABLE_SCHEMA_VALIDATION then
		for key, descriptor in ownedKeySet do
			if isSchemaDescriptor(descriptor) and schemaDescriptorByKey[key] == nil then
				validateSchemaProp(key, descriptor, owned[key])
			end
		end
	end

	if #props > 0 then
		table.move(props, 1, #props, 1, children)
	end

	return owned, forward, children
end

return Props
