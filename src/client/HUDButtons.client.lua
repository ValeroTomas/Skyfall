local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. EVENTOS Y VARIABLES
local toggleShopEvent = ReplicatedStorage:FindFirstChild("ToggleShopEvent")
if not toggleShopEvent then
	toggleShopEvent = Instance.new("BindableEvent")
	toggleShopEvent.Name = "ToggleShopEvent"
	toggleShopEvent.Parent = ReplicatedStorage
end

local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local cooldownEvent = ReplicatedStorage:WaitForChild("CooldownEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- ASSETS
local CART_ICON = "rbxassetid://113277509630221"
local DASH_ICON = "rbxassetid://97307955533015"
local PUSH_ICON = "rbxassetid://76175865229928"
local READY_SOUND_ID = "rbxassetid://137818744150574"
local ERROR_SOUND_ID = "rbxassetid://90683869968677" 
local CUSTOM_FONT = Font.new("rbxassetid://12187370000")

local readySound = Instance.new("Sound")
readySound.Name = "AbilityReadySound"; readySound.SoundId = READY_SOUND_ID; readySound.Volume = 0.5; readySound.Parent = playerGui
local errorSound = Instance.new("Sound")
errorSound.Name = "AbilityErrorSound"; errorSound.SoundId = ERROR_SOUND_ID; errorSound.Volume = 0.5; errorSound.Parent = playerGui

task.spawn(function() ContentProvider:PreloadAsync({readySound, errorSound}) end)

-------------------------------------------------------------------
-- 2. UI SETUP (CONTENEDOR)
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "HUDButtons"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5 

local container = Instance.new("Frame", screenGui)
container.Name = "ButtonContainer"
container.Size = UDim2.new(0, 400, 0, 80) 
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
-- 3. UTILS VISUALES (PALETA DE COLORES)
-------------------------------------------------------------------
local COLORS = {
	-- TIENDA (Amarillo/Naranja Fondo, Azul Borde)
	SHOP_BG_1 = Color3.fromRGB(255, 220, 0),    -- Amarillo Oro
	SHOP_BG_2 = Color3.fromRGB(255, 140, 0),    -- Naranja
	SHOP_STR_1 = Color3.fromRGB(0, 255, 255),   -- Cyan Eléctrico
	SHOP_STR_2 = Color3.fromRGB(0, 100, 255),   -- Azul Profundo

	-- HABILIDAD LISTA (Celeste Fondo, Verde Borde)
	READY_BG_1 = Color3.fromRGB(135, 206, 250), -- Celeste Claro
	READY_BG_2 = Color3.fromRGB(0, 150, 255),   -- Azul Cielo
	READY_STR_1 = Color3.fromRGB(0, 255, 100),  -- Verde Lima
	READY_STR_2 = Color3.fromRGB(0, 150, 50),   -- Verde Oscuro

	-- HABILIDAD COOLDOWN (Oscuro Fondo, Rojo Borde)
	CD_BG_1 = Color3.fromRGB(60, 60, 70),       -- Gris Oscuro
	CD_BG_2 = Color3.fromRGB(20, 20, 25),       -- Casi Negro
	CD_STR_1 = Color3.fromRGB(255, 50, 50),     -- Rojo Claro
	CD_STR_2 = Color3.fromRGB(150, 0, 0),       -- Rojo Oscuro

	-- FLASH / TEXTO
	WHITE = Color3.fromRGB(255, 255, 255),
	SILVER = Color3.fromRGB(200, 200, 200)
}

-- Función para actualizar el gradiente del BORDE (Stroke)
local function updateStrokeGradient(stroke, state)
	stroke.Color = Color3.new(1,1,1) -- Base blanca necesaria
	
	local grad = stroke:FindFirstChild("StrokeGradient")
	if not grad then
		grad = Instance.new("UIGradient")
		grad.Name = "StrokeGradient"; grad.Rotation = 90; grad.Parent = stroke
	end
	
	if state == "SHOP" then
		grad.Color = ColorSequence.new(COLORS.SHOP_STR_1, COLORS.SHOP_STR_2)
	elseif state == "READY" then
		grad.Color = ColorSequence.new(COLORS.READY_STR_1, COLORS.READY_STR_2)
	elseif state == "COOLDOWN" then
		grad.Color = ColorSequence.new(COLORS.CD_STR_1, COLORS.CD_STR_2)
	elseif state == "FLASH_GREEN" then
		grad.Color = ColorSequence.new(COLORS.WHITE, COLORS.READY_STR_1)
	elseif state == "FLASH_RED" then
		grad.Color = ColorSequence.new(COLORS.WHITE, COLORS.CD_STR_1)
	end
end

-- Función para actualizar el gradiente del FONDO (Background)
local function updateBackgroundGradient(frame, state)
	local grad = frame:FindFirstChild("BackGradient")
	if not grad then
		grad = Instance.new("UIGradient")
		grad.Name = "BackGradient"; grad.Rotation = 45; grad.Parent = frame
	end
	
	if state == "SHOP" then
		grad.Color = ColorSequence.new(COLORS.SHOP_BG_1, COLORS.SHOP_BG_2)
	elseif state == "READY" then
		grad.Color = ColorSequence.new(COLORS.READY_BG_1, COLORS.READY_BG_2)
	elseif state == "COOLDOWN" then
		grad.Color = ColorSequence.new(COLORS.CD_BG_1, COLORS.CD_BG_2)
	end
end

-------------------------------------------------------------------
-- 4. CLASE BOTÓN (SLOT)
-------------------------------------------------------------------
local abilitySlots = {} 

local function createSlot(id, defaultKey, order, initialState)
	local SIZE_PX = 65 
	
	local frame = Instance.new("Frame", container)
	frame.Name = id
	frame.Size = UDim2.new(0, SIZE_PX, 0, SIZE_PX)
	frame.BackgroundColor3 = Color3.new(1,1,1)
	frame.LayoutOrder = order
	frame.Visible = false 
	
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
	
	-- INICIALIZAR FONDO SEGÚN ESTADO (SHOP vs READY)
	updateBackgroundGradient(frame, initialState)
	
	-- BORDE (STROKE)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	updateStrokeGradient(stroke, initialState)
	
	-- ICONO
	local icon = Instance.new("ImageLabel", frame)
	icon.Size = UDim2.new(0.65, 0, 0.65, 0)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = ""
	icon.ZIndex = 2
	
	-- TECLA (Hint)
	local hint = Instance.new("TextLabel", frame)
	hint.Size = UDim2.new(0, 24, 0, 24)
	hint.Position = UDim2.new(0.5, 0, 0, -12)
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.BackgroundTransparency = 1 
	hint.Text = defaultKey
	hint.FontFace = CUSTOM_FONT
	hint.TextSize = 20
	hint.TextColor3 = Color3.new(1,1,1)
	hint.ZIndex = 10
	
	local textGrad = Instance.new("UIGradient", hint)
	textGrad.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 100, 255))
	textGrad.Rotation = 90
	
	local hStroke = Instance.new("UIStroke", hint)
	hStroke.Thickness = 1.5; hStroke.Color = Color3.new(0,0,0)

	-- OVERLAY COOLDOWN (Cortina)
	local cdOverlay = Instance.new("Frame", frame)
	cdOverlay.BackgroundColor3 = Color3.new(0,0,0)
	cdOverlay.BackgroundTransparency = 0.4
	cdOverlay.Visible = false
	cdOverlay.ZIndex = 5
	cdOverlay.BorderSizePixel = 0
	cdOverlay.AnchorPoint = Vector2.new(0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 0, 0)
	cdOverlay.Size = UDim2.new(1, 0, 1, 0)
	Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 12)
	
	-- TEXTO COOLDOWN (Ahora con Gradiente y Stroke)
	local cdText = Instance.new("TextLabel", cdOverlay)
	cdText.Size = UDim2.new(1,0,1,0)
	cdText.BackgroundTransparency = 1
	cdText.TextColor3 = Color3.new(1,1,1)
	cdText.Font = Enum.Font.GothamBlack -- Fuente gruesa para que se vea bien
	cdText.TextSize = 28
	cdText.Visible = true
	cdText.ZIndex = 6
	
	-- Estilo del Texto de Cooldown
	local cdTextStroke = Instance.new("UIStroke", cdText)
	cdTextStroke.Thickness = 2
	cdTextStroke.Color = Color3.new(0,0,0) -- Stroke negro para contraste
	
	local cdTextGrad = Instance.new("UIGradient", cdText)
	cdTextGrad.Color = ColorSequence.new(COLORS.WHITE, COLORS.SILVER)
	cdTextGrad.Rotation = 90

	-- OBJETO SLOT
	local slotObj = {
		Frame = frame,
		Icon = icon,
		Hint = hint,
		AssignedAbility = nil,
		InCooldown = false,
		
		SetAbility = function(self, abilityName, iconId)
			self.AssignedAbility = abilityName
			self.Icon.Image = iconId
			self.Frame.Visible = true
			
			-- Reset estado a "Listo"
			self.InCooldown = false
			cdOverlay.Visible = false
			updateStrokeGradient(stroke, "READY")
			updateBackgroundGradient(frame, "READY") -- Fondo Celeste
		end,
		
		Clear = function(self)
			self.AssignedAbility = nil
			self.Frame.Visible = false
			self.InCooldown = false
		end,
		
		FlashError = function(self)
			errorSound:Play()
			updateStrokeGradient(stroke, "FLASH_RED")
			
			local origin = self.Frame.Position
			local tShake = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true)
			TweenService:Create(self.Frame, tShake, {Position = origin + UDim2.new(0, 5, 0, 0)}):Play()

			task.delay(0.3, function()
				self.Frame.Position = origin
				if self.InCooldown then
					updateStrokeGradient(stroke, "COOLDOWN")
				else
					updateStrokeGradient(stroke, "READY")
				end
			end)
		end,
		
		StartCooldown = function(self, duration)
			self.InCooldown = true
			
			-- 1. CAMBIO ESTÉTICO: ROJO Y OSCURO
			updateStrokeGradient(stroke, "COOLDOWN")
			updateBackgroundGradient(frame, "COOLDOWN") -- Fondo Oscuro
			
			-- 2. Activar Cortina
			cdOverlay.Visible = true
			cdOverlay.Size = UDim2.new(1, 0, 1, 0)
			
			-- 3. Animación Cortina (Hacia Arriba)
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
			local tween = TweenService:Create(cdOverlay, tweenInfo, {
				Size = UDim2.new(1, 0, 0, 0)
			})
			tween:Play()
			
			-- Contador
			task.spawn(function()
				for i = duration, 1, -1 do
					if not self.InCooldown or not self.AssignedAbility then break end
					cdText.Text = i
					task.wait(1)
				end
			end)
			
			-- Fin Cooldown
			task.delay(duration, function()
				if not self.AssignedAbility then return end
				self.InCooldown = false
				cdOverlay.Visible = false
				
				-- 4. FLASH VERDE + VUELTA A CELESTE
				readySound:Play()
				updateStrokeGradient(stroke, "FLASH_GREEN")
				updateBackgroundGradient(frame, "READY") -- Volver a Fondo Celeste
				
				local popInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				TweenService:Create(frame, popInfo, {Size = UDim2.new(0, SIZE_PX + 8, 0, SIZE_PX + 8)}):Play()
				
				task.delay(0.3, function()
					updateStrokeGradient(stroke, "READY")
					TweenService:Create(frame, popInfo, {Size = UDim2.new(0, SIZE_PX, 0, SIZE_PX)}):Play()
				end)
			end)
		end
	}
	
	return slotObj
