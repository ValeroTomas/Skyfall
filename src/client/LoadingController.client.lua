local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LocalizationService = game:GetService("LocalizationService")

-- 1. ELIMINAR CARGA POR DEFECTO
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ESPERAR ESTRUCTURA SHARED
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local Localization = require(sharedFolder:WaitForChild("Localization"))

-- DETECTAR IDIOMA
local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)

-- BLOQUEO DE CONTROLES
local function setControlsEnabled(enabled)
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	if enabled then controls:Enable() else controls:Disable() end
end
setControlsEnabled(false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

--------------------------------------------------------------------------------
-- 2. CREACIÓN DE LA INTERFAZ
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomLoadingScreen"
screenGui.DisplayOrder = 100 
screenGui.IgnoreGuiInset = true 
screenGui.Parent = playerGui

local bg = Instance.new("Frame", screenGui)
bg.Name = "Background"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
bg.BorderSizePixel = 0

local bgGrad = Instance.new("UIGradient", bg)
bgGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 35, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 15))
}
bgGrad.Rotation = -45

-- ==============================================================================
-- NUEVO TÍTULO DIVIDIDO
-- ==============================================================================
-- Contenedor para centrar y animar ambas partes juntas
local titleContainer = Instance.new("Frame", bg)
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(0, 600, 0, 160)
titleContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
titleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
titleContainer.BackgroundTransparency = 1

-- PARTE 1: "SURVIVE THE" (Blanco a Gris)
local titleTop = Instance.new("TextLabel", titleContainer)
titleTop.Name = "TopText"
titleTop.Text = "SURVIVE THE"
titleTop.FontFace = FontManager.Get("Cartoon")
titleTop.TextSize = 35
titleTop.TextColor3 = Color3.new(1,1,1) -- Base para gradiente
titleTop.Size = UDim2.new(1, 0, 0, 40)
titleTop.Position = UDim2.new(0, 0, 0, 0)
titleTop.BackgroundTransparency = 1
titleTop.TextTransparency = 1 -- Empieza oculto
titleTop.ZIndex = 2

local gradTop = Instance.new("UIGradient", titleTop)
gradTop.Rotation = 90
gradTop.Color = ColorSequence.new(Color3.fromRGB(230,230,230), Color3.fromRGB(120,120,120))

local strokeTop = Instance.new("UIStroke", titleTop)
strokeTop.Thickness = 2
strokeTop.Color = Color3.new(0,0,0)
strokeTop.Transparency = 1 -- Empieza oculto

-- PARTE 2: "SKYFALL!" (Amarillo a Oscuro)
local titleMain = Instance.new("TextLabel", titleContainer)
titleMain.Name = "MainText"
titleMain.Text = "SKYFALL!"
titleMain.FontFace = FontManager.Get("Cartoon")
titleMain.TextSize = 90 -- Mucho más grande
titleMain.TextColor3 = Color3.new(1,1,1) -- Base para gradiente
titleMain.Size = UDim2.new(1, 0, 0, 100)
titleMain.Position = UDim2.new(0, 0, 0.3, 0) -- Debajo de la primera parte
titleMain.BackgroundTransparency = 1
titleMain.TextTransparency = 1 -- Empieza oculto
titleMain.ZIndex = 2

local gradMain = Instance.new("UIGradient", titleMain)
gradMain.Rotation = 90
-- Gradiente Amarillo Oro a Naranja Oscuro
gradMain.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 100, 0))

local strokeMain = Instance.new("UIStroke", titleMain)
strokeMain.Thickness = 4
strokeMain.Color = Color3.fromRGB(80, 40, 0) -- Borde marrón oscuro para contraste
strokeMain.Transparency = 1 -- Empieza oculto
-- ==============================================================================


