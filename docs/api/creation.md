---
title: Element Creation
---

UI element creation API와 `Attach` workflow를 설명합니다.

## create()

새 UI element를 만들고 props를 적용합니다.

- Type

  ```luau
  function create(class: string): (Properties) -> Instance
  function create(instance: Instance): (Properties) -> Instance

  type Properties = { [string | number]: unknown }
  ```

- Details

  - 첫 번째 인자로 `string`을 받으면 같은 클래스의 새 인스턴스를 만듭니다.
  - 첫 번째 인자로 `Instance`를 받으면 해당 인스턴스를 clone해서 사용합니다.
  - 반환값은 props를 적용하는 두 번째 함수입니다.

## create() property rules

- string key
  - `Attach`: attachment를 수집하고, 초기 mount가 끝난 뒤 순서대로 실행합니다.
  - 함수 값: event면 연결하고, 일반 property면 reactive effect를 만듭니다.
  - 그 외 값: property를 바로 설정합니다.
- number key
  - table: nested props로 재귀 처리합니다.
  - 함수: reactive children accessor로 처리합니다.
  - instance: child로 parent합니다.

## Attach

`Attach`는 인스턴스에 동작을 부착하는 내장 prop입니다.

```luau
local bide = require("bide")

local create = bide.Instance.create
local Attachments = bide.Attachments

local frame = create "TextButton" {
	Name = "Button",
	Text = "Click",
	Attach = {
		Attachments.Clickable({
			OnClick = function()
				print("clicked")
			end,
		}),
	},
}
```

attachment는 plain function입니다.

```luau
type Attachment<T> = (instance: T) -> (() -> ())?
```

## Changed

[`Changed`](../../src/Attachments/Changed.luau)는 property 변경을 구독하는 attachment helper입니다.

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

`Changed`는 즉시 한 번 실행되고, 이후 property가 바뀔 때마다 다시 실행됩니다.

## mount()

새 stable scope에서 컴포넌트를 실행하고, 결과를 target에 적용합니다.

- Type

  ```luau
  function mount<T>(component: () -> T, target: Instance?): () -> ()
  ```

- Details

  - `root()`의 UI mount용 유틸리티입니다.
  - 반환된 destroy 함수를 호출하면 stable scope를 정리합니다.
