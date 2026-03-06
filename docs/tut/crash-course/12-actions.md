---
title: Attachments
---

이전 `action()` workflow 대신 `Attach` prop을 사용합니다.

## 기본 사용

attachment는 인스턴스에 붙는 plain function입니다.

```luau
local bide = require("bide")

local create = bide.Instance.create

create "TextLabel" {
	Text = "test",
	Attach = function(instance)
		print(instance.Text)
	end,
}
```

초기 mount가 끝난 뒤 attachment가 실행됩니다.

## 여러 attachment 조합

여러 개를 붙일 때는 `Attach` 배열을 사용합니다.

```luau
local bide = require("bide")

local create = bide.Instance.create
local Attachments = bide.Attachments

create "TextButton" {
	Text = "Click",
	Attach = {
		Attachments.Clickable({
			OnClick = function()
				print("clicked")
			end,
		}),
		Attachments.HoverDelay({
			DelaySeconds = 0.2,
			OnHover = function()
				print("hover")
			end,
		}),
	},
}
```

순서는 배열 순서를 그대로 따릅니다.

## Changed helper

property 변경 구독은 `Attachments.Changed()`로 처리합니다.

```luau
local bide = require("bide")

local create = bide.Instance.create
local Attachments = bide.Attachments
local output = ""

create "TextBox" {
	Text = "hello",
	Attach = {
		Attachments.Changed("Text", function(value)
			output = value
		end),
	},
}
```

이 helper는 connection cleanup까지 함께 처리합니다.
