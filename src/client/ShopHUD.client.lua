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

-- IMPORTAMOS LA LISTA VIP
local VipList = require(sharedFolder:WaitForChild("VipList"))

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
local shopFunction = ReplicatedStorage:WaitForChild("ShopFunction")
local colorEvent = ReplicatedStorage:WaitForChild("ColorUpdateEvent", 5)
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")

-- ID DEL GAME PASS "CUSTOM COLORS!"
local GAME_PASS_ID = 1663859003 

local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
local function getTxt(key, ...)
	return Localization.get(key, playerLang, ...)
end

local refreshAllTabs 

-------------------------------------------------------------------
-- MAPEO EXACTO DE ESTADÍSTICAS A LOCALIZATION
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
	DashCooldown = "ITEM_COOLDOWN"
}

local ABILITY_LIST = {
	{Key = "DoubleJump", Icon = DecalManager.Get("DoubleJump"), NameKey = "ITEM_DOUBLE_JUMP", ColorKey = "DoubleJumpColor"}, 
	{Key = "PushUnlock", Icon = DecalManager.Get("Push"), NameKey = "HEADER_PUSH"},
	{Key = "DashUnlock", Icon = DecalManager.Get("Dash"), NameKey = "HEADER_DASH", ColorKey = "DashColor"},
}

local UPGRADE_GROUPS = {
	{ Header = "HEADER_JUMP", Dependency = nil, Items = {"JumpHeight", "JumpStaminaCost"} },
	{ Header = "HEADER_PUSH", Dependency = "PushUnlock", Items = {"PushDistance", "PushRange", "PushCooldown"} },
	{ Header = "HEADER_DASH", Dependency = "DashUnlock", Items = {"DashDistance", "DashSpeed", "DashCooldown"} },
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

-------------------------------------------------------------------
-- 1. UI SETUP (MARCO PRINCIPAL)
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

-- MARCO EXTERIOR
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Name = "ShopMenu"
menuFrame.Size = UDim2.new(0, 750, 0, 550) 
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0); menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.new(1,1,1)
menuFrame.Visible = false; menuFrame.ZIndex = 5 
menuFrame.Active = true 
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 16)

applyGradient(menuFrame, Color3.fromRGB(40, 45, 60), Color3.fromRGB(20, 22, 30), 45)
createDeepStroke(menuFrame, Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 50, 150), 4)

-- TÍTULO
local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, 0, 0, 60); title.BackgroundTransparency = 1
title.Text = getTxt("SHOP_TITLE")
title.FontFace = FontManager.Get("Cartoon")
title.TextSize = 45
title.TextColor3 = Color3.new(1,1,1)
title.Position = UDim2.new(0,0,0,10); title.ZIndex = 6
applyGradient(title, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 170, 0), 90)
local tStroke = Instance.new("UIStroke", title); tStroke.Thickness = 3; tStroke.Color = Color3.new(0,0,0)

-- MARCO INTERNO
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
-- 2. SISTEMA DE PESTAÑAS
-------------------------------------------------------------------
local tabContainer = Instance.new("Frame", menuFrame)
tabContainer.Name = "Tabs"
tabContainer.Size = UDim2.new(1, -30, 0, 45) 
tabContainer.Position = UDim2.new(0.5, 0, 0, 75); tabContainer.AnchorPoint = Vector2.new(0.5, 0)
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
	btn.TextSize = 18
	btn.TextColor3 = Color3.new(1,1,1)
	btn.ZIndex = 7
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
	sc.Size = UDim2.new(1, -20, 1, -20)
	sc.Position = UDim2.new(0.5, 0, 0.5, 0); sc.AnchorPoint = Vector2.new(0.5, 0.5)
	sc.BackgroundTransparency = 1
	sc.ScrollBarThickness = 6
	sc.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	sc.Visible = false
	sc.ZIndex = 10
	sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
	
	local lay = Instance.new("UIListLayout", sc)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 10)
	
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
-- 3. SELECTOR DE COLOR
-------------------------------------------------------------------
-- MARCO SELECTOR
local rgbFrame = Instance.new("Frame", screenGui)
rgbFrame.Name = "RGBSelector"
rgbFrame.Size = UDim2.new(0, 450, 0, 550) 
rgbFrame.Position = UDim2.new(0.5, 0, 0.5, 0); rgbFrame.AnchorPoint = Vector2.new(0.5, 0.5)
rgbFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
rgbFrame.Visible = false; rgbFrame.ZIndex = 25 
rgbFrame.Active = true 
Instance.new("UICorner", rgbFrame)
applyGradient(rgbFrame, Color3.fromRGB(40, 45, 60), Color3.fromRGB(20, 22, 30), 45)
createDeepStroke(rgbFrame, Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 50, 150), 4)

