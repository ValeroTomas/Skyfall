local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

-- Obtener referencia al estado del juego
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- Función para determinar si un jugador debe spawnear según las reglas
local function shouldSpawnPlayer(player)
	-- Verificar que el estado esté disponible
	if not estadoValue or not estadoValue.Value then
		print("RespawnService: EstadoRonda no disponible, permitiendo spawn por defecto")
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
				print("RespawnService: Limpiando personaje aplastado de " .. player.Name)
				oldChar:Destroy()
				task.wait(0.1) -- Pequeña pausa para asegurar limpieza
			end
			
			player:LoadCharacter()

			task.wait(0.2)

			if player.Character then
				player.Character:SetAttribute("KilledByLava", nil)
				player.Character:SetAttribute("Crushed", nil)
				player.Character:SetAttribute("CrushedEffectApplied", nil)
				print("RespawnService: Personaje recreado para " .. player.Name)
			else
				warn("RespawnService: Falló respawn de " .. player.Name)
			end
		else
			-- Si no se puede spawnear, asegurarse de que esté como espectador
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0 -- Matar al jugador para que entre en modo espectador
					print("RespawnService: " .. player.Name .. " mantenido como espectador (ronda en progreso)")
				end
			end
		end
	end)
end

local function respawnAllDead()
	print("RespawnService: Verificando respawn masivo...")
	local respawnedCount = 0
	local skippedCount = 0
	local cleanedCount = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if not char or (hum and hum.Health <= 0) then
			if shouldSpawnPlayer(player) then
				-- Limpiar personaje aplastado si existe
				if char and char:GetAttribute("CrushedEffectApplied") then
					print("RespawnService: Limpiando personaje aplastado de " .. player.Name)
					char:Destroy()
					cleanedCount = cleanedCount + 1
					task.wait(0.1) -- Pequeña pausa para asegurar limpieza
				end
				
				forceSpawn(player)
				respawnedCount = respawnedCount + 1
			else
				skippedCount = skippedCount + 1
				print("RespawnService: " .. player.Name .. " no respawneado (reglas actuales)")
			end
		end
	end
	
	print("RespawnService: " .. respawnedCount .. " jugadores respawneados, " .. skippedCount .. " omitidos, " .. cleanedCount .. " limpiados")
end

_G.RespawnAllPlayers = respawnAllDead

-- Función para spawnear jugadores sin personaje (útil para jugadores que ya están conectados)
local function spawnPlayersWithoutCharacter()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		
		-- Si no tiene personaje o está muerto, intentar spawnear
		if not char or (hum and hum.Health <= 0) then
			if shouldSpawnPlayer(player) then
				print("RespawnService: Spawneando a " .. player.Name .. " (sin personaje)")
				forceSpawn(player)
			end
		end
	end
end

-- Manejar jugadores que se unen al juego
Players.PlayerAdded:Connect(function(player)
	print("RespawnService: " .. player.Name .. " se unió al juego")
	
	-- Esperar un momento para asegurar que el estado esté disponible
	task.wait(0.5)
	
	-- Verificar si el jugador necesita spawnear
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	
	-- Si no tiene personaje o está muerto, intentar spawnear
	if not char or (hum and hum.Health <= 0) then
		if shouldSpawnPlayer(player) then
			print("RespawnService: Spawneando a " .. player.Name .. " (unión al juego)")
			forceSpawn(player)
		else
			print("RespawnService: " .. player.Name .. " no puede spawnear (estado: " .. estadoValue.Value .. ")")
		end
	else
		print("RespawnService: " .. player.Name .. " ya tiene personaje vivo")
	end
end)

-- Spawnear jugadores que ya están conectados pero sin personaje (al iniciar el script)
task.wait(1) -- Esperar a que todo esté inicializado
spawnPlayersWithoutCharacter()

