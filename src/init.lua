--[[ Example usage

		local Fader = require(script.Fader)

		local fadeUI = Fader({gui})
		local fadeOutUI = fadeUI:Out()
		local fadeInUI = fadeUI:In()
		fadeOutUI:Play():Wait()
		wait(1)
		fadeInUI:Play()
]]

local propertyDef = { -- Order is important because IsA returns true for inherited ClassNames
	{
		{"TextLabel", "TextButton", "TextBox"},
		{"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency"}
	},{
		{"ImageLabel", "ImageButton", "ViewportFrame"},
		{"BackgroundTransparency", "ImageTransparency"}
	},{
		{"ScrollingFrame"},
		{"BackgroundTransparency", "ScrollBarImageTransparency"}
	},{
		{"VideoFrame"},
		{"BackgroundTransparency", "Volume"}
	},{
		{"GuiObject"},
		{"BackgroundTransparency"}
	},{
		{"BasePart", "Decal", "UIStroke"},
		{"Transparency"}
	},{
		{"Light"},
		{"Brightness"}
	},{
		{"Smoke"},
		{"Opacity", "Enabled"}
	},{
		{"Sound"},
		{"Volume"}
	},{
		{"Fire"},
		{"Heat", "Size", "Enabled"}
	},{
		{"Sparkles"},
		{"Enabled"}
	},
}

local outOverride = {
	Sound = {Volume = 0},
	Fire = {Heat = 0, Size = 0, Enabled = false},
	Smoke = {Opacity = 0, Enabled = false},
	Sparkles = {Enabled = false},
	Light = {Brightness = 0},
}

local defaultInfo = TweenInfo.new()

local TweenService = game:GetService("TweenService")

local function getProperties(object: Instance)
	for _, def in next, propertyDef do
		for _, class in next, def[1] do
			if object:IsA(class) then
				return def[2]
			end
		end
	end
	return {}
end

local objectRef = {}

local function defineObject(object)
	if objectRef[object] == nil then
		local _in, _out = {}, {}
		for _, property in next, getProperties(object) do
			local value = object[property]
			_in[property] = value
			_out[property] = 1
		end
		for class, override in next, outOverride do
			if object:IsA(class) then
				for property, value in next, override do
					_out[property] = value
				end
				break
			end
		end
		objectRef[object] = {_in, _out}
	end
end

local function removeRef(objects: {Instance}, object)
	local index = table.find(objects, object)
	if index then
		table.remove(objects, index)
	end
	objectRef[object] = nil
end

local function removeTween(tweens: {Instance}, objects: {Instance})
	for _, tween in next, tweens do
		if table.find(objects, tween.Instance) then
			tween:Destroy()
		end
	end
end

local function cleanObject(interface, object: Instance, recursive: boolean?)
	local objects = interface._objects
	local tweensIn = interface._groupIn
	local tweensOut = interface._groupOut

	removeRef(objects, object)
	if tweensIn then
		removeTween(tweensIn._tweens, {object})
	end
	if tweensOut then
		removeTween(tweensOut._tweens, {object})
	end

	if recursive ~= false then
		local descendants = object:GetDescendants()
		for _, descendant in next, descendants do
			removeRef(objects, descendant)
		end
		if tweensIn then
			removeTween(tweensIn._tweens, descendants)
		end
		if tweensOut then
			removeTween(tweensOut._tweens, descendants)
		end
	end
end

local TweenGroup = {}
TweenGroup.__index = TweenGroup

function TweenGroup.new(tweens: {Tween}, info: TweenInfo)
	return setmetatable({
		Completed = tweens[#tweens].Completed,
		_tweens = tweens,
		_info = info,
	}, TweenGroup)
end

function TweenGroup:Play()
	for _, tween in next, self._tweens do
		tween:Play()
	end
	return self.Completed
end

function TweenGroup:Pause()
	for _, tween in next, self._tweens do
		tween:Pause()
	end
end

function TweenGroup:Cancel()
	for _, tween in next, self._tweens do
		tween:Cancel()
	end
end

function TweenGroup:Destroy()
	for _, tween in next, self._tweens do
		tween:Destroy()
	end
end

local Fade = {}
Fade.__index = Fade

function Fade:In(info: TweenInfo?)
	info = info or defaultInfo
	local tweens = {}
	for _, object in next, self._objects do
		local tween = TweenService:Create(object, info, objectRef[object][1])
		table.insert(tweens, tween)
	end
	if self._groupIn then
		self._groupIn:Destroy()
	end
	self._groupIn = TweenGroup.new(tweens, info)
	return self._groupIn
end

function Fade:Out(info: TweenInfo?)
	info = info or defaultInfo
	local tweens = {}
	for _, object in next, self._objects do
		local tween = TweenService:Create(object, info, objectRef[object][2])
		table.insert(tweens, tween)
	end
	if self._groupOut then
		self._groupOut:Destroy()
	end
	self._groupOut = TweenGroup.new(tweens, info)
	return self._groupOut
end

return function(objects: {Instance}, recursive: boolean?)
	local interface = setmetatable({_objects = objects}, Fade)

	for _, object in pairs(objects) do
		defineObject(object)
		if recursive ~= false then
			for _, descendant in next, object:GetDescendants() do
				defineObject(descendant)
				table.insert(objects, descendant)
			end

			-- add future descendants
			object.DescendantAdded:Connect(function(descendant)
				if objectRef[descendant] == nil then
					defineObject(descendant)
					table.insert(objects, descendant)
					-- add to tween groups
					local groupIn, groupOut = interface._groupIn, interface._groupOut
					if groupIn then
						local tween = TweenService:Create(descendant, groupIn._info, objectRef[descendant][1])
						table.insert(groupIn._tweens, tween)
					end
					if groupOut then
						local tween = TweenService:Create(descendant, groupOut._info, objectRef[descendant][2])
						table.insert(groupOut._tweens, tween)
					end
				end
			end)

			-- clean up references
			object.DescendantRemoving:Connect(function(descendant)
				cleanObject(interface, descendant, recursive)
			end)
		end

		object.Destroying:Connect(function()
			cleanObject(interface, object, recursive)
		end)
	end

	return interface
end
