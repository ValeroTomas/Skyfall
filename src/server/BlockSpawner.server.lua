local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris") -- [NUEVO] Necesario para limpiar partículas
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTAR MANAGERS
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder.SoundManager)
local DecalManager = require(sharedFolder.DecalManager) -- [NUEVO] Importamos DecalManager

-- CONFIGURACIÓN BASE
local CHUNK_SIZE = 50
local SPAWN_HEIGHT = 250
local BLOCK_THICKNESS = 10

-- CONFIGURACIÓN VISUAL [NUEVO]
local ENABLE_SHAKE = true
local FADE_TIME = 0.4 -- Tiempo que tarda en aparecer el bloque (Transparency 1 -> 0)

-- EVENTO DE SHAKE
local shakeEvent = ReplicatedStorage:FindFirstChild("ScreenShakeEvent")
if not shakeEvent then
	shakeEvent = Instance.new("RemoteEvent")
	shakeEvent.Name = "ScreenShakeEvent"
	shakeEvent.Parent = ReplicatedStorage
end

-- VALORES DINÁMICOS
local FALL_SPEED_START = 100 
local FALL_SPEED_MAX = 200
local SPAWN_RATE_START = 2
local SPAWN_RATE_MIN = 0.5 
local ROUND_MAX_TIME = 300 

local map = workspace:WaitForChild("Map")
local platform = map:WaitForChild("Platform")

_G.LluviaActiva = false
_G.DuracionRondaActual = 0 

local columnHeights = {}

local function resetColumnHeights()
	for x = -1, 1 do
		columnHeights[x] = {}
		for z = -1, 1 do
			columnHeights[x][z] = platform.Position.Y + (platform.Size.Y / 2)
		end
	end
end
resetColumnHeights()

_G.LimpiarMapa = function()
	_G.LluviaActiva = false
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "SkyfallBlock" or obj.Name == "LandingIndicator" then
			obj:Destroy()
		end
	end
	resetColumnHeights()
end

-- [CORREGIDO] FUNCIÓN PARA EFECTO DE IMPACTO DETALLADO (8 Puntos)
local function createImpactEffect(block)
	local color = block.Color
	local size = block.Size
	
	-- Calculamos la posición Y de la base del bloque
	-- [FIX] Le sumamos 1 stud hacia arriba para que el humo no nazca enterrado en el piso
	local bottomY = (-size.Y / 2) + 1 
	local hX = size.X / 2
	local hZ = size.Z / 2
	
	-- Los 8 puntos relativos al centro del bloque
	local offsets = {
		Vector3.new(hX, bottomY, hZ),   -- Esquina ++
		Vector3.new(-hX, bottomY, hZ),  -- Esquina -+
		Vector3.new(hX, bottomY, -hZ),  -- Esquina +-
		Vector3.new(-hX, bottomY, -hZ), -- Esquina --
		
		Vector3.new(hX, bottomY, 0),    -- Centro X+
		Vector3.new(-hX, bottomY, 0),   -- Centro X-
		Vector3.new(0, bottomY, hZ),    -- Centro Z+
		Vector3.new(0, bottomY, -hZ)    -- Centro Z-
	}
	
	-- Obtener ID
	local ImpactID = DecalManager.Get("BlockImpact")
	
	-- Si el ID original falla, prueba este ID genérico de humo de Roblox:
	-- finalID = "rbxassetid://243662261" 
	
	for _, offset in ipairs(offsets) do
		local att = Instance.new("Attachment")
		att.Position = offset
		att.Parent = block
		
		local p = Instance.new("ParticleEmitter")
		p.Name = "ImpactSmoke"
		p.Texture = ImpactID
		p.Color = ColorSequence.new(color) 
		p.Size = NumberSequence.new(4, 7) -- Un poco más grandes
		p.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3), -- Empieza visible
			NumberSequenceKeypoint.new(1, 1)    -- Termina invisible
		})
		p.Lifetime = NumberRange.new(0.8, 1.2) -- Viven un poco más
		p.Speed = NumberRange.new(20, 30) 
		p.Drag = 5 
		p.SpreadAngle = Vector2.new(180, 0) 
		
		-- [FIX] Propiedades para mejorar visibilidad
		p.LightEmission = 0.3 -- Un poco brillante para que resalte
		p.ZOffset = 1 -- Forza a renderizarse frente a la cámara si hay duda
		
		p.Rate = 0 
		p.Parent = att
		
		-- Emitimos
		p:Emit(5) 
		Debris:AddItem(att, 2)
	end
end

