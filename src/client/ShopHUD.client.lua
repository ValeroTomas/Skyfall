local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService") 
local LocalizationService = game:GetService("LocalizationService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local Localization = require(sharedFolder:WaitForChild("Localization")) 
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager")) 

local VipList = require(sharedFolder:WaitForChild("VipList"))

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
local shopFunction = ReplicatedStorage:WaitForChild("ShopFunction")
local colorEvent = ReplicatedStorage:WaitForChild("ColorUpdateEvent", 5)

-- Eventos Manuales
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local toggleInvEvent = ReplicatedStorage:WaitForChild("ToggleInventoryEvent")
local toggleLogEvent = ReplicatedStorage:WaitForChild("ToggleChangelogEvent")

-- Evento Shiny
local shinyEvent = ReplicatedStorage:WaitForChild("ToggleShinyEvent")

-- Detección Móvil
local isMobile = UserInputService.TouchEnabled

local GAME_PASS_ID = 1663859003 
local SHINY_PASS_ID = 1669617297 

local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
local function getTxt(key, ...)
	return Localization.get(key, playerLang, ...)
end

local refreshAllTabs 

-------------------------------------------------------------------
-- MAPEO DE LOCALIZATION
-------------------------------------------------------------------
local STAT_TO_LOCALE = {
	JumpHeight = "ITEM_HEIGHT",
	JumpStaminaCost = "ITEM_COST",
	MaxStamina = "ITEM_AMOUNT",
	StaminaRegen = "ITEM_REGEN",
	StaminaDrain = "ITEM_EFFICIENCY",
	PushDistance = "ITEM_DISTANCE",
	PushRange = "ITEM_RANGE",
	PushCooldown = "ITEM_COOLDOWN",
	DashDistance = "ITEM_DISTANCE",
	DashSpeed = "ITEM_SPEED",
	DashCooldown = "ITEM_COOLDOWN",
	BonkStun = "ITEM_STUN_TIME",
	BonkCooldown = "ITEM_COOLDOWN"
}

local ABILITY_LIST = {
	{Key = "DoubleJump", Icon = DecalManager.Get("DoubleJump"), NameKey = "ITEM_DOUBLE_JUMP", ColorKey = "DoubleJumpColor"}, 
	{Key = "PushUnlock", Icon = DecalManager.Get("Push"), NameKey = "HEADER_PUSH"},
	{Key = "DashUnlock", Icon = DecalManager.Get("Dash"), NameKey = "HEADER_DASH", ColorKey = "DashColor"},
	{Key = "BonkUnlock", Icon = DecalManager.Get("Bonk"), NameKey = "HEADER_BONK", ColorKey = "BonkColor"},
}

local UPGRADE_GROUPS = {
	{ Header = "HEADER_JUMP", Dependency = nil, Items = {"JumpHeight", "JumpStaminaCost"} },
	{ Header = "HEADER_PUSH", Dependency = "PushUnlock", Items = {"PushDistance", "PushRange", "PushCooldown"} },
	{ Header = "HEADER_DASH", Dependency = "DashUnlock", Items = {"DashDistance", "DashSpeed", "DashCooldown"} },
	{ Header = "HEADER_BONK", Dependency = "BonkUnlock", Items = {"BonkStun", "BonkCooldown"} },
	{ Header = "HEADER_STAMINA", Dependency = nil, Items = {"MaxStamina", "StaminaRegen", "StaminaDrain"} }
}

-------------------------------------------------------------------
-- UTILS VISUALES
-------------------------------------------------------------------
local function applyGradient(obj, c1, c2, rot)
	local g = obj:FindFirstChild("UIGradient") or Instance.new("UIGradient", obj)
	g.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2)
	}
	g.Rotation = rot or 90
	return g
end

local function createDeepStroke(parent, color1, color2, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = Color3.new(1,1,1) 
	applyGradient(s, color1, color2, 45)
	return s
end

local function addTextStroke(txtLabel, thickness, transparency)
	local s = Instance.new("UIStroke", txtLabel)
	s.Thickness = thickness or 2
	s.Color = Color3.new(0, 0, 0)
	s.Transparency = transparency or 0
	return s
end

-- HELPER: CREAR BOTÓN ESTILIZADO
local function createStyledButton(parent, text, color1, color2)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0, 120, 0, 45)
	btn.BackgroundColor3 = Color3.new(1,1,1); btn.Text = ""; btn.AutoButtonColor = true; btn.ZIndex = 12
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	applyGradient(btn, color1, color2, 90)
	createDeepStroke(btn, Color3.new(1,1,1), Color3.new(0.5,0.5,0.5), 2).Color = Color3.new(0,0,0)
	
	local label = Instance.new("TextLabel", btn)
	label.Size = UDim2.new(1,0,1,0); label.BackgroundTransparency = 1
	label.Text = text; label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	label.TextSize = isMobile and 18 or 22; label.TextColor3 = Color3.new(1,1,1); label.ZIndex = 13
	local tGrad = Instance.new("UIGradient", label)
	tGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))}
	tGrad.Rotation = 90
	local tStroke = Instance.new("UIStroke", label); tStroke.Thickness = 2; tStroke.Color = Color3.new(0,0,0)
	return btn