local barContainer = Instance.new("Frame", bg)
barContainer.Name = "BarContainer"
barContainer.Size = UDim2.new(0, 300, 0, 10)
barContainer.Position = UDim2.new(0.5, 0, 0.65, 0) -- Bajamos un poco la barra
barContainer.AnchorPoint = Vector2.new(0.5, 0.5)
barContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
barContainer.BackgroundTransparency = 1 -- <--- Oculto
Instance.new("UICorner", barContainer).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame", barContainer)
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
barFill.BackgroundTransparency = 1 -- <--- Oculto
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- TEXTO ESTADO (INVISIBLE AL PRINCIPIO)
local statusText = Instance.new("TextLabel", bg)
statusText.Name = "Status"
statusText.Text = Localization.get("LOADING_ASSETS", playerLang)
statusText.FontFace = Font.fromEnum(Enum.Font.GothamBold)
statusText.TextSize = 18
statusText.TextColor3 = Color3.fromRGB(150, 150, 150)
statusText.Size = UDim2.new(1, 0, 0, 30)
statusText.Position = UDim2.new(0.5, 0, 0.7, 0) -- Bajamos un poco el texto
statusText.AnchorPoint = Vector2.new(0.5, 0.5)
statusText.BackgroundTransparency = 1
statusText.TextTransparency = 1 -- <--- IMPORTANTE: Empieza oculto

--------------------------------------------------------------------------------
-- 3. FASE 1: CARGA DE FUENTES (PRIORIDAD)
--------------------------------------------------------------------------------
local fontAssets = FontManager.GetAssets()
ContentProvider:PreloadAsync(fontAssets)

-- REVELAR UI (Actualizado para las dos partes del título)
local revealInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(titleTop, revealInfo, {TextTransparency = 0}):Play()
TweenService:Create(strokeTop, revealInfo, {Transparency = 0}):Play()
TweenService:Create(titleMain, revealInfo, {TextTransparency = 0}):Play()
TweenService:Create(strokeMain, revealInfo, {Transparency = 0}):Play()

TweenService:Create(barContainer, revealInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(barFill, revealInfo, {BackgroundTransparency = 0}):Play()
TweenService:Create(statusText, revealInfo, {TextTransparency = 0}):Play()

task.wait(0.5)

--------------------------------------------------------------------------------
-- 4. FASE 2: CARGA MASIVA (SONIDOS Y DECALS)
--------------------------------------------------------------------------------
local otherAssets = {}
local sounds = SoundManager.GetAssets()
local decals = DecalManager.GetAssets()

for _, s in ipairs(sounds) do table.insert(otherAssets, s) end
for _, d in ipairs(decals) do table.insert(otherAssets, d) end

print("🚀 LoadingController: Cargando " .. #otherAssets .. " assets principales.")

local total = #otherAssets
local loadedCount = 0

if total == 0 then
	barFill.Size = UDim2.new(1, 0, 1, 0)
	task.wait(0.5)
else
	local function updateProgress(contentId, status)
		loadedCount = loadedCount + 1
		local progress = math.clamp(loadedCount / total, 0, 1)
		
		TweenService:Create(barFill, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			Size = UDim2.new(progress, 0, 1, 0)
		}):Play()
		
		local msg = Localization.get("LOADING_ASSETS", playerLang)
		statusText.Text = msg .. " " .. math.floor(progress * 100) .. "%"
	end

	ContentProvider:PreloadAsync(otherAssets, updateProgress)
end

--------------------------------------------------------------------------------
-- 5. FINALIZACIÓN
--------------------------------------------------------------------------------
statusText.Text = Localization.get("LOADING_COMPLETE", playerLang)
SoundManager.Play("AbilityReady") 

task.wait(0.5)

-- ANIMACIÓN DE SALIDA (Actualizada para mover el contenedor del título)
local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Movemos todo el contenedor del título hacia arriba
TweenService:Create(titleContainer, fadeInfo, {Position = UDim2.new(0.5, 0, 0.3, 0)}):Play()
-- Desvanecemos las partes individuales
TweenService:Create(titleTop, fadeInfo, {TextTransparency = 1}):Play()
TweenService:Create(strokeTop, fadeInfo, {Transparency = 1}):Play()
TweenService:Create(titleMain, fadeInfo, {TextTransparency = 1}):Play()
TweenService:Create(strokeMain, fadeInfo, {Transparency = 1}):Play()

TweenService:Create(barContainer, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(barFill, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(statusText, fadeInfo, {TextTransparency = 1}):Play()

task.delay(0.2, function()
	local bgFade = TweenService:Create(bg, fadeInfo, {BackgroundTransparency = 1})
	bgFade:Play()
	
	bgFade.Completed:Connect(function()
		screenGui:Destroy()
		
		setControlsEnabled(true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		print("✅ LoadingController: Carga completada.")
	end)
end)