local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- EVENTOS
local dashEvent = ReplicatedStorage:WaitForChild("DashEvent")
local pushEvent = ReplicatedStorage:WaitForChild("PushEvent")
local bonkEvent = ReplicatedStorage:WaitForChild("BonkEvent")
local roundStartEvent = ReplicatedStorage:WaitForChild("RoundStartEvent")
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- [NUEVO] Conexión con Patata Caliente
local forcePotatoPass = ReplicatedStorage:FindFirstChild("ForcePotatoPass") -- Se crea en MapEventManager

local cooldownEvent = ReplicatedStorage:FindFirstChild("CooldownEvent")
if not cooldownEvent then
	cooldownEvent = Instance.new("RemoteEvent")
	cooldownEvent.Name = "CooldownEvent"
	cooldownEvent.Parent = ReplicatedStorage
end

local botBridge = ReplicatedStorage:FindFirstChild("BotAbilityBridge")
if not botBridge then
	botBridge = Instance.new("BindableEvent")
	botBridge.Name = "BotAbilityBridge"
	botBridge.Parent = ReplicatedStorage
end

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager")) 

local batTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Bat")

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

local function applyStun(playerOrBot, duration)
	if not playerOrBot then return end
	local now = workspace:GetServerTimeNow()
	local currentEnd = playerOrBot:GetAttribute("StunnedUntil") or 0
	if (now + duration) > currentEnd then
		playerOrBot:SetAttribute("StunnedUntil", now + duration)
	end
end

local function isStunned(playerOrBot)
	local untilTime = playerOrBot:GetAttribute("StunnedUntil") or 0
	return workspace:GetServerTimeNow() < untilTime
end

local function isOnCooldown(playerOrBot, abilityName, duration)
	if not canUseAbility() then return true end
	if isStunned(playerOrBot) then return true end
	
	if not cooldowns[playerOrBot] then cooldowns[playerOrBot] = {} end
	local nextUse = cooldowns[playerOrBot][abilityName] or 0
	local now = os.time()
	
	if now >= nextUse then
		cooldowns[playerOrBot][abilityName] = now + duration
		if playerOrBot:IsA("Player") then
			cooldownEvent:FireClient(playerOrBot, abilityName, duration)
		end
		return false
	end
	return true
end

Players.PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		cooldowns[player] = {} 
		cooldownEvent:FireClient(player, "RESET_ALL", 0)
		player:SetAttribute("StunnedUntil", 0) 
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
	local ID_STAR = DecalManager.Get("BonkStun")
	local ID_SMOKE = "rbxassetid://243662261" 

	local stars = Instance.new("ParticleEmitter")
	stars.Texture = ID_STAR; stars.Size = NumberSequence.new(0.8, 0); stars.Rate = 5
	stars.Lifetime = NumberRange.new(duration); stars.Parent = head
	SoundManager.Play("BatHit", head)
	
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "HitSmoke"; smoke.Texture = ID_SMOKE; smoke.Size = NumberSequence.new(2, 5)
	smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	smoke.Lifetime = NumberRange.new(0.4, 0.6); smoke.Rate = 0; smoke.Enabled = false; smoke.Parent = head
	smoke:Emit(30)
	Debris:AddItem(stars, duration); Debris:AddItem(smoke, 1.5) 
end

-------------------------------------------------------------------
-- HABILIDADES
-------------------------------------------------------------------

