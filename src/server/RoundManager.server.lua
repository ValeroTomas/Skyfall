local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local PlayerManager = require(script.Parent.PlayerManager)

local SoundManager = require(ReplicatedStorage.shared.SoundManager)

-- 1. VALORES PÚBLICOS
local function ensureValue(name, className)
    local val = ReplicatedStorage:FindFirstChild(name)
    if not val then
        val = Instance.new(className)
        val.Name = name
        val.Parent = ReplicatedStorage
    end
    return val
end

local estadoValue = ensureValue("EstadoRonda", "StringValue")
local vivosValue = ensureValue("JugadoresVivos", "StringValue") 
local vivosCountValue = ensureValue("JugadoresVivosCount", "IntValue") 
local inicioValue = ensureValue("JugadoresInicio", "IntValue") 
local tiempoRestanteValue = ensureValue("TiempoRestante", "IntValue")

-- 2. EVENTOS
local roundStartEvent = ReplicatedStorage:FindFirstChild("RoundStartEvent")
if not roundStartEvent then
	roundStartEvent = Instance.new("BindableEvent") -- Para otros scripts del Server
	roundStartEvent.Name = "RoundStartEvent"
	roundStartEvent.Parent = ReplicatedStorage
end

local countdownEvent = ReplicatedStorage:FindFirstChild("CountdownEvent")
if not countdownEvent then
	countdownEvent = Instance.new("RemoteEvent") -- Para el Cliente (HUD/Sonido)
	countdownEvent.Name = "CountdownEvent"
	countdownEvent.Parent = ReplicatedStorage
end

-- CONFIGURACIÓN
local IntermissionTime = 20 
local MinPlayers = 2   
local ROUND_DURATION = 150 

_G.LluviaActiva = false
_G.DuracionRondaActual = 0

while true do
    -------------------------------------------------------------------
    -- FASE 1: LIMPIEZA Y ESPERA
    -------------------------------------------------------------------
    _G.LluviaActiva = false
    _G.DuracionRondaActual = 0
    
    SoundManager.PlayMusic("WaitingMusic", 2) 
    
    if _G.LimpiarMapa then _G.LimpiarMapa() end
    if _G.RespawnAllPlayers then _G.RespawnAllPlayers() end

    vivosValue.Value = "0"
    vivosCountValue.Value = 0
    inicioValue.Value = 0
    tiempoRestanteValue.Value = 0
    estadoValue.Value = "WAITING"
    
    local currentPlayers = Players:GetPlayers()
    while #currentPlayers < MinPlayers do
        estadoValue.Value = "WAITING|" .. #currentPlayers .. "|" .. MinPlayers
        task.wait(1)
        currentPlayers = Players:GetPlayers()
    end
    
    -------------------------------------------------------------------
    -- FASE 2: CUENTA REGRESIVA
    -------------------------------------------------------------------
    for i = IntermissionTime, 1, -1 do
        tiempoRestanteValue.Value = i
        estadoValue.Value = "STARTING|" .. i
        
        -- SEÑAL DE CUENTA REGRESIVA (3, 2, 1)
        if i <= 3 then
            countdownEvent:FireAllClients(i) -- Enviamos el número al cliente
        end
        
        if i == 1 and _G.RespawnAllPlayers then 
            _G.RespawnAllPlayers() 
        end
        task.wait(1)
    end
    
    -------------------------------------------------------------------
    -- FASE 3: JUEGO ACTIVO
    -------------------------------------------------------------------
    estadoValue.Value = "SURVIVE"
    _G.LluviaActiva = true
    
    -- SEÑAL DE INICIO
    countdownEvent:FireAllClients("GO") -- Enviamos "GO" al cliente
    SoundManager.PlayMusic("RoundMusic", 1) 
    
    local startingSurvivors = PlayerManager.GetAlivePlayers()
    inicioValue.Value = #startingSurvivors
    vivosCountValue.Value = #startingSurvivors
    
    for _, p in ipairs(startingSurvivors) do
        p:SetAttribute("RoundRank", 0) 
    end
    
    roundStartEvent:Fire()
    
    local gameRunning = true
    local startTime = tick()
    
    while gameRunning do
        local elapsed = tick() - startTime
        local remaining = ROUND_DURATION - elapsed
        _G.DuracionRondaActual = elapsed
        
        tiempoRestanteValue.Value = math.max(0, math.floor(remaining))
        
        local alivePlayers = PlayerManager.GetAlivePlayers()
        local aliveCount = #alivePlayers
        
        vivosValue.Value = tostring(aliveCount)
        vivosCountValue.Value = aliveCount
        
        if elapsed >= ROUND_DURATION then
            estadoValue.Value = "TIE"
            gameRunning = false
            for _, p in ipairs(alivePlayers) do
                p:SetAttribute("RoundRank", 1)
            end
            
        elseif aliveCount <= 1 then
            if aliveCount == 1 then
                local winner = alivePlayers[1]
                estadoValue.Value = "WINNER|" .. winner.Name
                winner:SetAttribute("RoundRank", 1)
            else
                estadoValue.Value = "NO_ONE"
            end
            gameRunning = false
        end
        
        task.wait(0.5)
    end
    
    -------------------------------------------------------------------
    -- FASE 4: FINALIZACIÓN
    -------------------------------------------------------------------
    _G.LluviaActiva = false
    
    SoundManager.PlayMusic("VictoryMusic", 2)
    
    task.wait(5)
end