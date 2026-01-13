local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local PlayerManager = require(script.Parent:WaitForChild("PlayerManager"))

-- REFERENCIAS AL MAPA
local mapFolder = workspace:WaitForChild("Map")
local platform = mapFolder:WaitForChild("Platform")
local lava = mapFolder:WaitForChild("Lava")

-- EVENTOS
local function getEvent(name, className)
	className = className or "BindableEvent"
	if ReplicatedStorage:FindFirstChild(name) then return ReplicatedStorage[name] end
	local ev = Instance.new(className)
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

local mapEventStart = getEvent("MapEventStart")
local mapEventStop = getEvent("MapEventStop")
local forcePassEvent = getEvent("ForcePotatoPass")
local killfeedEvent = getEvent("KillfeedEvent", "RemoteEvent")

-- CONFIGURACIÓN
local MAGMA_SIZE = 7 
local POTATO_DURATION = 15
local POTATO_COOLDOWN = 2 

-- ESTADO
local currentEvent = nil
local isEventRunning = false
local potatoTarget = nil
local potatoPassTime = 0
local potatoVisual = nil
local potatoHighlight = nil 

--------------------------------------------------------------------------------
-- 1. LLUVIA DE MAGMA
--------------------------------------------------------------------------------

local function applyMagmaKnockback(centerPosition, radius, pushForce)
	local region = Region3.new(centerPosition - Vector3.new(radius, radius, radius), centerPosition + Vector3.new(radius, radius, radius))
	local parts = workspace:FindPartsInRegion3(region, nil, math.huge)
	local affectedHumanoids = {}

	for _, part in ipairs(parts) do
		local char = part.Parent
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		
		if hum and root and hum.Health > 0 and not affectedHumanoids[hum] then
			affectedHumanoids[hum] = true
			
			local direction = (root.Position - centerPosition).Unit
			direction = Vector3.new(direction.X, 0.6, direction.Z).Unit 
			
			local att = Instance.new("Attachment", root)
			local lv = Instance.new("LinearVelocity", att)
			lv.MaxForce = 999999
			lv.VectorVelocity = direction * pushForce
			lv.Attachment0 = att
			
			hum.PlatformStand = true 
			
			Debris:AddItem(lv, 0.4) 
			Debris:AddItem(att, 0.4)
			
			task.delay(0.5, function() if hum then hum.PlatformStand = false end end)
		end
	end
end