local rgbTitle = Instance.new("TextLabel", rgbFrame)
rgbTitle.Size = UDim2.new(1,0,0,50); rgbTitle.BackgroundTransparency = 1
rgbTitle.Text = getTxt("COLOR_SELECTOR")
rgbTitle.TextColor3 = Color3.new(1,1,1)
rgbTitle.FontFace = FontManager.Get("Cartoon")
rgbTitle.TextSize = 28; rgbTitle.ZIndex = 26
local rgbTStroke = Instance.new("UIStroke", rgbTitle); rgbTStroke.Thickness = 2; rgbTStroke.Color = Color3.new(0,0,0)

-- PREVIEW BOX
local previewContainer = Instance.new("Frame", rgbFrame)
previewContainer.Size = UDim2.new(0, 80, 0, 80)
previewContainer.Position = UDim2.new(0.5, 0, 0.18, 0); previewContainer.AnchorPoint = Vector2.new(0.5, 0)
previewContainer.BackgroundColor3 = Color3.new(0,0,0); previewContainer.ZIndex = 26
Instance.new("UICorner", previewContainer).CornerRadius = UDim.new(1,0)

local preview = Instance.new("Frame", previewContainer)
preview.Size = UDim2.new(0.85, 0, 0.85, 0)
preview.AnchorPoint = Vector2.new(0.5, 0.5); preview.Position = UDim2.new(0.5,0,0.5,0)
preview.BackgroundColor3 = Color3.new(1,1,1); preview.ZIndex = 27
Instance.new("UICorner", preview).CornerRadius = UDim.new(1,0)

-- ESTADO
local currentItemToColor = nil
local selectedColor = Color3.new(1,1,1)

-- PALETA DE 30 COLORES
local COLORS_PALETTE = {
	Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 85, 0), Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(170, 255, 0), Color3.fromRGB(85, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 85),
	Color3.fromRGB(0, 255, 170), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 85, 255),
	Color3.fromRGB(0, 0, 255), Color3.fromRGB(85, 0, 255), Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(255, 0, 170), Color3.fromRGB(255, 0, 85), Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200),
	Color3.fromRGB(150, 150, 150), Color3.fromRGB(100, 100, 100), Color3.fromRGB(50, 50, 50), Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(80, 40, 0), Color3.fromRGB(139, 69, 19), Color3.fromRGB(210, 105, 30), Color3.fromRGB(244, 164, 96),
	Color3.fromRGB(255, 20, 147), Color3.fromRGB(75, 0, 130)
}

-- CONTENEDOR CON SCROLL PARA LA GRILLA
local gridContainer = Instance.new("ScrollingFrame", rgbFrame)
gridContainer.Size = UDim2.new(0.9, 0, 0.45, 0)
gridContainer.Position = UDim2.new(0.5, 0, 0.42, 0); gridContainer.AnchorPoint = Vector2.new(0.5, 0)
gridContainer.BackgroundTransparency = 1; gridContainer.ZIndex = 26
gridContainer.ScrollBarThickness = 6; gridContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 200)
gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
gridContainer.CanvasSize = UDim2.new(0,0,0,0)

local gridLayout = Instance.new("UIGridLayout", gridContainer)
gridLayout.CellSize = UDim2.new(0, 45, 0, 45)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- CREAR BOTONES DE COLOR
for _, col in ipairs(COLORS_PALETTE) do
	local btn = Instance.new("TextButton", gridContainer)
	btn.BackgroundColor3 = col
	btn.Text = ""; btn.ZIndex = 27
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local s = Instance.new("UIStroke", btn)
	s.Thickness = 2; s.Color = Color3.new(1,1,1); s.Transparency = 0.7
	
	btn.MouseButton1Click:Connect(function()
		selectedColor = col
		preview.BackgroundColor3 = col
		SoundManager.Play("ShopButton")
	end)