end

-------------------------------------------------------------------
-- 1. UI SETUP (MENÚ PRINCIPAL)
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ShopMenuUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20 
screenGui.IgnoreGuiInset = true 

-- BLOCKER
local mainBlocker = Instance.new("TextButton", screenGui)
mainBlocker.Name = "MainBlocker"
mainBlocker.Size = UDim2.new(1,0,1,0)
mainBlocker.BackgroundColor3 = Color3.new(0,0,0) 
mainBlocker.BackgroundTransparency = 1 
mainBlocker.Text = ""
mainBlocker.Visible = false; mainBlocker.ZIndex = 1
mainBlocker.AutoButtonColor = false 
mainBlocker.Modal = true 

-- FRAME PRINCIPAL
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Name = "ShopMenu"
-- El tamaño se ajusta en toggleMenu
menuFrame.Size = UDim2.new(0, 750, 0, 550) 
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0); menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.new(1,1,1)
menuFrame.Visible = false; menuFrame.ZIndex = 5 
menuFrame.Active = true 

Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 16)
applyGradient(menuFrame, Color3.fromRGB(40, 45, 60), Color3.fromRGB(20, 22, 30), 45)
createDeepStroke(menuFrame, Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 50, 150), 4)

-- Click Shield
local shield = Instance.new("TextButton", menuFrame)
shield.Size = UDim2.new(1,0,1,0); shield.BackgroundTransparency = 1; shield.Text = ""
shield.AutoButtonColor = false; shield.ZIndex = 1

local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, 0, 0, isMobile and 45 or 60); title.BackgroundTransparency = 1
title.Text = getTxt("SHOP_TITLE")
title.FontFace = FontManager.Get("Cartoon")
title.TextSize = isMobile and 35 or 45; title.TextColor3 = Color3.new(1,1,1)
title.Position = UDim2.new(0,0,0,10); title.ZIndex = 6
applyGradient(title, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 170, 0), 90)
local tStroke = Instance.new("UIStroke", title); tStroke.Thickness = 3; tStroke.Color = Color3.new(0,0,0)

local innerFrame = Instance.new("Frame", menuFrame)
innerFrame.Name = "ContentArea"
innerFrame.Size = UDim2.new(1, -30, 1, -150) 
innerFrame.Position = UDim2.new(0.5, 0, 1, -20); innerFrame.AnchorPoint = Vector2.new(0.5, 1)
innerFrame.BackgroundColor3 = Color3.new(1,1,1)
innerFrame.ZIndex = 6
Instance.new("UICorner", innerFrame).CornerRadius = UDim.new(0, 12)
applyGradient(innerFrame, Color3.fromRGB(25, 27, 35), Color3.fromRGB(15, 15, 20), 90)
createDeepStroke(innerFrame, Color3.fromRGB(60, 65, 80), Color3.fromRGB(30, 32, 40), 2)

-------------------------------------------------------------------
-- 2. PESTAÑAS
-------------------------------------------------------------------
local tabContainer = Instance.new("Frame", menuFrame)
tabContainer.Name = "Tabs"
tabContainer.Size = UDim2.new(1, -30, 0, 45) 
tabContainer.Position = UDim2.new(0.5, 0, 0, isMobile and 60 or 75); tabContainer.AnchorPoint = Vector2.new(0.5, 0)
tabContainer.BackgroundTransparency = 1; tabContainer.ZIndex = 6

local currentTab = "Abilities"
local tabButtons = {}
local contentFrames = {}

local function createTabButton(name, text, layoutOrder)
	local btn = Instance.new("TextButton", tabContainer)
	btn.Name = name
	btn.Size = UDim2.new(0.30, 0, 1, 0) 
	btn.Position = UDim2.new((layoutOrder-1)*0.35, 0, 0, 0)
	btn.BackgroundColor3 = Color3.new(1,1,1)
	btn.Text = text
	btn.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	btn.TextSize = isMobile and 14 or 18; btn.TextColor3 = Color3.new(1,1,1); btn.ZIndex = 7
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	local txtStroke = Instance.new("UIStroke", btn)
	txtStroke.Name = "TextStroke"; txtStroke.Color = Color3.new(0,0,0)
	txtStroke.Thickness = 2; txtStroke.Transparency = 1 
	
	local grad = applyGradient(btn, Color3.fromRGB(80, 80, 90), Color3.fromRGB(50, 50, 60), 90)
	local stroke = createDeepStroke(btn, Color3.fromRGB(120, 120, 130), Color3.fromRGB(60, 60, 70), 2)
	
	tabButtons[name] = {Btn = btn, Grad = grad, Stroke = stroke, TxtStroke = txtStroke}
	return btn
