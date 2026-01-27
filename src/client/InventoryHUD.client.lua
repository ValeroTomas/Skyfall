local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService") -- Servicio Input

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- MANAGER ASSETS
local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local Localization = require(sharedFolder:WaitForChild("Localization"))

-- DETECCIÓN MÓVIL
local isMobile = UserInputService.TouchEnabled

-- LOCALIZATION SETUP
local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
local function getTxt(key, ...)
	return Localization.get(key, playerLang, ...)
end

-- EVENTOS MANUALES
local toggleInvEvent = ReplicatedStorage:WaitForChild("ToggleInventoryEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local toggleLogEvent = ReplicatedStorage:WaitForChild("ToggleChangelogEvent")
local toggleSetEvent = ReplicatedStorage:WaitForChild("ToggleSettingsEvent")

local equipEvent = ReplicatedStorage:FindFirstChild("EquipAbilityEvent")
if not equipEvent then
	equipEvent = Instance.new("RemoteEvent")
	equipEvent.Name = "EquipAbilityEvent"
	equipEvent.Parent = ReplicatedStorage
end

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- DATA HABILIDADES
local ALL_ABILITIES = {
	{Name = "Push", Icon = DecalManager.Get("Push"), UnlockKey = "PushUnlock"},
	{Name = "Dash", Icon = DecalManager.Get("Dash"), UnlockKey = "DashUnlock"},
	{Name = "Bonk", Icon = DecalManager.Get("Bonk"), UnlockKey = "BonkUnlock"},
}

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
screenGui.Name = "InventoryUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 25 
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
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.new(1,1,1) 
mainFrame.Visible = false
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

applyGradient(mainFrame, Color3.fromRGB(35, 30, 45), Color3.fromRGB(20, 18, 25), 45)
createDeepStroke(mainFrame, Color3.fromRGB(180, 80, 255), Color3.fromRGB(100, 20, 200), 4)

-- Click Shield
local shield = Instance.new("TextButton", mainFrame)
shield.Size = UDim2.new(1,0,1,0); shield.BackgroundTransparency = 1; shield.Text = ""
shield.AutoButtonColor = false; shield.ZIndex = 1

-- Título (Ajuste Móvil)
local titleSize = isMobile and 32 or 42
local titleHeight = isMobile and 40 or 50

local title = Instance.new("TextLabel", mainFrame)
title.Text = getTxt("HUD_INVENTORY")
title.Size = UDim2.new(1, 0, 0, titleHeight)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.FontFace = FontManager.Get("Cartoon"); title.TextSize = titleSize
title.TextColor3 = Color3.fromRGB(255, 255, 255); title.ZIndex = 5
addTextStroke(title, 3)
applyGradient(title, Color3.fromRGB(255, 255, 200), Color3.fromRGB(200, 180, 255), 90)

-- Contenedor Habilidades (Izq)
local listFrame = Instance.new("ScrollingFrame", mainFrame)
listFrame.Size = UDim2.new(0.45, 0, 0.78, 0)
listFrame.Position = UDim2.new(0.05, 0, 0.18, 0)
listFrame.BackgroundColor3 = Color3.new(1,1,1); listFrame.ZIndex = 5
listFrame.ScrollBarThickness = 6; listFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 50, 255)
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
applyGradient(listFrame, Color3.fromRGB(30, 30, 40), Color3.fromRGB(15, 15, 20), 90)
createDeepStroke(listFrame, Color3.fromRGB(60, 60, 80), Color3.fromRGB(30, 30, 40), 2)

local listPad = Instance.new("UIPadding", listFrame)
listPad.PaddingTop = UDim.new(0, 15); listPad.PaddingBottom = UDim.new(0, 15)
listPad.PaddingLeft = UDim.new(0, 10); listPad.PaddingRight = UDim.new(0, 10) -- Padding reducido

local grid = Instance.new("UIGridLayout", listFrame)
-- [AJUSTE MÓVIL] Celdas más pequeñas
local cellSize = isMobile and 50 or 70
grid.CellSize = UDim2.new(0, cellSize, 0, cellSize)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; listFrame.CanvasSize = UDim2.new(0,0,0,0)

