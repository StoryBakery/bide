local Types = {}

export type attachment<T> = (T) -> unknown

export type child =
	Instance
	| (() -> child?) -- 반응적으로 자식을 바꾸고 싶을 때
	| { [number]: child } -- 트리 (배열처럼)

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
	Attachment는 인스턴스에 부착되어 정리 핸들을 반환할 수 있습니다.
]]
export type AttachmentCleanup = unknown

return Types