end

createTabButton("Abilities", "HABILIDADES", 1)
createTabButton("Upgrades", "MEJORAS", 2)
createTabButton("Coins", "MONEDAS", 3)

local function createContentScroll(name)
	local sc = Instance.new("ScrollingFrame", innerFrame)
	sc.Name = name
	sc.Size = UDim2.new(1, 0, 1, 0) 
	sc.Position = UDim2.new(0.5, 0, 0.5, 0); sc.AnchorPoint = Vector2.new(0.5, 0.5)
	sc.BackgroundTransparency = 1
	sc.ScrollBarThickness = 8 
	sc.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	sc.Visible = false
	sc.ZIndex = 10
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sc.CanvasSize = UDim2.new(0,0,0,0)
	sc.Active = true 
	
	local pad = Instance.new("UIPadding", sc)
	pad.PaddingTop = UDim.new(0, 15)
	pad.PaddingBottom = UDim.new(0, 15)
	pad.PaddingLeft = UDim.new(0, 15)
	pad.PaddingRight = UDim.new(0, 15) 
	
	local lay = Instance.new("UIListLayout", sc)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 10)
	
	local function updateScrollBar()
		local contentHeight = lay.AbsoluteContentSize.Y
		local frameHeight = sc.AbsoluteWindowSize.Y - 5 
		
		if contentHeight > frameHeight then
			sc.ScrollBarImageTransparency = 0 
			sc.ScrollingEnabled = true
		else
			sc.ScrollBarImageTransparency = 1 
			sc.ScrollingEnabled = false 
		end
	end
	
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollBar)
	sc:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollBar)
	task.defer(updateScrollBar)
	
	contentFrames[name] = sc
	return sc
end

createContentScroll("Abilities")
createContentScroll("Upgrades")
createContentScroll("Coins")

local function switchTab(tabName)
	currentTab = tabName
	SoundManager.Play("ShopButton")
	for name, data in pairs(tabButtons) do
		if name == tabName then
			data.Grad.Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 100, 200))
			data.Btn.TextColor3 = Color3.new(1,1,1) 
			data.TxtStroke.Transparency = 0.5 
		else
			data.Grad.Color = ColorSequence.new(Color3.fromRGB(60, 60, 70), Color3.fromRGB(40, 40, 50))
			data.Btn.TextColor3 = Color3.fromRGB(180, 180, 180) 
			data.TxtStroke.Transparency = 1 
		end
	end
	for name, frame in pairs(contentFrames) do frame.Visible = (name == tabName) end
end

for name, data in pairs(tabButtons) do
	data.Btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-------------------------------------------------------------------
-- 3. SELECTOR DE COLOR (COMPACTO Y ESCALABLE)
-------------------------------------------------------------------
local rgbFrame = Instance.new("Frame", screenGui)
rgbFrame.Name = "RGBSelector"
-- [AJUSTE MÓVIL]
if isMobile then
	rgbFrame.Size = UDim2.new(0.85, 0, 0.7, 0)
else
	rgbFrame.Size = UDim2.new(0, 450, 0, 460)
end
rgbFrame.Position = UDim2.new(0.5, 0, 0.5, 0); rgbFrame.AnchorPoint = Vector2.new(0.5, 0.5)
rgbFrame.BackgroundColor3 = Color3.new(1,1,1)
rgbFrame.Visible = false; rgbFrame.ZIndex = 25 
rgbFrame.Active = true 
Instance.new("UICorner", rgbFrame).CornerRadius = UDim.new(0, 16)

-- ESTÉTICA "SKYFALL"
applyGradient(rgbFrame, Color3.fromRGB(35, 40, 55), Color3.fromRGB(20, 22, 30), 45)
createDeepStroke(rgbFrame, Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 100, 200), 4)

-- TÍTULO
local rgbTitle = Instance.new("TextLabel", rgbFrame)
rgbTitle.Size = UDim2.new(1,0,0,50); rgbTitle.BackgroundTransparency = 1
rgbTitle.Text = getTxt("COLOR_SELECTOR")
rgbTitle.TextColor3 = Color3.new(1,1,1)
rgbTitle.FontFace = FontManager.Get("Cartoon")
rgbTitle.TextSize = isMobile and 30 or 40; rgbTitle.ZIndex = 26
rgbTitle.Position = UDim2.new(0, 0, 0, 10) 

