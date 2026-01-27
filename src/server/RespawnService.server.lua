local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

-- Obtener referencia al estado del juego
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- Función para determinar si un jugador debe spawnear según las reglas
local function shouldSpawnPlayer(player)
	-- Verificar que el estado esté disponible
	if not estadoValue or not estadoValue.Value then
		return true -- Permitir spawn si no hay estado
	end
	
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

local function forceSpawn(player)
	if not player or not player.Parent then return end

	task.defer(function()
		-- SOLO pedir a Roblox que cargue el character si las reglas lo permiten
		if shouldSpawnPlayer(player) then
			-- Limpiar personaje anterior si existe y está "aplastado"
			local oldChar = player.Character
			if oldChar and oldChar:GetAttribute("CrushedEffectApplied") then
				oldChar:Destroy()
				task.wait(0.1)
			end
			
			-- ESTA LÍNEA ES MÁGICA: Si estás vivo, te reinicia. Si estás muerto, te revive.
			player:LoadCharacter()

			task.wait(0.2)

			if player.Character then
				player.Character:SetAttribute("KilledByLava", nil)
				player.Character:SetAttribute("Crushed", nil)
				player.Character:SetAttribute("CrushedEffectApplied", nil)
			end
		else
			-- Si no se puede spawnear, asegurarse de que esté como espectador
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0 -- Matar al jugador para que entre en modo espectador
				end
			end
		end
	end)
end

-- [CORRECCIÓN] Ahora esta función respawnea a TODOS, no solo a los muertos
local function respawnAllPlayers()
	print("RespawnService: Forzando respawn GENERAL (Limpiando bugs)...")
	local respawnedCount = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		if shouldSpawnPlayer(player) then
			local char = player.Character

			-- Limpiar personaje aplastado si existe
			if char and char:GetAttribute("CrushedEffectApplied") then
				char:Destroy()
				task.wait(0.1)
			end
			
			-- [NUEVO] Forzamos el spawn sin importar si "hum.Health > 0"
			forceSpawn(player)
			respawnedCount = respawnedCount + 1
		end
	end
	
	print("RespawnService: " .. respawnedCount .. " jugadores reiniciados correctamente.")
end

-- Actualizamos la variable global
_G.RespawnAllPlayers = respawnAllPlayers

-- Manejar jugadores que se unen al juego
Players.PlayerAdded:Connect(function(player)
	task.wait(0.5)
	
	-- Si no tiene personaje o está muerto, intentar spawnear
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	
	if not char or (hum and hum.Health <= 0) then
		if shouldSpawnPlayer(player) then
			forceSpawn(player)
		end
	end
end)

local debugRespawnEvent = ReplicatedStorage:FindFirstChild("DebugRespawnEvent")
if not debugRespawnEvent then
	debugRespawnEvent = Instance.new("RemoteEvent")
	debugRespawnEvent.Name = "DebugRespawnEvent"
	debugRespawnEvent.Parent = ReplicatedStorage
end

debugRespawnEvent.OnServerEvent:Connect(function(player)
	respawnAllPlayers()
end)

print("RespawnService: Sistema Anti-Bug listo.")