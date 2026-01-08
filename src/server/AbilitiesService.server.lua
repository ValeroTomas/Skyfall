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

local cooldownEvent = ReplicatedStorage:FindFirstChild("CooldownEvent")
if not cooldownEvent then
	cooldownEvent = Instance.new("RemoteEvent")
	cooldownEvent.Name = "CooldownEvent"
	cooldownEvent.Parent = ReplicatedStorage
end

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
-- MANAGERS
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

-- Sound Folder creation
local SoundFolder = ReplicatedStorage:FindFirstChild("AbilitySounds") or Instance.new("Folder", ReplicatedStorage)
SoundFolder.Name = "AbilitySounds"

-- HELPERS BÁSICOS
local function canUseAbility()
	local rawState = estadoValue.Value
	local state = string.split(rawState, "|")[1]
	return state == "SURVIVE"
end

-------------------------------------------------------------------
-- [NUEVO] SISTEMA DE STUN POR TIMESTAMP
-------------------------------------------------------------------
-- Aplica stun solo si el nuevo tiempo es mayor al actual
local function applyStun(player, duration)
	if not player then return end
	local now = workspace:GetServerTimeNow() -- Tiempo ultra-preciso sincronizado
	local currentEnd = player:GetAttribute("StunnedUntil") or 0
	
	if (now + duration) > currentEnd then
		player:SetAttribute("StunnedUntil", now + duration)
	end
end

-- Verifica si el tiempo actual es menor al tiempo de fin del stun
local function isStunned(player)
	local untilTime = player:GetAttribute("StunnedUntil") or 0
	return workspace:GetServerTimeNow() < untilTime
end

local function isOnCooldown(player, abilityName, duration)
	if not canUseAbility() then return true end
	
	-- VALIDACIÓN ROBUSTA CON TIMESTAMP
	if isStunned(player) then return true end
	
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
		player:SetAttribute("StunnedUntil", 0) -- Reset al nacer
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

-- EFECTOS VISUALES (Humo sale de la cabeza)
local function createStunEffect(character, duration)
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local ID_STAR = DecalManager.Get("BonkStun")
	local ID_SMOKE = "rbxassetid://243662261" 

	-- Estrellas (Duran lo que el stun)
	local stars = Instance.new("ParticleEmitter")
	stars.Texture = ID_STAR
	stars.Size = NumberSequence.new(0.8, 0)
	stars.Rate = 5
	stars.Lifetime = NumberRange.new(duration) 
	stars.Parent = head
	
	SoundManager.Play("BatHit", head)
	
	-- Humo (Explosión instantánea desde la cabeza)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "HitSmoke"
	smoke.Texture = ID_SMOKE
	smoke.Size = NumberSequence.new(2, 5)
	smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
	smoke.Lifetime = NumberRange.new(0.4, 0.6)
	smoke.Rate = 0; smoke.Enabled = false 
	smoke.Parent = head
	smoke:Emit(30) -- ¡PUM!
	
	Debris:AddItem(stars, duration) 
	Debris:AddItem(smoke, 1.5) 
end

-------------------------------------------------------------------
-- DASH & PUSH
-------------------------------------------------------------------
dashEvent.OnServerEvent:Connect(function(player)
	local cd = player:GetAttribute("DashCooldown") or 8
	if isOnCooldown(player, "Dash", cd) then return end

	local force = player:GetAttribute("DashDistance") or 50
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or char.Humanoid.Health <= 0 then return end

	SoundManager.Play("Dash", hrp)
	
	local wind = Instance.new("ParticleEmitter"); wind.Parent = hrp; wind.Enabled = false
	Debris:AddItem(wind, 1) -- Dummy para el layout

	local att = Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity", att)
	lv.MaxForce, lv.Attachment0 = 999999, att
	lv.VectorVelocity = hrp.CFrame.LookVector * force

	task.wait(0.2)
	lv:Destroy(); att:Destroy()
end)

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
		
		if enemyRoot and not hitCharacters[enemyChar] then
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
			Debris:AddItem(att, 0.25); Debris:AddItem(vel, 0.25)
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
	
	-- [1] AUTO-LOCK ATACANTE (Timestamp)
	applyStun(player, SELF_LOCK_TIME)
	hum.WalkSpeed = 0; hum.JumpPower = 0
	
	-- SPAWN BATE
	local bat = batTemplate:Clone()
	bat.Name = "Bat" -- Nombre clave para la interrupción
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
	
	-- TIMER PARA RESTAURAR VELOCIDAD (Si ya no está stuneado por otra causa)
	task.delay(SELF_LOCK_TIME, function()
		if player and hum and not isStunned(player) then
			hum.WalkSpeed = 16; hum.JumpPower = 50
		end
	end)
	
	-- HITBOX (Windup delay)
	task.delay(0.3, function() 
		-- Interrupción: Si me stunearon en este lapso, el bate habrá sido destruido.
		if not char or not bat or not bat.Parent then return end
		
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
				
				-- [2] STUN VÍCTIMA (Timestamp)
				if enemyPlayer then applyStun(enemyPlayer, stunTime) end
				-- Backup para NPCs o scripts que lean el char
				enemyChar:SetAttribute("StunnedUntil", workspace:GetServerTimeNow() + stunTime) 
				
				-- DESARMAR AL ENEMIGO (Interrumpe su ataque si estaba cargando uno)
				local enemyBat = enemyChar:FindFirstChild("Bat")
				if enemyBat then enemyBat:Destroy() end
				
				enemyHum.WalkSpeed = 0
				enemyHum.JumpPower = 0
				
				local stunAnim = Instance.new("Animation"); stunAnim.AnimationId = ANIM_STUN_ID
				local stunTrack = enemyHum.Animator:LoadAnimation(stunAnim)
				stunTrack.Looped = true
				stunTrack.Priority = Enum.AnimationPriority.Action4; stunTrack:Play()
				
				local att = Instance.new("Attachment", enemyRoot)
				local lv = Instance.new("LinearVelocity", att)
				lv.MaxForce = 500000
				lv.VectorVelocity = (enemyRoot.Position - root.Position).Unit * 20 + Vector3.new(0, 10, 0)
				lv.Attachment0 = att
				Debris:AddItem(lv, 0.2); Debris:AddItem(att, 0.2)

				-- RESTAURAR VÍCTIMA
				task.delay(stunTime, function()
					if enemyChar and enemyHum and enemyHum.Health > 0 then
						-- Solo restauramos movimiento si el tiempo de stun ACTUAL ya pasó.
						-- Esto maneja perfectamente si recibió OTRO stun más largo mientras tanto.
						local pTime = enemyPlayer and (enemyPlayer:GetAttribute("StunnedUntil") or 0) or 0
						local cTime = enemyChar:GetAttribute("StunnedUntil") or 0
						local now = workspace:GetServerTimeNow()
						
						-- Si "ahora" es mayor que el tiempo de stun del player Y del character
						if now >= pTime and now >= cTime then
							enemyHum.WalkSpeed = 16 
							enemyHum.JumpPower = 50
							stunTrack:Stop()
						end
					end
				end)
			end
		end
	end)
end)