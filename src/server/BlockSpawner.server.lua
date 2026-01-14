local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder.SoundManager)
local DecalManager = require(sharedFolder.DecalManager) 

local cleanMapEvent = ReplicatedStorage:FindFirstChild("CleanMapEvent")
if not cleanMapEvent then
	cleanMapEvent = Instance.new("BindableEvent")
	cleanMapEvent.Name = "CleanMapEvent"
	cleanMapEvent.Parent = ReplicatedStorage
end

-- CARPETA DE BLOQUES (Para limpieza eficiente)
local levelFolder = workspace:FindFirstChild("LevelObjects") or Instance.new("Folder", workspace)
levelFolder.Name = "LevelObjects"

-- CONFIGURACIÓN BASE
local CHUNK_SIZE = 50
local SPAWN_HEIGHT = 250
local BLOCK_THICKNESS = 10
local ENABLE_SHAKE = true
local FADE_TIME = 0.4 

local shakeEvent = ReplicatedStorage:FindFirstChild("ScreenShakeEvent")
if not shakeEvent then
	shakeEvent = Instance.new("RemoteEvent")
	shakeEvent.Name = "ScreenShakeEvent"
	shakeEvent.Parent = ReplicatedStorage
end

local FALL_SPEED_START = 100 
local FALL_SPEED_MAX = 200
local SPAWN_RATE_START = 2
local SPAWN_RATE_MIN = 0.5 
local ROUND_MAX_TIME = 300 

_G.LluviaActiva = false
_G.DuracionRondaActual = 0 

local columnHeights = {}

-- [HELPER] Buscar plataforma activa
local function getPlatform()
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("Platform")
end

local function resetColumnHeights()
	local platform = getPlatform()
	if not platform then return end
	
	for x = -1, 1 do
		columnHeights[x] = {}
		for z = -1, 1 do
			columnHeights[x][z] = platform.Position.Y + (platform.Size.Y / 2)
		end
	end
	-- print("🧹 [BlockSpawner] Alturas reseteadas.")
end

-- Inicializamos una vez, pero se llamará de nuevo al limpiar
resetColumnHeights()

cleanMapEvent.Event:Connect(function()
	print("🧹 [BlockSpawner] LIMPIEZA TOTAL")
	_G.LluviaActiva = false
	
	levelFolder:ClearAllChildren()
	
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "LandingIndicator" or obj.Name == "MagmaBall" or obj.Name == "Explosion" then
			obj:Destroy()
		end
	end
	
	-- [IMPORTANTE] Recalcular alturas base porque el mapa es nuevo
	task.wait(0.1) -- Pequeña espera para asegurar que el nuevo mapa cargó
	resetColumnHeights()
end)

_G.LimpiarMapa = function() cleanMapEvent:Fire() end

local function createImpactEffect(block)
	local color = block.Color
	local size = block.Size
	
	local bottomY = (-size.Y / 2) + 1 
	local hX = size.X / 2
	local hZ = size.Z / 2
	
	local offsets = {
		Vector3.new(hX, bottomY, hZ), Vector3.new(-hX, bottomY, hZ),  
		Vector3.new(hX, bottomY, -hZ), Vector3.new(-hX, bottomY, -hZ), 
		Vector3.new(hX, bottomY, 0), Vector3.new(-hX, bottomY, 0),   
		Vector3.new(0, bottomY, hZ), Vector3.new(0, bottomY, -hZ)    
	}
	
	local ImpactID = (_G.CurrentMapEvent == "SlipperyBlocks") and DecalManager.Get("IceBlockImpact") or DecalManager.Get("BlockImpact")
	
	for _, offset in ipairs(offsets) do
		local att = Instance.new("Attachment")
		att.Position = offset; att.Parent = block
		
		local p = Instance.new("ParticleEmitter")
		p.Name = "ImpactSmoke"; p.Texture = ImpactID; p.Color = ColorSequence.new(color) 
		p.Size = NumberSequence.new(4, 7); p.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
		p.Lifetime = NumberRange.new(0.8, 1.2); p.Speed = NumberRange.new(20, 30); p.Drag = 5; p.SpreadAngle = Vector2.new(180, 0) 
		p.LightEmission = 0.3; p.ZOffset = 1; p.Rate = 0; p.Parent = att
		
		p:Emit(5); Debris:AddItem(att, 2)
	end
end