applyGradient(rgbTitle, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 170, 0), 90)
local rgbTStroke = Instance.new("UIStroke", rgbTitle); rgbTStroke.Thickness = 3; rgbTStroke.Color = Color3.new(0,0,0)

-- CONTENEDOR PREVIEW
local previewContainer = Instance.new("Frame", rgbFrame)
previewContainer.Size = UDim2.new(0.2, 0, 0.2, 0) -- Relativo
-- Forzar ratio cuadrado
local aspect = Instance.new("UIAspectRatioConstraint", previewContainer)
aspect.AspectRatio = 1

previewContainer.Position = UDim2.new(0.5, 0, 0.18, 0); previewContainer.AnchorPoint = Vector2.new(0.5, 0) 
previewContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20); previewContainer.ZIndex = 26
Instance.new("UICorner", previewContainer).CornerRadius = UDim.new(0, 12)
createDeepStroke(previewContainer, Color3.fromRGB(100, 100, 120), Color3.fromRGB(50, 50, 60), 2)

local preview = Instance.new("Frame", previewContainer)
preview.Size = UDim2.new(0.8, 0, 0.8, 0)
preview.AnchorPoint = Vector2.new(0.5, 0.5); preview.Position = UDim2.new(0.5,0,0.5,0)
preview.BackgroundColor3 = Color3.new(1,1,1); preview.ZIndex = 27
Instance.new("UICorner", preview).CornerRadius = UDim.new(1, 0)

local currentItemToColor = nil
local selectedColor = Color3.new(1,1,1)

-- PALETA DE 32 COLORES ORDENADA
local COLORS_PALETTE = {
	-- FILA 1: Cálidos (Rojos a Verdes)
	Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 85, 0), Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(170, 255, 0), Color3.fromRGB(85, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 85),
	
	-- FILA 2: Fríos (Cianes a Violetas)
	Color3.fromRGB(0, 255, 170), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 85, 255),
	Color3.fromRGB(0, 0, 255), Color3.fromRGB(85, 0, 255), Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 0, 255),
	
	-- FILA 3: Intensos y Oscuros
	Color3.fromRGB(255, 0, 170), Color3.fromRGB(255, 0, 85), Color3.fromRGB(255, 20, 147), Color3.fromRGB(75, 0, 130),
	Color3.fromRGB(128, 0, 0), Color3.fromRGB(0, 0, 128), Color3.fromRGB(0, 100, 0), Color3.fromRGB(0, 128, 128), 
	
	-- FILA 4: Tierras y Grises
	Color3.fromRGB(244, 164, 96), Color3.fromRGB(210, 105, 30), Color3.fromRGB(139, 69, 19), Color3.fromRGB(80, 40, 0),
	Color3.fromRGB(200, 200, 200), Color3.fromRGB(150, 150, 150), Color3.fromRGB(100, 100, 100), Color3.fromRGB(50, 50, 50)
}

local gridContainer = Instance.new("ScrollingFrame", rgbFrame)
gridContainer.Size = UDim2.new(0.85, 0, 0.45, 0)
gridContainer.Position = UDim2.new(0.5, 0, 0.44, 0); gridContainer.AnchorPoint = Vector2.new(0.5, 0) 
gridContainer.BackgroundTransparency = 1; gridContainer.ZIndex = 26
gridContainer.ScrollBarThickness = 6; gridContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 200)
gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
gridContainer.CanvasSize = UDim2.new(0,0,0,0)

local gridLayout = Instance.new("UIGridLayout", gridContainer)
-- [AJUSTE MÓVIL] Celdas más pequeñas
local gSize = isMobile and 25 or 36
gridLayout.CellSize = UDim2.new(0, gSize, 0, gSize)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8) 
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local gridButtons = {}

local function updateGridVisuals()
	for _, data in ipairs(gridButtons) do
		local btn = data.Button
		local col = data.Color
		
		-- Comparar color flotante
		local isSelected = (math.abs(col.R - selectedColor.R) < 0.01) and
						   (math.abs(col.G - selectedColor.G) < 0.01) and
						   (math.abs(col.B - selectedColor.B) < 0.01)
		
		local stroke = btn:FindFirstChild("UIStroke")
		
		if isSelected then
			stroke.Color = Color3.new(1, 1, 1) -- Borde blanco brillante
			stroke.Thickness = 3
			stroke.Transparency = 0
			btn.ZIndex = 30 
		else
			stroke.Color = Color3.new(0, 0, 0)
			stroke.Thickness = 2
			stroke.Transparency = 0.5
			btn.ZIndex = 27
		end
	end
end

