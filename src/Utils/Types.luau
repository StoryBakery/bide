local Types = {}

export type action = (
	(Instance) -> (),
	priority: number?
) -> {
	priority: number,
	callback: (Instance) -> (),
}

export type child =
	Instance
	| (() -> child?) -- 반응적으로 자식을 바꾸고 싶을 때
	| { [number]: child } -- 트리 (배열처럼)
	| action

export type function props(props: type)
	for key, prop in props:properties() do
		local readType = (prop.read or types.any) :: type

		props:setproperty(
			key,
			types.unionof(readType, types.newfunction({}, { head = { readType } }))
		)
	end

	props:setindexer(types.number, types.any)

	return props
end

export type prop<T> = T | () -> T

--[[
	Behavior 의 setup 함수가 반환하는 정리 핸들입니다.
]]
export type BehaviorHandle = {
	Destroy: () -> (),
	Update: (() -> ())?,
}

--[[
	InteractionState: 하나의 GuiObject에 대한 통합 상호작용 상태입니다.
	여러 Behavior가 이벤트를 중복 연결하지 않고 이 상태를 공유합니다.
]]
export type InteractionState = {
	isHovered: () -> boolean,
	isPressed: () -> boolean,
	pressInputObject: () -> InputObject?,
	Destroy: () -> (),
}

return Types
