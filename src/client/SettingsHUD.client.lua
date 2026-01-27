local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))

-- EVENTOS
local toggleSetEvent = ReplicatedStorage:WaitForChild("ToggleSettingsEvent")
local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")
local toggleInvEvent = ReplicatedStorage:WaitForChild("ToggleInventoryEvent")
local toggleLogEvent = ReplicatedStorage:WaitForChild("ToggleChangelogEvent")

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

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

local function addTextStroke(txtLabel, thickness)
	local s = Instance.new("UIStroke", txtLabel)
	s.Thickness = thickness or 2; s.Color = Color3.new(0, 0, 0); s.Transparency = 0
	return s
end

-------------------------------------------------------------------
-- UI SETUP
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 30 
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
mainFrame.Size = UDim2.new(0, 450, 0, 320) -- Tamaño final objetivo
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.new(1,1,1)
mainFrame.Visible = false
mainFrame.ZIndex = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Estilo Gris Oscuro
applyGradient(mainFrame, Color3.fromRGB(45, 50, 55), Color3.fromRGB(30, 35, 40), 45)
createDeepStroke(mainFrame, Color3.fromRGB(150, 150, 160), Color3.fromRGB(80, 80, 90), 3)

-- TÍTULO (Amarillo/Dorado)
local title = Instance.new("TextLabel", mainFrame)
title.Text = "AJUSTES"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.FontFace = FontManager.Get("Cartoon"); title.TextSize = 32
title.TextColor3 = Color3.fromRGB(255, 255, 255); title.ZIndex = 6
addTextStroke(title, 2)
applyGradient(title, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 170, 0), 90)

-- Contenedor de Sliders
local container = Instance.new("Frame", mainFrame)
container.Size = UDim2.new(0.9, 0, 0.75, 0)
container.Position = UDim2.new(0.5, 0, 0.6, 0); container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1; container.ZIndex = 6

local layout = Instance.new("UIListLayout", container)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 15)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top

-------------------------------------------------------------------
-- CURSOR CONSOLA
-------------------------------------------------------------------
local selectionCursor = Instance.new("Frame")
selectionCursor.Name = "ConsoleCursor"
selectionCursor.Size = UDim2.new(1, 10, 1, 10)
selectionCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
selectionCursor.AnchorPoint = Vector2.new(0.5, 0.5)
selectionCursor.BackgroundTransparency = 1
selectionCursor.Visible = false
local selStroke = Instance.new("UIStroke", selectionCursor)
selStroke.Color = Color3.fromRGB(0, 255, 255)
selStroke.Thickness = 3
selStroke.Transparency = 0
Instance.new("UICorner", selectionCursor).CornerRadius = UDim.new(0, 8)

