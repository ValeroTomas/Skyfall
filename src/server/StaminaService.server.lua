local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

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

local BASE_WALK = 16
local BASE_SPRINT = 28

-- Variables para control de regeneración
local lastActionTimes = {} -- [Model] = Tick

--------------------------------------------------------------------------------
-- MANEJO DE INPUTS (SOLO JUGADORES)
--------------------------------------------------------------------------------
sprintEvent.OnServerEvent:Connect(function(player, isSprinting)
	if player.Character then
		-- Usamos un atributo para que sea compatible con la IA de los bots
		player.Character:SetAttribute("WantsToSprint", isSprinting)
	end
end)

jumpStaminaEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	if not char then return end
	
	if char:GetAttribute("IsExhausted") then return end 
	
	local current = char:GetAttribute("CurrentStamina") or DEFAULT_MAX_STAMINA
	if current <= 0 then return end

	local multiplier = player:GetAttribute("JumpStaminaCost") or 1.0
	local finalJumpCost = BASE_JUMP_COST * multiplier
	
	local newValue = math.max(0, current - finalJumpCost)
	char:SetAttribute("CurrentStamina", newValue)
	lastActionTimes[char] = tick()
	
	if newValue <= 0 then char:SetAttribute("IsExhausted", true) end
end)

--------------------------------------------------------------------------------
-- PROCESAMIENTO DE UN PERSONAJE (HUMANO O BOT)
--------------------------------------------------------------------------------
local function processCharacter(char, dt, isBot)
	local hum = char:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 then 
		lastActionTimes[char] = nil
		return 
	end
	
	-- LEER STATS (Los bots los tienen en el Modelo, los jugadores en el Player)
	local source = isBot and char or Players:GetPlayerFromCharacter(char)
	if not source then return end -- Jugador desconectado
	
	local maxStamina = source:GetAttribute("MaxStamina") or DEFAULT_MAX_STAMINA
	local regenRate = source:GetAttribute("StaminaRegen") or DEFAULT_REGEN
	local drainRate = source:GetAttribute("StaminaDrain") or DEFAULT_DRAIN
	
	-- SALTO
	local targetJumpPower = source:GetAttribute("JumpHeight") or 50
	if not hum.UseJumpPower then hum.UseJumpPower = true end

	local current = char:GetAttribute("CurrentStamina") or maxStamina
	local isExhausted = char:GetAttribute("IsExhausted")
	local wantsToSprint = char:GetAttribute("WantsToSprint") == true
	local isMoving = hum.MoveDirection.Magnitude > 0

	-- LÓGICA DE VELOCIDAD Y GASTO
	if isExhausted then
		hum.JumpPower = 0
		hum.WalkSpeed = BASE_WALK
		
		-- Recuperarse del agotamiento al 30%
		if current >= (maxStamina * 0.3) then
			char:SetAttribute("IsExhausted", false)
		end
	else
		hum.JumpPower = targetJumpPower
		
		-- ¿Está corriendo realmente?
		if wantsToSprint and isMoving and current > 0 then
			hum.WalkSpeed = BASE_SPRINT
			current = math.max(0, current - (drainRate * dt))
			lastActionTimes[char] = tick()
			
			if current <= 0 then
				char:SetAttribute("IsExhausted", true)
				-- Cortar sprint forzoso visualmente
				if not isBot then sprintEvent:FireClient(source, false) end 
			end
		else
			-- [FIX] Si el bot usa habilidades que pausan movimiento (WalkSpeed 0),
			-- no lo sobreescribimos aquí si es 0. Solo si es > 0.
			if hum.WalkSpeed > 0 then
				hum.WalkSpeed = BASE_WALK
			end
		end
	end
	
	-- REGENERACIÓN
	local lastTime = lastActionTimes[char] or 0
	if tick() - lastTime >= REGEN_DELAY then
		if current < maxStamina then
			current = math.min(maxStamina, current + (regenRate * dt))
		end
	end
	
	char:SetAttribute("CurrentStamina", current)
end

--------------------------------------------------------------------------------
-- BUCLE PRINCIPAL
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	-- 1. Procesar Jugadores
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			processCharacter(player.Character, dt, false)
		end
	end
	
	-- 2. Procesar Bots
	for _, bot in ipairs(CollectionService:GetTagged("Bot")) do
		processCharacter(bot, dt, true)
	end
end)