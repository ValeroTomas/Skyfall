local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService") -- [NUEVO]

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local ChangelogData = require(sharedFolder:WaitForChild("ChangelogData")) 

-- [NUEVO] DETECCIÓN IDIOMA
local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)

-- EVENTOS
local toggleLogEvent = ReplicatedStorage:WaitForChild("ToggleChangelogEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local toggleInvEvent = ReplicatedStorage:WaitForChild("ToggleInventoryEvent")
local toggleSetEvent = ReplicatedStorage:WaitForChild("ToggleSettingsEvent")

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- Detección Móvil
local isMobile = UserInputService.TouchEnabled

-------------------------------------------------------------------
-- UTILS VISUALES
-------------------------------------------------------------------
local function applyGradient(obj, c1, c2, rot)
	local g = obj:FindFirstChild("UIGradient") or Instance.new("UIGradient", obj)
	g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}
	g.Rotation = rot or 90
	return g
end

local function createDeepStroke(parent, color1, color2, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Thickness = thickness; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = Color3.new(1,1,1)
	applyGradient(s, color1, color2, 45)
	return s
end

local function addTextStroke(txtLabel, thickness, transparency)
	local s = Instance.new("UIStroke", txtLabel)
	s.Thickness = thickness or 2; s.Color = Color3.new(0, 0, 0); s.Transparency = transparency or 0
	return s
end

-------------------------------------------------------------------
-- UI SETUP
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ChangelogUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 25 
screenGui.IgnoreGuiInset = true

-- BLOCKER (Fondo Oscuro + Mouse Fix)
local mainBlocker = Instance.new("TextButton", screenGui)
mainBlocker.Name = "MainBlocker"
mainBlocker.Size = UDim2.new(1,0,1,0)
mainBlocker.BackgroundColor3 = Color3.new(0,0,0) 
mainBlocker.BackgroundTransparency = 1 
mainBlocker.Text = ""
mainBlocker.Visible = false; mainBlocker.ZIndex = 1
mainBlocker.AutoButtonColor = false 
mainBlocker.Modal = true -- Mouse Libre

-- FRAME PRINCIPAL (Capa 5)
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 600)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.new(1,1,1)
mainFrame.Visible = false
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- Estilo Frame Principal
applyGradient(mainFrame, Color3.fromRGB(35, 30, 45), Color3.fromRGB(20, 18, 25), 45)
createDeepStroke(mainFrame, Color3.fromRGB(80, 80, 100), Color3.fromRGB(40, 40, 60), 4)

-- Click Shield
local shield = Instance.new("TextButton", mainFrame)
shield.Size = UDim2.new(1,0,1,0); shield.BackgroundTransparency = 1; shield.Text = ""
shield.AutoButtonColor = false; shield.ZIndex = 5

local title = Instance.new("TextLabel", mainFrame)
title.Text = (playerLang == "es") and "NOTAS DEL PARCHE" or "PATCH NOTES" -- [MODIFICADO]
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.FontFace = FontManager.Get("Cartoon")
title.TextSize = isMobile and 30 or 38
title.TextColor3 = Color3.fromRGB(255, 255, 255); title.ZIndex = 6
addTextStroke(title, 2)
applyGradient(title, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 150, 0), 90)

-- [NUEVO] CONTENT FRAME (Fondo claro para el texto - Capa 6)
local contentBg = Instance.new("Frame", mainFrame)
contentBg.Name = "ContentBackground"
local contentHeight = isMobile and 0.75 or 0.82
contentBg.Size = UDim2.new(0.9, 0, contentHeight, 0)
contentBg.Position = UDim2.new(0.5, 0, 1, -20); contentBg.AnchorPoint = Vector2.new(0.5, 1)
contentBg.BackgroundColor3 = Color3.fromRGB(50, 45, 60) -- Color ligeramente más claro que el fondo
contentBg.ZIndex = 6
Instance.new("UICorner", contentBg).CornerRadius = UDim.new(0, 12)
createDeepStroke(contentBg, Color3.fromRGB(70, 65, 80), Color3.fromRGB(40, 35, 50), 2) -- Borde sutil

-- SCROLLING FRAME (Dentro del ContentBg - Capa 7)
local scroll = Instance.new("ScrollingFrame", contentBg)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.Position = UDim2.new(0, 0, 0, 0)
scroll.BackgroundTransparency = 1
scroll.ZIndex = 7 
scroll.ScrollBarThickness = 8 
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255) 
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)

local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop = UDim.new(0, 15)
pad.PaddingBottom = UDim.new(0, 15)
pad.PaddingLeft = UDim.new(0, 15)
pad.PaddingRight = UDim.new(0, 15) -- Espacio extra para scrollbar

-- TEXTO (Capa 8)
local textLabel = Instance.new("TextLabel", scroll)
textLabel.Size = UDim2.new(1, -10, 0, 0) -- Scale 1 para ajustar ancho
textLabel.Position = UDim2.new(0, 0, 0, 0)
textLabel.BackgroundTransparency = 1
-- [MODIFICADO] Solicitamos el texto en el idioma del jugador
textLabel.Text = ChangelogData.GetText(playerLang)
textLabel.RichText = true
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextSize = isMobile and 16 or 20
textLabel.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.TextWrapped = true
textLabel.AutomaticSize = Enum.AutomaticSize.Y
textLabel.ZIndex = 8 -- [IMPORTANTE] Capa más alta

-- CONTROL
local isOpen = false

local function closeMenu()
	if not isOpen then return end
	isOpen = false
	mainFrame.Visible = false
	mainBlocker.Visible = false
	mainBlocker.BackgroundTransparency = 1
	
	local stateRaw = estadoValue.Value or ""
	local state = string.split(stateRaw, "|")[1]
	if state == "SURVIVE" then
		UserInputService.MouseIconEnabled = false
	end
end

local function toggle()
	isOpen = not isOpen
	mainFrame.Visible = isOpen
	mainBlocker.Visible = isOpen
	
	if isOpen then 
		UserInputService.MouseIconEnabled = true
		
		SoundManager.Play("ShopButton") 
		TweenService:Create(mainBlocker, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
		
		local startSize, endSize
		if isMobile then
			startSize = UDim2.new(0.8, 0, 0.8, 0)
			endSize = UDim2.new(0.85, 0, 0.85, 0)
		else
			startSize = UDim2.new(0, 450, 0, 550)
			endSize = UDim2.new(0, 500, 0, 600)
		end
		
		mainFrame.Size = startSize
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = endSize}):Play()
	else
		mainBlocker.BackgroundTransparency = 1
		local stateRaw = estadoValue.Value or ""
		local state = string.split(stateRaw, "|")[1]
		if state == "SURVIVE" then
			UserInputService.MouseIconEnabled = false
		end
	end
end

-- [NUEVO] CIERRE CON MANDO (CÍRCULO / B)
UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	if isOpen and input.KeyCode == Enum.KeyCode.ButtonB then
		toggle()
	end
end)

toggleLogEvent.Event:Connect(toggle)
mainBlocker.MouseButton1Click:Connect(toggle)

toggleShopEvent.Event:Connect(closeMenu)
toggleInvEvent.Event:Connect(closeMenu)
toggleSetEvent.Event:Connect(closeMenu)

estadoValue.Changed:Connect(function()
	local state = string.split(estadoValue.Value, "|")[1]
	if state == "SURVIVE" then closeMenu() end
end)