local function getWeightedRandomChunk()
	local choices = {}
	local totalWeight = 0
	local maxHeight = -math.huge
	
	-- Validar inicialización
	if not columnHeights[-1] then resetColumnHeights() end
	if not columnHeights[-1] then return nil, nil end -- Si sigue sin haber mapa, salir
	
	for x = -1, 1 do
		for z = -1, 1 do
			local h = columnHeights[x][z] or 0
			if h > maxHeight then maxHeight = h end
		end
	end
	for x = -1, 1 do
		for z = -1, 1 do
			local h = columnHeights[x][z] or 0
			local heightDiff = maxHeight - h
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
	-- [FIX] Obtener plataforma dinámica (por si cambió el mapa)
	local platform = getPlatform()
	if not platform then return end -- Si no hay mapa, no hacemos nada
	
	local gridX, gridZ = getWeightedRandomChunk()
	if not gridX then return end 
	
	local targetPosX = platform.Position.X + (gridX * CHUNK_SIZE)
	local targetPosZ = platform.Position.Z + (gridZ * CHUNK_SIZE)
	
	local startPos = Vector3.new(targetPosX, SPAWN_HEIGHT, targetPosZ)
	local targetY = columnHeights[gridX][gridZ] + (BLOCK_THICKNESS / 2)
	local endPos = Vector3.new(targetPosX, targetY, targetPosZ)
	
	local alpha = math.clamp(_G.DuracionRondaActual / ROUND_MAX_TIME, 0, 1)
	local currentFallSpeed = FALL_SPEED_START + (alpha * (FALL_SPEED_MAX - FALL_SPEED_START))
	local duration = (SPAWN_HEIGHT - targetY) / currentFallSpeed

	-- INDICADOR
	local indicator = Instance.new("Part")
	indicator.Name = "LandingIndicator"
	indicator.Size = Vector3.new(CHUNK_SIZE - 2, 0.2, CHUNK_SIZE - 2)
	local floorY = targetY - (BLOCK_THICKNESS / 2)
	indicator.CFrame = CFrame.new(targetPosX, floorY + 0.1, targetPosZ)
	indicator.Anchored = true; indicator.CanCollide = false; indicator.CanQuery = false
	indicator.Material = Enum.Material.Neon; indicator.Color = Color3.fromRGB(0, 255, 100); indicator.Transparency = 1 
	indicator.Parent = workspace

	SoundManager.Play("BlockBlink", indicator)
	TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true), {Transparency = 0.2}):Play()
	task.delay(duration, function() if indicator then indicator:Destroy() end end)

	-- BLOQUE REAL
	local block = Instance.new("Part")
	block.Name = "SkyfallBlock"
	block.Size = Vector3.new(CHUNK_SIZE, BLOCK_THICKNESS, CHUNK_SIZE)
	block.CFrame = CFrame.new(startPos)
	block.Anchored = true; block.CanCollide = false 
	block.Material = Enum.Material.SmoothPlastic
	block.Color = Color3.fromHSV(math.random(), math.random(70, 100)/100, 1)
	
	local targetTransparency = 0 
	
	if _G.CurrentMapEvent == "SlipperyBlocks" then
		block.Material = Enum.Material.Glass; block.Color = Color3.fromRGB(0, 230, 255); targetTransparency = 0.15 
		block.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.01, 0, 100, 1)
	end
	
	block.Transparency = 1 
	block.Parent = levelFolder -- Usamos la carpeta limpia
	
	TweenService:Create(block, TweenInfo.new(FADE_TIME), {Transparency = targetTransparency}):Play()
	columnHeights[gridX][gridZ] = targetY + (BLOCK_THICKNESS / 2)
	
	local tween = TweenService:Create(block, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endPos)})
	
	local damageConn
	damageConn = RunService.Heartbeat:Connect(function()
		if not block.Parent then damageConn:Disconnect(); return end
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
	
	tween.Completed:Connect(function()
		if damageConn then damageConn:Disconnect() end
		block.CanCollide = true 
		block.CFrame = CFrame.new(endPos)
		
		if _G.CurrentMapEvent == "SlipperyBlocks" then SoundManager.Play("IceBlockImpact" .. math.random(1, 2), block)
		else SoundManager.Play("BlockImpact", block) end
		
		createImpactEffect(block)
		if ENABLE_SHAKE then shakeEvent:FireAllClients(endPos) end
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