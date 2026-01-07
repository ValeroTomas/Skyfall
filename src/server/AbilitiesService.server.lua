local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- 1. REFERENCIAS A EVENTOS
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local roundStartEvent = ReplicatedStorage:WaitForChild("RoundStartEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

local cooldownEvent = ReplicatedStorage:FindFirstChild("CooldownEvent")
if not cooldownEvent then
	cooldownEvent = Instance.new("RemoteEvent")
	cooldownEvent.Name = "CooldownEvent"
	cooldownEvent.Parent = ReplicatedStorage
end

-- SONIDOS
local SoundFolder = Instance.new("Folder", ReplicatedStorage)
SoundFolder.Name = "AbilitySounds"
local function preload(id, name)
	local s = Instance.new("Sound")
	s.Name = name; s.SoundId = id; s.Volume = 0; s.Parent = SoundFolder
	s:Play(); s:Stop() 
end
preload("rbxassetid://12222124", "PushSound")
preload("rbxassetid://9117879142", "DashSound")

local cooldowns = {}

-- FUNCIÓN DE SEGURIDAD
local function canUseAbility()
	local rawState = estadoValue.Value
	local state = string.split(rawState, "|")[1]
	return state == "SURVIVE"
end

local function isOnCooldown(player, abilityName, duration)
	if not canUseAbility() then return true end
	
	if not cooldowns[player] then cooldowns[player] = {} end
	local nextUse = cooldowns[player][abilityName] or 0
	local now = os.time()
	
	if now >= nextUse then
		cooldowns[player][abilityName] = now + duration
		cooldownEvent:FireClient(player, abilityName, duration)
		return false
	end
	return true
end

Players.PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		cooldowns[player] = {} 
		cooldownEvent:FireClient(player, "RESET_ALL", 0)
	end)
end)

roundStartEvent.Event:Connect(function()
	cooldowns = {} 
	cooldownEvent:FireAllClients("RESET_ALL", 0)
end)

local function playAbilitySound(parent, soundName, volume)
	local template = SoundFolder:FindFirstChild(soundName)
	if template then
		local sound = template:Clone()
		sound.Volume = volume or 0.6
		sound.Parent = parent
		sound:Play()
		Debris:AddItem(sound, 3)
	end
end

local function animateArms(character)
	local lS = character:FindFirstChild("LeftUpperArm") and character.LeftUpperArm:FindFirstChild("LeftShoulder")
	local rS = character:FindFirstChild("RightUpperArm") and character.RightUpperArm:FindFirstChild("RightShoulder")
	if lS and rS then
		local oldL, oldR = lS.C0, rS.C0
		local targetL = oldL * CFrame.Angles(math.rad(90), 0, math.rad(-15))
		local targetR = oldR * CFrame.Angles(math.rad(90), 0, math.rad(15))
		local info = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(lS, info, {C0 = targetL}):Play()
		TweenService:Create(rS, info, {C0 = targetR}):Play()
		task.delay(0.4, function()
			local ret = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(lS, ret, {C0 = oldL}):Play()
			TweenService:Create(rS, ret, {C0 = oldR}):Play()
		end)
	end
end

-------------------------------------------------------------------
-- LÓGICA DEL DASH
-------------------------------------------------------------------
dashEvent.OnServerEvent:Connect(function(player)
	-- LEER ATRIBUTOS DEL JUGADOR (MEJORAS)
	local cd = player:GetAttribute("DashCooldown") or 8
	if isOnCooldown(player, "Dash", cd) then return end

	local force = player:GetAttribute("DashDistance") or 50 -- Ahora es Fuerza de Dash
	-- DashSpeed lo usamos como duración o multiplicador extra si quieres
	
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char.Humanoid.Health <= 0 then return end

	playAbilitySound(hrp, "DashSound", 0.6)

	-- Efectos Visuales
	local wind = Instance.new("ParticleEmitter")
	wind.Acceleration = hrp.CFrame.LookVector * -50
	wind.Lifetime = NumberRange.new(0.1, 0.3)
	wind.Rate = 100
	wind.Speed = NumberRange.new(20, 40)
	wind.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	wind.Parent = hrp
	
	local a0, a1 = Instance.new("Attachment", hrp), Instance.new("Attachment", hrp)
	a0.Position, a1.Position = Vector3.new(0,1,0), Vector3.new(0,-1,0)
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	
	-- COLOR PERSONALIZADO (Si existe el atributo DashColor como Color3)
	local dashColor = player:GetAttribute("DashColor")
	if typeof(dashColor) == "Color3" then
		trail.Color = ColorSequence.new(dashColor)
	else
		trail.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
	end

	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.4
	trail.Parent = hrp

	-- Física
	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce, lv.Attachment0 = 999999, att
	lv.VectorVelocity = hrp.CFrame.LookVector * force

	task.wait(0.2) -- Duración fija corta para dash instantáneo
	lv:Destroy(); att:Destroy(); wind.Enabled = false
	Debris:AddItem(trail, 0.5); Debris:AddItem(wind, 0.5)
	Debris:AddItem(a0, 0.5); Debris:AddItem(a1, 0.5)
end)