for _, col in ipairs(COLORS_PALETTE) do
	local btn = Instance.new("TextButton", gridContainer)
	btn.BackgroundColor3 = col; btn.Text = ""; btn.ZIndex = 27
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	local s = Instance.new("UIStroke", btn); s.Thickness = 2; s.Color = Color3.new(0,0,0); s.Transparency = 0.5
	
	btn.MouseButton1Click:Connect(function()
		selectedColor = col
		preview.BackgroundColor3 = col
		SoundManager.Play("ShopButton")
		
		local tw = TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5})
		tw:Play(); tw.Completed:Wait()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
		
		updateGridVisuals()
	end)
	
	table.insert(gridButtons, {Button = btn, Color = col})
end

local function createSelectorButton(parent, text, color1, color2, pos, size)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.Position = pos; btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.BackgroundColor3 = Color3.new(1,1,1); btn.Text = ""; btn.ZIndex = 27
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	applyGradient(btn, color1, color2, 90)
	createDeepStroke(btn, Color3.new(1,1,1), Color3.new(0.5,0.5,0.5), 2).Color = Color3.new(0,0,0)
	local lbl = Instance.new("TextLabel", btn)
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	lbl.TextSize = isMobile and 16 or 20; lbl.TextColor3 = Color3.new(1,1,1); lbl.ZIndex = 28
	local str = Instance.new("UIStroke", lbl); str.Thickness = 2; str.Color = Color3.new(0,0,0)
	return btn
end

local confirmColor = createSelectorButton(
	rgbFrame, getTxt("BTN_CONFIRM"), 
	Color3.fromRGB(0, 200, 100), Color3.fromRGB(0, 150, 50),
	UDim2.new(0.5, 0, 0.96, 0), UDim2.new(0.4, 0, 0.1, 0) -- Relativo
)
confirmColor.MouseButton1Click:Connect(function()
	if currentItemToColor and colorEvent then
		SoundManager.Play("AbilityReady") 
		colorEvent:FireServer(currentItemToColor, selectedColor.R, selectedColor.G, selectedColor.B)
	end
	rgbFrame.Visible = false
end)

local closeColor = Instance.new("TextButton", rgbFrame)
closeColor.Size = UDim2.new(0, 35, 0, 35); closeColor.Position = UDim2.new(1, -10, 0, 10); closeColor.AnchorPoint = Vector2.new(1, 0)
closeColor.BackgroundColor3 = Color3.fromRGB(200, 50, 50); closeColor.Text = "X"
closeColor.FontFace = Font.fromEnum(Enum.Font.GothamBlack); closeColor.TextColor3 = Color3.new(1,1,1)
closeColor.TextSize = 20; closeColor.ZIndex = 27
Instance.new("UICorner", closeColor)
closeColor.MouseButton1Click:Connect(function() SoundManager.Play("ShopButton"); rgbFrame.Visible = false end)

-- Función de apertura
local function openColorSelector(itemKey)
	if itemKey == "DoubleJumpColor" then 
		currentItemToColor = "DoubleJump"
		rgbTitle.Text = getTxt("ITEM_JUMP_COLOR")
	elseif itemKey == "DashColor" then 
		currentItemToColor = "Dash"
		rgbTitle.Text = getTxt("ITEM_DASH_COLOR")
	elseif itemKey == "BonkColor" then 
		currentItemToColor = "Bonk"
		rgbTitle.Text = getTxt("ITEM_BONK_COLOR")
	end
	
	local savedColor = player:GetAttribute(itemKey)
	if typeof(savedColor) ~= "Color3" then
		savedColor = Color3.fromRGB(255, 255, 255)
	end
	
	selectedColor = savedColor
	preview.BackgroundColor3 = selectedColor
	
	rgbFrame.Visible = true; screenGui.DisplayOrder = 25 
	
	updateGridVisuals()
end