-- Contenedor Slots (Der)
local slotsFrame = Instance.new("Frame", mainFrame)
slotsFrame.Size = UDim2.new(0.4, 0, 0.75, 0); slotsFrame.Position = UDim2.new(0.55, 0, 0.18, 0)
slotsFrame.BackgroundTransparency = 1; slotsFrame.ZIndex = 5
local slotsList = Instance.new("UIListLayout", slotsFrame)
slotsList.FillDirection = Enum.FillDirection.Vertical
slotsList.Padding = UDim.new(0, isMobile and 10 or 20) -- Menos espacio entre slots
slotsList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local selectedAbility = nil
local abilityButtons = {}
local equipSlots = {}

-------------------------------------------------------------------
-- RENDERIZADO
-------------------------------------------------------------------
local function updateSelection()
	for name, btn in pairs(abilityButtons) do
		local s = btn:FindFirstChild("UIStroke")
		if s then
			if selectedAbility == name then
				s.Color = Color3.new(1,1,1)
				applyGradient(s, Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 200, 50), 45)
				s.Thickness = 4
			else
				s.Color = Color3.new(1,1,1)
				applyGradient(s, Color3.fromRGB(100, 100, 120), Color3.fromRGB(60, 60, 70), 45)
				s.Thickness = 2
			end
		end
	end
end

local function renderPool()
	for _, child in pairs(listFrame:GetChildren()) do if child:IsA("ImageButton") then child:Destroy() end end
	abilityButtons = {}
	
	for _, ab in ipairs(ALL_ABILITIES) do
		local isUnlocked = player:GetAttribute(ab.UnlockKey) == true
		
		local btn = Instance.new("ImageButton", listFrame)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
		btn.BackgroundTransparency = 0.3 
		btn.Image = ab.Icon
		btn.ImageTransparency = isUnlocked and 0 or 0.8
		btn.ZIndex = 6
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		
		createDeepStroke(btn, Color3.fromRGB(100, 100, 120), Color3.fromRGB(60, 60, 70), 2)
		
		if not isUnlocked then
			local lock = Instance.new("TextLabel", btn)
			lock.Size = UDim2.new(1,0,1,0); lock.BackgroundTransparency = 1
			lock.Text = "🔒"; lock.TextSize = isMobile and 20 or 28; lock.ZIndex = 7
			addTextStroke(lock, 2)
		else
			btn.MouseButton1Click:Connect(function()
				selectedAbility = ab.Name
				SoundManager.Play("ShopButton")
				updateSelection()
			end)
			abilityButtons[ab.Name] = btn
		end
	end
	updateSelection()
end

