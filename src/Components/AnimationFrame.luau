--[=[
	@class AnimationFrame

	프레임 이미지를 순차 재생하는 컴포넌트입니다.
]=]

local RunService = game:GetService("RunService")

local vide = require("../vide")

local ImageLabel = require("./ImageLabel")
local Props = require("../Utils/Props")

local cleanup = vide.cleanup
local effect = vide.effect
local source = vide.source
local read = vide.read

local PROP_SCHEMA = {
	ImageContents = Props.required<<{ Content }>>(),
	Frame = Props.optional<<number>>(),
	AutoPlay = Props.optional<<boolean>>(),
	Fps = Props.optional<<number>>(),
}

type AnimationFrameLocalProps = typeof(PROP_SCHEMA)

export type AnimationFrameProps = AnimationFrameLocalProps & ImageLabel.ImageLabelProps

local function getInitialFrame(frameValue: number?, totalFrames: number): number
	if frameValue ~= nil and totalFrames > 0 then
		return math.clamp(frameValue, 1, totalFrames)
	end

	if totalFrames > 0 then
		return 1
	end

	return 0
end

local function AnimationFrame(props: AnimationFrameProps)
	local localProps, otherProps = Props.splitProps(props, PROP_SCHEMA)
	local imageContentsProp = localProps.ImageContents
	local frameProp = localProps.Frame
	local autoPlayProp = localProps.AutoPlay
	local fpsProp = localProps.Fps

	local totalFrames = vide.derive(function()
		return #(read(imageContentsProp) or {})
	end)

	local currentFrameIndex = source(getInitialFrame(read(frameProp), totalFrames()))

	effect(function()
		local total = totalFrames()
		local frame = read(frameProp) or 1

		if total > 0 then
			currentFrameIndex(math.clamp(frame, 1, total))
		else
			currentFrameIndex(0)
		end

		return nil
	end)

	effect(function()
		local total = totalFrames()
		local autoPlay = read(autoPlayProp)
		local frame = read(frameProp)

		if autoPlay and frame == nil and total > 0 then
			local fps = read(fpsProp) or 16
			if fps <= 0 then
				fps = 16
			end

			local frameDuration = 1 / fps
			local accumulatedTime = 0

			local frameForAutoplay = currentFrameIndex()
			if frameForAutoplay == 0 or frameForAutoplay > total then
				frameForAutoplay = 1
				currentFrameIndex(1)
			end

			local conn = RunService.RenderStepped:Connect(function(dt: number)
				accumulatedTime = accumulatedTime + dt
				if accumulatedTime >= frameDuration then
					accumulatedTime = accumulatedTime - frameDuration

					local prev = currentFrameIndex()
					local nextFrame = prev + 1
					if nextFrame > total then
						nextFrame = 1
					end
					currentFrameIndex(nextFrame)
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
			local imageContents = (read(imageContentsProp) :: { Content }?) or {}
			return imageContents[index]
		end,
	}

	return ImageLabel(Props.composeProps(base, otherProps :: any, nil))
end

return AnimationFrame