end

-- FUNCIÓN HELPER PARA BOTONES ESTILIZADOS DEL SELECTOR
local function createSelectorButton(parent, text, color1, color2, pos, size)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.Position = pos; btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.BackgroundColor3 = Color3.new(1,1,1); btn.Text = ""
	btn.ZIndex = 27
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	applyGradient(btn, color1, color2, 90)
	createDeepStroke(btn, Color3.new(1,1,1), Color3.new(0.5,0.5,0.5), 2).Color = Color3.new(0,0,0)
	
	local lbl = Instance.new("TextLabel", btn)
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	lbl.TextSize = 20; lbl.TextColor3 = Color3.new(1,1,1); lbl.ZIndex = 28
	local str = Instance.new("UIStroke", lbl); str.Thickness = 2; str.Color = Color3.new(0,0,0)
	return btn
end

-- BOTÓN CONFIRMAR
local confirmColor = createSelectorButton(
	rgbFrame, getTxt("BTN_CONFIRM"), 
	Color3.fromRGB(0, 200, 100), Color3.fromRGB(0, 150, 50),
	UDim2.new(0.5, 0, 0.96, 0), UDim2.new(0, 160, 0, 50)
)

confirmColor.MouseButton1Click:Connect(function()
	if currentItemToColor and colorEvent then
		SoundManager.Play("AbilityReady") 
		-- ENVÍO AL SERVIDOR
		colorEvent:FireServer(currentItemToColor, selectedColor.R, selectedColor.G, selectedColor.B)
	end
	rgbFrame.Visible = false
end)

-- BOTÓN CERRAR (X)
local closeColor = Instance.new("TextButton", rgbFrame)
closeColor.Size = UDim2.new(0, 35, 0, 35); closeColor.Position = UDim2.new(1, -10, 0, 10); closeColor.AnchorPoint = Vector2.new(1, 0)
closeColor.BackgroundColor3 = Color3.fromRGB(200, 50, 50); closeColor.Text = "X"
closeColor.FontFace = Font.fromEnum(Enum.Font.GothamBlack); closeColor.TextColor3 = Color3.new(1,1,1)
closeColor.TextSize = 20; closeColor.ZIndex = 27
Instance.new("UICorner", closeColor)

closeColor.MouseButton1Click:Connect(function()
	SoundManager.Play("ShopButton")
	rgbFrame.Visible = false
end)

local function openColorSelector(itemKey)
	currentItemToColor = (itemKey == "DoubleJumpColor" and "DoubleJump") or (itemKey == "DashColor" and "Dash")
	rgbFrame.Visible = true
	screenGui.DisplayOrder = 25 
end

-------------------------------------------------------------------
-- 4. RENDERIZADO DE FILAS
-------------------------------------------------------------------
local function createStyledButton(parent, text, color1, color2)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0, 120, 0, 45)
	btn.BackgroundColor3 = Color3.new(1,1,1)
	btn.Text = "" 
	btn.AutoButtonColor = true 
	btn.ZIndex = 12
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	applyGradient(btn, color1, color2, 90)
	createDeepStroke(btn, Color3.new(1,1,1), Color3.new(0.5,0.5,0.5), 2).Color = Color3.new(0,0,0)
	
	-- TEXT LABEL PERSONALIZADO
	local label = Instance.new("TextLabel", btn)
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	label.TextSize = 22 
	label.TextColor3 = Color3.new(1,1,1)
	label.ZIndex = 13
	
	-- Gradiente Blanco a Gris
	local tGrad = Instance.new("UIGradient", label)
	tGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
	}
	tGrad.Rotation = 90
	
	-- Stroke Negro
	local tStroke = Instance.new("UIStroke", label)
	tStroke.Thickness = 2
	tStroke.Color = Color3.new(0,0,0)
	
	return btn
end

