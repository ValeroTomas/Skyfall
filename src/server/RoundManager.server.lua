local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local PlayerManager = require(script.Parent.PlayerManager) 
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder.SoundManager)

-- EVENTOS
local function getRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name) or Instance.new("RemoteEvent")
	r.Name = name; r.Parent = ReplicatedStorage
	return r
end

local matchStatusEvent = getRemote("MatchStatusEvent") 
local countdownEvent = ReplicatedStorage:FindFirstChild("CountdownEvent") or Instance.new("RemoteEvent")
countdownEvent.Name = "CountdownEvent"; countdownEvent.Parent = ReplicatedStorage
local roundStartEvent = ReplicatedStorage:FindFirstChild("RoundStartEvent") or Instance.new("BindableEvent")
roundStartEvent.Name = "RoundStartEvent"; roundStartEvent.Parent = ReplicatedStorage

local mapEventStart = ReplicatedStorage:WaitForChild("MapEventStart")
local mapEventStop = ReplicatedStorage:WaitForChild("MapEventStop")
local voteEvent = ReplicatedStorage:FindFirstChild("VoteMapEvent") or Instance.new("RemoteEvent")
voteEvent.Name = "VoteMapEvent"; voteEvent.Parent = ReplicatedStorage

local cleanMapEvent = ReplicatedStorage:FindFirstChild("CleanMapEvent")
if not cleanMapEvent then
	cleanMapEvent = Instance.new("BindableEvent")
	cleanMapEvent.Name = "CleanMapEvent"
	cleanMapEvent.Parent = ReplicatedStorage
end

-- VALORES
local function ensureValue(name, className)
	local val = ReplicatedStorage:FindFirstChild(name) or Instance.new(className)
	val.Name = name; val.Parent = ReplicatedStorage
	return val
end
local estadoValue = ensureValue("EstadoRonda", "StringValue")
local vivosValue = ensureValue("JugadoresVivos", "StringValue") 
local vivosCountValue = ensureValue("JugadoresVivosCount", "IntValue") 
local inicioValue = ensureValue("JugadoresInicio", "IntValue")        
local humanosInicioValue = ensureValue("HumanosInicio", "IntValue")   
local tiempoRestanteValue = ensureValue("TiempoRestante", "IntValue")

-- CONFIGURACIÓN
local MIN_PLAYERS = 2
local ROUND_DURATION = 120 
local MAX_ROUNDS = 3 

local EVENT_POOL = {
	{Name = "MagmaRain", Display = "LLUVIA DE MAGMA"},
	{Name = "SlipperyBlocks", Display = "BLOQUES DE HIELO"},
	{Name = "HotPotato", Display = "PATATA CALIENTE"}
}

local MAP_LIST = {
	{Id = "LavaPit", Name = "POZO DE LAVA"},
	{Id = "Classic", Name = "CLÁSICO"},
	{Id = "Space", Name = "ESPACIO"}
}

local matchStats = {} 
local currentVotes = {}

-- FUNCIONES
local function resetMatchStats()
	matchStats = {}
	for _, p in ipairs(Players:GetPlayers()) do
		matchStats[p.UserId] = {Wins = 0, Name = p.Name}
	end
end

local function addMatchWin(player)
	if not matchStats[player.UserId] then
		matchStats[player.UserId] = {Wins = 0, Name = player.Name}
	end
	matchStats[player.UserId].Wins = matchStats[player.UserId].Wins + 1
end

local function getWinnersPodium()
	local sorted = {}
	for _, data in pairs(matchStats) do table.insert(sorted, data) end
	table.sort(sorted, function(a, b) return a.Wins > b.Wins end)
	return sorted
end

