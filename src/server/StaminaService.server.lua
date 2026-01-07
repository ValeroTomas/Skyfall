local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- EVENTOS
local sprintEvent = ReplicatedStorage:FindFirstChild("SprintEvent")
if not sprintEvent then
	sprintEvent = Instance.new("RemoteEvent")
	sprintEvent.Name = "SprintEvent"
	sprintEvent.Parent = ReplicatedStorage
end

local jumpStaminaEvent = ReplicatedStorage:FindFirstChild("JumpStaminaEvent")
if not jumpStaminaEvent then
	jumpStaminaEvent = Instance.new("RemoteEvent")
	jumpStaminaEvent.Name = "JumpStaminaEvent"
	jumpStaminaEvent.Parent = ReplicatedStorage
end

-- CONFIGURACIÓN
local REGEN_DELAY = 2.5       
local DEFAULT_MAX_STAMINA = 100
local DEFAULT_REGEN = 15      
local DEFAULT_DRAIN = 20      
local BASE_JUMP_COST = 20     
local DEFAULT_JUMP_POWER = 50 

local BASE_WALK = 16
local BASE_SPRINT = 28

local playerStates = {}

-- DEBUG (Imprimir valor cada 5 segundos para verificar)
local lastPrint = 0

--------------------------------------------------------------------------------
-- 1. SETUP DEL JUGADOR
--------------------------------------------------------------------------------
local function setupPlayer(player)
	playerStates[player] = {
		WantsToSprint = false,
		LastActionTime = 0,
		IsExhausted = false
	}
	
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		
		-- Inicializar atributos
		if not player:GetAttribute("MaxStamina") then player:SetAttribute("MaxStamina", DEFAULT_MAX_STAMINA) end
		char:SetAttribute("CurrentStamina", player:GetAttribute("MaxStamina"))
		char:SetAttribute("IsExhausted", false) 
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player) playerStates[player] = nil end)
for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

--------------------------------------------------------------------------------
-- 2. HANDLERS DE EVENTOS
--------------------------------------------------------------------------------
sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
	if playerStates[player] then
		playerStates[player].WantsToSprint = isSprinting
	end
end)

jumpStaminaEvent.OnServerEvent:Connect(function(player)
	local state = playerStates[player]
	local char = player.Character
	if not state or not char then return end
	
	if state.IsExhausted then return end 
	
	local current = char:GetAttribute("CurrentStamina") or DEFAULT_MAX_STAMINA
	if current <= 0 then return end

	local multiplier = player:GetAttribute("JumpStaminaCost") or 1.0
	local finalJumpCost = BASE_JUMP_COST * multiplier
	
	local newValue = math.max(0, current - finalJumpCost)
	char:SetAttribute("CurrentStamina", newValue)
	state.LastActionTime = tick()
	
	if newValue <= 0 then
		state.IsExhausted = true
	end
end)

--------------------------------------------------------------------------------
-- 3. BUCLE PRINCIPAL
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	-- Debug Timer
	local doDebug = false
	if tick() - lastPrint > 5 then
		lastPrint = tick()
		doDebug = true
	end

	for player, state in pairs(playerStates) do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		
		if char and hum and hum.Health > 0 then
			local maxStamina = player:GetAttribute("MaxStamina") or DEFAULT_MAX_STAMINA
			local regenRate = player:GetAttribute("StaminaRegen") or DEFAULT_REGEN
			local drainRate = player:GetAttribute("StaminaDrain") or DEFAULT_DRAIN
			
			-- OBTENER PODER DE SALTO DEL ATRIBUTO O DEFAULT
			local targetJumpPower = player:GetAttribute("JumpHeight") or DEFAULT_JUMP_POWER
			
			if doDebug then
				print("DEBUG SALTO (" .. player.Name .. "): Atributo=" .. tostring(player:GetAttribute("JumpHeight")) .. " | Aplicado=" .. targetJumpPower)
			end

			local current = char:GetAttribute("CurrentStamina") or maxStamina
			local isMoving = hum.MoveDirection.Magnitude > 0
			
			-- GARANTIZAR QUE USAMOS JUMP POWER
			if not hum.UseJumpPower then hum.UseJumpPower = true end

			-- LÓGICA DE AGOTAMIENTO
			if state.IsExhausted then
				hum.JumpPower = 0 
				hum.WalkSpeed = BASE_WALK
				
				if current >= (maxStamina * 0.2) then
					state.IsExhausted = false
				end
			else
				hum.JumpPower = targetJumpPower -- APLICAR FUERZA
				
				local actuallySprinting = state.WantsToSprint and isMoving and current > 0
				
				if actuallySprinting then
					hum.WalkSpeed = BASE_SPRINT
					current = math.max(0, current - (drainRate * dt))
					state.LastActionTime = tick()
					
					if current <= 0 then
						state.IsExhausted = true
					end
				else
					hum.WalkSpeed = BASE_WALK
				end
			end
			
			if tick() - state.LastActionTime >= REGEN_DELAY then
				if current < maxStamina then
					current = math.min(maxStamina, current + (regenRate * dt))
				end
			end
			
			char:SetAttribute("CurrentStamina", current)
			char:SetAttribute("IsExhausted", state.IsExhausted)
		end
	end
end)