local function renderAbilityRow(config, playerData)
	local isOwned = playerData[config.Key] == true
	
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 90)
	card.BackgroundColor3 = Color3.new(1,1,1)
	card.ZIndex = 11
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	applyGradient(card, Color3.fromRGB(50, 55, 70), Color3.fromRGB(35, 40, 50), 45)
	createDeepStroke(card, Color3.fromRGB(80, 90, 110), Color3.fromRGB(40, 45, 55), 2)
	
	local iconBg = Instance.new("Frame", card)
	iconBg.Size = UDim2.new(0, 70, 0, 70)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0); iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = Color3.new(0,0,0); iconBg.BackgroundTransparency = 0.5
	iconBg.ZIndex = 12
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
	
	local icon = Instance.new("ImageLabel", iconBg)
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5,0,0.5,0); icon.AnchorPoint = Vector2.new(0.5,0.5)
	icon.BackgroundTransparency = 1; icon.Image = config.Icon
	icon.ZIndex = 13
	
	local nameLab = Instance.new("TextLabel", card)
	nameLab.Text = getTxt(config.NameKey)
	nameLab.Size = UDim2.new(0.5, 0, 0.4, 0)
	nameLab.Position = UDim2.new(0, 95, 0, 10)
	nameLab.BackgroundTransparency = 1
	nameLab.TextColor3 = Color3.new(1,1,1)
	nameLab.FontFace = FontManager.Get("Cartoon")
	nameLab.TextSize = 26
	nameLab.TextXAlignment = Enum.TextXAlignment.Left
	nameLab.ZIndex = 12
	
	if isOwned then
		-- Si es una habilidad con color (Salto Doble o Dash)
		if config.Key == "DoubleJump" or config.Key == "DashUnlock" then
			local colBtn = createStyledButton(
				card, 
				getTxt("BTN_COLOR"), 
				Color3.fromRGB(0, 150, 255), 
				Color3.fromRGB(0, 100, 200)
			)
			colBtn.Size = UDim2.new(0, 120, 0, 45)
			colBtn.Position = UDim2.new(1, -15, 0.5, 0); colBtn.AnchorPoint = Vector2.new(1, 0.5)
			
			-- [MODIFICACIÓN VIP]: USANDO MÓDULO VIPLIST
			colBtn.MouseButton1Click:Connect(function()
				SoundManager.Play("ShopButton")
				
				local hasPass = false
				
				-- 1. CHEQUEO VIP (GRATIS)
				if VipList.IsVip(player.UserId) then
					hasPass = true
				else
					-- 2. CHEQUEO NORMAL (PAGO)
					pcall(function()
						hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
					end)
				end

				if hasPass then
					-- TIENE PASE/ES VIP: Abrir Selector
					if config.ColorKey then
						openColorSelector(config.ColorKey)
					end
				else
					-- NO TIENE PASE: Sugerir Compra
					MarketplaceService:PromptGamePassPurchase(player, GAME_PASS_ID)
				end
			end)
		else
			-- Etiqueta ADQUIRIDO normal
			local acquired = Instance.new("TextLabel", card)
			acquired.Text = getTxt("LBL_ACQUIRED")
			acquired.Size = UDim2.new(0, 150, 0, 30)
			acquired.Position = UDim2.new(1, -15, 0.5, 0); acquired.AnchorPoint = Vector2.new(1, 0.5)
			acquired.BackgroundTransparency = 1
			acquired.TextColor3 = Color3.fromRGB(100, 255, 100)
			acquired.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
			acquired.TextSize = 20
			acquired.ZIndex = 12
		end
	else
		local price = ShopConfig.Prices[config.Key]
		local buyBtn = createStyledButton(
			card, 
			"$ " .. price, 
			Color3.fromRGB(0, 220, 100), 
			Color3.fromRGB(0, 150, 50)
		)
		buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5)
		
		buyBtn.MouseButton1Click:Connect(function()
			local s = shopFunction:InvokeServer("BuyUpgrade", config.Key)
			if s then 
				SoundManager.Play("UnlockSkill") 
				refreshAllTabs() 
			else 
				SoundManager.Play("InsufficientFunds") 
			end
		end)
	end
	return card
end