local function spawnMagmaBall()
	if not isEventRunning then return end
	
	-- Puntería inteligente (50% probabilidad)
	local targetPos
	local alivePlayers = PlayerManager.GetAlivePlayers()
	
	if #alivePlayers > 0 and math.random() < 0.5 then
		local victim = alivePlayers[math.random(1, #alivePlayers)]
		local root
		if victim:IsA("Player") and victim.Character then
			root = victim.Character:FindFirstChild("HumanoidRootPart")
		elseif victim:IsA("Model") then
			root = victim:FindFirstChild("HumanoidRootPart")
		end
		
		if root then
			targetPos = root.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
			targetPos = Vector3.new(targetPos.X, platform.Position.Y + 2, targetPos.Z)
		else
			targetPos = Vector3.new(math.random(-65, 65), platform.Position.Y + 2, math.random(-65, 65))
		end
	else
		targetPos = Vector3.new(math.random(-65, 65), platform.Position.Y + 2, math.random(-65, 65))
	end
	
	-- Origen
	local angle = math.rad(math.random(0, 360))
	local dist = 100
	local spawnPos = Vector3.new(math.sin(angle) * dist, lava.Position.Y + 15, math.cos(angle) * dist)
	
	local ball = Instance.new("Part")
	ball.Name = "MagmaBall"
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(255, 90, 0)
	ball.Size = Vector3.new(MAGMA_SIZE, MAGMA_SIZE, MAGMA_SIZE)
	ball.Position = spawnPos
	ball.CanCollide = false
	ball.RotVelocity = Vector3.new(math.random(-20,20), math.random(-20,20), math.random(-20,20))
	ball.Parent = workspace
	
	local spawnTime = tick()
	
	-- Efectos
	local fire = Instance.new("Fire", ball); fire.Size = 18; fire.Heat = 25
	local att0 = Instance.new("Attachment", ball); att0.Position = Vector3.new(0, MAGMA_SIZE/2, 0)
	local att1 = Instance.new("Attachment", ball); att1.Position = Vector3.new(0, -MAGMA_SIZE/2, 0)
	local trail = Instance.new("Trail", ball)
	trail.Attachment0 = att0; trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 0, 0))
	trail.Transparency = NumberSequence.new(0.2, 1); trail.Lifetime = 0.8
	
	-- Física
	local timeToHit = 3.2 
	local g = workspace.Gravity
	local vY = (targetPos.Y - spawnPos.Y + 0.5 * g * timeToHit^2) / timeToHit
	local vX = (targetPos.X - spawnPos.X) / timeToHit
	local vZ = (targetPos.Z - spawnPos.Z) / timeToHit
	
	ball.AssemblyLinearVelocity = Vector3.new(vX, vY, vZ)
	
	SoundManager.Play("MagmaSpawn1", ball)
	SoundManager.Play("MagmaSpawn2", ball)
	
	local touched = false
	ball.Touched:Connect(function(hit)
		if touched then return end
		if tick() - spawnTime < 0.8 then return end
		
		if hit.Name == "MagmaBall" or hit.Name == "Lava" or hit.Name == "LandingIndicator" then return end
		if hit.Transparency == 1 and hit.Name ~= "SkyfallBlock" then return end 
		
		touched = true
		
		-- Visuales Explosión
		local expVisual = Instance.new("Explosion")
		expVisual.Position = ball.Position
		expVisual.BlastRadius = 0 
		expVisual.BlastPressure = 0
		expVisual.Parent = workspace
		
		SoundManager.Play("BlockImpact", ball)
		
		-- Splash
		local splash = Instance.new("Part")
		splash.Transparency = 1; splash.Anchored = true; splash.CanCollide = false
		splash.Position = ball.Position; splash.Parent = workspace
		local p = Instance.new("ParticleEmitter", splash)
		p.Texture = "rbxassetid://242203604"; p.Color = ColorSequence.new(Color3.fromRGB(255, 80, 0))
		p.Size = NumberSequence.new(3, 0); p.Speed = NumberRange.new(30, 50); p.SpreadAngle = Vector2.new(180, 180)
		p.Drag = 5; p.Rate = 0; p:Emit(60)
		Debris:AddItem(splash, 2)
		
		-- [AUDIO FIX] Reproducir en el splash que persiste, no en la bola que muere
		SoundManager.Play("MagmaExplosion", splash)
		
		-- Knockback
		applyMagmaKnockback(ball.Position, 28, 80)
		
		ball:Destroy()
	end)
	
	Debris:AddItem(ball, 8)
end

local function startMagmaRain()
	task.spawn(function()
		while isEventRunning and currentEvent == "MagmaRain" do
			spawnMagmaBall()
			task.wait(2.5) -- [AJUSTE] Cadencia más lenta
		end
	end)
end

--------------------------------------------------------------------------------
-- 2. PATATA CALIENTE
--------------------------------------------------------------------------------
local function cleanPotatoVisuals()
	if potatoVisual then potatoVisual:Destroy(); potatoVisual = nil end
	if potatoHighlight then potatoHighlight:Destroy(); potatoHighlight = nil end
end

local function updatePotatoVisual(targetChar)
	cleanPotatoVisuals() 
	if not targetChar then return end
	
	if targetChar:FindFirstChild("Head") then
		local bb = Instance.new("BillboardGui")
		bb.Name = "PotatoGui"; bb.Adornee = targetChar.Head; bb.Size = UDim2.new(0, 100, 0, 100)
		bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true
		local img = Instance.new("ImageLabel", bb)
		img.Size = UDim2.new(1,0,1,0); img.BackgroundTransparency = 1
		img.Image = "rbxassetid://9986307689" 
		img.ImageColor3 = Color3.fromRGB(255, 50, 50)
		bb.Parent = targetChar.Head
		potatoVisual = bb
	end
	
	local hl = Instance.new("Highlight")
	hl.Name = "PotatoHighlight"
	hl.Adornee = targetChar
	hl.FillTransparency = 1 
	hl.OutlineColor = Color3.fromRGB(255, 0, 0)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = targetChar
	potatoHighlight = hl
end

