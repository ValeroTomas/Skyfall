local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTAR MANAGERS
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder.SoundManager)
local DecalManager = require(sharedFolder.DecalManager) 

-- EVENTO DE LIMPIEZA (Nuevo y Robusto)
local cleanMapEvent = ReplicatedStorage:FindFirstChild("CleanMapEvent")
if not cleanMapEvent then
	cleanMapEvent = Instance.new("BindableEvent")
	cleanMapEvent.Name = "CleanMapEvent"
	cleanMapEvent.Parent = ReplicatedStorage
end

-- CONFIGURACIÓN BASE
local CHUNK_SIZE = 50
local SPAWN_HEIGHT = 250
local BLOCK_THICKNESS = 10

-- CONFIGURACIÓN VISUAL
local ENABLE_SHAKE = true
local FADE_TIME = 0.4 

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
	print("🧹 [BlockSpawner] Alturas de columnas reseteadas.")
end
resetColumnHeights()

-- LÓGICA DE LIMPIEZA FORZADA
cleanMapEvent.Event:Connect(function()
	print("🧹 [BlockSpawner] EJECUTANDO LIMPIEZA TOTAL DEL MAPA")
	_G.LluviaActiva = false
	
	-- Borrar todo lo que sea basura de la ronda
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "SkyfallBlock" or 
		   obj.Name == "LandingIndicator" or 
		   obj.Name == "MagmaBall" or 
		   obj.Name == "Explosion" or -- Visuales
		   obj.Name == "Part" and obj:FindFirstChild("ParticleEmitter") then -- Particulas sueltas
			obj:Destroy()
		end
	end
	
	resetColumnHeights()
end)

-- Mantengo _G por compatibilidad si algo más lo llama, pero el evento es el principal
_G.LimpiarMapa = function() cleanMapEvent:Fire() end

-- FUNCIÓN PARA EFECTO DE IMPACTO
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
	
	local ImpactID
	if _G.CurrentMapEvent == "SlipperyBlocks" then
		ImpactID = DecalManager.Get("IceBlockImpact")
	else
		ImpactID = DecalManager.Get("BlockImpact")
	end
	
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
	if not gridX then return end -- Seguridad
	
	local targetPosX = platform.Position.X + (gridX * CHUNK_SIZE)
	local targetPosZ = platform.Position.Z + (gridZ * CHUNK_SIZE)
	
	local startPos = Vector3.new(targetPosX, SPAWN_HEIGHT, targetPosZ)
	local targetY = columnHeights[gridX][gridZ] + (BLOCK_THICKNESS / 2)
	local endPos = Vector3.new(targetPosX, targetY, targetPosZ)
	
	local alpha = math.clamp(_G.DuracionRondaActual / ROUND_MAX_TIME, 0, 1)
	local currentFallSpeed = FALL_SPEED_START + (alpha * (FALL_SPEED_MAX - FALL_SPEED_START))
	local duration = (SPAWN_HEIGHT - targetY) / currentFallSpeed

	-- 1. INDICADOR
	local indicator = Instance.new("Part")
	indicator.Name = "LandingIndicator"
	indicator.Size = Vector3.new(CHUNK_SIZE - 2, 0.2, CHUNK_SIZE - 2)
	local floorY = targetY - (BLOCK_THICKNESS / 2)
	indicator.CFrame = CFrame.new(targetPosX, floorY + 0.1, targetPosZ)
	indicator.Anchored = true; indicator.CanCollide = false; indicator.CanQuery = false
	indicator.Material = Enum.Material.Neon; indicator.Color = Color3.fromRGB(0, 255, 100); indicator.Transparency = 1 
	indicator.Parent = workspace

	SoundManager.Play("BlockBlink", indicator)
	local blinkTween = TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true), {Transparency = 0.2})
	blinkTween:Play()

	task.delay(duration, function() if indicator then indicator:Destroy() end end)

	-- 2. BLOQUE REAL
	local block = Instance.new("Part")
	block.Name = "SkyfallBlock"
	block.Size = Vector3.new(CHUNK_SIZE, BLOCK_THICKNESS, CHUNK_SIZE)
	block.CFrame = CFrame.new(startPos)
	block.Anchored = true; block.CanCollide = false 
	block.Material = Enum.Material.SmoothPlastic
	block.Color = Color3.fromHSV(math.random(), math.random(70, 100)/100, 1)
	
	local targetTransparency = 0 
	
	-- EVENTO HIELO
	if _G.CurrentMapEvent == "SlipperyBlocks" then
		block.Material = Enum.Material.Glass 
		block.Color = Color3.fromRGB(0, 230, 255) 
		targetTransparency = 0.15 
		block.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.01, 0, 100, 1)
	end
	
	block.Transparency = 1 
	block.Parent = workspace
	
	TweenService:Create(block, TweenInfo.new(FADE_TIME), {Transparency = targetTransparency}):Play()
	columnHeights[gridX][gridZ] = targetY + (BLOCK_THICKNESS / 2)
	
	local tween = TweenService:Create(block, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endPos)})
	
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
	
	tween.Completed:Connect(function()
		if damageConn then damageConn:Disconnect() end
		block.CanCollide = true 
		block.CFrame = CFrame.new(endPos)
		
		if _G.CurrentMapEvent == "SlipperyBlocks" then
			SoundManager.Play("IceBlockImpact" .. math.random(1, 2), block)
		else
			SoundManager.Play("BlockImpact", block)
		end
		
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