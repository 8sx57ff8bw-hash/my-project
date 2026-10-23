--!strict

-- ضع هذا السكربت داخل ServerScriptService
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- بافتراض وجود الموديولات داخل ReplicatedStorage.Source أو ServerScriptService
local CrusherHandler = require(ReplicatedStorage:WaitForChild("CrusherHandler"))

-- تشغيل النظام تلقائياً للبحث عن الكسارات بوسم "Crusher"
CrusherHandler.Init()

-- ملاحظة: يمكنك أيضاً تسجيل موديل يدوياً بإعدادات مخصصة بدون استخدام CollectionService:
--[[
local workspace = game:GetService("Workspace")
local specialCrusherModel = workspace:WaitForChild("BigBossCrusher")

CrusherHandler.RegisterCrusher(specialCrusherModel, {
	CrushTime = 0.15,      -- نزول فائق السرعة
	RetractTime = 2.0,      -- صعود بطيء
	DownWaitTime = 1.0,     -- يبقى في الأسفل ثانية كاملة
	UpWaitTime = 3.0,       -- ينتظر 3 ثوانٍ قبل الضربة التالية
	DropDistance = 25,      -- مسافة الهبوط بالـ Studs
	InstantKill = true,     -- قتل فوري
})
]]
