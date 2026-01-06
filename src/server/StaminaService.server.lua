local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- EVENTO
local sprintEvent = ReplicatedStorage:FindFirstChild("SprintEvent")
if not sprintEvent then
	sprintEvent = Instance.new("RemoteEvent")
	sprintEvent.Name = "SprintEvent"
	sprintEvent.Parent = ReplicatedStorage
end

-- CONFIGURACIÓN BASE (Valores por defecto si no hay mejoras compradas)
local BASE_WALK = 16
local BASE_SPRINT = 28
local DEFAULT_JUMP_POWER = 50 -- Valor normal de Roblox

-- VALORES DE STAMINA (Defaults)
local DEFAULT_MAX = 100
local DEFAULT_REGEN = 15      -- Cuánto regenera por segundo
local DEFAULT_DRAIN = 20      -- Cuánto gasta correr por segundo
local DEFAULT_JUMP_COST = 15  -- Cuánto gasta saltar (NUEVO)
local REGEN_DELAY = 2.5       -- Segundos a esperar para regenerar

-- TABLA DE ESTADOS
-- Guardaremos: { IntentionalSprint = bool, LastActionTime = number, IsExhausted = bool }
local playerStates = {}

--------------------------------------------------------------------------------
-- 1. SETUP DEL JUGADOR
--------------------------------------------------------------------------------
local function setupPlayer(player)
	playerStates[player] = {
		IntentionalSprint = false,
		LastActionTime = 0, -- Momento de la última acción que gastó energía
		IsExhausted = false
	}
	
	player.CharacterAdded:Connect(function(char)
		-- Inicializar atributos visuales
		char:SetAttribute("CurrentStamina", player:GetAttribute("MaxStamina") or DEFAULT_MAX)
		char:SetAttribute("IsExhausted", false)
		
		local hum = char:WaitForChild("Humanoid")
		
		-- DETECCIÓN DE SALTO (Gasto instantáneo)
		hum.StateChanged:Connect(function(old, new)
			if new == Enum.HumanoidStateType.Jumping then
				local state = playerStates[player]
				if not state then return end
				
				-- Leemos atributos actuales (por si compró mejoras)
				local jumpCost = player:GetAttribute("JumpCost") or DEFAULT_JUMP_COST
				local currentStamina = char:GetAttribute("CurrentStamina") or DEFAULT_MAX
				
				-- Solo consumimos si NO está agotado
				if not state.IsExhausted and currentStamina > 0 then
					local newStamina = math.max(0, currentStamina - jumpCost)
					char:SetAttribute("CurrentStamina", newStamina)
					state.LastActionTime = tick() -- Reseteamos el timer de regeneración
					
					-- Si saltar lo dejó en 0, se agota
					if newStamina <= 0 then
						state.IsExhausted = true
					end
				else
					-- Si está agotado, el salto no debería ocurrir físicamente
					-- (Lo controlamos abajo en el bucle seteando JumpPower a 0)
					hum.Jump = false
				end
			end
		end)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end -- Por si recargas el script

Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

--------------------------------------------------------------------------------
-- 2. INPUT DE CORRER
--------------------------------------------------------------------------------
sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
	if playerStates[player] then
		playerStates[player].IntentionalSprint = isSprinting
	end
end)

--------------------------------------------------------------------------------
-- 3. BUCLE DE LÓGICA (HEARTBEAT)
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for player, state in pairs(playerStates) do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		
		if char and hum and hum.Health > 0 then
			-- LEER VARIABLES (Compatibilidad con Tienda)
			local maxStamina = player:GetAttribute("MaxStamina") or DEFAULT_MAX
			local regenRate = player:GetAttribute("StaminaRegen") or DEFAULT_REGEN
			local drainRate = player:GetAttribute("StaminaDrain") or DEFAULT_DRAIN
			
			local current = char:GetAttribute("CurrentStamina") or maxStamina
			
			local isMoving = hum.MoveDirection.Magnitude > 0
			
			-- LÓGICA DE AGOTAMIENTO (EXHAUSTED)
			if state.IsExhausted then
				-- Si está agotado: Bloquear Correr y Saltar
				hum.WalkSpeed = BASE_WALK
				hum.JumpPower = 0 -- No puede saltar
				
				-- Salir del estado agotado solo si recupera el 20%
				if current >= (maxStamina * 0.2) then
					state.IsExhausted = false
					hum.JumpPower = DEFAULT_JUMP_POWER -- Devolver salto
				end
				
			else
				-- ESTADO NORMAL
				hum.JumpPower = DEFAULT_JUMP_POWER
				
				local isSprinting = false
				
				-- ¿Intenta correr + Se mueve + Tiene energía?
				if state.IntentionalSprint and isMoving and current > 0 then
					isSprinting = true
				end
				
				if isSprinting then
					-- GASTAR
					current = math.max(0, current - (drainRate * dt))
					state.LastActionTime = tick() -- Reseteamos el delay de regen
					hum.WalkSpeed = BASE_SPRINT
					
					-- Si llega a 0 corriendo, se agota
					if current <= 0 then
						state.IsExhausted = true
					end
				else
					-- CAMINAR
					hum.WalkSpeed = BASE_WALK
				end
			end
			
			-- REGENERACIÓN (Con Delay)
			-- Solo regenera si pasaron 2.5s desde la última vez que gastó (correr o saltar)
			if tick() - state.LastActionTime >= REGEN_DELAY then
				if current < maxStamina then
					current = math.min(maxStamina, current + (regenRate * dt))
				end
			end
			
			-- ACTUALIZAR ATRIBUTOS (Para que el Cliente/HUD lo vea)
			char:SetAttribute("CurrentStamina", current)
			char:SetAttribute("IsExhausted", state.IsExhausted)
		end
	end
end)