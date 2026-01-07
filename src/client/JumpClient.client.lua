local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- EVENTOS
local doubleJumpEvent = ReplicatedStorage:WaitForChild("DoubleJumpEvent")
local jumpStaminaEvent = ReplicatedStorage:WaitForChild("JumpStaminaEvent") -- Nuevo evento de resta

-- ESTADO DOBLE SALTO
local canDoubleJump = false
local hasDoubleJumped = false
local lastJumpTime = 0
local JUMP_COOLDOWN = 0.2 

local function getJumpVelocity(humanoid)
	if humanoid.UseJumpPower then return humanoid.JumpPower
	else return math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight) end
end

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	local rootPart = char:WaitForChild("HumanoidRootPart")

	-- ------------------------------------------------------------------
	-- 1. BLOQUEO DE SALTO (LÓGICA CLIENTE - "Check 1")
	-- ------------------------------------------------------------------
	-- Función para activar/desactivar la capacidad de saltar
	local function updateJumpAbility()
		local isExhausted = char:GetAttribute("IsExhausted")
		local stamina = char:GetAttribute("CurrentStamina") or 100
		
		-- Si está agotado O tiene 0 stamina, prohibimos el salto
		if isExhausted or stamina <= 0 then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end

	-- Escuchar cambios en los atributos para bloquear/desbloquear al instante
	char:GetAttributeChangedSignal("IsExhausted"):Connect(updateJumpAbility)
	char:GetAttributeChangedSignal("CurrentStamina"):Connect(updateJumpAbility)
	-- Chequeo inicial
	updateJumpAbility()

	-- ------------------------------------------------------------------
	-- 2. DETECCIÓN DE SALTO NORMAL (PARA RESTAR STAMINA)
	-- ------------------------------------------------------------------
	humanoid.Jumping:Connect(function(isActive)
		if isActive then
			-- Si logramos saltar, le decimos al servidor que reste la stamina
			jumpStaminaEvent:FireServer()
		end
		
		lastJumpTime = tick() -- Para el cooldown del doble salto
	end)

	-- ------------------------------------------------------------------
	-- 3. LÓGICA DE DOBLE SALTO
	-- ------------------------------------------------------------------
	humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			hasDoubleJumped = false
		elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
			if not hasDoubleJumped then
				canDoubleJump = true
			end
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		if tick() - lastJumpTime < JUMP_COOLDOWN then return end
		
		-- Si estamos agotados, salimos (El bloqueo de arriba ya evita el primer salto,
		-- esto evita el doble salto si caemos de un borde sin energía)
		if char:GetAttribute("IsExhausted") then return end

		local ownsUpgrade = player:GetAttribute("DoubleJump") == true

		if canDoubleJump and not hasDoubleJumped and ownsUpgrade then
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
				
				hasDoubleJumped = true
				lastJumpTime = tick()
				
				local jumpVel = getJumpVelocity(humanoid) * 0.9
				local currentVel = rootPart.AssemblyLinearVelocity
				rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, jumpVel, currentVel.Z)
				
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				
				doubleJumpEvent:FireServer()
			end
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)