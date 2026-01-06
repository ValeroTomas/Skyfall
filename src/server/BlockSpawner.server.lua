local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTAR SOUNDMANAGER
local SoundManager = require(ReplicatedStorage.shared.SoundManager)

-- CONFIGURACIÓN BASE
local CHUNK_SIZE = 50
local SPAWN_HEIGHT = 250
local BLOCK_THICKNESS = 10

-- CONFIGURACIÓN NUEVA (Screen Shake)
local ENABLE_SHAKE = true -- <--- Aquí está tu interruptor para el futuro Settings

-- EVENTO DE SHAKE (Comunicación Server -> Client)
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
    block.BrickColor = BrickColor.random()
    block.Material = Enum.Material.Concrete
    block.Parent = workspace
    
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
    tween.Completed:Connect(function()
        if damageConn then damageConn:Disconnect() end
        block.CanCollide = true 
        block.CFrame = CFrame.new(endPos)
        
        -- SONIDO
        SoundManager.Play("BlockImpact", block)
        
        -- SCREEN SHAKE (NUEVO)
        if ENABLE_SHAKE then
            -- Enviamos la posición del impacto para calcular distancia
            shakeEvent:FireAllClients(endPos) 
        end
    end)
end

task.spawn(function()
    while true do
        if _G.LluviaActiva then spawnBlock() end
        local alpha = math.clamp(_G.DuracionRondaActual / ROUND_MAX_TIME, 0, 1)
        task.wait(SPAWN_RATE_START - (alpha * (SPAWN_RATE_START - SPAWN_RATE_MIN)))
    end
end)