end

-- CREACIÓN DE INSTANCIAS
-- Shop: Inicia con estilo "SHOP" (Amarillo fondo, Azul borde)
local shopSlot = createSlot("ShopSlot", "E", 0, "SHOP")

-- Habilidades: Inician con estilo "READY" (Celeste fondo, Verde borde)
abilitySlots = {
	createSlot("Slot1", "1", 1, "READY"),
	createSlot("Slot2", "2", 2, "READY")
}

-------------------------------------------------------------------
-- 5. LÓGICA DE ASIGNACIÓN
-------------------------------------------------------------------
local function updateLoadout()
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	
	if not char or not hum or hum.Health <= 0 then
		shopSlot:Clear()
		for _, s in ipairs(abilitySlots) do s:Clear() end
		return
	end

	local raw = estadoValue.Value
	local state = string.split(raw, "|")[1]
	
	if state == "STARTING" or state == "WAITING" then
		shopSlot:SetAbility("Shop", CART_ICON)
		-- Re-aplicar estilo SHOP por si acaso
		updateBackgroundGradient(shopSlot.Frame, "SHOP")
		updateStrokeGradient(shopSlot.Frame:FindFirstChild("UIStroke"), "SHOP")
		
		for _, s in ipairs(abilitySlots) do s:Clear() end
		
	elseif state == "SURVIVE" then
		shopSlot:Clear()
		
		local available = {}
		if player:GetAttribute("PushUnlock") == true then
			table.insert(available, {Name = "Push", Icon = PUSH_ICON})
		end
		if player:GetAttribute("DashUnlock") == true then
			table.insert(available, {Name = "Dash", Icon = DASH_ICON})
		end
		
		for i, slot in ipairs(abilitySlots) do
			if available[i] then
				if slot.AssignedAbility ~= available[i].Name then
					slot:SetAbility(available[i].Name, available[i].Icon)
				end
			else
				slot:Clear()
			end
		end
	else
		shopSlot:Clear()
		for _, s in ipairs(abilitySlots) do s:Clear() end
	end
