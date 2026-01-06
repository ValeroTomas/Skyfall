local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- VALORES PÚBLICOS
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
local inicioValue = ReplicatedStorage:WaitForChild("JugadoresInicio") -- Cantidad inicial de jugadores

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
	
	-- 2. Calcular Multiplicador (10% por cada jugador participante)
	-- Ejemplo: 10 jugadores -> 1 + (10 * 0.1) = 1 + 1 = x2 Multiplicador
	local multiplier = 1 + (totalPlayers * 0.10)
	
	-- 3. Total
	return math.floor(base * multiplier)
end

local function distributeRewards()
	local totalPlayers = inicioValue.Value
	if totalPlayers <= 0 then totalPlayers = 1 end -- Evitar errores si se prueba solo
	
	print("💰 Iniciando reparto de premios. Jugadores base: " .. totalPlayers)

	for _, player in ipairs(Players:GetPlayers()) do
		-- Obtenemos el Rank calculado por DeathHandler/RoundManager
		local rank = player:GetAttribute("RoundRank")
		
		-- Si rank es nil o 0 (bug/recién entrado), asumimos último puesto
		if not rank or rank == 0 then
			rank = totalPlayers + 1
		end
		
		-- Calcular Monedas
		local coinsToGive = calculateReward(rank, totalPlayers)
		
		-- Calcular Wins (Solo el Top 1 gana la Win)
		local winsToGive = (rank == 1) and 1 or 0
		
		-- APLICAR PREMIOS
		local currentCoins = getStat:Invoke(player, "Coins") or 0
		setStat:Fire(player, "Coins", currentCoins + coinsToGive)
		
		if winsToGive > 0 then
			local currentWins = getStat:Invoke(player, "Wins") or 0
			setStat:Fire(player, "Wins", currentWins + winsToGive)
		end
		
		-- AVISAR AL CLIENTE (Sonido + UI)
		rewardEvent:FireClient(player, coinsToGive)
		
		print(string.format("   -> %s (Rank %d) gana %d monedas (Wins: +%d)", player.Name, rank, coinsToGive, winsToGive))
	end
end

estadoValue.Changed:Connect(function(val)
	local data = string.split(val, "|")
	local state = data[1]
	
	-- Repartimos premios cuando la ronda termina (Gane alguien, Empate, o Nadie)
	-- IMPORTANTE: "NO_ONE" también reparte premios (2do puesto para abajo ganan sus monedas)
	if state == "WINNER" or state == "TIE" or state == "NO_ONE" then
		task.wait(1) -- Esperamos un segundo para asegurar que los Ranks se hayan seteado
		distributeRewards()
	end
end)