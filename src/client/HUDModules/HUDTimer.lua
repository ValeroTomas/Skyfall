local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local HUD_Timer = {}

function HUD_Timer.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	local Localization = require(sharedFolder:WaitForChild("Localization"))
	local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
	local isMobile = UserInputService.TouchEnabled

	local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
	local tiempoRestante = ReplicatedStorage:WaitForChild("TiempoRestante")

	-- [AJUSTE MÓVIL]
	local textSize = isMobile and 19 or 22

	-- UI BASE
	local labelEstado = Utils.CreateLabel("EstadoLabel", UDim2.new(0, 100, 0, 50), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0), screenGui)
	labelEstado.AutomaticSize = Enum.AutomaticSize.X
	labelEstado.TextSize = textSize
	
	local pad = Instance.new("UIPadding", labelEstado)
	pad.PaddingTop = UDim.new(0, 6) 
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)

	local function updateTimer()
		local val = estadoValue.Value
		local data = string.split(val, "|")
		local state = data[1]
		
		if state == "SURVIVE" then 
			labelEstado.Text = string.format(" %02d:%02d ", math.floor(tiempoRestante.Value/60), tiempoRestante.Value%60)
			
			Utils.ApplyCartoonStyle(
				labelEstado, 
				Color3.fromRGB(255, 255, 255), 
				Color3.fromRGB(150, 240, 255), 
				Color3.fromRGB(50, 0, 0)       
			)
			
			if labelEstado.TextTransparency == 1 then
				labelEstado.TextTransparency = 0
				local stroke = labelEstado:FindFirstChild("UIStroke")
				if stroke then stroke.Transparency = 0 end
				
				labelEstado.Rotation = math.random(-5, 5)
				TweenService:Create(labelEstado, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			end
			
		elseif state == "STARTING" then 
			labelEstado.Text = " " .. Localization.get("STARTING", playerLang, (data[2] or "0")) .. " "
			Utils.ApplyCartoonStyle(labelEstado, Color3.fromRGB(255, 230, 100), Color3.fromRGB(255, 140, 0), Color3.fromRGB(80, 40, 0))
			labelEstado.TextTransparency = 0
			local stroke = labelEstado:FindFirstChild("UIStroke"); if stroke then stroke.Transparency = 0 end
			
		elseif state == "WAITING" then
			labelEstado.Text = " " .. Localization.get("WAITING", playerLang, (data[2] or "?"), (data[3] or "?")) .. " "
			Utils.ApplyCartoonStyle(labelEstado, Color3.fromRGB(150, 240, 255), Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 50, 100))
			labelEstado.TextTransparency = 0
			local stroke = labelEstado:FindFirstChild("UIStroke"); if stroke then stroke.Transparency = 0 end
			
		else
			labelEstado.Text = "" 
			labelEstado.TextTransparency = 1
			local stroke = labelEstado:FindFirstChild("UIStroke"); if stroke then stroke.Transparency = 1 end
		end
	end

	estadoValue.Changed:Connect(updateTimer)
	tiempoRestante.Changed:Connect(updateTimer)
	updateTimer()
end

return HUD_Timer