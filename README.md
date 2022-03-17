# Description
Roblox module for generic TweenService fading of Instances.
* This module supports fading GUIs, parts, lights, sounds, and more.

# Reference
## Fader(objects: {Instance}, recursive: true?) -> Fade
	Instance properties are cached as the "In" state.

## Fade
	:In(info: TweenInfo?) -> TweenGroup
		Returns a TweenGroup representing the "In" state.
	:Out(info: TweenInfo?) -> TweenGroup
		Returns a TweenGroup representing the "Out" state.

## TweenGroup
Controls a group of Tweens from TweenService.
Follows the same behavior as a [Tween](https://developer.roblox.com/en-us/api-reference/class/Tween).

	:Play() -> .Completed
	:Pause()
	:Cancel()
	:Destroy()
	.Completed -> RBXScriptSignal

# Example
```lua
local Fader = require(script.Fader)

local fadeUI = Fader({gui})
local fadeOutUI = fadeUI:Out()
local fadeInUI = fadeUI:In()
fadeOutUI:Play():Wait()
wait(1)
fadeInUI:Play()
```