-------------------------------------------------------------------
-- SLIDER COMPONENTE
-------------------------------------------------------------------
local function createSlider(labelText, soundGroupName, layoutOrder)
	local soundGroup = SoundService:WaitForChild(soundGroupName)
	
	local wrapper = Instance.new("Frame", container)
	wrapper.Name = "Slider_" .. soundGroupName
	wrapper.Size = UDim2.new(1, 0, 0, 45)
	wrapper.BackgroundTransparency = 1
	wrapper.LayoutOrder = layoutOrder
	wrapper.ZIndex = 7
	
	-- Etiqueta Izquierda
	local label = Instance.new("TextLabel", wrapper)
	label.Size = UDim2.new(0.25, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.new(1,1,1); label.TextXAlignment = Enum.TextXAlignment.Left
	label.FontFace = FontManager.Get("Cartoon"); label.TextSize = 18 
	label.ZIndex = 7
	addTextStroke(label, 2)
	
	-- Porcentaje Derecha
	local percentLabel = Instance.new("TextLabel", wrapper)
	percentLabel.Size = UDim2.new(0.15, 0, 1, 0)
	percentLabel.Position = UDim2.new(1, 0, 0, 0); percentLabel.AnchorPoint = Vector2.new(1, 0)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Text = "100%"
	percentLabel.TextColor3 = Color3.fromRGB(200, 200, 200); percentLabel.TextXAlignment = Enum.TextXAlignment.Right
	percentLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold); percentLabel.TextSize = 16
	percentLabel.ZIndex = 7
	addTextStroke(percentLabel, 1)

	-- Barra Fondo (Interactuable)
	local barBg = Instance.new("TextButton", wrapper)
	barBg.Text = ""
	barBg.Size = UDim2.new(0.55, 0, 0.3, 0)
	barBg.Position = UDim2.new(0.3, 0, 0.5, 0); barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	barBg.AutoButtonColor = false
	barBg.ZIndex = 7
	barBg.Selectable = true
	barBg.SelectionImageObject = selectionCursor
	
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
	local bStroke = Instance.new("UIStroke", barBg); bStroke.Thickness = 2; bStroke.Color = Color3.fromRGB(80, 80, 90)
	
	-- Barra Relleno
	local fill = Instance.new("Frame", barBg)
	fill.Name = "Fill"
	fill.Size = UDim2.new(0.5, 0, 1, 0) 
	fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	fill.ZIndex = 8
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	applyGradient(fill, Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 150, 255), 90)
	
	-- Knob
	local knob = Instance.new("Frame", barBg)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.SizeConstraint = Enum.SizeConstraint.RelativeYY
	knob.Position = UDim2.new(0.5, 0, 0.5, 0); knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.new(1,1,1); knob.ZIndex = 9
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	
	local function updateVisuals(percent)
		local clamped = math.clamp(percent, 0, 1)
		fill.Size = UDim2.new(clamped, 0, 1, 0)
		knob.Position = UDim2.new(clamped, 0, 0.5, 0)
		soundGroup.Volume = clamped * 2 
		percentLabel.Text = math.floor(clamped * 100) .. "%"
	end
	
	local isDragging = false
	local function updateFromInput(input)
		local barPos = barBg.AbsolutePosition.X
		local barSize = barBg.AbsoluteSize.X
		local mousePos = input.Position.X
		local relative = (mousePos - barPos) / barSize
		updateVisuals(relative)
	end
	
	barBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			SoundManager.Play("ShopButton")
			updateFromInput(input)
		elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
			local currentPercent = fill.Size.X.Scale
			local step = 0.05
			
			if input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if input.Position.X < -0.5 or input.KeyCode == Enum.KeyCode.DPadLeft then 
					SoundManager.Play("ShopButton")
					updateVisuals(currentPercent - step)
				end
			elseif input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if input.Position.X > 0.5 or input.KeyCode == Enum.KeyCode.DPadRight then
					SoundManager.Play("ShopButton")
					updateVisuals(currentPercent + step)
				end
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)
	
	local currentVol = math.clamp(soundGroup.Volume / 2, 0, 1)
	updateVisuals(currentVol)
end

createSlider("MÚSICA", "Music", 1)
createSlider("EFECTOS", "SFX", 2)
createSlider("INTERFAZ", "UI", 3)

-------------------------------------------------------------------
-- CONTROL (ANIMACIÓN CORREGIDA)
-------------------------------------------------------------------
local isOpen = false

local function closeMenu()
	if not isOpen then return end
	isOpen = false
	
	mainFrame.Visible = false
	mainBlocker.Visible = false
	mainBlocker.BackgroundTransparency = 1
	
	GuiService.SelectedObject = nil
	
	local stateRaw = estadoValue.Value or ""
	local state = string.split(stateRaw, "|")[1]
	if state == "SURVIVE" then
		UserInputService.MouseIconEnabled = false
	end
end

local function toggle()
	if isOpen then
		closeMenu()
	else
		isOpen = true
		mainFrame.Visible = true
		mainBlocker.Visible = true
		UserInputService.MouseIconEnabled = true
		
		SoundManager.Play("ShopButton") 
		
		-- [CORRECCIÓN CRÍTICA DE ANIMACIÓN]
		-- Ahora usa "Back" y tiempos idénticos a Shop/Inventory para sentirse igual
		mainFrame.Size = UDim2.new(0, 400, 0, 270) -- Empieza un poco más chico (aprox 50px menos)
		mainBlocker.BackgroundTransparency = 1
		
		TweenService:Create(mainBlocker, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
		
		-- Tween de 0.2s con EasingStyle.Back (Golpe seco y rápido)
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 450, 0, 320)}):Play()
		
		task.delay(0.1, function()
			local firstSlider = container:FindFirstChild("Slider_Music")
			if firstSlider then
				local btn = firstSlider:FindFirstChild("TextButton")
				if btn then GuiService.SelectedObject = btn end
			end
		end)
	end
end

toggleSetEvent.Event:Connect(toggle)
mainBlocker.MouseButton1Click:Connect(toggle)

-- Exclusividad
toggleShopEvent.Event:Connect(closeMenu)
toggleInvEvent.Event:Connect(closeMenu)
toggleLogEvent.Event:Connect(closeMenu)

estadoValue.Changed:Connect(function()
	local state = string.split(estadoValue.Value, "|")[1]
	if state == "SURVIVE" then closeMenu() end
end)