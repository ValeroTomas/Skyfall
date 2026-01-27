local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))

-------------------------------------------------------------------
-- SISTEMA DE EVENTOS
-------------------------------------------------------------------
local function getEvent(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("BindableEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
	end
	return ev
end

local toggleShopEvent = getEvent("ToggleShopEvent")
local toggleInvEvent = getEvent("ToggleInventoryEvent")
local toggleLogEvent = getEvent("ToggleChangelogEvent")
local toggleSetEvent = getEvent("ToggleSettingsEvent") 

local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local bonkEvent = ReplicatedStorage:WaitForChild("BonkEvent")
local cooldownEvent = ReplicatedStorage:WaitForChild("CooldownEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- ASSETS
local CART_ICON = DecalManager.Get("Cart")
local PACK_ICON = DecalManager.Get("Backpack")
local NOTE_ICON = DecalManager.Get("Notebook")
local SETTINGS_ICON = DecalManager.Get("Settings") -- [NUEVO] Icono Settings del Manager
local DASH_ICON = DecalManager.Get("Dash")
local PUSH_ICON = DecalManager.Get("Push")
local BONK_ICON = DecalManager.Get("Bonk")
local CUSTOM_FONT = FontManager.Get("Cartoon")

-------------------------------------------------------------------
-- UI SETUP
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "HUDButtons"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5 

local container = Instance.new("Frame", screenGui)
container.Name = "ButtonContainer"
container.Size = UDim2.new(0, 600, 0, 80)
container.Position = UDim2.new(0.5, 0, 1, -20)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 15)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-------------------------------------------------------------------
-- UTILS VISUALES
-------------------------------------------------------------------
local COLORS = {
	SHOP_BG_1 = Color3.fromRGB(255, 220, 0), SHOP_BG_2 = Color3.fromRGB(255, 140, 0),
	SHOP_STR_1 = Color3.fromRGB(0, 255, 255), SHOP_STR_2 = Color3.fromRGB(0, 100, 255),
	
	INV_BG_1 = Color3.fromRGB(180, 80, 255), INV_BG_2 = Color3.fromRGB(100, 20, 200),
	
	LOG_BG_1 = Color3.fromRGB(240, 240, 240), LOG_BG_2 = Color3.fromRGB(180, 180, 180),
	
	SET_BG_1 = Color3.fromRGB(100, 105, 110), SET_BG_2 = Color3.fromRGB(50, 55, 60),
	
	READY_BG_1 = Color3.fromRGB(135, 206, 250), READY_BG_2 = Color3.fromRGB(0, 150, 255),
	READY_STR_1 = Color3.fromRGB(0, 255, 100), READY_STR_2 = Color3.fromRGB(0, 150, 50),
	CD_BG_1 = Color3.fromRGB(60, 60, 70), CD_BG_2 = Color3.fromRGB(20, 20, 25),
	CD_STR_1 = Color3.fromRGB(255, 50, 50), CD_STR_2 = Color3.fromRGB(150, 0, 0),
	WHITE = Color3.fromRGB(255, 255, 255)
}

local function updateStrokeGradient(stroke, state)
	stroke.Color = Color3.new(1,1,1)
	local grad = stroke:FindFirstChild("StrokeGradient") or Instance.new("UIGradient", stroke)
	grad.Name = "StrokeGradient"; grad.Rotation = 90
	
	if state == "SHOP" or state == "INV" or state == "LOG" or state == "SET" then grad.Color = ColorSequence.new(COLORS.SHOP_STR_1, COLORS.SHOP_STR_2)
	elseif state == "READY" then grad.Color = ColorSequence.new(COLORS.READY_STR_1, COLORS.READY_STR_2)
	elseif state == "COOLDOWN" then grad.Color = ColorSequence.new(COLORS.CD_STR_1, COLORS.CD_STR_2)
	elseif state == "FLASH_GREEN" then grad.Color = ColorSequence.new(COLORS.WHITE, COLORS.READY_STR_1)
	elseif state == "FLASH_RED" then grad.Color = ColorSequence.new(COLORS.WHITE, COLORS.CD_STR_1)
	end
end

local function updateBackgroundGradient(frame, state)
	local grad = frame:FindFirstChild("BackGradient") or Instance.new("UIGradient", frame)
	grad.Name = "BackGradient"; grad.Rotation = 45
	
	if state == "SHOP" then grad.Color = ColorSequence.new(COLORS.SHOP_BG_1, COLORS.SHOP_BG_2)
	elseif state == "INV" then grad.Color = ColorSequence.new(COLORS.INV_BG_1, COLORS.INV_BG_2)
	elseif state == "LOG" then grad.Color = ColorSequence.new(COLORS.LOG_BG_1, COLORS.LOG_BG_2)
	elseif state == "SET" then grad.Color = ColorSequence.new(COLORS.SET_BG_1, COLORS.SET_BG_2)
	elseif state == "READY" then grad.Color = ColorSequence.new(COLORS.READY_BG_1, COLORS.READY_BG_2)
	elseif state == "COOLDOWN" then grad.Color = ColorSequence.new(COLORS.CD_BG_1, COLORS.CD_BG_2)
	end
end

local allSlotObjects = {}

-- [NUEVO] Función para actualizar los íconos (PC vs Consola)
local function updateInputIcons()
	local inputType = UserInputService:GetLastInputType()
	local isGamepad = (inputType.Name:match("Gamepad"))
	local isTouch = (inputType == Enum.UserInputType.Touch)
	
	for _, slot in ipairs(allSlotObjects) do
		if isTouch then
			slot.HintText.Visible = false
			slot.HintIcon.Visible = false
		elseif isGamepad and slot.ConsoleKeyCode then
			-- [NUEVO] Usar imagen nativa de Roblox
			local image = UserInputService:GetImageForKeyCode(slot.ConsoleKeyCode)
			slot.HintIcon.Image = image
			slot.HintIcon.Visible = true
			slot.HintText.Visible = false
		else
			-- Modo PC
			slot.HintText.Visible = true
			slot.HintIcon.Visible = false
		end
	end
end

local function createSlot(id, defaultKey, consoleKeyCode, order, initialState)
	local frame = Instance.new("Frame", container)
	frame.Name = id
	frame.Size = UDim2.new(0, 65, 0, 65) 
	frame.BackgroundColor3 = Color3.new(1,1,1); frame.LayoutOrder = order; frame.Visible = false 
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	
	updateBackgroundGradient(frame, initialState)
	local stroke = Instance.new("UIStroke", frame); stroke.Thickness = 4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	updateStrokeGradient(stroke, initialState)
	
	local icon = Instance.new("ImageLabel", frame)
	icon.Size = UDim2.new(0.65, 0, 0.65, 0); icon.Position = UDim2.new(0.5, 0, 0.5, 0); icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1; icon.Image = ""; icon.ZIndex = 2
	
	-- 1. HINT DE TEXTO (PC)
	local hintText = Instance.new("TextLabel", frame)
	hintText.Size = UDim2.new(0, 24, 0, 24); hintText.Position = UDim2.new(0.5, 0, 0, -12); hintText.AnchorPoint = Vector2.new(0.5, 0.5)
	hintText.BackgroundTransparency = 1; hintText.Text = defaultKey; hintText.FontFace = CUSTOM_FONT
	hintText.TextSize = 20; hintText.TextColor3 = Color3.new(1,1,1); hintText.ZIndex = 10
	local tGrad = Instance.new("UIGradient", hintText); tGrad.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 100, 255)); tGrad.Rotation = 90
	local hStroke = Instance.new("UIStroke", hintText); hStroke.Thickness = 1.5; hStroke.Color = Color3.new(0,0,0)

	-- 2. HINT DE IMAGEN (CONSOLA)
	local hintIcon = Instance.new("ImageLabel", frame)
	hintIcon.Size = UDim2.new(0, 28, 0, 28); hintIcon.Position = UDim2.new(0.5, 0, 0, -14); hintIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	hintIcon.BackgroundTransparency = 1; hintIcon.Image = ""; hintIcon.ZIndex = 10; hintIcon.Visible = false

	local cdOverlay = Instance.new("Frame", frame)
	cdOverlay.BackgroundColor3 = Color3.new(0,0,0); cdOverlay.BackgroundTransparency = 0.4
	cdOverlay.Visible = false; cdOverlay.ZIndex = 5; cdOverlay.Size = UDim2.new(1, 0, 1, 0)
	Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 12)
	
	local cdText = Instance.new("TextLabel", cdOverlay)
	cdText.Size = UDim2.new(1,0,1,0); cdText.BackgroundTransparency = 1
	cdText.TextColor3 = Color3.new(1,1,1); cdText.Font = Enum.Font.GothamBlack 
	cdText.TextSize = 28; cdText.Visible = true; cdText.ZIndex = 6
	Instance.new("UIStroke", cdText).Thickness = 2
	
	local slotObj = {
		Frame = frame, Icon = icon, 
		HintText = hintText, HintIcon = hintIcon, 
		ConsoleKeyCode = consoleKeyCode, -- Guardamos la tecla de consola para usarla luego
		AssignedAbility = nil, InCooldown = false,
		
		SetAbility = function(self, abilityName, iconId)
			self.AssignedAbility = abilityName; self.Icon.Image = iconId; self.Frame.Visible = true
			self.InCooldown = false; cdOverlay.Visible = false
			updateStrokeGradient(stroke, "READY"); updateBackgroundGradient(frame, "READY") 
		end,
		Clear = function(self) self.AssignedAbility = nil; self.Frame.Visible = false; self.InCooldown = false end,
		FlashError = function(self)
			SoundManager.Play("AbilityError")
			updateStrokeGradient(stroke, "FLASH_RED")
			local origin = self.Frame.Position
			TweenService:Create(self.Frame, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true), {Position = origin + UDim2.new(0, 5, 0, 0)}):Play()
			task.delay(0.3, function() self.Frame.Position = origin; updateStrokeGradient(stroke, self.InCooldown and "COOLDOWN" or "READY") end)
		end,
		StartCooldown = function(self, duration)
			self.InCooldown = true
			updateStrokeGradient(stroke, "COOLDOWN"); updateBackgroundGradient(frame, "COOLDOWN") 
			cdOverlay.Visible = true; cdOverlay.Size = UDim2.new(1, 0, 1, 0)
			TweenService:Create(cdOverlay, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 0)}):Play()
			task.spawn(function()
				for i = duration, 1, -1 do if not self.InCooldown then break end; cdText.Text = i; task.wait(1) end
			end)
			task.delay(duration, function()
				if not self.AssignedAbility then return end
				self.InCooldown = false; cdOverlay.Visible = false
				SoundManager.Play("AbilityReady")
				updateStrokeGradient(stroke, "FLASH_GREEN"); updateBackgroundGradient(frame, "READY") 
				task.delay(0.3, function() updateStrokeGradient(stroke, "READY") end)
			end)
		end
	}
	
	table.insert(allSlotObjects, slotObj)
	return slotObj
