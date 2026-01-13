local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- VALORES PÚBLICOS
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
-- [CAMBIO] Usamos el nuevo valor de solo humanos para calcular premios
local inicioValue = ReplicatedStorage:WaitForChild("HumanosInicio") 

-- EVENTO PARA CLIENTE
local rewardEvent = ReplicatedStorage:FindFirstChild("RewardEvent")
if not rewardEvent then
	rewardEvent = Instance.new("RemoteEvent")
	rewardEvent.Name = "RewardEvent"
	rewardEvent.Parent = ReplicatedStorage
end

-- ACCESO A BASE DE DATOS
local eventsFolder = ServerStorage:WaitForChild("PlayerDataEvents")
local getStat = eventsFolder:WaitForChild("GetPlayerStat")
local setStat = eventsFolder:WaitForChild("SetPlayerStat")

-- TABLA DE PAGOS BASE
local BASE_REWARDS = {
	[1] = 100, -- 1er Puesto
	[2] = 50,  -- 2do Puesto
	[3] = 25   -- 3er Puesto
}
local CONSOLATION_PRIZE = 10 -- Del 4to para abajo

local function calculateReward(rank, totalPlayers)
	-- 1. Determinar Base
	local base = BASE_REWARDS[rank] or CONSOLATION_PRIZE
	
	-- 2. Calcular Multiplicador (10% por cada jugador HUMANO participante)
	local multiplier = 1 + (totalPlayers * 0.10)
	
	-- 3. Total
	return math.floor(base * multiplier)
end

local function distributeRewards()
	local totalPlayers = inicioValue.Value
	if totalPlayers <= 0 then totalPlayers = 1 end 
	
	print("💰 Iniciando reparto de premios. Jugadores Humanos base: " .. totalPlayers)

	for _, player in ipairs(Players:GetPlayers()) do
		local rank = player:GetAttribute("RoundRank")
		
		if not rank or rank == 0 then
			-- Si no tiene rank, asumimos que quedó último entre los participantes totales
			-- (No importa mucho porque el premio consuelo es fijo, pero por consistencia)
			rank = 999 
		end
		
		local coinsToGive = calculateReward(rank, totalPlayers)
		local winsToGive = (rank == 1) and 1 or 0
		
		local currentCoins = getStat:Invoke(player, "Coins") or 0
		setStat:Fire(player, "Coins", currentCoins + coinsToGive)
		
		if winsToGive > 0 then
			local currentWins = getStat:Invoke(player, "Wins") or 0
			setStat:Fire(player, "Wins", currentWins + winsToGive)
		end
		
		rewardEvent:FireClient(player, coinsToGive)
		
		print(string.format("   -> %s (Rank %d) gana %d monedas (Wins: +%d)", player.Name, rank, coinsToGive, winsToGive))
	end
end

estadoValue.Changed:Connect(function(val)
	local data = string.split(val, "|")
	local state = data[1]
	
	if state == "WINNER" or state == "TIE" or state == "NO_ONE" then
		task.wait(1) 
		distributeRewards()
	end
end)