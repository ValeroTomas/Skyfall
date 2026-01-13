local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUD_Alive = {}

function HUD_Alive.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	
	-- Referencias a valores
	local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
	local vivosValue = ReplicatedStorage:WaitForChild("JugadoresVivos") 
	local inicioValue = ReplicatedStorage:WaitForChild("JugadoresInicio") -- Ahora contiene TOTAL (Bots+Humanos)
	
	-- UI BASE
	local labelVivos = Utils.CreateLabel("VivosLabel", UDim2.new(0, 100, 0, 45), UDim2.new(1, -25, 0, 10), Vector2.new(1, 0), screenGui)
	labelVivos.AutomaticSize = Enum.AutomaticSize.X
	labelVivos.Visible = false 
	
	local pad = Instance.new("UIPadding", labelVivos)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	Utils.ApplyCartoonStyle(
		labelVivos, 
		Color3.fromRGB(180, 255, 180), 
		Color3.fromRGB(0, 200, 50),    
		Color3.fromRGB(0, 60, 20)      
	)

	-- Función auxiliar para contar bots en el cliente (Para STARTING)
	local function countBots()
		local folder = workspace:FindFirstChild("ActiveBots")
		if folder then return #folder:GetChildren() end
		return 0
	end

	local function updateHUD()
		local rawState = estadoValue.Value
		local parts = string.split(rawState, "|")
		local state = parts[1]
		
		if state == "WAITING" then
			labelVivos.Visible = false
			
		elseif state == "STARTING" then
			labelVivos.Visible = true
			
			local humans = #Players:GetPlayers()
			local bots = countBots()
			local total = humans + bots
			local max = Players.MaxPlayers -- [DINÁMICO] Se actualiza solo
			
			labelVivos.Text = string.format("%d / %d", total, max)
			
		elseif state == "SURVIVE" or state == "WINNER" or state == "TIE" or state == "NO_ONE" then
			labelVivos.Visible = true
			
			local currentAlive = tonumber(vivosValue.Value) or 0
			local startedCount = tonumber(inicioValue.Value) or 0
			
			-- Ahora startedCount es correcto (Total al inicio), no necesitamos parches
			labelVivos.Text = string.format("%d / %d", currentAlive, startedCount)
			
			local popUp = TweenService:Create(labelVivos, TweenInfo.new(0.1), {TextSize = 26})
			popUp:Play()
			popUp.Completed:Connect(function()
				TweenService:Create(labelVivos, TweenInfo.new(0.1), {TextSize = 22}):Play()
			end)
		end
	end

	-- Conexiones
	estadoValue.Changed:Connect(updateHUD)
	vivosValue.Changed:Connect(updateHUD)
	
	Players.PlayerAdded:Connect(updateHUD)
	Players.PlayerRemoving:Connect(updateHUD)
	
	updateHUD()
end

return HUD_Alive