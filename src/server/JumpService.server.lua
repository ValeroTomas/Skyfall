local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- 1. CREAR EVENTO REMOTO
local jumpEvent = ReplicatedStorage:FindFirstChild("DoubleJumpEvent")
if not jumpEvent then
	jumpEvent = Instance.new("RemoteEvent")
	jumpEvent.Name = "DoubleJumpEvent"
	jumpEvent.Parent = ReplicatedStorage
end

-- 2. CONEXIÓN CON PLAYER DATA
local eventsFolder = ServerStorage:WaitForChild("PlayerDataEvents")
local getStatFunction = eventsFolder:WaitForChild("GetPlayerStat")

-- CONFIGURACIÓN DE COLORES
local TRAIL_COLORS = {
	[0] = ColorSequence.new(Color3.fromRGB(255, 255, 255)), -- Blanco
	[1] = ColorSequence.new(Color3.fromRGB(0, 255, 255)),   -- Cyan
	[2] = ColorSequence.new(Color3.fromRGB(255, 0, 0)),     -- Rojo
	[3] = ColorSequence.new(Color3.fromRGB(255, 255, 0)),   -- Amarillo
	[4] = ColorSequence.new(Color3.fromRGB(170, 0, 255)),   -- Violeta
}

local function spawnVisuals(character, colorId)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	-- 1. Attachments
	local a0 = Instance.new("Attachment", hrp)
	local a1 = Instance.new("Attachment", hrp)
	a0.Position = Vector3.new(0, 1, 0)
	a1.Position = Vector3.new(0, -1, 0)

	-- 2. Trail
	local trail = Instance.new("Trail")
	trail.Name = "DoubleJumpTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	
	trail.Color = TRAIL_COLORS[colorId] or TRAIL_COLORS[0]
	trail.Transparency = NumberSequence.new(0.4, 1) 
	trail.Lifetime = 0.5 
	trail.FaceCamera = true
	trail.LightEmission = 1 
	trail.Enabled = true
	trail.Parent = hrp

	-- 3. LOGICA INTELIGENTE: ESPERAR A TOCAR EL SUELO
	local connection
	local isActive = true

	local function stopTrail()
		if not isActive then return end
		isActive = false
		
		-- Desconectamos el evento para ahorrar memoria
		if connection then connection:Disconnect() end
		
		-- Dejamos de emitir cinta nueva
		if trail then trail.Enabled = false end
		
		-- Esperamos a que la cinta vieja desaparezca suavemente
		task.delay(trail.Lifetime + 0.1, function()
			if trail then trail:Destroy() end
			if a0 then a0:Destroy() end
			if a1 then a1:Destroy() end
		end)
	end

	-- Escuchamos cambios de estado del humanoide
	connection = humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			stopTrail() -- ¡Tocó el suelo! Apagar trail.
		end
	end)

	-- 4. SEGURIDAD: Timeout por si nunca toca el suelo (cae al vacío)
	task.delay(5, function()
		if isActive then
			stopTrail()
		end
	end)
end

jumpEvent.OnServerEvent:Connect(function(player)
	local upgrades = getStatFunction:Invoke(player, "Upgrades")
	
	if not upgrades or not upgrades.DoubleJump then 
		return 
	end

	if player.Character then
		spawnVisuals(player.Character, upgrades.DoubleJumpColor or 0)
	end
end)