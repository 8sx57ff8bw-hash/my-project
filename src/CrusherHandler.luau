--!strict

local CollectionService = game:GetService("CollectionService")
local Crusher = require(script.Parent.Crusher)

type CrusherObject = Crusher.CrusherObject

local TAG_NAME = "Crusher"

local CrusherHandler = {}
local activeCrushers: { [Model]: CrusherObject } = {}
local isInitialized = false

-- تسجيل كسّارة جديدة وتشغيلها
function CrusherHandler.RegisterCrusher(model: Model, customConfig: { [string]: any }?): CrusherObject?
	if activeCrushers[model] then
		return activeCrushers[model]
	end

	local success, result = pcall(function()
		return Crusher.new(model, customConfig)
	end)

	if not success then
		warn(`[CrusherHandler] Failed to register crusher "{model.Name}": {result}`)
		return nil
	end

	local crusherObj: CrusherObject = result
	activeCrushers[model] = crusherObj
	crusherObj:Start()

	return crusherObj
end

-- إزالة كسارة وإيقافها
function CrusherHandler.UnregisterCrusher(model: Model)
	local crusherObj = activeCrushers[model]
	if crusherObj then
		crusherObj:Destroy()
		activeCrushers[model] = nil
	end
end

-- الحصول على كائن الكسارة لموديل معين
function CrusherHandler.GetCrusher(model: Model): CrusherObject?
	return activeCrushers[model]
end

-- إيقاف كل الكسارات
function CrusherHandler.StopAll()
	for _, crusher in activeCrushers do
		crusher:Stop()
	end
end

-- إعادة تشغيل كل الكسارات
function CrusherHandler.StartAll()
	for _, crusher in activeCrushers do
		crusher:Start()
	end
end

-- تهيئة النظام تلقائياً للبحث عن أي مجسم يحمل الوسم "Crusher" عبر CollectionService
function CrusherHandler.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- تسجيل الكسارات الموجودة مسبقاً في اللعبة
	for _, instance in CollectionService:GetTagged(TAG_NAME) do
		if instance:IsA("Model") then
			CrusherHandler.RegisterCrusher(instance)
		end
	end

	-- مراقبة أي كسارة جديدة تُضاف أثناء تشغيل اللعبة
	CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(function(instance: Instance)
		if instance:IsA("Model") then
			CrusherHandler.RegisterCrusher(instance)
		end
	end)

	-- تنظيف الكسارة عند حذفها من اللعبة
	CollectionService:GetInstanceRemovedSignal(TAG_NAME):Connect(function(instance: Instance)
		if instance:IsA("Model") then
			CrusherHandler.UnregisterCrusher(instance)
		end
	end)

	print("[CrusherHandler] Initialized successfully via CollectionService!")
end

return CrusherHandler