local function DoDash(playerOrBot, character)
	local cd = playerOrBot:GetAttribute("DashCooldown") or 8
	if isOnCooldown(playerOrBot, "Dash", cd) then return end

	local force = playerOrBot:GetAttribute("DashDistance") or 50
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or character.Humanoid.Health <= 0 then return end

	SoundManager.Play("Dash", hrp)
	local dashColor = playerOrBot:GetAttribute("DashColor") or Color3.fromRGB(0, 150, 255)
	
	local a0 = Instance.new("Attachment", hrp); a0.Position = Vector3.new(0, 2, 0)
	local a1 = Instance.new("Attachment", hrp); a1.Position = Vector3.new(0, -2, 0)
	local dashTrail = Instance.new("Trail")
	dashTrail.Name = "DashTrail"; dashTrail.Attachment0 = a0; dashTrail.Attachment1 = a1
	dashTrail.Color = ColorSequence.new(dashColor); dashTrail.Transparency = NumberSequence.new(0.2, 0.8)
	dashTrail.Lifetime = 0.3; dashTrail.FaceCamera = true; dashTrail.LightEmission = 0.8; dashTrail.Enabled = true; dashTrail.Parent = hrp

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://243662261"; particles.Color = ColorSequence.new(dashColor)
	particles.Size = NumberSequence.new(1, 3); particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	particles.Lifetime = NumberRange.new(0.2, 0.4); particles.Rate = 50; particles.Speed = NumberRange.new(5, 15)
	particles.Acceleration = Vector3.new(0, -10, 0); particles.Parent = hrp; particles:Emit(20)

	task.delay(1, function() if dashTrail then dashTrail:Destroy() end; if a0 then a0:Destroy() end; if a1 then a1:Destroy() end; if particles then particles:Destroy() end end)

	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce, lv.Attachment0 = 999999, att
	lv.VectorVelocity = hrp.CFrame.LookVector * force
	task.wait(0.2)
	lv:Destroy(); att:Destroy()
end

local function DoPush(playerOrBot, character)
	local cd = playerOrBot:GetAttribute("PushCooldown") or 10
	if isOnCooldown(playerOrBot, "Push", cd) then return end

	local pushPower = playerOrBot:GetAttribute("PushDistance") or 50 
	local rangeSize = playerOrBot:GetAttribute("PushRange") or 10    
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or character.Humanoid.Health <= 0 then return end

	SoundManager.Play("Push", root)
	animateArms(character)

	local boxSize = Vector3.new(10, 8, rangeSize) 
	local boxCFrame = root.CFrame * CFrame.new(0, 0, -rangeSize / 2)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {character}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local partsInBox = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
	local hitCharacters = {}

	for _, part in ipairs(partsInBox) do
		local enemyChar = part.Parent
		local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
		
		if enemyRoot and not hitCharacters[enemyChar] then
			hitCharacters[enemyChar] = true 
			local tag = enemyChar:FindFirstChild("LastAttacker") or Instance.new("ObjectValue", enemyChar)
			tag.Name = "LastAttacker"; tag.Value = playerOrBot; Debris:AddItem(tag, 10) 

			local att = Instance.new("Attachment", enemyRoot)
			local vel = Instance.new("LinearVelocity", att)
			vel.MaxForce = 500000; vel.Attachment0 = att
			local pushDir = (enemyRoot.Position - root.Position).Unit 
			pushDir = Vector3.new(pushDir.X, 0.3, pushDir.Z).Unit 
			vel.VectorVelocity = pushDir * pushPower
			Debris:AddItem(att, 0.25); Debris:AddItem(vel, 0.25)
			
			-- [NUEVO] INTENTAR PASAR PATATA
			if forcePotatoPass then forcePotatoPass:Fire(character, enemyChar) end
		end
	end
end