-------------------------------------------------------------------
-- 4. RENDERIZADO (SHINY BAT RECUPERADO)
-------------------------------------------------------------------
local function renderAbilityRow(config, playerData)
	local isOwned = playerData[config.Key] == true
	
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 90)
	card.BackgroundColor3 = Color3.new(1,1,1); card.ZIndex = 11
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	applyGradient(card, Color3.fromRGB(50, 55, 70), Color3.fromRGB(35, 40, 50), 45)
	createDeepStroke(card, Color3.fromRGB(80, 90, 110), Color3.fromRGB(40, 45, 55), 2)
	
	local iconBg = Instance.new("Frame", card)
	iconBg.Size = UDim2.new(0, 70, 0, 70)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0); iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = Color3.new(0,0,0); iconBg.BackgroundTransparency = 0.5; iconBg.ZIndex = 12
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
	local icon = Instance.new("ImageLabel", iconBg)
	icon.Size = UDim2.new(0.8, 0, 0.8, 0); icon.Position = UDim2.new(0.5,0,0.5,0); icon.AnchorPoint = Vector2.new(0.5,0.5)
	icon.BackgroundTransparency = 1; icon.Image = config.Icon; icon.ZIndex = 13
	
	local nameLab = Instance.new("TextLabel", card)
	nameLab.Text = getTxt(config.NameKey)
	nameLab.Size = UDim2.new(0.5, 0, 0.4, 0); nameLab.Position = UDim2.new(0, 95, 0, 10)
	nameLab.BackgroundTransparency = 1; nameLab.TextColor3 = Color3.new(1,1,1)
	nameLab.FontFace = FontManager.Get("Cartoon"); nameLab.TextSize = isMobile and 22 or 26; nameLab.TextXAlignment = Enum.TextXAlignment.Left; nameLab.ZIndex = 12
	addTextStroke(nameLab)
	
	if isOwned then
		-- BOTÓN DE COLOR
		if config.Key == "DoubleJump" or config.Key == "DashUnlock" or config.Key == "BonkUnlock" then
			local colBtn = createStyledButton(card, getTxt("BTN_COLOR"), Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 100, 200))
			colBtn.Size = UDim2.new(0, 120, 0, 45); colBtn.Position = UDim2.new(1, -15, 0.5, 0); colBtn.AnchorPoint = Vector2.new(1, 0.5)
			colBtn.MouseButton1Click:Connect(function()
				SoundManager.Play("ShopButton")
				local hasPass = false
				if VipList.IsVip(player.UserId) then hasPass = true
				else pcall(function() hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID) end) end

				if hasPass then if config.ColorKey then openColorSelector(config.ColorKey) end
				else MarketplaceService:PromptGamePassPurchase(player, GAME_PASS_ID) end
			end)
			
			-- [SHINY BAT TOGGLE]
			if config.Key == "BonkUnlock" then
				local isShiny = player:GetAttribute("BonkNeon") == true
				local shinyText = isShiny and getTxt("LBL_SHINY") .. ": ON" or getTxt("LBL_SHINY") .. ": OFF"
				local c1 = isShiny and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(100, 100, 120)
				local c2 = isShiny and Color3.fromRGB(150, 0, 150) or Color3.fromRGB(60, 60, 80)
				
				local shinyBtn = createStyledButton(card, shinyText, c1, c2)
				-- [AJUSTE] Ancho aumentado a 200 para que entre el texto
				shinyBtn.Size = UDim2.new(0, 200, 0, 45)
				shinyBtn.Position = UDim2.new(1, -145, 0.5, 0); shinyBtn.AnchorPoint = Vector2.new(1, 0.5)
				
				local txt = shinyBtn:FindFirstChild("TextLabel"); if txt then txt.TextSize = 16 end
				
				shinyBtn.MouseButton1Click:Connect(function()
					SoundManager.Play("ShopButton")
					local hasAccess = false; if VipList.IsVip(player.UserId) then hasAccess = true else pcall(function() hasAccess = MarketplaceService:UserOwnsGamePassAsync(player.UserId, SHINY_PASS_ID) end) end
					if hasAccess then shinyEvent:FireServer(); task.wait(0.2); refreshAllTabs() else MarketplaceService:PromptGamePassPurchase(player, SHINY_PASS_ID) end
				end)
			end
		else
			local acquired = Instance.new("TextLabel", card)
			acquired.Text = getTxt("LBL_ACQUIRED"); acquired.Size = UDim2.new(0, 150, 0, 30)
			acquired.Position = UDim2.new(1, -15, 0.5, 0); acquired.AnchorPoint = Vector2.new(1, 0.5)
			acquired.BackgroundTransparency = 1; acquired.TextColor3 = Color3.fromRGB(100, 255, 100)
			acquired.FontFace = Font.fromEnum(Enum.Font.GothamBlack); acquired.TextSize = 20; acquired.ZIndex = 12
			addTextStroke(acquired)
		end
	else
		local price = ShopConfig.Prices[config.Key]
		local buyBtn = createStyledButton(card, "$ " .. price, Color3.fromRGB(0, 220, 100), Color3.fromRGB(0, 150, 50))
		buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5)
		buyBtn.MouseButton1Click:Connect(function()
			local s = shopFunction:InvokeServer("BuyUpgrade", config.Key)
			if s then SoundManager.Play("UnlockSkill"); refreshAllTabs() else SoundManager.Play("InsufficientFunds") end
		end)
	end
	return card
end

