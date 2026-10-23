--!strict

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

export type CrusherConfig = {
	CrushTime: number,
	RetractTime: number,
	DownWaitTime: number,
	UpWaitTime: number,
	DropDistance: number,
	Damage: number,
	InstantKill: boolean,
	CrushEasingStyle: Enum.EasingStyle,
	CrushEasingDirection: Enum.EasingDirection,
	RetractEasingStyle: Enum.EasingStyle,
	RetractEasingDirection: Enum.EasingDirection,
}

local DEFAULT_CONFIG: CrusherConfig = {
	CrushTime = 0.25,
	RetractTime = 1.5,
	DownWaitTime = 0.5,
	UpWaitTime = 2.0,
	DropDistance = 15,
	Damage = 100,
	InstantKill = true,
	CrushEasingStyle = Enum.EasingStyle.Quad,
	CrushEasingDirection = Enum.EasingDirection.In,
	RetractEasingStyle = Enum.EasingStyle.Sine,
	RetractEasingDirection = Enum.EasingDirection.Out,
}

local Crusher = {}
Crusher.__index = Crusher

export type CrusherObject = typeof(setmetatable({} :: {
	Model: Model,
	MovingPart: BasePart,
	HitboxPart: BasePart,
	StartCFrame: CFrame,
	TargetCFrame: CFrame,
	Config: CrusherConfig,
	IsRunning: boolean,
	IsCrushing: boolean,
	_damagedHumanoids: { [Humanoid]: boolean },
	_touchConnection: RBXScriptConnection?,
	_currentTween: Tween?,
}, Crusher))

-- قراءة الإعدادات من Attributes داخل الموديل أو استخدام القيم الافتراضية
local function resolveConfig(model: Model, customConfig: { [string]: any }?): CrusherConfig
	local config = table.clone(DEFAULT_CONFIG)

	-- دمج أي إعدادات برمجية مخصصة
	if customConfig then
		for key, value in customConfig do
			if (config :: any)[key] ~= nil then
				(config :: any)[key] = value
			end
		end
	end

	-- قراءة الـ Attributes المعينة على Model من Roblox Studio إن وجدت
	for key, defaultValue in DEFAULT_CONFIG do
		local attributeValue = model:GetAttribute(key)
		if attributeValue ~= nil and typeof(attributeValue) == typeof(defaultValue) then
			(config :: any)[key] = attributeValue
		end
	end

	return config
end

function Crusher.new(model: Model, customConfig: { [string]: any }?): CrusherObject
	local movingPart = model:FindFirstChild("CrusherPart") or model.PrimaryPart
	if not movingPart or not movingPart:IsA("BasePart") then
		error(`[CrusherHandler] Model "${model.Name}" must have a PrimaryPart or a child named "CrusherPart" of type BasePart!`)
	end

	local hitboxPart = model:FindFirstChild("Hitbox")
	if not hitboxPart or not hitboxPart:IsA("BasePart") then
		hitboxPart = movingPart
	end

	-- تحديد موقع النهاية (إما جزء هدف TargetPart أو مسافة DropDistance للأسفل)
	local targetPart = model:FindFirstChild("TargetPart")
	local targetCFrame: CFrame
	local startCFrame = movingPart.CFrame

	local resolved = resolveConfig(model, customConfig)

	if targetPart and targetPart:IsA("BasePart") then
		targetCFrame = targetPart.CFrame
	else
		targetCFrame = startCFrame * CFrame.new(0, -resolved.DropDistance, 0)
	end

	local self = setmetatable({
		Model = model,
		MovingPart = movingPart,
		HitboxPart = hitboxPart :: BasePart,
		StartCFrame = startCFrame,
		TargetCFrame = targetCFrame,
		Config = resolved,
		IsRunning = false,
		IsCrushing = false,
		_damagedHumanoids = {},
		_touchConnection = nil,
		_currentTween = nil,
	}, Crusher)

	self:_setupTouchDetection()

	return self
end

function Crusher._setupTouchDetection(self: CrusherObject)
	local hitbox = self.HitboxPart

	self._touchConnection = hitbox.Touched:Connect(function(otherPart: BasePart)
		-- لا نطبق الضرر إلا أثناء طور النزول/السحق (IsCrushing)
		if not self.IsCrushing then
			return
		end

		local character = otherPart.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		-- التأكد من عدم تكرار الضرر لنفس الشخصية في نفس ضربة السحق
		if self._damagedHumanoids[humanoid] then
			return
		end

		self._damagedHumanoids[humanoid] = true

		if self.Config.InstantKill then
			humanoid.Health = 0
		else
			humanoid:TakeDamage(self.Config.Damage)
		end

		-- تشغيل صوت سحق مخصص للاعب إن وجد
		local squishSound = self.MovingPart:FindFirstChild("SquishSound") :: Sound?
		if squishSound and squishSound:IsA("Sound") then
			squishSound:Play()
		end
	end)
end

function Crusher._playSound(self: CrusherObject, soundName: string)
	local sound = self.MovingPart:FindFirstChild(soundName) :: Sound?
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

function Crusher.Start(self: CrusherObject)
	if self.IsRunning then
		return
	end
	self.IsRunning = true

	task.spawn(function()
		while self.IsRunning do
			-- 1. انتظار في الأعلى (UpWaitTime)
			task.wait(self.Config.UpWaitTime)
			if not self.IsRunning then break end

			-- صوت تحذيري قبل النزول إن وجد
			self:_playSound("WarningSound")

			-- 2. مرحلة السحق (Crush Downward)
			self.IsCrushing = true
			table.clear(self._damagedHumanoids)

			local crushTweenInfo = TweenInfo.new(
				self.Config.CrushTime,
				self.Config.CrushEasingStyle,
				self.Config.CrushEasingDirection
			)

			local crushTween = TweenService:Create(self.MovingPart, crushTweenInfo, {
				CFrame = self.TargetCFrame
			})
			self._currentTween = crushTween
			crushTween:Play()
			crushTween.Completed:Wait()

			-- صوت الارتطام / الاصطدام بالأرض
			self:_playSound("ImpactSound")

			-- إيقاف تفعيل الضرر بعد اكتمال النزول
			self.IsCrushing = false

			if not self.IsRunning then break end

			-- 3. البقاء في الأسفل لفترة (DownWaitTime)
			task.wait(self.Config.DownWaitTime)
			if not self.IsRunning then break end

			-- 4. مرحلة الصعود البطيء (Retract Upward)
			local retractTweenInfo = TweenInfo.new(
				self.Config.RetractTime,
				self.Config.RetractEasingStyle,
				self.Config.RetractEasingDirection
			)

			local retractTween = TweenService:Create(self.MovingPart, retractTweenInfo, {
				CFrame = self.StartCFrame
			})
			self._currentTween = retractTween
			retractTween:Play()
			retractTween.Completed:Wait()
		end
	end)
end

function Crusher.Stop(self: CrusherObject)
	self.IsRunning = false
	self.IsCrushing = false
	if self._currentTween then
		self._currentTween:Cancel()
	end
	-- إعادة القطعة لموقع البداية
	self.MovingPart.CFrame = self.StartCFrame
end

function Crusher.Destroy(self: CrusherObject)
	self:Stop()
	if self._touchConnection then
		self._touchConnection:Disconnect()
		self._touchConnection = nil
	end
	table.clear(self._damagedHumanoids)
end

return Crusher
