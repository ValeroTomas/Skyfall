local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")

local HUD_Alive = {}

function HUD_Alive.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	local Localization = require(sharedFolder:WaitForChild("Localization"))
	local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
	local vivosValue = ReplicatedStorage:WaitForChild("JugadoresVivos")

	-- UI
	local labelVivos = Utils.CreateLabel("VivosLabel", UDim2.new(0, 100, 0, 45), UDim2.new(1, -25, 0, 10), Vector2.new(1, 0), screenGui)
	labelVivos.AutomaticSize = Enum.AutomaticSize.X
	
	-- Padding para alinear mejor el texto
	local pad = Instance.new("UIPadding", labelVivos)
	pad.PaddingTop = UDim.new(0, 6) 

	-- Aplicamos el estilo UNA VEZ (Ya que no cambia de color según el estado, siempre es verde)
	Utils.ApplyCartoonStyle(
		labelVivos, 
		Color3.fromRGB(180, 255, 180), -- Top: Verde muy pálido (casi blanco)
		Color3.fromRGB(0, 200, 50),    -- Bottom: Verde Esmeralda
		Color3.fromRGB(0, 60, 20)      -- Stroke: Verde oscuro bosque
	)

	local function updateAlive()
		local count = vivosValue.Value
		labelVivos.Text = "  " .. Localization.get("ALIVE", playerLang, count) .. "  "
		
		-- Pequeño efecto "Pop" cuando alguien muere (el número cambia)
		local popUp = TweenService:Create(labelVivos, TweenInfo.new(0.1), {TextSize = 26})
		popUp:Play()
		popUp.Completed:Connect(function()
			TweenService:Create(labelVivos, TweenInfo.new(0.1), {TextSize = 22}):Play()
		end)
	end

	vivosValue.Changed:Connect(updateAlive)
	updateAlive()
end

return HUD_Alive