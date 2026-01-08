local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- 1. REFERENCIAS A EVENTOS
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local bonkEvent = ReplicatedStorage:WaitForChild("BonkEvent")
local roundStartEvent = ReplicatedStorage:WaitForChild("RoundStartEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

local cooldownEvent = ReplicatedStorage:FindFirstChild("CooldownEvent")
if not cooldownEvent then
	cooldownEvent = Instance.new("RemoteEvent")
	cooldownEvent.Name = "CooldownEvent"
	cooldownEvent.Parent = ReplicatedStorage
end

local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- MANAGERS (Delegación correcta de responsabilidades)
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager")) 

-- ASSETS
local batTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Bat")

-- CONSTANTES BONK
local ANIM_SWING_ID = "rbxassetid://101758597360192"
local ANIM_STUN_ID = "rbxassetid://119114608212049"

local SELF_LOCK_TIME = 0.6 
local BAT_GRIP_OFFSET = CFrame.new(0, -0.2, -1.7) * CFrame.Angles(math.rad(-93), 0, math.rad(0))

local cooldowns = {}

-- HELPERS
local function canUseAbility()
	local rawState = estadoValue.Value
	local state = string.split(rawState, "|")[1]
	return state == "SURVIVE"
end

local function isOnCooldown(player, abilityName, duration)
	if not canUseAbility() then return true end
	
	-- VALIDACIÓN STUN: Si tiene el atributo, no puede usar skills
	if player:GetAttribute("IsStunned") == true then return true end
	
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

local function createStunEffect(character, duration)
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	-- Carga desde DecalManager
	local ID_STAR = DecalManager.Get("BonkStun")
	local ID_SMOKE = DecalManager.Get("BonkHit") 

	local stars = Instance.new("ParticleEmitter")
	stars.Texture = ID_STAR
	stars.Size = NumberSequence.new(0.5, 0)
	stars.Rate = 5
	stars.Speed = NumberRange.new(0)
	stars.SpreadAngle = Vector2.new(360, 360)
	stars.Rotation = NumberRange.new(0, 360)
	stars.RotSpeed = NumberRange.new(100, 200)
	stars.Lifetime = NumberRange.new(1)
	stars.Parent = head
	
	SoundManager.Play("BatHit", head)
	
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = ID_SMOKE
	smoke.Size = NumberSequence.new(2, 4)
	smoke.Rate = 50 
	smoke.Lifetime = NumberRange.new(0.5)
	smoke.Speed = NumberRange.new(5)
	smoke.Parent = head
	task.delay(0.2, function() smoke.Enabled = false end)
	
	Debris:AddItem(stars, duration) 
	Debris:AddItem(smoke, 2)
end

-------------------------------------------------------------------
-- LÓGICA DEL DASH
-------------------------------------------------------------------
dashEvent.OnServerEvent:Connect(function(player)
	local cd = player:GetAttribute("DashCooldown") or 8
	if isOnCooldown(player, "Dash", cd) then return end

	local force = player:GetAttribute("DashDistance") or 50
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char.Humanoid.Health <= 0 then return end

	-- Usamos SoundManager (Asegúrate que "Dash" exista en tu SoundManager, o usa la key correcta)
	SoundManager.Play("Dash", hrp)

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
	
	local dashColor = player:GetAttribute("DashColor")
	if typeof(dashColor) == "Color3" then
		trail.Color = ColorSequence.new(dashColor)
	else
		trail.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255))
	end

	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.4
	trail.Parent = hrp

	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce, lv.Attachment0 = 999999, att
	lv.VectorVelocity = hrp.CFrame.LookVector * force

	task.wait(0.2)
	lv:Destroy(); att:Destroy(); wind.Enabled = false
	Debris:AddItem(trail, 0.5); Debris:AddItem(wind, 0.5)
	Debris:AddItem(a0, 0.5); Debris:AddItem(a1, 0.5)
end)

-------------------------------------------------------------------
-- LÓGICA DEL PUSH
-------------------------------------------------------------------
pushEvent.OnServerEvent:Connect(function(player)
	local cd = player:GetAttribute("PushCooldown") or 10
	if isOnCooldown(player, "Push", cd) then return end

	local pushPower = player:GetAttribute("PushDistance") or 50 
	local rangeSize = player:GetAttribute("PushRange") or 10    
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or char.Humanoid.Health <= 0 then return end

	SoundManager.Play("Push", root)
	animateArms(char)

	local boxSize = Vector3.new(10, 8, rangeSize) 
	local boxCFrame = root.CFrame * CFrame.new(0, 0, -rangeSize / 2)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {char}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local partsInBox = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
	local hitCharacters = {}

	for _, part in ipairs(partsInBox) do
		local enemyChar = part.Parent
		local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
		local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
		
		if enemyRoot and enemyHum and enemyHum.Health > 0 and not hitCharacters[enemyChar] then
			hitCharacters[enemyChar] = true 
			local tag = enemyChar:FindFirstChild("LastAttacker") or Instance.new("ObjectValue", enemyChar)
			tag.Name = "LastAttacker"; tag.Value = player
			Debris:AddItem(tag, 10) 

			local att = Instance.new("Attachment", enemyRoot)
			local vel = Instance.new("LinearVelocity", att)
			vel.MaxForce = 500000 
			vel.Attachment0 = att
			local pushDir = (enemyRoot.Position - root.Position).Unit 
			pushDir = Vector3.new(pushDir.X, 0.3, pushDir.Z).Unit 
			vel.VectorVelocity = pushDir * pushPower
			Debris:AddItem(att, 0.25) 
			Debris:AddItem(vel, 0.25)
		end
	end
end)