local function renderUpgradeRow(key, playerData)
	local lvl = playerData[key] or 1; local max = ShopConfig.MAX_LEVEL
	local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 70); row.BackgroundTransparency = 1; row.ZIndex = 11
	local title = Instance.new("TextLabel", row); local localeKey = STAT_TO_LOCALE[key] or key 
	title.Text = getTxt(localeKey); title.Size = UDim2.new(0.3, 0, 1, 0); title.Position = UDim2.new(0, 10, 0, 0); title.BackgroundTransparency = 1; title.TextColor3 = Color3.new(0.9, 0.9, 0.9); title.FontFace = Font.fromEnum(Enum.Font.GothamBold); title.TextSize = isMobile and 14 or 18; title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 12; addTextStroke(title)
	local barCont = Instance.new("Frame", row); barCont.Size = UDim2.new(0.4, 0, 0.4, 0); barCont.Position = UDim2.new(0.5, 0, 0.5, 0); barCont.AnchorPoint = Vector2.new(0.5, 0.5); barCont.BackgroundTransparency = 1; barCont.ZIndex = 12
	local blay = Instance.new("UIListLayout", barCont); blay.FillDirection = Enum.FillDirection.Horizontal; blay.Padding = UDim.new(0, 5); blay.HorizontalAlignment = Enum.HorizontalAlignment.Center 
	for i = 1, max do local sq = Instance.new("Frame", barCont); sq.Size = UDim2.new(0, 20, 1, 0); sq.BackgroundColor3 = Color3.new(1,1,1); sq.ZIndex = 13; Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 4); if i <= lvl then applyGradient(sq, Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 100, 200), 90) else applyGradient(sq, Color3.fromRGB(60, 60, 60), Color3.fromRGB(40, 40, 40), 90) end end
	if lvl >= max then local maxLab = Instance.new("TextLabel", row); maxLab.Text = "MAX"; maxLab.Size = UDim2.new(0, 80, 1, 0); maxLab.Position = UDim2.new(1, -10, 0, 0); maxLab.AnchorPoint = Vector2.new(1, 0); maxLab.BackgroundTransparency = 1; maxLab.TextColor3 = Color3.fromRGB(0, 255, 255); maxLab.FontFace = Font.fromEnum(Enum.Font.GothamBlack); maxLab.TextSize = 20; maxLab.ZIndex = 12; addTextStroke(maxLab)
	else local price = ShopConfig.Prices[key][lvl]; local upBtn = createStyledButton(row, "$ " .. price, Color3.fromRGB(255, 200, 50), Color3.fromRGB(200, 150, 0)); upBtn.Size = UDim2.new(0, 80, 0, 35); upBtn.Position = UDim2.new(1, -10, 0.5, 0); upBtn.AnchorPoint = Vector2.new(1, 0.5)
		upBtn.MouseButton1Click:Connect(function() local s = shopFunction:InvokeServer("BuyUpgrade", key); if s then SoundManager.Play("BuyUpgrade"); refreshAllTabs() else SoundManager.Play("InsufficientFunds") end end)
	end
	return row
end

local function renderCoinRow(pkg)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, 90); card.BackgroundColor3 = Color3.new(1,1,1); card.ZIndex = 11; Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10); applyGradient(card, Color3.fromRGB(60, 50, 80), Color3.fromRGB(40, 30, 60), 45); createDeepStroke(card, Color3.fromRGB(150, 100, 200), Color3.fromRGB(80, 40, 120), 2)
	local iconBg = Instance.new("Frame", card); iconBg.Size = UDim2.new(0, 70, 0, 70); iconBg.Position = UDim2.new(0, 10, 0.5, 0); iconBg.AnchorPoint = Vector2.new(0, 0.5); iconBg.BackgroundColor3 = Color3.new(0,0,0); iconBg.BackgroundTransparency = 0.5; iconBg.ZIndex = 12; Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
	local icon = Instance.new("ImageLabel", iconBg); icon.Size = UDim2.new(0.8, 0, 0.8, 0); icon.Position = UDim2.new(0.5,0,0.5,0); icon.AnchorPoint = Vector2.new(0.5,0.5); icon.BackgroundTransparency = 1; icon.Image = DecalManager.Get(pkg.IconKey); icon.ZIndex = 13
	local nameLab = Instance.new("TextLabel", card); nameLab.Text = string.format("%d COINS", pkg.Amount); nameLab.Size = UDim2.new(0.5, 0, 0.4, 0); nameLab.Position = UDim2.new(0, 95, 0, 10); nameLab.BackgroundTransparency = 1; nameLab.TextColor3 = Color3.fromRGB(255, 220, 0); nameLab.FontFace = FontManager.Get("Cartoon"); nameLab.TextSize = 28; nameLab.TextXAlignment = Enum.TextXAlignment.Left; nameLab.ZIndex = 12; addTextStroke(nameLab)
	local buyBtn = createStyledButton(card, pkg.PriceText, Color3.fromRGB(0, 200, 100), Color3.fromRGB(0, 150, 50)); buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	buyBtn.MouseButton1Click:Connect(function() SoundManager.Play("ShopButton"); MarketplaceService:PromptProductPurchase(player, pkg.ProductId) end)
	return card
