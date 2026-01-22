local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
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

local estadoValue = ensureValue("EstadoRonda", "StringValue") :: StringValue
local vivosValue = ensureValue("JugadoresVivos", "StringValue") :: StringValue
local vivosCountValue = ensureValue("JugadoresVivosCount", "IntValue") :: IntValue
local inicioValue = ensureValue("JugadoresInicio", "IntValue") :: IntValue
-- [CORRECCIÓN] RESTAURAMOS ESTE VALOR PORQUE REWARDSERVICE LO NECESITA
local humanosInicioValue = ensureValue("HumanosInicio", "IntValue") :: IntValue 
local tiempoRestanteValue = ensureValue("TiempoRestante", "IntValue") :: IntValue

-- CONFIGURACIÓN
local MIN_PLAYERS = 1
local ROUND_DURATION = 120 
local MAX_ROUNDS = 3 

local EVENT_POOL = {
	{Name = "MagmaRain", Display = "LLUVIA DE MAGMA"},
	{Name = "SlipperyBlocks", Display = "BLOQUES DE HIELO"},
	{Name = "HotPotato", Display = "PATATA CALIENTE"}
}

local MAP_LIST = {
	{Id = "DefaultMap", Name = "POZO DE LAVA", Image = "LavaPit"}, 
	{Id = "EndlessPool", Name = "PISCINA SINFIN", Image = "EndlessPool"} 
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

local function applyLighting(configFolder)
	print("💡 Aplicando iluminación del mapa...")
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end
	
	if not configFolder then
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		return
	end
	
	for _, effect in ipairs(configFolder:GetChildren()) do
		effect:Clone().Parent = Lighting
	end
	
	local atts = configFolder:GetAttributes()
	for key, value in pairs(atts) do
		pcall(function() Lighting[key] = value end)
	end
end

local function loadMap(mapId)
	print("🗺️ Cargando mapa: " .. mapId)
	local oldMap = workspace:FindFirstChild("Map")
	if oldMap then oldMap:Destroy() end
	
	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	local template = mapsFolder and mapsFolder:FindFirstChild(mapId)
	
	if template then
		local newMap = template:Clone()
		newMap.Name = "Map" 
		newMap.Parent = workspace
		
		local lightingConfig = newMap:FindFirstChild("LightingConfig")
		applyLighting(lightingConfig)
	else
		warn("❌ ERROR CRÍTICO: No se encontró el mapa '" .. mapId .. "'")
	end
end

voteEvent.OnServerEvent:Connect(function(player, mapId)
	currentVotes[player.UserId] = mapId
end)

-- BUCLE PRINCIPAL
local nextMapToLoad = MAP_LIST[2].Id 
loadMap(nextMapToLoad)

while true do
	SoundManager.PlayMusic("WaitingMusic", 1, 1)
	
	local mapNameDisplay = "DESCONOCIDO"
	for _, m in ipairs(MAP_LIST) do
		if m.Id == nextMapToLoad then mapNameDisplay = m.Name; break end
	end
	
	matchStatusEvent:FireAllClients("LOADING", {MapName = mapNameDisplay})
	task.wait(2) 
	
	_G.LluviaActiva = false
	mapEventStop:Fire()
	cleanMapEvent:Fire()
	loadMap(nextMapToLoad)
	
	task.wait(1) 
	
	if _G.RespawnAllPlayers then _G.RespawnAllPlayers() end
	
	estadoValue.Value = "WAITING"
	
	repeat
		task.wait(1)
		local count = #PlayerManager.GetAlivePlayers()
		estadoValue.Value = "WAITING|" .. count .. "|" .. MIN_PLAYERS
		matchStatusEvent:FireAllClients("WAITING", nil) 
	until count >= MIN_PLAYERS
	
	task.wait(3) 
	
	resetMatchStats()
	
	-- CICLO DE RONDAS
	for roundNum = 1, MAX_ROUNDS do
		SoundManager.StopMusic(2, 0.1) 
		SoundManager.PlayMusic("WaitingMusic", 1, 1)
		
		cleanMapEvent:Fire()
		_G.LluviaActiva = false
		
		local nextEventData
		local eventName = "None"
		if roundNum == 1 then nextEventData = {Name = "None", Display = "NORMAL"} 
		else nextEventData = EVENT_POOL[math.random(1, #EVENT_POOL)] end
		eventName = nextEventData.Name
		
		matchStatusEvent:FireAllClients("TRANSITION", {
			Round = roundNum,
			TargetEvent = nextEventData.Display,
			Duration = 6 
		})
		
		task.wait(6.5)
		
		matchStatusEvent:FireAllClients("PREPARE", nil)
		if _G.RespawnAllPlayers then _G.RespawnAllPlayers() end
		
		for i = 15, 1, -1 do
			tiempoRestanteValue.Value = i
			estadoValue.Value = "STARTING|" .. i
			if i <= 3 then countdownEvent:FireAllClients(i) end
			task.wait(1)
		end
		
		estadoValue.Value = "SURVIVE"
		_G.LluviaActiva = true
		SoundManager.PlayMusic("RoundMusic", 1, 0.5)
		
		if eventName ~= "None" then mapEventStart:Fire(eventName) end
		
		countdownEvent:FireAllClients("GO")
		roundStartEvent:Fire()
		
		local startTime = tick()
		local roundRunning = true
		
		-- [CORRECCIÓN] Actualizar los valores de inicio para RewardService
		local alive = PlayerManager.GetAlivePlayers()
		inicioValue.Value = #alive
		humanosInicioValue.Value = #alive -- Simplificado: cuenta a todos como "humanos" por ahora para evitar errores
		
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
				else estadoValue.Value = "NO_ONE" end
				roundRunning = false
			elseif elapsed >= ROUND_DURATION then
				estadoValue.Value = "TIE"; roundRunning = false
			end
			task.wait(0.5)
		end
		
		mapEventStop:Fire()
		_G.LluviaActiva = false
		SoundManager.StopMusic(1)
		SoundManager.PlayMusic("VictoryMusic", 2, 0.8) 
		
		task.wait(5)
	end
	
	SoundManager.StopMusic(1) 
	local podiumData = getWinnersPodium()
	matchStatusEvent:FireAllClients("PODIUM", podiumData)
	task.wait(8) 
	
	currentVotes = {} 
	matchStatusEvent:FireAllClients("VOTING", MAP_LIST)
	local voteDuration = 10
	for i = voteDuration, 1, -1 do task.wait(1) end
	
	local selectedMap = processMapVoting()
	matchStatusEvent:FireAllClients("MAP_RESULT", selectedMap)
	nextMapToLoad = selectedMap.Id 
	
	task.wait(4)
end