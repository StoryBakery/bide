--[=[
	@class AnimationFrame

	프레임 이미지를 순차 재생하는 컴포넌트입니다.
]=]

local RunService = game:GetService("RunService")

local reactive = require("../Reactive")
local TableUtil = require("../../roblox_packages/TableUtil")

local ImageLabel = require("./ImageLabel")
local Props = require("../Utils/Props")

local effect = reactive.effect
local memo = reactive.memo
local signal = reactive.signal
local cleanup = reactive.cleanup
local read = reactive.read

local OWN_PROPS_SCHEMA = {
	Frames = Props.required<<{ Content }>>(),
	FrameIndex = Props.optional<<number>>(),
	AutoPlay = Props.optional<<boolean>>(),
	FrameRate = Props.optional<<number>>(),
}

export type AnimationFrameOwnProps = typeof(OWN_PROPS_SCHEMA)

export type AnimationFrameProps = AnimationFrameOwnProps & ImageLabel.ImageLabelProps

local function getInitialFrameIndex(frameIndexValue: number?, totalFrames: number): number
	if frameIndexValue ~= nil and totalFrames > 0 then
		return math.clamp(frameIndexValue, 1, totalFrames)
	end

	if totalFrames > 0 then
		return 1
	end

	return 0
end

local function AnimationFrame(props: AnimationFrameProps)
	local ownProps, otherProps, children = Props.splitProps(props, OWN_PROPS_SCHEMA)
	local framesProp = ownProps.Frames
	local frameIndexProp = ownProps.FrameIndex
	local autoPlayProp = ownProps.AutoPlay
	local frameRateProp = ownProps.FrameRate

	local totalFrames = memo(function()
		return #(read(framesProp) or {})
	end)

	local currentFrameIndex, setCurrentFrameIndex =
		signal(getInitialFrameIndex(read(frameIndexProp), totalFrames()))

	effect(function()
		local total = totalFrames()
		local frameIndex = read(frameIndexProp) or 1

		if total > 0 then
			setCurrentFrameIndex(math.clamp(frameIndex, 1, total))
		else
			setCurrentFrameIndex(0)
		end

		return nil
	end)

	effect(function()
		local total = totalFrames()
		local autoPlay = read(autoPlayProp)
		local frameIndex = read(frameIndexProp)

		if autoPlay and frameIndex == nil and total > 0 then
			local frameRate = read(frameRateProp) or 16
			if frameRate <= 0 then
				frameRate = 16
			end

			local frameDuration = 1 / frameRate
			local accumulatedTime = 0

			local conn = RunService.RenderStepped:Connect(function(dt: number)
				accumulatedTime = accumulatedTime + dt
				if accumulatedTime >= frameDuration then
					accumulatedTime = accumulatedTime - frameDuration

					setCurrentFrameIndex(function(previousFrameIndex)
						local nextFrameIndex = previousFrameIndex + 1
						if nextFrameIndex > total then
							return 1
						end

						return nextFrameIndex
					end)
				end
			end)

			cleanup(conn)
		end

		return nil
	end)

	local base = {
		ImageContent = function(): Content?
			local total = totalFrames()
			if total <= 0 then
				return nil
			end

			local index = math.clamp(currentFrameIndex(), 1, total)
			local frames = read(framesProp) or {}
			return frames[index]
		end,
	}

	local imageLabelProps = TableUtil.merge(base, otherProps)
	if #children > 0 then
		table.move(children, 1, #children, #imageLabelProps + 1, imageLabelProps)
	end

	return ImageLabel(imageLabelProps)
end

return AnimationFrame
