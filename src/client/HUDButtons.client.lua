local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

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

local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local bonkEvent = ReplicatedStorage:WaitForChild("BonkEvent")
local cooldownEvent = ReplicatedStorage:WaitForChild("CooldownEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- ASSETS
local CART_ICON = DecalManager.Get("Cart")
local PACK_ICON = DecalManager.Get("Backpack")
local NOTE_ICON = DecalManager.Get("Notebook")
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
container.Size = UDim2.new(0, 500, 0, 80)
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
	
	if state == "SHOP" or state == "INV" or state == "LOG" then grad.Color = ColorSequence.new(COLORS.SHOP_STR_1, COLORS.SHOP_STR_2)
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
	elseif state == "READY" then grad.Color = ColorSequence.new(COLORS.READY_BG_1, COLORS.READY_BG_2)
	elseif state == "COOLDOWN" then grad.Color = ColorSequence.new(COLORS.CD_BG_1, COLORS.CD_BG_2)
	end
end

local abilitySlots = {} 

local function createSlot(id, defaultKey, order, initialState)
	local frame = Instance.new("Frame", container)
	frame.Name = id; frame.Size = UDim2.new(0, 65, 0, 65)
	frame.BackgroundColor3 = Color3.new(1,1,1); frame.LayoutOrder = order; frame.Visible = false 
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	
	updateBackgroundGradient(frame, initialState)
	local stroke = Instance.new("UIStroke", frame); stroke.Thickness = 4; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	updateStrokeGradient(stroke, initialState)
	
	local icon = Instance.new("ImageLabel", frame)
	icon.Size = UDim2.new(0.65, 0, 0.65, 0); icon.Position = UDim2.new(0.5, 0, 0.5, 0); icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1; icon.Image = ""; icon.ZIndex = 2
	
	local hint = Instance.new("TextLabel", frame)
	hint.Size = UDim2.new(0, 24, 0, 24); hint.Position = UDim2.new(0.5, 0, 0, -12); hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.BackgroundTransparency = 1; hint.Text = defaultKey; hint.FontFace = CUSTOM_FONT
	hint.TextSize = 20; hint.TextColor3 = Color3.new(1,1,1); hint.ZIndex = 10
	local textGrad = Instance.new("UIGradient", hint)
	textGrad.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 100, 255)); textGrad.Rotation = 90
	local hStroke = Instance.new("UIStroke", hint); hStroke.Thickness = 1.5; hStroke.Color = Color3.new(0,0,0)

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
		Frame = frame, Icon = icon, Hint = hint, AssignedAbility = nil, InCooldown = false,
		
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
	return slotObj
end

local backpackSlot = createSlot("BackpackSlot", "Q", 1, "INV")
local shopSlot = createSlot("ShopSlot", "E", 2, "SHOP")
local logSlot = createSlot("LogSlot", "N", 3, "LOG")

abilitySlots = {
	createSlot("Slot1", "1", 4, "READY"),
	createSlot("Slot2", "2", 5, "READY"),
	createSlot("Slot3", "3", 6, "READY") 
}

local function updateLoadout()
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local isDead = (not char or not hum or hum.Health <= 0)
	local state = string.split(estadoValue.Value, "|")[1]

	-- REGLA: Los menús SOLO se muestran si:
	-- A) Estamos en el Lobby (WAITING/STARTING)
	-- B) Estamos Muertos
	local showMenus = false
	if state == "WAITING" or state == "STARTING" then
		showMenus = true
	elseif state == "SURVIVE" then
		if isDead then showMenus = true else showMenus = false end
	else
		-- En TIE/WINNER mostramos menús
		showMenus = true
	end

	-- 1. Actualizar Menús
	if showMenus then
		backpackSlot:SetAbility("Inventory", PACK_ICON); updateBackgroundGradient(backpackSlot.Frame, "INV")
		shopSlot:SetAbility("Shop", CART_ICON); updateBackgroundGradient(shopSlot.Frame, "SHOP")
		logSlot:SetAbility("Changelog", NOTE_ICON); updateBackgroundGradient(logSlot.Frame, "LOG")
	else
		backpackSlot:Clear()
		shopSlot:Clear()
		logSlot:Clear()
	end

	-- 2. Actualizar Habilidades (Solo Vivos + Juego)
	if isDead or state ~= "SURVIVE" then
		for _, s in ipairs(abilitySlots) do s:Clear() end
		return
	end

	-- Cargar habilidades si estoy vivo y jugando
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
	-- Si es habilidad de menú, permitir siempre que sea visible
	if abilityName == "Shop" then toggleShopEvent:Fire(); return end
	if abilityName == "Inventory" then toggleInvEvent:Fire(); return end
	if abilityName == "Changelog" then toggleLogEvent:Fire(); return end

	-- Si es habilidad de combate, chequear estado físico
	local untilTime = player:GetAttribute("StunnedUntil") or 0
	if workspace:GetServerTimeNow() < untilTime then return end
	if slotObj.InCooldown then slotObj:FlashError(); return end

	if abilityName == "Push" then pushEvent:FireServer()
	elseif abilityName == "Dash" then dashEvent:FireServer()
	elseif abilityName == "Bonk" then bonkEvent:FireServer()
	end
	
	local f = slotObj.Frame
	TweenService:Create(f, TweenInfo.new(0.05), {Size = UDim2.new(0, 60, 0, 60)}):Play()
	task.delay(0.05, function() TweenService:Create(f, TweenInfo.new(0.05), {Size = UDim2.new(0, 65, 0, 65)}):Play() end)
end

UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	
	-- Menús (Solo si el botón está visible)
	if backpackSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.Q then triggerAbility("Inventory", backpackSlot) end
	if shopSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.E then triggerAbility("Shop", shopSlot) end
	if logSlot.Frame.Visible and input.KeyCode == Enum.KeyCode.N then triggerAbility("Changelog", logSlot) end
	
	-- Habilidades
	if abilitySlots[1].Frame.Visible and input.KeyCode == Enum.KeyCode.One then triggerAbility(abilitySlots[1].AssignedAbility, abilitySlots[1]) end
	if abilitySlots[2].Frame.Visible and input.KeyCode == Enum.KeyCode.Two then triggerAbility(abilitySlots[2].AssignedAbility, abilitySlots[2]) end
	if abilitySlots[3].Frame.Visible and input.KeyCode == Enum.KeyCode.Three then triggerAbility(abilitySlots[3].AssignedAbility, abilitySlots[3]) end
end)

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