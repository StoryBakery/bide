--[=[
	@class Props

	props 유틸리티 모듈. extract/merge 두 함수로 모든 props 처리를 수행합니다.
]=]

local Modifier = require("../Modifier")
local RunService = game:GetService("RunService")

local Props = {}
local ENABLE_SCHEMA_VALIDATION = RunService:IsStudio()

type SchemaDescriptor = {
	_isPropsSchemaDescriptor: true,
	Required: boolean,
	Kind: "Mixed" | "Accessor" | "Static",
}

local function createSchemaDescriptor(
	required: boolean,
	kind: "Mixed" | "Accessor" | "Static"
): SchemaDescriptor
	return {
		_isPropsSchemaDescriptor = true,
		Required = required,
		Kind = kind,
	}
end

local function isSchemaDescriptor(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	return (value :: any)._isPropsSchemaDescriptor == true
end

local function validateSchemaProp(key: string, descriptor: SchemaDescriptor, value: any)
	if value == nil then
		if descriptor.Required then
			error(`Missing required prop "{key}"`)
		end

		return
	end

	if descriptor.Kind == "Accessor" and type(value) ~= "function" then
		error(`Invalid prop "{key}": accessor function is required`)
	end

	if descriptor.Kind == "Static" and type(value) == "function" then
		error(`Invalid prop "{key}": static value is required`)
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
	스키마 테이블에서 owned key Set을 생성합니다.
]=]
function Props.keySetFromSchema(schema: { [string]: any }): { [string]: true }
	local set: { [string]: true } = {}
	for key in schema do
		set[key] = true
	end
	return set
end

--[=[
	required mixed prop (정적 값 또는 Accessor) 스키마 엔트리를 생성합니다.
]=]
function Props.required<T>(): T | (() -> T)
	return createSchemaDescriptor(true, "Mixed") :: any
end

--[=[
	optional mixed prop (정적 값 또는 Accessor) 스키마 엔트리를 생성합니다.
]=]
function Props.optional<T>(): (T | (() -> T))?
	return createSchemaDescriptor(false, "Mixed") :: any
end

--[=[
	required accessor-only prop 스키마 엔트리를 생성합니다.
]=]
function Props.requiredAccessor<T>(): () -> T
	return createSchemaDescriptor(true, "Accessor") :: any
end

--[=[
	optional accessor-only prop 스키마 엔트리를 생성합니다.
]=]
function Props.optionalAccessor<T>(): (() -> T)?
	return createSchemaDescriptor(false, "Accessor") :: any
end

--[=[
	required static-only prop 스키마 엔트리를 생성합니다.
]=]
function Props.requiredStatic<T>(): T
	return createSchemaDescriptor(true, "Static") :: any
end

--[=[
	optional static-only prop 스키마 엔트리를 생성합니다.
]=]
function Props.optionalStatic<T>(): T?
	return createSchemaDescriptor(false, "Static") :: any
end

--[=[
	props 에서 숫자 인덱스 자식들이 action 인지 판별합니다.
]=]
function Props.isAction(child: any): boolean
	if type(child) == "table" and type(child[1]) == "function" then
		return true
	end
	return false
end

--[=[
	props에서 owned/forward/children을 분리합니다.
	owned: owned table에 포함된 string key props
	forward: 나머지 string key props
	children: 숫자 인덱스 자식들 (Modifier 는 풀어서 forward에 병합)
]=]
function Props.extract(
	props: { [any]: any },
	ownedKeySet: { [string]: any }
): ({ [string]: any }, { [any]: any }, { any })
	local owned: { [string]: any } = {}
	local forward: { [any]: any } = {}
	local children: { any } = {}
	local schemaDescriptorByKey = {} :: { [string]: SchemaDescriptor }

	for key, value in props do
		if type(key) == "number" then
			if Modifier.isModifier(value) then
				for mKey, mVal in value do
					if type(mKey) == "number" then
						children[#children + 1] = mVal
					else
						forward[mKey] = mVal
					end
				end
			else
				children[#children + 1] = value
			end
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

	return owned, forward, children
end

function Props.splitProps(
	props: { [any]: any },
	ownedKeySet: { [string]: any }
): ({ [string]: any }, { [any]: any })
	local owned, forward, children = Props.extract(props, ownedKeySet)
	Props.appendChildren(forward, children)
	return owned, forward
end

function Props.composeProps(
	base: { [any]: any },
	override: { [any]: any }?,
	childrenOrProps: { [any]: any }?
): { [any]: any }
	local result = table.clone(base)

	if override then
		for key, value in override do
			result[key] = value
		end
	end

	if childrenOrProps then
		for key, value in childrenOrProps do
			if type(key) == "number" then
				Props.appendChild(result, value)
			else
				result[key] = value
			end
		end
	end

	return result
end

--[=[
	base 위에 override를 덮어씌워 새 테이블을 반환합니다.
]=]
function Props.merge(base: { [any]: any }, override: { [any]: any }): { [any]: any }
	local result = table.clone(base)
	for key, value in override do
		result[key] = value
	end
	return result
end

--[=[
	숫자 인덱스 자식을 맨 뒤에 추가합니다.
]=]
function Props.appendChild(target: { [any]: any }, child: any)
	local index = 1
	while target[index] ~= nil do
		index += 1
	end
	target[index] = child
end

--[=[
	숫자 인덱스 자식을 맨 앞에 삽입합니다.
]=]
function Props.prependChild(target: { [any]: any }, child: any)
	local count = 0
	while target[count + 1] ~= nil do
		count += 1
	end
	for i = count, 1, -1 do
		target[i + 1] = target[i]
	end
	target[1] = child
end

--[=[
	배열의 모든 원소를 target에 추가합니다.
]=]
function Props.appendChildren(target: { [any]: any }, children: { any })
	for _, child in children do
		Props.appendChild(target, child)
	end
end

return Props