end

-- [CONFIGURACIÓN] Pasamos el Enum.KeyCode real para que Roblox busque la imagen
local backpackSlot = createSlot("BackpackSlot", "Q", Enum.KeyCode.DPadLeft, 1, "INV")
local shopSlot = createSlot("ShopSlot", "E", Enum.KeyCode.DPadUp, 2, "SHOP")
local logSlot = createSlot("LogSlot", "N", Enum.KeyCode.DPadDown, 3, "LOG")
-- [AJUSTE] Settings ahora usa la P y DPadRight
local setSlot = createSlot("SetSlot", "P", Enum.KeyCode.DPadRight, 4, "SET") 

local abilitySlots = {
	createSlot("Slot1", "1", nil, 5, "READY"),
	createSlot("Slot2", "2", nil, 6, "READY"),
	createSlot("Slot3", "3", nil, 7, "READY") 
}

-- Inicializar estado de íconos
updateInputIcons()
UserInputService.LastInputTypeChanged:Connect(updateInputIcons)

local function updateLoadout()
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local isDead = (not char or not hum or hum.Health <= 0)
	local state = string.split(estadoValue.Value, "|")[1]

	local showMenus = false
	if state == "WAITING" or state == "STARTING" then showMenus = true
	elseif state == "SURVIVE" then if isDead then showMenus = true else showMenus = false end
	else showMenus = true end

	if showMenus then
		backpackSlot:SetAbility("Inventory", PACK_ICON); updateBackgroundGradient(backpackSlot.Frame, "INV")
		shopSlot:SetAbility("Shop", CART_ICON); updateBackgroundGradient(shopSlot.Frame, "SHOP")
		logSlot:SetAbility("Changelog", NOTE_ICON); updateBackgroundGradient(logSlot.Frame, "LOG")
		setSlot:SetAbility("Settings", SETTINGS_ICON); updateBackgroundGradient(setSlot.Frame, "SET")
	else
		backpackSlot:Clear(); shopSlot:Clear(); logSlot:Clear(); setSlot:Clear()
	end

	if isDead or state ~= "SURVIVE" then
		for _, s in ipairs(abilitySlots) do s:Clear() end
		return
	end

	local function configSlot(slotObj, abilityName)
		if not abilityName then slotObj:Clear(); return end
		local icon = nil
		if abilityName == "Push" then icon = PUSH_ICON
		elseif abilityName == "Dash" then icon = DASH_ICON
		elseif abilityName == "Bonk" then icon = BONK_ICON end
		if icon then slotObj:SetAbility(abilityName, icon) else slotObj:Clear() end
	end
	configSlot(abilitySlots[1], player:GetAttribute("EquippedSlot1"))
	configSlot(abilitySlots[2], player:GetAttribute("EquippedSlot2"))
	configSlot(abilitySlots[3], player:GetAttribute("EquippedSlot3"))