local function DoBonk(playerOrBot, character)
	local cdLevel = playerOrBot:GetAttribute("BonkCooldown") or 8
	local stunTime = playerOrBot:GetAttribute("BonkStun") or 2
	
	if isOnCooldown(playerOrBot, "Bonk", cdLevel) then return end
	
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChild("Humanoid")
	local rightHand = character and character:FindFirstChild("RightHand") 
	
	if not root or not hum or hum.Health <= 0 or not rightHand then return end
	
	applyStun(playerOrBot, SELF_LOCK_TIME)
	hum.WalkSpeed = 0; hum.JumpPower = 0
	
	local bat = batTemplate:Clone(); bat.Name = "Bat"; bat.CanCollide = false; bat.Massless = true
	local batColor = playerOrBot:GetAttribute("BonkColor")
	if typeof(batColor) == "Color3" then for _, p in pairs(bat:GetDescendants()) do if p:IsA("BasePart") then p.Color = batColor end end; if bat:IsA("BasePart") then bat.Color = batColor end end
	if playerOrBot:GetAttribute("BonkNeon") == true then if bat:IsA("BasePart") then bat.Material = Enum.Material.Neon end; for _, p in pairs(bat:GetDescendants()) do if p:IsA("BasePart") then p.Material = Enum.Material.Neon end end end
	
	bat.Parent = character
	local weld = Instance.new("Weld"); weld.Part0 = rightHand; weld.Part1 = bat; weld.C0 = BAT_GRIP_OFFSET; weld.Parent = bat
	Debris:AddItem(bat, 1.5) 
	
	SoundManager.Play("BatSwing", root)
	local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
	local swingAnim = Instance.new("Animation"); swingAnim.AnimationId = ANIM_SWING_ID
	local swingTrack = animator:LoadAnimation(swingAnim); swingTrack.Priority = Enum.AnimationPriority.Action; swingTrack:Play()
	
	task.delay(SELF_LOCK_TIME, function() if playerOrBot and hum and not isStunned(playerOrBot) then hum.WalkSpeed = 16; hum.JumpPower = 50 end end)
	
	task.delay(0.3, function() 
		if not character or not bat or not bat.Parent then return end
		local hitSize = Vector3.new(6, 6, 8)
		local hitCFrame = root.CFrame * CFrame.new(0, 0, -4) 
		local params = OverlapParams.new(); params.FilterDescendantsInstances = {character}; params.FilterType = Enum.RaycastFilterType.Exclude
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
				tag.Name = "LastAttacker"; tag.Value = playerOrBot; Debris:AddItem(tag, 10)
				
				if enemyPlayer then applyStun(enemyPlayer, stunTime) end
				enemyChar:SetAttribute("StunnedUntil", workspace:GetServerTimeNow() + stunTime) 
				
				local enemyBat = enemyChar:FindFirstChild("Bat"); if enemyBat then enemyBat:Destroy() end
				
				enemyHum.WalkSpeed = 0; enemyHum.JumpPower = 0
				local stunAnim = Instance.new("Animation"); stunAnim.AnimationId = ANIM_STUN_ID
				local stunTrack = enemyHum.Animator:LoadAnimation(stunAnim); stunTrack.Looped = true; stunTrack.Priority = Enum.AnimationPriority.Action4; stunTrack:Play()
				
				local att = Instance.new("Attachment", enemyRoot)
				local lv = Instance.new("LinearVelocity", att)
				lv.MaxForce = 500000; lv.VectorVelocity = (enemyRoot.Position - root.Position).Unit * 20 + Vector3.new(0, 10, 0); lv.Attachment0 = att
				Debris:AddItem(lv, 0.2); Debris:AddItem(att, 0.2)

				-- [NUEVO] INTENTAR PASAR PATATA
				if forcePotatoPass then forcePotatoPass:Fire(character, enemyChar) end

				task.delay(stunTime, function()
					if enemyChar and enemyHum and enemyHum.Health > 0 then
						local pTime = enemyPlayer and (enemyPlayer:GetAttribute("StunnedUntil") or 0) or 0
						local cTime = enemyChar:GetAttribute("StunnedUntil") or 0
						local now = workspace:GetServerTimeNow()
						if now >= pTime and now >= cTime then
							enemyHum.WalkSpeed = 16; enemyHum.JumpPower = 50; stunTrack:Stop()
						end
					end
				end)
			end
		end
	end)
end

dashEvent.OnServerEvent:Connect(function(player) DoDash(player, player.Character) end)
pushEvent.OnServerEvent:Connect(function(player) DoPush(player, player.Character) end)
bonkEvent.OnServerEvent:Connect(function(player) DoBonk(player, player.Character) end)

botBridge.Event:Connect(function(botModel, abilityName)
    if abilityName == "Dash" then DoDash(botModel, botModel)
    elseif abilityName == "Push" then DoPush(botModel, botModel)
    elseif abilityName == "Bonk" then DoBonk(botModel, botModel)
    end
end)