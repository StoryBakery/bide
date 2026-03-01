--[=[
	@class ElementResolver

	CullingListFrame의 요소 정렬/키/팩토리 해결 유틸리티입니다.
]=]

local vide = require("../../vide")

local read = vide.read

type ElementFactory = () -> GuiObject
type ElementLike = GuiObject | ElementFactory

local ElementResolver = {}

function ElementResolver.getElementKey(element: any, fallbackKey: any): any
	if element == nil then
		return fallbackKey
	end

	local entry = if type(element) == "table" then element :: any else nil

	if entry ~= nil then
		local entryAny = entry :: any
		if entry.Key ~= nil then
			return read(entry.Key)
		end

		if entryAny.Element ~= nil and type(entryAny.Element) == "table" then
			local nested = entryAny.Element :: any
			if nested.props and nested.props.key ~= nil then
				return read(nested.props.key)
			end

			if nested.key ~= nil then
				return read(nested.key)
			end
		end
	end

	return fallbackKey
end

function ElementResolver.getCompareElementInfo(sortOrder: string): (any, any) -> boolean
	if sortOrder == "Order" then
		return function(a: any, b: any)
			return (a.Order or math.huge) < (b.Order or math.huge)
		end
	elseif sortOrder == "Index" then
		return function(a: any, b: any)
			return (a.Index or 0) < (b.Index or 0)
		end
	elseif sortOrder == "Name" then
		return function(a: any, b: any)
			return tostring(a.Key) < tostring(b.Key)
		end
	end

	return function()
		return false
	end
end

function ElementResolver.resolveElementFactory(element: ElementLike): ElementFactory
	if type(element) == "function" then
		return element :: ElementFactory
	end

	return function()
		return element :: GuiObject
	end
end

--[[
	요소 목록을 정렬된 PropElementInfo 배열로 변환합니다.
]]
function ElementResolver.resolveElements(
	elements: { [any]: any },
	sortOrder: string
): ({ any }, { [number]: any }, number)
	local compareElementInfo = ElementResolver.getCompareElementInfo(sortOrder)
	local newPropElementInfosByIndex: { any } = {}
	local newElementKeysByIndex: { [number]: any } = {}
	local newElementCount = 0

	if sortOrder == "Index" then
		for index, element in elements do
			newElementCount += 1

			local info: { [any]: any } = {}
			info.Key = ElementResolver.getElementKey(element, index)
			info.ElementFactory = ElementResolver.resolveElementFactory(
				(
						if type(element) == "table" and element.Element ~= nil
							then element.Element
							else element
					) :: ElementLike
			)
			info.Index = index

			newPropElementInfosByIndex[#newPropElementInfosByIndex + 1] = info
		end
	else
		for name, element in elements do
			newElementCount += 1

			local info: { [any]: any } = {}

			if sortOrder == "Order" then
				local elementEntry = element :: any
				local child = elementEntry.Element or element

				info.Key = ElementResolver.getElementKey(elementEntry, name)
				info.ElementFactory = ElementResolver.resolveElementFactory(child)
				info.Order = read(elementEntry.Order) or math.huge
			else
				info.Key = ElementResolver.getElementKey(element, name)
				info.ElementFactory = ElementResolver.resolveElementFactory(
					(
							if type(element) == "table" and element.Element ~= nil
								then element.Element
								else element
						) :: ElementLike
				)
			end
			newPropElementInfosByIndex[#newPropElementInfosByIndex + 1] = info
		end
	end

	table.sort(newPropElementInfosByIndex, compareElementInfo)

	for index, elementInfo in newPropElementInfosByIndex do
		newElementKeysByIndex[index] = elementInfo.Key
	end

	return newPropElementInfosByIndex, newElementKeysByIndex, newElementCount
end

return ElementResolver