-------------------------------------------------------------------
-- LÓGICA DEL PUSH (HITBOX ACTUALIZADA)
-------------------------------------------------------------------
pushEvent.OnServerEvent:Connect(function(player)
	-- LEER ATRIBUTOS
	local cd = player:GetAttribute("PushCooldown") or 10
	if isOnCooldown(player, "Push", cd) then return end

	local pushPower = player:GetAttribute("PushDistance") or 50  -- Fuerza
	local rangeSize = player:GetAttribute("PushRange") or 10     -- Tamaño Hitbox

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or char.Humanoid.Health <= 0 then return end

	playAbilitySound(root, "PushSound", 0.7)
	animateArms(char)

	-------------------------------------------------------------------
	-- NUEVA LÓGICA: HITBOX ESPACIAL (Caja enfrente del jugador)
	-------------------------------------------------------------------
	-- Definimos la caja: Ancho y Alto fijos, Largo depende del Rango
	local boxSize = Vector3.new(10, 8, rangeSize) 
	
	-- Posicionamos la caja DELANTE del jugador (Mitad del rango hacia adelante)
	local boxCFrame = root.CFrame * CFrame.new(0, 0, -rangeSize / 2)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {char} -- Ignorarnos a nosotros mismos
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local partsInBox = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
	local hitCharacters = {} -- Para no empujar 2 veces al mismo personaje si tocamos 2 partes

	for _, part in ipairs(partsInBox) do
		local enemyChar = part.Parent
		local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
		local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
		
		-- Verificamos que sea un personaje vivo y no lo hayamos empujado ya
		if enemyRoot and enemyHum and enemyHum.Health > 0 and not hitCharacters[enemyChar] then
			hitCharacters[enemyChar] = true -- Marcar como golpeado
			
			-- Taggear para Killfeed
			local tag = enemyChar:FindFirstChild("LastAttacker") or Instance.new("ObjectValue", enemyChar)
			tag.Name = "LastAttacker"; tag.Value = player
			Debris:AddItem(tag, 10) -- El tag dura 10 segundos

			-- APLICAR FUERZA FÍSICA
			local att = Instance.new("Attachment", enemyRoot)
			local vel = Instance.new("LinearVelocity", att)
			vel.MaxForce = 500000 -- Fuerza suficiente para moverlo
			vel.Attachment0 = att
			
			-- Dirección: Desde nosotros hacia ellos + un poco hacia arriba
			local pushDir = (enemyRoot.Position - root.Position).Unit 
			pushDir = Vector3.new(pushDir.X, 0.3, pushDir.Z).Unit -- 0.3 hacia arriba para levantarlos del suelo

			vel.VectorVelocity = pushDir * pushPower
			
			Debris:AddItem(att, 0.25) -- Empujón dura 0.25s
			Debris:AddItem(vel, 0.25)
		end
	end
	
	-- DEBUG VISUAL (Opcional: Si quieres ver la hitbox, descomenta esto)
	-- local viz = Instance.new("Part", workspace)
	-- viz.Anchored = true; viz.CanCollide = false; viz.Transparency = 0.8; viz.Color = Color3.new(1,0,0)
	-- viz.Size = boxSize; viz.CFrame = boxCFrame
	-- Debris:AddItem(viz, 0.5)
end)