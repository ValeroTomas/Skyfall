local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- EVENTOS REMOTOS (Servidor)
local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local cooldownEvent = ReplicatedStorage:WaitForChild("CooldownEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- EVENTO LOCAL (Comunicación con ShopHUD)
local toggleShopEvent = ReplicatedStorage:FindFirstChild("ToggleShopEvent")
if not toggleShopEvent then
	toggleShopEvent = Instance.new("BindableEvent")
	toggleShopEvent.Name = "ToggleShopEvent"
	toggleShopEvent.Parent = ReplicatedStorage
end

-- ASSETS
local CART_ICON = "rbxassetid://113277509630221"
local READY_SOUND_ID = "rbxassetid://137818744150574"

local readySound = Instance.new("Sound")
readySound.Name = "AbilityReadySound"
readySound.SoundId = READY_SOUND_ID
readySound.Volume = 0.5
readySound.Parent = playerGui
ContentProvider:PreloadAsync({readySound})

-------------------------------------------------------------------
-- 1. UI SETUP (CONTENEDOR CENTRAL)
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "HUDButtons"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5 

-- Contenedor Horizontal para alinear todo
local container = Instance.new("Frame", screenGui)
container.Name = "ButtonContainer"
container.Size = UDim2.new(0, 600, 0, 100)
container.Position = UDim2.new(0.5, 0, 1, -20)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 20)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-------------------------------------------------------------------
-- 2. FÁBRICA DE BOTONES (ESTÉTICA UNIFICADA)
-------------------------------------------------------------------
local buttons = {} -- Referencia para cooldowns

local function createButton(id, config)
	local frame = Instance.new("Frame", container)
	frame.Name = id
	frame.Size = UDim2.new(0, 80, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35) -- Azul Noche (Estilo Shop)
	frame.LayoutOrder = config.Order
	frame.Visible = config.Visible
	
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 3; stroke.Color = Color3.new(0,0,0)
	
	-- TECLA (Burbuja Arriba)
	local hint = Instance.new("TextLabel", frame)
	hint.Size = UDim2.new(0, 28, 0, 28)
	hint.Position = UDim2.new(0.5, 0, 0, -14)
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.BackgroundColor3 = Color3.new(1, 1, 1)
	hint.TextColor3 = Color3.new(0, 0, 0)
	hint.Font = Enum.Font.LuckiestGuy
	hint.TextSize = 18
	hint.Text = config.Key
	hint.ZIndex = 5
	Instance.new("UICorner", hint).CornerRadius = UDim.new(1, 0)
	local hStroke = Instance.new("UIStroke", hint); hStroke.Thickness = 2
	
	-- CONTENIDO (Icono o Emoji)
	local iconLabel
	if config.IconId then
		iconLabel = Instance.new("ImageLabel", frame)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = config.IconId
		iconLabel.Size = UDim2.new(0, 50, 0, 50)
		iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	else
		iconLabel = Instance.new("TextLabel", frame)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = config.Emoji or "?"
		iconLabel.TextSize = 40
		iconLabel.Size = UDim2.new(1,0,1,0)
	end
	
	-- COOLDOWN OVERLAY (Solo para habilidades)
	local cdOverlay = nil
	local cdText = nil
	
	if config.HasCooldown then
		cdOverlay = Instance.new("Frame", frame)
		cdOverlay.Size = UDim2.new(1,0,1,0)
		cdOverlay.BackgroundColor3 = Color3.new(0,0,0)
		cdOverlay.BackgroundTransparency = 0.5
		cdOverlay.Visible = false
		Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 16)
		
		cdText = Instance.new("TextLabel", cdOverlay)
		cdText.Size = UDim2.new(1,0,1,0)
		cdText.BackgroundTransparency = 1
		cdText.TextColor3 = Color3.new(1,1,1)
		cdText.Font = Enum.Font.GothamBold
		cdText.TextSize = 28
	end
	
	-- LÓGICA INTERNA
	local btnData = {
		Frame = frame,
		Hint = hint,
		StartCooldown = function(duration)
			if not config.HasCooldown then return end
			
			frame:SetAttribute("InCooldown", true)
			cdOverlay.Visible = true
			stroke.Color = Color3.fromRGB(100, 100, 100) -- Gris en CD
			
			for i = duration, 1, -1 do
				if not frame:GetAttribute("InCooldown") then break end
				cdText.Text = i
				task.wait(1)
			end
			
			frame:SetAttribute("InCooldown", false)
			cdOverlay.Visible = false
			stroke.Color = Color3.new(0,0,0)
			
			-- Efecto Pop al terminar
			readySound:Play()
			local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(frame, tInfo, {Size = UDim2.new(0, 90, 0, 90)}):Play()
			task.delay(0.2, function()
				TweenService:Create(frame, tInfo, {Size = UDim2.new(0, 80, 0, 80)}):Play()
			end)
		end,
		Reset = function()
			if cdOverlay then cdOverlay.Visible = false end
			frame:SetAttribute("InCooldown", false)
			stroke.Color = Color3.new(0,0,0)
		end
	}
	
	buttons[id] = btnData
	return btnData
