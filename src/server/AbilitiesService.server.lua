local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- 1. REFERENCIAS A EVENTOS
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local roundStartEvent = ReplicatedStorage:WaitForChild("RoundStartEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda") -- REFERENCIA AL ESTADO

local cooldownEvent = ReplicatedStorage:FindFirstChild("CooldownEvent")
if not cooldownEvent then
	cooldownEvent = Instance.new("RemoteEvent")
	cooldownEvent.Name = "CooldownEvent"
	cooldownEvent.Parent = ReplicatedStorage
end

-- 2. CONFIGURACIÓN
local PUSH_COOLDOWN = 30
local DASH_COOLDOWN = 45
local PUSH_POWER = 120
local MAX_PUSH_DIST = 10
local DASH_FORCE = 120 
local DASH_DURATION = 0.2 

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

-- FUNCIÓN DE SEGURIDAD: ¿ESTAMOS EN JUEGO?
local function canUseAbility()
	local rawState = estadoValue.Value
	local state = string.split(rawState, "|")[1]
	return state == "SURVIVE"
end

local function isOnCooldown(player, abilityName, duration)
	-- CHECK DE FASE DE JUEGO
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
	print("🔄 Ronda iniciada: Reseteando habilidades.")
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
		task.delay(3, function() if sound then sound:Destroy() end end)
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
	if isOnCooldown(player, "Dash", DASH_COOLDOWN) then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char.Humanoid.Health <= 0 then return end

	playAbilitySound(hrp, "DashSound", 0.6)

	local wind = Instance.new("ParticleEmitter")
	wind.Acceleration = hrp.CFrame.LookVector * -50
	wind.Lifetime = NumberRange.new(0.1, 0.3)
	wind.Rate = 100
	wind.Speed = NumberRange.new(20, 40)
	wind.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	wind.Parent = hrp
	
	local a0 = Instance.new("Attachment", hrp)
	local a1 = Instance.new("Attachment", hrp)
	a0.Position, a1.Position = Vector3.new(0,1,0), Vector3.new(0,-1,0)
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.4
	trail.Parent = hrp

	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce, lv.Attachment0 = 999999, att
	lv.VectorVelocity = hrp.CFrame.LookVector * DASH_FORCE

	task.wait(DASH_DURATION)
	lv:Destroy(); att:Destroy(); wind.Enabled = false
	task.delay(0.5, function() trail:Destroy(); a0:Destroy(); a1:Destroy(); wind:Destroy() end)
end)

-------------------------------------------------------------------
-- LÓGICA DEL PUSH
-------------------------------------------------------------------
pushEvent.OnServerEvent:Connect(function(player)
	if isOnCooldown(player, "Push", PUSH_COOLDOWN) then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or char.Humanoid.Health <= 0 then return end

	playAbilitySound(root, "PushSound", 0.7)
	animateArms(char)

	local targetChar, closestDist = nil, MAX_PUSH_DIST
	for _, other in pairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local oRoot = other.Character.HumanoidRootPart
			local vec = oRoot.Position - root.Position
			local dot = root.CFrame.LookVector:Dot(vec.Unit)
			if vec.Magnitude < closestDist and dot > 0.5 then
				targetChar, closestDist = other.Character, vec.Magnitude
			end
		end
	end

	if targetChar then
		local tRoot = targetChar.HumanoidRootPart
		local tag = targetChar:FindFirstChild("LastAttacker") or Instance.new("ObjectValue", targetChar)
		tag.Name = "LastAttacker"; tag.Value = player
		
		local att = Instance.new("Attachment", tRoot)
		local vel = Instance.new("LinearVelocity", att)
		vel.MaxForce, vel.Attachment0 = 250000, att
		vel.VectorVelocity = ((tRoot.Position - root.Position).Unit + Vector3.new(0, 0.5, 0)).Unit * PUSH_POWER
		task.delay(0.25, function() vel:Destroy(); att:Destroy() end)
	end
end)