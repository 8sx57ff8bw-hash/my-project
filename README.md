# Roblox Crusher Handler (Luau) 🔨

نظام كسّارة (Crusher Handler) احترافي وسهل الاستخدام لألعاب **Roblox** مكتوب بلغة **Luau** بنظام الأنواع الصارم (`--!strict`).

يدعم النظام الحركة السلسة عبر `TweenService`، وإلحاق الضرر أو القتل الفوري للاعبين عند السحق فقط، مع دعم الربط التلقائي عبر **CollectionService** والتحكم عبر **Attributes**.

---

## 📁 بنية الملفات (File Structure)

- [`src/Crusher.luau`](src/Crusher.luau): موديول كائن الكسّارة الفردية (OOP Class)، يدير الحركة، الأنيميشن، الأصوات، واكتشاف اللمس والضرر.
- [`src/CrusherHandler.luau`](src/CrusherHandler.luau): مدير الكسارات، يكتشف الكسارات تلقائياً باستخدام الوسم (Tag: `Crusher`) وينظم تشغيلها وتنظيفها من الذاكرة.
- [`src/Server/CrusherServer.server.luau`](src/Server/CrusherServer.server.luau): سكربت تشغيل من جهة السيرفر يوضع في `ServerScriptService`.

---

## 🛠️ كيفية الإعداد في Roblox Studio

### 1. إعداد مجسّم الكسارة (Model Setup)
أنشئ مجسماً (`Model`) في `Workspace` وضَع بداخله:
- **`CrusherPart`** (أو عيّن `PrimaryPart` للموديل): الجزء الذي سيتحرك ويسحق اللاعبين (تأكد من تفعيل `Anchored = true`).
- **(اختياري) `TargetPart`**: قطعة تحدد النقطة التي سيهبط إليها الساحق (إذا لم تضعها، سيهبط تلقائياً بمقدار `DropDistance`).
- **(اختياري) أصوات**:
  - `WarningSound`: صوت تحذيري يعمل قبل النزول.
  - `ImpactSound`: صوت ارتطام بالأرض يعمل عند اكتمال النزول.
  - `SquishSound`: صوت سحق يعمل عند لمس اللاعب أثناء النزول.

### 2. وسم المجسم (Tagging)
- افتح نافذة **Tag Editor** في روبلوكس ستوديو.
- أضف وسم باسم **`Crusher`** إلى الموديل.
- سيقوم السكربت باكتشافه وتشغيله تلقائياً!

### 3. تخصيص الإعدادات عبر الـ Attributes
يمكنك تعديل أي من الخصائص التالية مباشرة من نافذة **Properties > Attributes** في الموديل:

| الخاصية (Attribute) | النوع | الافتراضي | الوصف |
| :--- | :--- | :--- | :--- |
| `CrushTime` | number | `0.25` | سرعة الهبوط بالثواني (كلما قلّ زادت السرعة). |
| `RetractTime` | number | `1.5` | وقت الصعود للأعلى بالثواني. |
| `DownWaitTime` | number | `0.5` | فترة البقاء في الأسفل بعد السحق. |
| `UpWaitTime` | number | `2.0` | فترة الانتظار في الأعلى قبل الهبوط التالي. |
| `DropDistance` | number | `15` | مسافة النزول بالـ Studs إذا لم يوجد `TargetPart`. |
| `Damage` | number | `100` | مقدار الضرر. |
| `InstantKill` | boolean | `true` | قتل فوري عند ملامسة الساحق أثناء النزول. |

---

## 💻 الاستخدام البرمجي (Scripting API)

### التشغيل التلقائي:
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrusherHandler = require(ReplicatedStorage.CrusherHandler)

-- تشغيل كل الكسارات الحاملة للوسم Crusher
CrusherHandler.Init()
```

### تسجيل كسّارة برمجياً بإعدادات مخصصة:
```luau
local Workspace = game:GetService("Workspace")
local CrusherHandler = require(ReplicatedStorage.CrusherHandler)

local myCrusherModel = Workspace.CrusherMachine

local crusher = CrusherHandler.RegisterCrusher(myCrusherModel, {
    CrushTime = 0.2,
    UpWaitTime = 1.5,
    DropDistance = 20,
    InstantKill = true,
})

-- التحكم في الكسارة:
-- crusher:Stop()
-- crusher:Start()
-- crusher:Destroy()
```
