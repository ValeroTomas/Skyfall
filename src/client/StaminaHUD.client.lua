local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local sprintEvent = ReplicatedStorage:WaitForChild("SprintEvent")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- IMPORTANTE: Ya no necesitamos enviar eventos de salto desde aquí.
-- Eso ahora es trabajo de JumpClient.

local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))

-- UI SETUP
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "StaminaHUD"
screenGui.ResetOnSpawn = false

-- CONFIGURACIÓN VISUAL
local BAR_WIDTH = 140 
local BAR_HEIGHT = 8
local POS_Y_OFFSET = -170
local ORIGINAL_POS = UDim2.new(0.5, 0, 1, POS_Y_OFFSET)

-- COLORES
local COLOR_BLUE   = Color3.fromRGB(0, 170, 255)
local COLOR_WHITE  = Color3.fromRGB(255, 255, 255)
local COLOR_YELLOW = Color3.fromRGB(255, 255, 0)
local COLOR_RED    = Color3.fromRGB(255, 50, 50)

-- CREACIÓN DE UI
local staminaGlow = Instance.new("Frame", screenGui); staminaGlow.Name = "Glow"; staminaGlow.Size = UDim2.new(0, BAR_WIDTH + 15, 0, BAR_HEIGHT + 15); staminaGlow.Position = ORIGINAL_POS; staminaGlow.AnchorPoint = Vector2.new(0.5, 0.5); staminaGlow.BackgroundColor3 = COLOR_BLUE; staminaGlow.BackgroundTransparency = 1; staminaGlow.ZIndex = 1; Instance.new("UICorner", staminaGlow).CornerRadius = UDim.new(1, 0)
local staminaBack = Instance.new("Frame", screenGui); staminaBack.Name = "StaminaBack"; staminaBack.Size = UDim2.new(0, BAR_WIDTH, 0, BAR_HEIGHT); staminaBack.Position = ORIGINAL_POS; staminaBack.AnchorPoint = Vector2.new(0.5, 0.5); staminaBack.BackgroundColor3 = Color3.fromRGB(20, 20, 20); staminaBack.BackgroundTransparency = 1; staminaBack.Visible = false; staminaBack.ZIndex = 2; Instance.new("UICorner", staminaBack).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", staminaBack); stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0,0,0); stroke.Transparency = 1
local staminaFill = Instance.new("Frame", staminaBack); staminaFill.Name = "Fill"; staminaFill.Size = UDim2.new(1, 0, 1, 0); staminaFill.BackgroundColor3 = COLOR_BLUE; staminaFill.BackgroundTransparency = 1; staminaFill.ZIndex = 3; Instance.new("UICorner", staminaFill).CornerRadius = UDim.new(1, 0)

--------------------------------------------------------------------------------
-- LÓGICA DE SHAKE & SOUND (FEEDBACK SOLAMENTE)
--------------------------------------------------------------------------------
local isShaking = false
local function triggerShake()
	if isShaking then return end
	isShaking = true
	SoundManager.Play("StaminaEmpty")
	task.spawn(function()
		local startTime = tick()
		local duration = 0.3 
		while tick() - startTime < duration do
			local offsetX = math.random(-4, 4)
			local offsetY = math.random(-2, 2)
			staminaBack.Position = ORIGINAL_POS + UDim2.new(0, offsetX, 0, offsetY)
			staminaGlow.Position = staminaBack.Position 
			RunService.RenderStepped:Wait()
		end
		staminaBack.Position = ORIGINAL_POS
		staminaGlow.Position = ORIGINAL_POS
		isShaking = false
	end)
end

--------------------------------------------------------------------------------
-- CONTROL VISUAL
--------------------------------------------------------------------------------
local isVisible = false
local isFlashing = false 
local lastPercent = 1 

local function resetAndHide()
	isFlashing = false
	local outInfo = TweenInfo.new(0.5)
	TweenService:Create(staminaBack, outInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(staminaFill, outInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
	TweenService:Create(staminaGlow, outInfo, {BackgroundTransparency = 1}):Play()
	task.delay(0.6, function()
		staminaBack.Visible = false; staminaGlow.Visible = false; isVisible = false
		staminaFill.Size = UDim2.new(1, 0, 1, 0); staminaFill.BackgroundColor3 = COLOR_BLUE
	end)
end

local function updateState(percent)
	local targetColor = COLOR_BLUE
	local targetGlowTransp = 1
	local targetGlowColor = COLOR_BLUE
	
	if percent >= 0.99 and lastPercent < 0.99 and isVisible then
		SoundManager.Play("StaminaFull")
	end
	lastPercent = percent
	
	if percent >= 0.99 then
		if not isFlashing and isVisible then
			isFlashing = true
			TweenService:Create(staminaGlow, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, BackgroundColor3 = COLOR_BLUE}):Play()
			task.delay(0.2, function()
				if isFlashing then 
					local outInfo = TweenInfo.new(0.5)
					TweenService:Create(staminaBack, outInfo, {BackgroundTransparency = 1}):Play()
					TweenService:Create(staminaFill, outInfo, {BackgroundTransparency = 1}):Play()
					TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
					TweenService:Create(staminaGlow, outInfo, {BackgroundTransparency = 1}):Play()
					task.wait(0.5)
					staminaBack.Visible = false; staminaGlow.Visible = false; isVisible = false; isFlashing = false 
				end
			end)
		end
		return 
	elseif percent > 0.9 then targetColor = COLOR_BLUE; targetGlowTransp = 1; isFlashing = false
	elseif percent > 0.5 then targetColor = COLOR_WHITE; targetGlowTransp = 1; isFlashing = false
	elseif percent > 0.19 then targetColor = COLOR_YELLOW; targetGlowTransp = 1; isFlashing = false
	else targetColor = COLOR_RED; targetGlowColor = COLOR_RED; targetGlowTransp = 0.3; isFlashing = false end

	if not isFlashing then
		if not isVisible then
			isVisible = true; staminaBack.Visible = true; staminaGlow.Visible = true
			local inInfo = TweenInfo.new(0.3)
			TweenService:Create(staminaBack, inInfo, {BackgroundTransparency = 0.5}):Play()
			TweenService:Create(staminaFill, inInfo, {BackgroundTransparency = 0}):Play()
			TweenService:Create(stroke, inInfo, {Transparency = 0}):Play()
		end
		TweenService:Create(staminaFill, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
		TweenService:Create(staminaGlow, TweenInfo.new(0.3), {BackgroundTransparency = targetGlowTransp, BackgroundColor3 = targetGlowColor}):Play()
	end
end

-- CONEXIONES DE INTERFAZ
local function connectCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(function() resetAndHide() end)
	
	char:GetAttributeChangedSignal("CurrentStamina"):Connect(function()
		local current = char:GetAttribute("CurrentStamina") or 100
		local max = player:GetAttribute("MaxStamina") or 100 
		local percent = math.clamp(current / max, 0, 1)
		TweenService:Create(staminaFill, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
		updateState(percent)
	end)
end

if player.Character then connectCharacter(player.Character) end
player.CharacterAdded:Connect(connectCharacter)

-- INPUTS (SOLO PARA CORRER Y FEEDBACK)
UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	
	-- Si intentan saltar o correr agotados, VIBRAMOS el HUD
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
		local char = player.Character
		if char and char:GetAttribute("IsExhausted") then
			triggerShake()
		end
	end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
		sprintEvent:FireServer(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
		sprintEvent:FireServer(false)
	end
end)