end

-------------------------------------------------------------------
-- 3. CREACIÓN DE LOS 3 BOTONES
-------------------------------------------------------------------

-- A) TIENDA (Orden 0 - Izquierda)
createButton("Shop", {
	Order = 0,
	Visible = false, -- Se activa en Waiting/Starting
	Key = "E",
	IconId = CART_ICON,
	HasCooldown = false
})

-- B) PUSH (Orden 1 - Centro)
createButton("Push", {
	Order = 1,
	Visible = false, -- Se activa en Survive
	Key = "1",
	Emoji = "✋",
	HasCooldown = true
})

-- C) DASH (Orden 2 - Derecha)
createButton("Dash", {
	Order = 2,
	Visible = false, -- Se activa en Survive
	Key = "2",
	Emoji = "⚡",
	HasCooldown = true
})

-------------------------------------------------------------------
-- 4. MANEJO DE ESTADOS (VISIBILIDAD)
-------------------------------------------------------------------
local function updateState()
	local raw = estadoValue.Value
	local state = string.split(raw, "|")[1]
	
	local shopBtn = buttons["Shop"].Frame
	local pushBtn = buttons["Push"].Frame
	local dashBtn = buttons["Dash"].Frame
	
	if state == "STARTING" or state == "WAITING" then
		-- FASE LOBBY: Solo Tienda
		shopBtn.Visible = true
		pushBtn.Visible = false
		dashBtn.Visible = false
		
	elseif state == "SURVIVE" then
		-- FASE JUEGO: Solo Habilidades
		shopBtn.Visible = false
		pushBtn.Visible = true
		dashBtn.Visible = true
		
	else
		-- OTROS (Winner, etc): Nada
		shopBtn.Visible = false
		pushBtn.Visible = false
		dashBtn.Visible = false
	end
end

estadoValue.Changed:Connect(updateState)
task.spawn(updateState)

-------------------------------------------------------------------
-- 5. MANEJO DE INPUTS
-------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	
	-- TIENDA (E o Y)
	if buttons["Shop"].Frame.Visible then
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonY then
			toggleShopEvent:Fire() -- Avisar al otro script
			
			-- Animación visual de clic
			local f = buttons["Shop"].Frame
			f.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
			task.delay(0.1, function() f.BackgroundColor3 = Color3.fromRGB(20, 20, 35) end)
		end
	end
	
	-- HABILIDADES (1/X, 2/B)
	if buttons["Push"].Frame.Visible then
		
		-- PUSH
		if (input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.ButtonX) 
		   and not buttons["Push"].Frame:GetAttribute("InCooldown") then
			
			pushEvent:FireServer()
			-- Efecto cámara local
			local cam = workspace.CurrentCamera
			task.spawn(function()
				for i=1,5 do cam.CFrame *= CFrame.new(math.random(-1,1)/10, math.random(-1,1)/10, 0); task.wait() end
			end)
		end
		
		-- DASH
		if (input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.ButtonB) 
		   and not buttons["Dash"].Frame:GetAttribute("InCooldown") then
			
			dashEvent:FireServer()
			-- Efecto FOV local
			local cam = workspace.CurrentCamera
			TweenService:Create(cam, TweenInfo.new(0.2), {FieldOfView = cam.FieldOfView + 10}):Play()
			task.delay(0.3, function() TweenService:Create(cam, TweenInfo.new(0.5), {FieldOfView = 70}):Play() end)
		end
	end
end)

-- Detectar Gamepad para cambiar las pistas visuales (E -> Y, 1 -> X, etc)
UserInputService.GamepadConnected:Connect(function()
	buttons["Shop"].Hint.Text = "Y"
	buttons["Push"].Hint.Text = "X"
	buttons["Dash"].Hint.Text = "B"
end)

UserInputService.GamepadDisconnected:Connect(function()
	buttons["Shop"].Hint.Text = "E"
	buttons["Push"].Hint.Text = "1"
	buttons["Dash"].Hint.Text = "2"
end)

-------------------------------------------------------------------
-- 6. COOLDOWNS DEL SERVIDOR
-------------------------------------------------------------------
cooldownEvent.OnClientEvent:Connect(function(abilityName, duration)
	if abilityName == "RESET_ALL" then
		for _, btn in pairs(buttons) do btn.Reset() end
	elseif buttons[abilityName] then
		buttons[abilityName].StartCooldown(duration)
	end
end)