end

-- LISTENERS
estadoValue.Changed:Connect(updateLoadout)
player:GetAttributeChangedSignal("PushUnlock"):Connect(updateLoadout)
player:GetAttributeChangedSignal("DashUnlock"):Connect(updateLoadout)

local function onCharAdded(c)
	local h = c:WaitForChild("Humanoid")
	h.Died:Connect(updateLoadout)
	updateLoadout()
end
if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(onCharAdded)
task.spawn(updateLoadout)

-------------------------------------------------------------------
-- 6. INPUT HANDLER
-------------------------------------------------------------------
local function triggerAbility(abilityName, slotObj)
	if slotObj.InCooldown then
		slotObj:FlashError()
		return 
	end

	if abilityName == "Push" then
		pushEvent:FireServer()
	elseif abilityName == "Dash" then
		dashEvent:FireServer()
	elseif abilityName == "Shop" then
		toggleShopEvent:Fire()
	end
	
	-- Animación Click
	local f = slotObj.Frame
	local t = TweenInfo.new(0.05)
	TweenService:Create(f, t, {Size = UDim2.new(0, 60, 0, 60)}):Play()
	task.delay(0.05, function()
		TweenService:Create(f, t, {Size = UDim2.new(0, 65, 0, 65)}):Play()
	end)