local function renderUpgradeRow(key, playerData)
	local lvl = playerData[key] or 1
	local max = ShopConfig.MAX_LEVEL
	
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 70)
	row.BackgroundTransparency = 1
	row.ZIndex = 11
	
	local title = Instance.new("TextLabel", row)
	local localeKey = STAT_TO_LOCALE[key] or key 
	title.Text = getTxt(localeKey)
	
	title.Size = UDim2.new(0.3, 0, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 12
	
	-- BARRA DE PROGRESO (CENTRADA)
	local barCont = Instance.new("Frame", row)
	barCont.Size = UDim2.new(0.4, 0, 0.4, 0)
	barCont.Position = UDim2.new(0.5, 0, 0.5, 0); barCont.AnchorPoint = Vector2.new(0.5, 0.5)
	barCont.BackgroundTransparency = 1
	barCont.ZIndex = 12
	local blay = Instance.new("UIListLayout", barCont)
	blay.FillDirection = Enum.FillDirection.Horizontal
	blay.Padding = UDim.new(0, 5)
	blay.HorizontalAlignment = Enum.HorizontalAlignment.Center 
	
	for i = 1, max do
		local sq = Instance.new("Frame", barCont)
		sq.Size = UDim2.new(0, 20, 1, 0)
		sq.BackgroundColor3 = Color3.new(1,1,1)
		sq.ZIndex = 13
		Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 4)
		
		if i <= lvl then
			applyGradient(sq, Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 100, 200), 90)
		else
			applyGradient(sq, Color3.fromRGB(60, 60, 60), Color3.fromRGB(40, 40, 40), 90)
		end
	end
	
	if lvl >= max then
		local maxLab = Instance.new("TextLabel", row)
		maxLab.Text = "MAX"
		maxLab.Size = UDim2.new(0, 80, 1, 0)
		maxLab.Position = UDim2.new(1, -10, 0, 0); maxLab.AnchorPoint = Vector2.new(1, 0)
		maxLab.BackgroundTransparency = 1
		maxLab.TextColor3 = Color3.fromRGB(0, 255, 255)
		maxLab.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
		maxLab.TextSize = 20
		maxLab.ZIndex = 12
	else
		local price = ShopConfig.Prices[key][lvl]
		local upBtn = createStyledButton(
			row, 
			"$ " .. price, 
			Color3.fromRGB(255, 200, 50), 
			Color3.fromRGB(200, 150, 0)
		)
		upBtn.Size = UDim2.new(0, 80, 0, 35)
		upBtn.Position = UDim2.new(1, -10, 0.5, 0); upBtn.AnchorPoint = Vector2.new(1, 0.5)
		
		upBtn.MouseButton1Click:Connect(function()
			local s = shopFunction:InvokeServer("BuyUpgrade", key)
			if s then 
				SoundManager.Play("BuyUpgrade") 
				refreshAllTabs()
			else 
				SoundManager.Play("InsufficientFunds") 
			end
		end)
	end
	return row
end

-- [NUEVO] RENDERIZADO DE FILA DE MONEDAS
local function renderCoinRow(pkg)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 90)
	card.BackgroundColor3 = Color3.new(1,1,1)
	card.ZIndex = 11
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	applyGradient(card, Color3.fromRGB(60, 50, 80), Color3.fromRGB(40, 30, 60), 45) -- Morado/Oro oscuro
	createDeepStroke(card, Color3.fromRGB(150, 100, 200), Color3.fromRGB(80, 40, 120), 2)
	
	-- ICONO
	local iconBg = Instance.new("Frame", card)
	iconBg.Size = UDim2.new(0, 70, 0, 70)
	iconBg.Position = UDim2.new(0, 10, 0.5, 0); iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = Color3.new(0,0,0); iconBg.BackgroundTransparency = 0.5
	iconBg.ZIndex = 12
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
	
	local icon = Instance.new("ImageLabel", iconBg)
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.5,0,0.5,0); icon.AnchorPoint = Vector2.new(0.5,0.5)
	icon.BackgroundTransparency = 1; 
	icon.Image = DecalManager.Get(pkg.IconKey) -- Usamos DecalManager con la clave nueva
	icon.ZIndex = 13
	
	-- TEXTO
	local nameLab = Instance.new("TextLabel", card)
	nameLab.Text = string.format("%d COINS", pkg.Amount)
	nameLab.Size = UDim2.new(0.5, 0, 0.4, 0)
	nameLab.Position = UDim2.new(0, 95, 0, 10)
	nameLab.BackgroundTransparency = 1
	nameLab.TextColor3 = Color3.fromRGB(255, 220, 0) -- Dorado
	nameLab.FontFace = FontManager.Get("Cartoon")
	nameLab.TextSize = 28
	nameLab.TextXAlignment = Enum.TextXAlignment.Left
	nameLab.ZIndex = 12
	
	-- BOTÓN DE COMPRA (ROBUX)
	local buyBtn = createStyledButton(
		card, 
		pkg.PriceText, 
		Color3.fromRGB(0, 200, 100), 
		Color3.fromRGB(0, 150, 50)
	)
	buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	
	buyBtn.MouseButton1Click:Connect(function()
		SoundManager.Play("ShopButton")
		MarketplaceService:PromptProductPurchase(player, pkg.ProductId)
	end)
	
	return card