local function processMapVoting()
	local counts = {}
	local totalVotes = 0
	for _, mapId in pairs(currentVotes) do
		counts[mapId] = (counts[mapId] or 0) + 1
		totalVotes = totalVotes + 1
	end
	if totalVotes == 0 then return MAP_LIST[math.random(1, #MAP_LIST)] end
	local ticket = math.random(1, totalVotes)
	local currentTicket = 0
	for _, mapInfo in ipairs(MAP_LIST) do
		local votesForThis = counts[mapInfo.Id] or 0
		if votesForThis > 0 then
			currentTicket = currentTicket + votesForThis
			if ticket <= currentTicket then return mapInfo end
		end
	end
	return MAP_LIST[1]
end

voteEvent.OnServerEvent:Connect(function(player, mapId)
	currentVotes[player.UserId] = mapId
end)

-- BUCLE PRINCIPAL
while true do
	_G.LluviaActiva = false
	mapEventStop:Fire()
	cleanMapEvent:Fire()
	
	estadoValue.Value = "WAITING"
	
	-- Música de espera (Canal 1), asegurando que el Canal 2 (Victoria) esté mudo
	SoundManager.StopMusic(2) 
	SoundManager.PlayMusic("WaitingMusic", 1, 0.5)
	
	if _G.RespawnAllPlayers then _G.RespawnAllPlayers() end
	
	repeat
		task.wait(1)
		local count = #PlayerManager.GetAlivePlayers()
		estadoValue.Value = "WAITING|" .. count .. "|" .. MIN_PLAYERS
		matchStatusEvent:FireAllClients("WAITING", nil) 
	until count >= MIN_PLAYERS
	
	resetMatchStats()
	
	-- CICLO DE RONDAS
	for roundNum = 1, MAX_ROUNDS do
		-- Parar música de victoria de la ronda anterior si la hubiera
		SoundManager.StopMusic(2)
		SoundManager.StopMusic(1) -- Parar música de espera o ronda anterior
		
		-- Limpieza
		cleanMapEvent:Fire()
		_G.LluviaActiva = false
		
		-- Elegir Evento
		local nextEventData
		local eventName = "None"
		
		if roundNum == 1 then
			nextEventData = {Name = "None", Display = "NORMAL"} 
		else
			nextEventData = EVENT_POOL[math.random(1, #EVENT_POOL)] 
		end
		eventName = nextEventData.Name
		
		-- TRANSICIÓN (Cliente muestra Ruleta y Camara)
		matchStatusEvent:FireAllClients("TRANSITION", {
			Round = roundNum,
			TargetEvent = nextEventData.Display,
			Duration = 6 
		})
		
		task.wait(6.5) -- Esperar a que termine la ruleta
		
		-- PREPARACIÓN
		matchStatusEvent:FireAllClients("PREPARE", nil)
		if _G.RespawnAllPlayers then _G.RespawnAllPlayers() end
		
		-- CUENTA ATRÁS (Sin música aún, solo tensión)
		for i = 5, 1, -1 do
			tiempoRestanteValue.Value = i
			estadoValue.Value = "STARTING|" .. i
			if i <= 3 then countdownEvent:FireAllClients(i) end
			task.wait(1)
		end
		
		-- JUEGO ACTIVO
		estadoValue.Value = "SURVIVE"
		_G.LluviaActiva = true
		
		-- Iniciar Música de Ronda (Canal 1)
		SoundManager.PlayMusic("RoundMusic", 1, 0.5)
		
		if eventName ~= "None" then
			print("🎲 EVENTO: " .. eventName)
			mapEventStart:Fire(eventName)
		end
		
		countdownEvent:FireAllClients("GO")
		roundStartEvent:Fire()
		
		-- Control de Ronda
		local survivors = PlayerManager.GetAlivePlayers()
		inicioValue.Value = #survivors
		vivosCountValue.Value = #survivors
		
		local startTime = tick()
		local roundRunning = true
		
		while roundRunning do
			local elapsed = tick() - startTime
			local remaining = ROUND_DURATION - elapsed
			_G.DuracionRondaActual = elapsed
			tiempoRestanteValue.Value = math.max(0, math.floor(remaining))
			
			local currentSurvivors = PlayerManager.GetAlivePlayers()
			vivosCountValue.Value = #currentSurvivors
			vivosValue.Value = tostring(#currentSurvivors)
			
			if #currentSurvivors <= 1 then
				if #currentSurvivors == 1 then
					local winner = currentSurvivors[1]
					estadoValue.Value = "WINNER|" .. winner.Name
					if winner:IsA("Player") then addMatchWin(winner) end
				else
					estadoValue.Value = "NO_ONE"
				end
				roundRunning = false
			elseif elapsed >= ROUND_DURATION then
				estadoValue.Value = "TIE"
				roundRunning = false
			end
			task.wait(0.5)
		end
		
		-- FIN DE RONDA
		mapEventStop:Fire()
		_G.LluviaActiva = false
		SoundManager.StopMusic(1) -- Parar música de acción
		SoundManager.PlayMusic("VictoryMusic", 2, 0.8) -- Tocar victoria
		task.wait(4)
	end
	
	-- PODIO FINAL
	SoundManager.StopMusic(1) 
	-- Mantenemos la música de victoria sonando durante el podio
	
	local podiumData = getWinnersPodium()
	matchStatusEvent:FireAllClients("PODIUM", podiumData)
	task.wait(8) 
	
	-- VOTACIÓN
	currentVotes = {} 
	matchStatusEvent:FireAllClients("VOTING", MAP_LIST)
	
	local voteDuration = 10
	for i = voteDuration, 1, -1 do task.wait(1) end
	
	local selectedMap = processMapVoting()
	matchStatusEvent:FireAllClients("MAP_RESULT", selectedMap)
	task.wait(4)
end