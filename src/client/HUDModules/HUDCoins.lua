local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD_Coins = {}

function HUD_Coins.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	local Localization = require(sharedFolder:WaitForChild("Localization"))
	local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
	local COIN_ICON_ID = "rbxassetid://99365746352443"

	local player = Players.LocalPlayer
	local rewardEvent = ReplicatedStorage:WaitForChild("RewardEvent")
	local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent") -- Para notificar al feed
	
	-- CREACIÓN UI
	local coinsFrame = Instance.new("Frame", screenGui)
	coinsFrame.Name = "CoinsDisplay"
	coinsFrame.Size = UDim2.new(0, 0, 0, 50) 
	coinsFrame.Position = UDim2.new(0, 25, 0, 25) 
	coinsFrame.BackgroundTransparency = 1
	coinsFrame.AutomaticSize = Enum.AutomaticSize.X 

	local cLayout = Instance.new("UIListLayout", coinsFrame)
	cLayout.FillDirection = Enum.FillDirection.Horizontal
	cLayout.VerticalAlignment = Enum.VerticalAlignment.Center 
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Padding = UDim.new(0, 8)

	local cPadding = Instance.new("UIPadding", coinsFrame)
	cPadding.PaddingLeft = UDim.new(0, 12); cPadding.PaddingRight = UDim.new(0, 12)

	-- Icono (Orden 1)
	local cIcon = Instance.new("ImageLabel", coinsFrame)
	cIcon.Name = "Icon"; cIcon.Size = UDim2.new(0, 40, 0, 40)
	cIcon.BackgroundTransparency = 1; cIcon.Image = COIN_ICON_ID
	cIcon.LayoutOrder = 1
	
	-- CORRECCIÓN DEL OUTLINE (Borde Ajustado)
	-- Creamos un marco interno invisible para el borde, así podemos hacerlo más pequeño
	local outlineFrame = Instance.new("Frame", cIcon)
	outlineFrame.Name = "OutlineFix"
	outlineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	outlineFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	outlineFrame.BackgroundTransparency = 1 -- Invisible, solo queremos el borde
	
	-- AJUSTE DE TAMAÑO:
	-- 0.75 significa el 75% del tamaño.
	-- Si el círculo sigue quedando grande, baja a 0.7 o 0.65.
	-- Si queda muy chico (corta la moneda), sube a 0.8 o 0.85.
	outlineFrame.Size = UDim2.new(0.75, 0, 0.75, 0) 
	
	-- Aplicamos el borde al marco interno en lugar de a la imagen
	Instance.new("UICorner", outlineFrame).CornerRadius = UDim.new(1, 0)
	local iconStroke = Instance.new("UIStroke", outlineFrame)
	iconStroke.Thickness = 2; iconStroke.Color = Color3.new(0,0,0)

	-- Texto Cantidad (Orden 2)
	local cText = Instance.new("TextLabel", coinsFrame)
	cText.Name = "Amount"; cText.AutomaticSize = Enum.AutomaticSize.XY
	cText.BackgroundTransparency = 1; cText.Text = "0"
	cText.LayoutOrder = 2; cText.TextSize = 28
	
	-- SOLUCIÓN DE ALINEACIÓN: Relleno interno
	-- Esto empuja el texto hacia abajo sin pelear con el Layout
	local textPad = Instance.new("UIPadding", cText)
	textPad.PaddingTop = UDim.new(0, 7) -- <--- AUMENTA ESTE NÚMERO PARA BAJAR EL TEXTO
	
	-- ESTILO DORADO (Con los colores exactos del icono)
	local function applyGoldStyle()
		-- Top: #fcf025 (Amarillo brillante)
		-- Bottom: #ea9d04 (Naranja oscuro)
		Utils.ApplyCartoonStyle(
			cText, 
			Color3.fromHex("fcf025"), 
			Color3.fromHex("ea9d04"), 
			Color3.new(0,0,0)
		)
	end
	applyGoldStyle()

	-- Texto Suma (Orden 3)
	local cPlus = Instance.new("TextLabel", coinsFrame)
	cPlus.Name = "Plus"; cPlus.AutomaticSize = Enum.AutomaticSize.XY
	cPlus.BackgroundTransparency = 1; cPlus.Text = ""
	cPlus.LayoutOrder = 3; cPlus.Visible = false; cPlus.TextSize = 32
	
	-- Relleno para alinear también la suma
	local plusPad = Instance.new("UIPadding", cPlus)
	plusPad.PaddingTop = UDim.new(0, 7) -- <--- USA EL MISMO VALOR QUE ARRIBA
	Utils.ApplyCartoonStyle(cPlus, Color3.fromRGB(150, 255, 150), Color3.fromRGB(0, 200, 0), Color3.new(0,0,0))

	-- LÓGICA
	local currentDisplayValue = 0

	local function animateCoinsStep(finalValue, amountAdded)
		if amountAdded > 0 then
			cPlus.Text = "+" .. amountAdded
			cPlus.Visible = true; cPlus.TextTransparency = 0
			local str = cPlus:FindFirstChild("UIStroke"); if str then str.Transparency = 0 end
			
			task.spawn(function()
				task.wait(1.5)
				local fade = TweenService:Create(cPlus, TweenInfo.new(0.5), {TextTransparency = 1})
				fade:Play(); if str then TweenService:Create(str, TweenInfo.new(0.5), {Transparency = 1}):Play() end
				fade.Completed:Wait(); cPlus.Visible = false
			end)
		end
		
		local step = 10
		if amountAdded < 10 and amountAdded > 0 then step = amountAdded end
		
		task.spawn(function()
			if amountAdded > 0 then
				Utils.ApplyCartoonStyle(cText, Color3.fromRGB(150, 255, 150), Color3.fromRGB(0, 200, 0), Color3.new(0,0,0))
			end
			
			while currentDisplayValue < finalValue do
				local diff = finalValue - currentDisplayValue
				local add = math.min(step, diff)
				currentDisplayValue = currentDisplayValue + add
				cText.Text = tostring(currentDisplayValue)
				SoundManager.Play("CoinPop") 
				
				local popUp = TweenService:Create(cText, TweenInfo.new(0.05), {TextSize = 34})
				popUp:Play(); popUp.Completed:Wait()
				local popDown = TweenService:Create(cText, TweenInfo.new(0.05), {TextSize = 28})
				popDown:Play(); task.wait(0.05)
			end
			currentDisplayValue = finalValue
			cText.Text = tostring(currentDisplayValue)
			applyGoldStyle()
		end)
	end

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local coinsVal = leaderstats:WaitForChild("Coins", 10)
			if coinsVal then
				currentDisplayValue = coinsVal.Value
				cText.Text = tostring(currentDisplayValue)
				coinsVal.Changed:Connect(function(newVal)
					if newVal < currentDisplayValue then
						currentDisplayValue = newVal
						cText.Text = tostring(currentDisplayValue)
					end
				end)
			end
		end
	end)

	rewardEvent.OnClientEvent:Connect(function(amount)
		local targetValue = currentDisplayValue + amount
		animateCoinsStep(targetValue, amount)
	end)
end

return HUD_Coins