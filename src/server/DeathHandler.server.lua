local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PlayerManager = require(script.Parent.PlayerManager)
local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent")

-- SISTEMA DE RESPAWN AUTOMÁTICO
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
local respawnQueue = {} -- Cola de jugadores esperando respawn
local respawnCheckInterval = 1 -- Verificar cada segundo

-- Función para agregar jugador a la cola de respawn
local function addToRespawnQueue(player, deathType)
	if not respawnQueue[player] then
		respawnQueue[player] = {
			player = player,
			deathTime = tick(),
			deathType = deathType or "unknown"
		}
		print("DeathHandler: " .. player.Name .. " agregado a cola de respawn (" .. deathType .. ")")
	end
end

-- SISTEMA DE RESPAWN AUTOMÁTICO
local function shouldRespawnPlayer(player, deathEntry)
	local estado = estadoValue.Value
	local estadoPartes = string.split(estado, "|")
	local estadoActual = estadoPartes[1]
	local tiempoRestante = tonumber(estadoPartes[2]) or 0
	
	-- Reglas de spawn según el estado del juego
	if estadoActual == "WAITING" then
		return true -- Spawn activo durante WAITING
	elseif estadoActual == "STARTING" then
		return true -- Spawn forzado al inicio de STARTING
	elseif estadoActual == "STARTING" and tiempoRestante <= 3 and tiempoRestante >= 1 then
		return true -- Spawn forzado entre segundos 3-1 de STARTING
	else
		return false -- No hay spawn durante ronda (SURVIVE)
	end
end

-- Detectar cambios de estado para respawn masivo
local lastEstado = ""
local function onEstadoChanged()
	local currentEstado = estadoValue.Value
	if currentEstado ~= lastEstado then
		local estadoPartes = string.split(currentEstado, "|")
		local estadoActual = estadoPartes[1]
		
		-- Si cambiamos a STARTING, respawnear todos los jugadores muertos
		if estadoActual == "STARTING" and lastEstado ~= "STARTING" then
			print("DeathHandler: Cambio a STARTING detectado - respawn masivo activado")
			if _G.RespawnAllPlayers then
				_G.RespawnAllPlayers()
			end
		end
		
		lastEstado = currentEstado
	end
end

-- Procesar la cola de respawn
local function processRespawnQueue()
	for player, deathEntry in pairs(respawnQueue) do
		if player and player.Parent then
			if shouldRespawnPlayer(player, deathEntry) then
				-- Respawnear al jugador
				if _G.RespawnAllPlayers then
					_G.RespawnAllPlayers()
				end
				-- Remover de la cola
				respawnQueue[player] = nil
				print("DeathHandler: " .. player.Name .. " respawneado")
			end
		else
			-- Jugador se desconectó, remover de la cola
			respawnQueue[player] = nil
		end
	end
end

-- Iniciar el sistema de verificación de respawn
task.spawn(function()
	while true do
		onEstadoChanged() -- Verificar cambios de estado
		processRespawnQueue() -- Procesar cola de respawn
		task.wait(respawnCheckInterval)
	end
end)

local function setupDeath(character, playerName, isBot)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	humanoid.Died:Connect(function()
		---------------------------------------------------------------
		-- 1. CÁLCULO DE RANK (PUESTO)
		---------------------------------------------------------------
		local currentAlive = PlayerManager.GetAlivePlayers()
		local rank = #currentAlive + 1
		
		if rank == 1 then rank = 2 end
		
		-- Si es jugador, guardamos atributo en player. Si es bot, en el modelo.
		if not isBot then
			local p = Players:GetPlayerFromCharacter(character)
			if p then p:SetAttribute("RoundRank", rank) end
		else
			character:SetAttribute("RoundRank", rank) -- El bot guarda su rank en el modelo
		end
		
		print(playerName .. " eliminado. Puesto: #" .. rank)

		---------------------------------------------------------------
		-- 2. KILLFEED
		---------------------------------------------------------------
		local attackerTag = character:FindFirstChild("LastAttacker")
		local attacker = attackerTag and attackerTag.Value
		
		local cause = "LAVA"
		if character:GetAttribute("Crushed") then
			cause = "CRUSH"
		end
		
		local attackerName = nil
		if attacker then
			if attacker:IsA("Player") then attackerName = attacker.Name
			elseif attacker:IsA("Model") then attackerName = attacker.Name end -- Soporte nombre bot atacante
		end
		
		local messageKey = ""
		if attackerName then
			messageKey = (cause == "LAVA") and "DEATH_PUSH_LAVA" or "DEATH_PUSH_CRUSH"
			killfeedEvent:FireAllClients(messageKey, playerName, attackerName)
		else
			messageKey = (cause == "LAVA") and "DEATH_LAVA" or "DEATH_CRUSH"
			killfeedEvent:FireAllClients(messageKey, playerName)
		end
		
		---------------------------------------------------------------
		-- 3. SISTEMA DE RESPAWN PARA JUGADORES
		---------------------------------------------------------------
		if not isBot then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				-- Determinar tipo de muerte para el respawn
				local deathType = "unknown"
				if character:GetAttribute("Crushed") then
					deathType = "crushed"
				elseif character:GetAttribute("KilledByLava") then
					deathType = "lava"
				elseif character:GetAttribute("KilledByWater") then
					deathType = "water"
				end
				
				-- Agregar a la cola de respawn
				addToRespawnQueue(player, deathType)
			end
		end
		
		---------------------------------------------------------------
		-- 4. LIMPIEZA DE BOTS MUERTOS
		---------------------------------------------------------------
		if isBot then
			-- Marcar el bot como muerto inmediatamente
			character:SetAttribute("IsDead", true)
			
			-- Para bots, eliminamos el modelo después de un tiempo
			task.wait(1)
			if character and character.Parent then
				character:Destroy()
			end
		end
	end)
end

-- Conectar Jugadores
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		setupDeath(char, player.Name, false)
	end)
end)

-- Conectar Bots
CollectionService:GetInstanceAddedSignal("Bot"):Connect(function(bot)
	setupDeath(bot, bot.Name, true)
end)

for _, bot in ipairs(CollectionService:GetTagged("Bot")) do
	setupDeath(bot, bot.Name, true)
end