end

UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	
	if shopSlot.Frame.Visible and (input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonY) then
		triggerAbility("Shop", shopSlot)
	end
	
	if abilitySlots[1].Frame.Visible and (input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.ButtonX) then
		triggerAbility(abilitySlots[1].AssignedAbility, abilitySlots[1])
	end
	
	if abilitySlots[2].Frame.Visible and (input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.ButtonB) then
		triggerAbility(abilitySlots[2].AssignedAbility, abilitySlots[2])
	end
end)

UserInputService.GamepadConnected:Connect(function()
	shopSlot.Hint.Text = "Y"; abilitySlots[1].Hint.Text = "X"; abilitySlots[2].Hint.Text = "B"
end)
UserInputService.GamepadDisconnected:Connect(function()
	shopSlot.Hint.Text = "E"; abilitySlots[1].Hint.Text = "1"; abilitySlots[2].Hint.Text = "2"
end)

-------------------------------------------------------------------
-- 7. COOLDOWNS SERVER
-------------------------------------------------------------------
cooldownEvent.OnClientEvent:Connect(function(abilityName, duration)
	if abilityName == "RESET_ALL" then
		for _, slot in ipairs(abilitySlots) do 
			slot.InCooldown = false
			slot.Frame:FindFirstChild("Frame", true).Visible = false
			-- Resetear a Celeste/Verde
			updateStrokeGradient(slot.Frame:FindFirstChild("UIStroke"), "READY")
			updateBackgroundGradient(slot.Frame, "READY")
		end
	else
		for _, slot in ipairs(abilitySlots) do
			if slot.AssignedAbility == abilityName then
				slot:StartCooldown(duration)
				break
			end
		end
	end
end)