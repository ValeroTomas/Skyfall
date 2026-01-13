local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players") 

local HUD_Spectator = {}

function HUD_Spectator.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	local Localization = require(sharedFolder:WaitForChild("Localization"))
	local FontManager = require(sharedFolder:WaitForChild("FontManager"))
	
	local player = Players.LocalPlayer
	local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
	
	-- Escuchar el evento (BindableEvent)
	local eventName = "SpectateHUDBindable"
	local spectateEvent = ReplicatedStorage:FindFirstChild(eventName)
	
	if not spectateEvent then
		spectateEvent = Instance.new("BindableEvent")
		spectateEvent.Name = eventName
		spectateEvent.Parent = ReplicatedStorage
	end

	-- === CREACIÓN UI ===
	-- [CORRECCIÓN] Usamos CanvasGroup para poder usar GroupTransparency
	local frame = Instance.new("CanvasGroup", screenGui)
	frame.Name = "SpectatorFrame"
	frame.Size = UDim2.new(0, 400, 0, 55)
	frame.Position = UDim2.new(0.5, 0, 0.75, 0) 
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.GroupTransparency = 1 -- Empieza invisible
	frame.Visible = false 

	-- Texto "ESPECTEANDO A:"
	local titleLabel = Instance.new("TextLabel", frame)
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = Localization.get("SPECTATING", playerLang)
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.FontFace = FontManager.Get("Cartoon")
	titleLabel.TextSize = 14
	
	local titleStroke = Instance.new("UIStroke", titleLabel)
	titleStroke.Thickness = 2; titleStroke.Color = Color3.new(0,0,0)

	-- Texto "[NOMBRE JUGADOR]"
	local nameLabel = Instance.new("TextLabel", frame)
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "PlayerName"
	nameLabel.TextSize = 24 
	nameLabel.AutomaticSize = Enum.AutomaticSize.X
	
	-- Estilo estético
	Utils.ApplyCartoonStyle(
		nameLabel,
		Color3.fromRGB(255, 255, 255), 
		Color3.fromRGB(100, 220, 255), 
		Color3.new(0, 0, 0)            
	)

	-- === LÓGICA ===
	local function updateSpectator(targetName)
		-- [SEGURIDAD] Verificar si YO estoy vivo.
		local myChar = player.Character
		local myHum = myChar and myChar:FindFirstChild("Humanoid")
		
		if myHum and myHum.Health > 0 then
			targetName = nil
		end

		if targetName then
			-- MOSTRAR
			nameLabel.Text = targetName
			frame.Visible = true
			
			-- Animación Pop
			frame.Position = UDim2.new(0.5, 0, 0.8, 0)
			frame.GroupTransparency = 1
			
			local info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(frame, info, {Position = UDim2.new(0.5, 0, 0.75, 0), GroupTransparency = 0}):Play()
		else
			-- OCULTAR (Con animación)
			if frame.Visible then
				local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local tween = TweenService:Create(frame, info, {Position = UDim2.new(0.5, 0, 0.8, 0), GroupTransparency = 1})
				tween:Play()
				tween.Completed:Connect(function()
					-- Verificación extra por si se volvió a mostrar durante la animación
					if frame.GroupTransparency >= 0.9 then 
						frame.Visible = false
					end
				end)
			end
		end
	end

	spectateEvent.Event:Connect(updateSpectator)
	
	-- LIMPIEZA AL RESPAWNEAR
	player.CharacterAdded:Connect(function(c)
		frame.Visible = false
		frame.GroupTransparency = 1
	end)
end

return HUD_Spectator