local function renderSlots()
	for _, child in pairs(slotsFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	equipSlots = {}
	
	for i = 1, 3 do
		local slotName = "EquippedSlot" .. i
		local currentEq = player:GetAttribute(slotName)
		
		-- [AJUSTE MÓVIL] Altura reducida para que entren
		local slotHeight = isMobile and 60 or 90
		
		local frame = Instance.new("Frame", slotsFrame)
		frame.Size = UDim2.new(1, 0, 0, slotHeight)
		frame.BackgroundColor3 = Color3.new(1,1,1)
		frame.ZIndex = 6
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
		
		applyGradient(frame, Color3.fromRGB(60, 55, 70), Color3.fromRGB(45, 40, 50), 90)
		createDeepStroke(frame, Color3.fromRGB(200, 150, 255), Color3.fromRGB(100, 50, 200), 2)
		
		local num = Instance.new("TextLabel", frame)
		num.Text = tostring(i)
		num.Size = UDim2.new(0, 40, 1, 0); num.Position = UDim2.new(0, 5, 0, 0)
		num.BackgroundTransparency = 1; num.TextColor3 = Color3.new(1,1,1)
		num.TextSize = isMobile and 28 or 38; num.FontFace = FontManager.Get("Cartoon"); num.ZIndex = 7
		addTextStroke(num, 3, 0)
		applyGradient(num, Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), 90)
		
		if currentEq then
			local iconData = nil
			for _, ab in ipairs(ALL_ABILITIES) do if ab.Name == currentEq then iconData = ab.Icon break end end
			
			if iconData then
				local icon = Instance.new("ImageLabel", frame)
				-- Ajuste icono
				icon.Size = UDim2.new(0, isMobile and 45 or 65, 0, isMobile and 45 or 65)
				icon.Position = UDim2.new(0.5, 0, 0.5, 0)
				icon.AnchorPoint = Vector2.new(0.5, 0.5); icon.BackgroundTransparency = 1
				icon.Image = iconData; icon.ZIndex = 7
				icon.ImageColor3 = Color3.new(1,1,1) 
			end
			
			local unequip = Instance.new("TextButton", frame)
			unequip.Text = "X"
			unequip.Size = UDim2.new(0, 24, 0, 24)
			unequip.Position = UDim2.new(1, -5, 0.5, 0)
			unequip.AnchorPoint = Vector2.new(1, 0.5)
			unequip.BackgroundColor3 = Color3.new(1,1,1)
			unequip.TextColor3 = Color3.new(0,0,0)
			unequip.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
			unequip.TextSize = 14
			unequip.ZIndex = 8
			Instance.new("UICorner", unequip, UDim.new(0, 6))
			
			applyGradient(unequip, Color3.fromRGB(255, 100, 100), Color3.fromRGB(200, 50, 50), 45)
			createDeepStroke(unequip, Color3.fromRGB(150, 0, 0), Color3.fromRGB(80, 0, 0), 2)
			
			unequip.MouseButton1Click:Connect(function()
				equipEvent:FireServer(i, nil) 
				SoundManager.Play("AbilityError") 
				task.wait(0.1); renderSlots()
			end)
		else
			local empty = Instance.new("TextLabel", frame)
			empty.Text = getTxt("HUD_EMPTY") 
			empty.Size = UDim2.new(1,0,1,0); empty.BackgroundTransparency = 1
			empty.TextColor3 = Color3.fromRGB(150,150,170); empty.ZIndex = 7
			empty.FontFace = FontManager.Get("Cartoon"); empty.TextSize = isMobile and 18 or 24
		end
		
		local btn = Instance.new("TextButton", frame)
		btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 9
		btn.MouseButton1Click:Connect(function()
			if selectedAbility then
				SoundManager.Play("AbilityReady")
				equipEvent:FireServer(i, selectedAbility)
				
				local originalSize = frame.Size
				-- Pequeño bounce
				local shrinkH = isMobile and 55 or 85
				TweenService:Create(frame, TweenInfo.new(0.05), {Size = UDim2.new(0.95, 0, 0, shrinkH)}):Play()
				task.delay(0.05, function() TweenService:Create(frame, TweenInfo.new(0.05), {Size = originalSize}):Play() end)
				
				task.wait(0.1); renderSlots()
			end
		end)
	end
end

-------------------------------------------------------------------
-- CONTROL
-------------------------------------------------------------------
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
			startSize = UDim2.new(0.75, 0, 0.75, 0)
			endSize = UDim2.new(0.8, 0, 0.8, 0)
		else
			startSize = UDim2.new(0, 550, 0, 400)
			endSize = UDim2.new(0, 600, 0, 450)
		end
		
		mainFrame.Size = startSize
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = endSize}):Play()
		
		renderPool()
		renderSlots()
	else
		mainBlocker.BackgroundTransparency = 1
		
		local stateRaw = estadoValue.Value or ""
		local state = string.split(stateRaw, "|")[1]
        UserInputService.MouseIconEnabled = false
	end
end

toggleInvEvent.Event:Connect(toggle)
mainBlocker.MouseButton1Click:Connect(toggle)

toggleShopEvent.Event:Connect(closeMenu)
toggleLogEvent.Event:Connect(closeMenu)
toggleSetEvent.Event:Connect(closeMenu)


estadoValue.Changed:Connect(function()
	local state = string.split(estadoValue.Value, "|")[1]
	if state == "SURVIVE" then closeMenu() end
end)

player:GetAttributeChangedSignal("EquippedSlot1"):Connect(renderSlots)
player:GetAttributeChangedSignal("EquippedSlot2"):Connect(renderSlots)
player:GetAttributeChangedSignal("EquippedSlot3"):Connect(renderSlots)