end

refreshAllTabs = function()
	local success, data = pcall(function() return shopFunction:InvokeServer("GetData") end); if not success or not data then return end
	local abScroll = contentFrames["Abilities"]; for _, c in pairs(abScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, abilityConfig in ipairs(ABILITY_LIST) do renderAbilityRow(abilityConfig, data).Parent = abScroll end
	
	local upScroll = contentFrames["Upgrades"]; for _, c in pairs(upScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, group in ipairs(UPGRADE_GROUPS) do
		local showGroup = true; if group.Dependency and not data[group.Dependency] then showGroup = false end
		if showGroup then
			local headerContainer = Instance.new("Frame", upScroll); headerContainer.Size = UDim2.new(1, 0, 0, 35); headerContainer.BackgroundTransparency = 0; headerContainer.ZIndex = 11; Instance.new("UICorner", headerContainer).CornerRadius = UDim.new(0, 8); applyGradient(headerContainer, Color3.fromRGB(45, 55, 75), Color3.fromRGB(30, 35, 50), 90); local hStroke = Instance.new("UIStroke", headerContainer); hStroke.Thickness = 2; hStroke.Color = Color3.fromRGB(0, 200, 255); hStroke.Transparency = 0.5
			local h = Instance.new("TextLabel", headerContainer); h.Size = UDim2.new(1, 0, 1, 0); h.Position = UDim2.new(0.5, 0, 0.5, 3); h.AnchorPoint = Vector2.new(0.5, 0.5); h.BackgroundTransparency = 1; h.Text = getTxt(group.Header); h.TextColor3 = Color3.fromRGB(0, 255, 255); h.FontFace = FontManager.Get("Cartoon"); h.TextSize = 24; h.ZIndex = 12; h.TextYAlignment = Enum.TextYAlignment.Center; addTextStroke(h)
			for _, itemKey in ipairs(group.Items) do renderUpgradeRow(itemKey, data).Parent = upScroll end
		end
	end
	local coinScroll = contentFrames["Coins"]; for _, c in pairs(coinScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, pkg in ipairs(ShopConfig.CoinProducts) do renderCoinRow(pkg).Parent = coinScroll end
end

local isOpen = false
local function closeMenu()
	if not isOpen then return end; isOpen = false; menuFrame.Visible = false; mainBlocker.Visible = false; mainBlocker.BackgroundTransparency = 1; rgbFrame.Visible = false
	local stateRaw = estadoValue.Value or ""; local state = string.split(stateRaw, "|")[1]; if state == "SURVIVE" then UserInputService.MouseIconEnabled = false end
end

local function toggleMenu()
	isOpen = not isOpen
	menuFrame.Visible = isOpen
	mainBlocker.Visible = isOpen 
	
	if isOpen then 
		UserInputService.MouseIconEnabled = true
		SoundManager.Play("ShopButton")
		TweenService:Create(mainBlocker, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
		
		-- [MODIFICACIÓN PARA MÓVILES]
		local startSize, endSize
		if isMobile then
			startSize = UDim2.new(0.85, 0, 0.85, 0)
			endSize = UDim2.new(0.9, 0, 0.9, 0)
		else
			startSize = UDim2.new(0, 700, 0, 500)
			endSize = UDim2.new(0, 750, 0, 550)
		end
		
		menuFrame.Size = startSize
		TweenService:Create(menuFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = endSize}):Play()
		
		switchTab("Abilities")
		refreshAllTabs()
		task.spawn(function() while isOpen do refreshAllTabs(); break end end)
	else 
		mainBlocker.BackgroundTransparency = 1; rgbFrame.Visible = false; screenGui.DisplayOrder = 20
		local stateRaw = estadoValue.Value or ""; local state = string.split(stateRaw, "|")[1]
		if state == "SURVIVE" then UserInputService.MouseIconEnabled = false end 
	end
end

mainBlocker.MouseButton1Click:Connect(toggleMenu); toggleShopEvent.Event:Connect(toggleMenu)
toggleInvEvent.Event:Connect(closeMenu); toggleLogEvent.Event:Connect(closeMenu)
task.spawn(function() while true do wait(0.5); if isOpen then refreshAllTabs() end end end)
local function checkGameState() local raw = estadoValue.Value; local state = string.split(raw, "|")[1]; if state == "SURVIVE" then closeMenu() end end
estadoValue.Changed:Connect(checkGameState)