local function performTransfer(newHolder)
	potatoTarget = newHolder
	potatoPassTime = tick()
	updatePotatoVisual(newHolder)
	SoundManager.Play("PotatoPass", newHolder:FindFirstChild("HumanoidRootPart"))
	print("🥔 Patata pasada a: " .. newHolder.Name)
end

local function passPotato(hit)
	if tick() - potatoPassTime < POTATO_COOLDOWN then return end
	local char = hit.Parent
	local hum = char and char:FindFirstChild("Humanoid")
	if hum and hum.Health > 0 and char ~= potatoTarget then
		if Players:GetPlayerFromCharacter(char) or CollectionService:HasTag(char, "Bot") then
			performTransfer(char)
		end
	end
end

local function explodePotato()
	if potatoTarget and potatoTarget.Parent then
		local hum = potatoTarget:FindFirstChild("Humanoid")
		local root = potatoTarget:FindFirstChild("HumanoidRootPart")
		if root then
			local exp = Instance.new("Explosion")
			exp.Position = root.Position; exp.BlastRadius = 10; exp.DestroyJointRadiusPercent = 1
			exp.Parent = workspace
			SoundManager.Play("PotatoExplode", root)
		end
		if potatoTarget then killfeedEvent:FireAllClients("DEATH_POTATO", potatoTarget.Name) end
		if hum then hum.Health = 0 end
	end
	potatoTarget = nil
	cleanPotatoVisuals()
end

local function startHotPotato()
	task.spawn(function()
		while isEventRunning and currentEvent == "HotPotato" do
			local alive = PlayerManager.GetAlivePlayers()
			if #alive < 1 then break end 
			local victim = alive[math.random(1, #alive)]
			if victim:IsA("Player") then potatoTarget = victim.Character else potatoTarget = victim end
			if not potatoTarget then break end
			
			updatePotatoVisual(potatoTarget)
			potatoPassTime = tick() 
			
			local timeLeft = POTATO_DURATION
			local lastBeepTime = 0
			while timeLeft > 0 and isEventRunning and currentEvent == "HotPotato" do
				local beepInterval = math.max(0.15, timeLeft / 15)
				if tick() - lastBeepTime >= beepInterval then
					if potatoTarget and potatoTarget:FindFirstChild("Head") then
						SoundManager.Play("PotatoBeep", potatoTarget.Head)
					end
					lastBeepTime = tick()
				end
				
				if potatoTarget and potatoTarget:FindFirstChild("HumanoidRootPart") then
					local hrp = potatoTarget.HumanoidRootPart
					local detectionSize = Vector3.new(5, 6, 5) 
					local params = OverlapParams.new()
					params.FilterDescendantsInstances = {potatoTarget}
					params.FilterType = Enum.RaycastFilterType.Exclude
					local parts = workspace:GetPartBoundsInBox(hrp.CFrame, detectionSize, params)
					for _, part in ipairs(parts) do 
						passPotato(part)
						if potatoTarget ~= hrp.Parent then break end
					end
				else break end
				task.wait(0.1)
				timeLeft = timeLeft - 0.1
			end
			if timeLeft <= 0 and isEventRunning and currentEvent == "HotPotato" then
				explodePotato()
				task.wait(2) 
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- GESTOR
--------------------------------------------------------------------------------
mapEventStart.Event:Connect(function(eventName)
	if isEventRunning then return end
	print("⚠️ EVENTO: " .. eventName)
	isEventRunning = true
	currentEvent = eventName
	_G.CurrentMapEvent = eventName
	if eventName == "MagmaRain" then startMagmaRain()
	elseif eventName == "HotPotato" then startHotPotato()
	end
end)

mapEventStop.Event:Connect(function()
	isEventRunning = false
	currentEvent = nil
	_G.CurrentMapEvent = nil
	cleanPotatoVisuals()
	potatoTarget = nil
end)

forcePassEvent.Event:Connect(function(attackerChar, victimChar)
	if not isEventRunning or currentEvent ~= "HotPotato" then return end
	if not potatoTarget or not attackerChar or not victimChar then return end
	if tick() - potatoPassTime < POTATO_COOLDOWN then return end
	if potatoTarget == attackerChar then
		local hum = victimChar:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then performTransfer(victimChar) end
	end
end)