-------------------------------------------------------------------
-- LÓGICA DEL BONK (Bate)
-------------------------------------------------------------------
bonkEvent.OnServerEvent:Connect(function(player)
	local cdLevel = player:GetAttribute("BonkCooldown") or 8
	local stunTime = player:GetAttribute("BonkStun") or 2
	
	if isOnCooldown(player, "Bonk", cdLevel) then return end
	
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	local rightHand = char and char:FindFirstChild("RightHand") 
	
	if not root or not hum or hum.Health <= 0 or not rightHand then return end
	
	-- AUTO-LOCK DEL ATACANTE (Sin Anchor)
	-- Aplicamos el atributo para que el cliente bloquee inputs
	player:SetAttribute("IsStunned", true)
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	
	-- SPAWN BATE
	local bat = batTemplate:Clone()
	bat.CanCollide = false; bat.Massless = true
	local batColor = player:GetAttribute("BonkColor")
	
	if typeof(batColor) == "Color3" then
		for _, p in pairs(bat:GetDescendants()) do if p:IsA("BasePart") then p.Color = batColor end end
		if bat:IsA("BasePart") then bat.Color = batColor end
	end
	
	bat.Parent = char
	local weld = Instance.new("Weld")
	weld.Part0 = rightHand; weld.Part1 = bat; weld.C0 = BAT_GRIP_OFFSET; weld.Parent = bat
	Debris:AddItem(bat, 1.5) 
	
	SoundManager.Play("BatSwing", root)
	
	local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
	local swingAnim = Instance.new("Animation"); swingAnim.AnimationId = ANIM_SWING_ID
	local swingTrack = animator:LoadAnimation(swingAnim)
	swingTrack.Priority = Enum.AnimationPriority.Action; swingTrack:Play()
	
	-- LIBERAR ATACANTE
	task.delay(SELF_LOCK_TIME, function()
		if player and hum then
			player:SetAttribute("IsStunned", nil)
			hum.WalkSpeed = 16 
			hum.JumpPower = 50
		end
	end)
	
	-- HITBOX
	task.delay(0.3, function() 
		if not char or not bat then return end
		local hitSize = Vector3.new(6, 6, 8)
		local hitCFrame = root.CFrame * CFrame.new(0, 0, -4) 
		local params = OverlapParams.new()
		params.FilterDescendantsInstances = {char}
		params.FilterType = Enum.RaycastFilterType.Exclude
		local hits = workspace:GetPartBoundsInBox(hitCFrame, hitSize, params)
		local hitHumanoids = {}
		
		for _, part in ipairs(hits) do
			local enemyChar = part.Parent
			local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
			local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
			local enemyPlayer = Players:GetPlayerFromCharacter(enemyChar)
			
			if enemyHum and enemyHum.Health > 0 and not hitHumanoids[enemyHum] then
				hitHumanoids[enemyHum] = true
				
				createStunEffect(enemyChar, stunTime)
				local tag = enemyChar:FindFirstChild("LastAttacker") or Instance.new("ObjectValue", enemyChar)
				tag.Name = "LastAttacker"; tag.Value = player
				Debris:AddItem(tag, 10)
				
				-- STUN VÍCTIMA (Atributo + Speed 0)
				if enemyPlayer then enemyPlayer:SetAttribute("IsStunned", true) end
				enemyChar:SetAttribute("IsStunned", true)
				
				enemyHum.WalkSpeed = 0
				enemyHum.JumpPower = 0
				
				local stunAnim = Instance.new("Animation"); stunAnim.AnimationId = ANIM_STUN_ID
				local stunTrack = enemyHum.Animator:LoadAnimation(stunAnim)
				stunTrack.Looped = true
				stunTrack.Priority = Enum.AnimationPriority.Action4; stunTrack:Play()
				
				-- KNOCKBACK
				local att = Instance.new("Attachment", enemyRoot)
				local lv = Instance.new("LinearVelocity", att)
				lv.MaxForce = 500000
				lv.VectorVelocity = (enemyRoot.Position - root.Position).Unit * 20 + Vector3.new(0, 10, 0)
				lv.Attachment0 = att
				Debris:AddItem(lv, 0.2); Debris:AddItem(att, 0.2)
				
				-- RESTAURAR VÍCTIMA
				task.delay(stunTime, function()
					if enemyChar and enemyHum and enemyHum.Health > 0 then
						if enemyPlayer then enemyPlayer:SetAttribute("IsStunned", nil) end
						enemyChar:SetAttribute("IsStunned", nil)
						
						enemyHum.WalkSpeed = 16 
						enemyHum.JumpPower = 50
						stunTrack:Stop()
					end
				end)
			end
		end
	end)
end)