end

-------------------------------------------------------------------
-- 4. REFRESCAR TIENDA
-------------------------------------------------------------------
refreshAllTabs = function()
	local success, data = pcall(function() return shopFunction:InvokeServer("GetData") end)
	if not success or not data then return end
	
	-- PESTAÑA HABILIDADES
	local abScroll = contentFrames["Abilities"]
	for _, c in pairs(abScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, abilityConfig in ipairs(ABILITY_LIST) do
		local card = renderAbilityRow(abilityConfig, data)
		card.Parent = abScroll
	end
	
	-- PESTAÑA MEJORAS
	local upScroll = contentFrames["Upgrades"]
	for _, c in pairs(upScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
	for _, group in ipairs(UPGRADE_GROUPS) do
		local showGroup = true
		if group.Dependency and not data[group.Dependency] then showGroup = false end
		
		if showGroup then
			local h = Instance.new("TextLabel", upScroll)
			h.Text = getTxt(group.Header)
			h.Size = UDim2.new(1, 0, 0, 30)
			h.BackgroundTransparency = 1
			h.TextColor3 = Color3.fromRGB(0, 255, 255)
			h.FontFace = FontManager.Get("Cartoon")
			h.TextSize = 24
			h.ZIndex = 12
			
			for _, itemKey in ipairs(group.Items) do
				local row = renderUpgradeRow(itemKey, data)
				row.Parent = upScroll
			end
		end
	end
	
	-- [MODIFICADO] PESTAÑA MONEDAS
	local coinScroll = contentFrames["Coins"]
	for _, c in pairs(coinScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	
	for _, pkg in ipairs(ShopConfig.CoinProducts) do
		local card = renderCoinRow(pkg)
		card.Parent = coinScroll
	end
end

-------------------------------------------------------------------
-- 5. CONTROL DE APERTURA
-------------------------------------------------------------------
local isOpen = false

local function toggleMenu()
	isOpen = not isOpen
	menuFrame.Visible = isOpen
	mainBlocker.Visible = isOpen 
	
	if isOpen then
		SoundManager.Play("ShopButton") 
		
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine)
		TweenService:Create(mainBlocker, tweenInfo, {BackgroundTransparency = 0.4}):Play() 
		
		switchTab("Abilities") 
		refreshAllTabs()
		
		task.spawn(function()
			while isOpen do
				refreshAllTabs()
				break 
			end
		end)
	else
		mainBlocker.BackgroundTransparency = 1
		rgbFrame.Visible = false -- Cerrar selector si se cierra tienda
		screenGui.DisplayOrder = 20
	end
end

mainBlocker.MouseButton1Click:Connect(function() if isOpen then toggleMenu() end end)
toggleShopEvent.Event:Connect(toggleMenu)

task.spawn(function()
	while true do
		wait(0.5)
		if isOpen then refreshAllTabs() end 
	end
end)

local function checkGameState()
	local raw = estadoValue.Value
	local state = string.split(raw, "|")[1]
	if state == "SURVIVE" then
		isOpen = false
		menuFrame.Visible = false
		mainBlocker.Visible = false
		rgbFrame.Visible = false
	end
end
estadoValue.Changed:Connect(checkGameState)