end

estadoValue.Changed:Connect(updateLoadout)
player:GetAttributeChangedSignal("EquippedSlot1"):Connect(updateLoadout)
player:GetAttributeChangedSignal("EquippedSlot2"):Connect(updateLoadout)
player:GetAttributeChangedSignal("EquippedSlot3"):Connect(updateLoadout)

local function onCharAdded(c)
	local h = c:WaitForChild("Humanoid")
	h.Died:Connect(updateLoadout)
	updateLoadout()
end
if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(onCharAdded)
task.spawn(updateLoadout)

local function triggerAbility(abilityName, slotObj)
	if not slotObj or not slotObj.Frame.Visible then return end

	local f = slotObj.Frame
	TweenService:Create(f, TweenInfo.new(0.05), {Size = UDim2.new(0, 58, 0, 58)}):Play()
	task.delay(0.05, function() TweenService:Create(f, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 65, 0, 65)}):Play() end)

	if abilityName == "Shop" then toggleShopEvent:Fire(); return end
	if abilityName == "Inventory" then toggleInvEvent:Fire(); return end
	if abilityName == "Changelog" then toggleLogEvent:Fire(); return end
	if abilityName == "Settings" then toggleSetEvent:Fire(); return end 

	local untilTime = player:GetAttribute("StunnedUntil") or 0
	if workspace:GetServerTimeNow() < untilTime then return end
	if slotObj.InCooldown then slotObj:FlashError(); return end

	if abilityName == "Push" then pushEvent:FireServer()
	elseif abilityName == "Dash" then dashEvent:FireServer()
	elseif abilityName == "Bonk" then bonkEvent:FireServer()
	end