local function getWeightedRandomChunk()
	local choices = {}
	local totalWeight = 0
	local maxHeight = -math.huge
	for x = -1, 1 do
		for z = -1, 1 do
			if columnHeights[x][z] > maxHeight then maxHeight = columnHeights[x][z] end
		end
	end
	for x = -1, 1 do
		for z = -1, 1 do
			local heightDiff = maxHeight - columnHeights[x][z]
			local weight = 1 + (heightDiff / BLOCK_THICKNESS) 
			table.insert(choices, {x = x, z = z, weight = weight})
			totalWeight = totalWeight + weight
		end
	end
	local randomNumber = math.random() * totalWeight
	local currentSum = 0
	for _, choice in ipairs(choices) do
		currentSum = currentSum + choice.weight
		if randomNumber <= currentSum then return choice.x, choice.z end
	end
end

local function spawnBlock()
	local gridX, gridZ = getWeightedRandomChunk()
	local targetPosX = platform.Position.X + (gridX * CHUNK_SIZE)
	local targetPosZ = platform.Position.Z + (gridZ * CHUNK_SIZE)
	
	local startPos = Vector3.new(targetPosX, SPAWN_HEIGHT, targetPosZ)
	
	local targetY = columnHeights[gridX][gridZ] + (BLOCK_THICKNESS / 2)
	local endPos = Vector3.new(targetPosX, targetY, targetPosZ)
	
	local alpha = math.clamp(_G.DuracionRondaActual / ROUND_MAX_TIME, 0, 1)
	local currentFallSpeed = FALL_SPEED_START + (alpha * (FALL_SPEED_MAX - FALL_SPEED_START))
	local duration = (SPAWN_HEIGHT - targetY) / currentFallSpeed

	-----------------------------------------------------------------------
	-- 1. INDICADOR
	-----------------------------------------------------------------------
	local indicator = Instance.new("Part")
	indicator.Name = "LandingIndicator"
	indicator.Size = Vector3.new(CHUNK_SIZE - 2, 0.2, CHUNK_SIZE - 2)
	
	local floorY = targetY - (BLOCK_THICKNESS / 2)
	indicator.CFrame = CFrame.new(targetPosX, floorY + 0.1, targetPosZ)
	
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.CanQuery = false
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(0, 255, 100)
	indicator.Transparency = 1 
	indicator.Parent = workspace

	SoundManager.Play("BlockBlink", indicator)

	local blinkInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true)
	local blinkTween = TweenService:Create(indicator, blinkInfo, {Transparency = 0.2})
	blinkTween:Play()

	task.delay(duration, function()
		if indicator then indicator:Destroy() end
	end)

	-----------------------------------------------------------------------
	-- 2. BLOQUE REAL
	-----------------------------------------------------------------------
	local block = Instance.new("Part")
	block.Name = "SkyfallBlock"
	block.Size = Vector3.new(CHUNK_SIZE, BLOCK_THICKNESS, CHUNK_SIZE)
	block.CFrame = CFrame.new(startPos)
	block.Anchored = true 
	block.CanCollide = false 
	
	-- [ACTUALIZADO] ESTÉTICA VISUAL
	block.Material = Enum.Material.SmoothPlastic
	-- Colores vivos: Saturación alta (0.7-1), Brillo máximo (1)
	block.Color = Color3.fromHSV(math.random(), math.random(70, 100)/100, 1)
	
	-- [ACTUALIZADO] FADE-IN
	block.Transparency = 1 -- Empieza invisible
	block.Parent = workspace
	
	-- Tween para aparecer suavemente
	TweenService:Create(block, TweenInfo.new(FADE_TIME), {Transparency = 0}):Play()
	
	columnHeights[gridX][gridZ] = targetY + (BLOCK_THICKNESS / 2)
	
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(block, info, {CFrame = CFrame.new(endPos)})
	
	local damageConn
	damageConn = RunService.Heartbeat:Connect(function()
		local hitboxCFrame = block.CFrame * CFrame.new(0, -BLOCK_THICKNESS/2, 0)
		local hitboxSize = Vector3.new(CHUNK_SIZE - 2, 4, CHUNK_SIZE - 2)
		local parts = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, OverlapParams.new())
		for _, part in ipairs(parts) do
			local char = part.Parent
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				char:SetAttribute("Crushed", true) 
				hum.Health = 0
			end
		end
	end)
	
	tween:Play()
	
	-- LÓGICA DE IMPACTO
	tween.Completed:Connect(function()
		if damageConn then damageConn:Disconnect() end
		block.CanCollide = true 
		block.CFrame = CFrame.new(endPos)
		
		-- SONIDO
		SoundManager.Play("BlockImpact", block) -- Asegúrate de tener un sonido con este nombre
		
		-- [NUEVO] EFECTO DE HUMO
		createImpactEffect(block)
		
		-- SCREEN SHAKE
		if ENABLE_SHAKE then
			shakeEvent:FireAllClients(endPos) 
		end
	end)
end

task.spawn(function()
	while true do
		if _G.LluviaActiva then spawnBlock() end
		local alpha = math.clamp(_G.DuracionRondaActual / ROUND_MAX_TIME, 0, 1)
		local currentWait = SPAWN_RATE_START - (alpha * (SPAWN_RATE_START - SPAWN_RATE_MIN))
		task.wait(currentWait)
	end
end)