local debugRespawnEvent = ReplicatedStorage:FindFirstChild("DebugRespawnEvent")
if not debugRespawnEvent then
	debugRespawnEvent = Instance.new("RemoteEvent")
	debugRespawnEvent.Name = "DebugRespawnEvent"
	debugRespawnEvent.Parent = ReplicatedStorage
end

debugRespawnEvent.OnServerEvent:Connect(function(player)
	respawnAllDead()
end)

print("RespawnService: Sistema mejorado listo.")local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

-- Obtener referencia al estado del juego
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- Función para determinar si un jugador debe spawnear según las reglas
local function shouldSpawnPlayer(player)
	-- Verificar que el estado esté disponible
	if not estadoValue or not estadoValue.Value then
		print("RespawnService: EstadoRonda no disponible, permitiendo spawn por defecto")
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
				print("RespawnService: Limpiando personaje aplastado de " .. player.Name)
				oldChar:Destroy()
				task.wait(0.1) -- Pequeña pausa para asegurar limpieza
			end
			
			player:LoadCharacter()

			task.wait(0.2)

			if player.Character then
				player.Character:SetAttribute("KilledByLava", nil)
				player.Character:SetAttribute("Crushed", nil)
				player.Character:SetAttribute("CrushedEffectApplied", nil)
				print("RespawnService: Personaje recreado para " .. player.Name)
			else
				warn("RespawnService: Falló respawn de " .. player.Name)
			end
		else
			-- Si no se puede spawnear, asegurarse de que esté como espectador
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0 -- Matar al jugador para que entre en modo espectador
					print("RespawnService: " .. player.Name .. " mantenido como espectador (ronda en progreso)")
				end
			end
		end
	end)
end

local function respawnAllDead()
	print("RespawnService: Verificando respawn masivo...")
	local respawnedCount = 0
	local skippedCount = 0
	local cleanedCount = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if not char or (hum and hum.Health <= 0) then
			if shouldSpawnPlayer(player) then
				-- Limpiar personaje aplastado si existe
				if char and char:GetAttribute("CrushedEffectApplied") then
					print("RespawnService: Limpiando personaje aplastado de " .. player.Name)
					char:Destroy()
					cleanedCount = cleanedCount + 1
					task.wait(0.1) -- Pequeña pausa para asegurar limpieza
				end
				
				forceSpawn(player)
				respawnedCount = respawnedCount + 1
			else
				skippedCount = skippedCount + 1
				print("RespawnService: " .. player.Name .. " no respawneado (reglas actuales)")
			end
		end
	end
	
	print("RespawnService: " .. respawnedCount .. " jugadores respawneados, " .. skippedCount .. " omitidos, " .. cleanedCount .. " limpiados")
end

_G.RespawnAllPlayers = respawnAllDead

-- Manejar jugadores que se unen al juego
Players.PlayerAdded:Connect(function(player)
	print("RespawnService: " .. player.Name .. " se unió al juego")
	
	-- Esperar un momento para asegurar que el estado esté disponible
	task.wait(0.5)
	
	-- Verificar si el jugador necesita spawnear
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	
	-- Si no tiene personaje o está muerto, intentar spawnear
	if not char or (hum and hum.Health <= 0) then
		if shouldSpawnPlayer(player) then
			print("RespawnService: Spawneando a " .. player.Name .. " (unión al juego)")
			forceSpawn(player)
		else
			print("RespawnService: " .. player.Name .. " no puede spawnear (estado: " .. estadoValue.Value .. ")")
		end
	else
		print("RespawnService: " .. player.Name .. " ya tiene personaje vivo")
	end
end)

local debugRespawnEvent = ReplicatedStorage:FindFirstChild("DebugRespawnEvent")
if not debugRespawnEvent then
	debugRespawnEvent = Instance.new("RemoteEvent")
	debugRespawnEvent.Name = "DebugRespawnEvent"
	debugRespawnEvent.Parent = ReplicatedStorage
end

debugRespawnEvent.OnServerEvent:Connect(function(player)
	respawnAllDead()
end)

print("RespawnService: Sistema listo.")