end

UserInputService.InputBegan:Connect(function(input, proc)
	-- [CORRECCIÓN] Permitir que las teclas de Menú (Q, E, N, P) funcionen
	-- incluso si "proc" es true (ej. si el menú está abierto y bloqueando clicks),
	-- SIEMPRE Y CUANDO no estemos escribiendo en un chat.
	
	local isMenuKey = (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E or 
					   input.KeyCode == Enum.KeyCode.N or input.KeyCode == Enum.KeyCode.P or
					   input.KeyCode == Enum.KeyCode.Escape) -- Escape suele cerrar cosas
					
	if proc and not isMenuKey then return end
	if UserInputService:GetFocusedTextBox() then return end -- Si escribe en chat, no activar
	
	-- TECLAS PC
	if backpackSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.Q then triggerAbility("Inventory", backpackSlot) end
	if shopSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.E then triggerAbility("Shop", shopSlot) end
	if logSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.N then triggerAbility("Changelog", logSlot) end
	if setSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.P then triggerAbility("Settings", setSlot) end 
	
	-- HABILIDADES (Estas sí respetan 'proc' porque son de juego)
	if not proc then
		if abilitySlots[1].Frame.Visible and input.KeyCode == Enum.KeyCode.One then triggerAbility(abilitySlots[1].AssignedAbility, abilitySlots[1]) end
		if abilitySlots[2].Frame.Visible and input.KeyCode == Enum.KeyCode.Two then triggerAbility(abilitySlots[2].AssignedAbility, abilitySlots[2]) end
		if abilitySlots[3].Frame.Visible and input.KeyCode == Enum.KeyCode.Three then triggerAbility(abilitySlots[3].AssignedAbility, abilitySlots[3]) end
	end

	-- TECLAS CONSOLA
	if input.UserInputType == Enum.UserInputType.Gamepad1 then
		if backpackSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.DPadLeft then triggerAbility("Inventory", backpackSlot) end
		if shopSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.DPadUp then triggerAbility("Shop", shopSlot) end
		if logSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.DPadDown then triggerAbility("Changelog", logSlot) end
		if setSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.DPadRight then triggerAbility("Settings", setSlot) end
	end
end)

local function connectTouch(slotObj, name)
	local btn = Instance.new("TextButton", slotObj.Frame)
	btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 20
	btn.MouseButton1Click:Connect(function()
		triggerAbility(name, slotObj)
	end)
end

connectTouch(backpackSlot, "Inventory")
connectTouch(shopSlot, "Shop")
connectTouch(logSlot, "Changelog")
connectTouch(setSlot, "Settings")

for i, slot in ipairs(abilitySlots) do
	local btn = Instance.new("TextButton", slot.Frame)
	btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 20
	btn.MouseButton1Click:Connect(function()
		if slot.AssignedAbility then triggerAbility(slot.AssignedAbility, slot) end
	end)
end

cooldownEvent.OnClientEvent:Connect(function(abilityName, duration)
	if abilityName == "RESET_ALL" then
		for _, slot in ipairs(abilitySlots) do 
			slot.InCooldown = false; slot.Frame:FindFirstChild("Frame", true).Visible = false
			updateStrokeGradient(slot.Frame:FindFirstChild("UIStroke"), "READY"); updateBackgroundGradient(slot.Frame, "READY")
		end
	else
		for _, slot in ipairs(abilitySlots) do
			if slot.AssignedAbility == abilityName then slot:StartCooldown(duration); break end
		end
	end
end)