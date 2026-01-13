local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- IMPORTAR MANAGERS
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))

-- FUNCIÓN DE GRAVEDAD BAJA (Para muerte por Lava)
local function applyLowGravity(part)
	local att = Instance.new("Attachment")
	att.Name = "GravityAttachment"
	att.Parent = part

	local vf = Instance.new("VectorForce")
	vf.Name = "GravityForce"
	vf.Attachment0 = att
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	vf.Force = Vector3.new(0, part.AssemblyMass * workspace.Gravity * 0.2, 0)
	vf.Parent = part

	return {att, vf}
end

-- EFECTO DE APLASTAMIENTO (CRUSH)
local function applyCrushEffect(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	SoundManager.Play("Squish", root or character.Head)
	
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			
			local oldSize = part.Size
			local targetSize = Vector3.new(oldSize.X * 1.8, 0.2, oldSize.Z * 1.8)
			local targetCFrame = part.CFrame * CFrame.new(0, -oldSize.Y / 2, 0)
			
			local info = TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			TweenService:Create(part, info, {
				Size = targetSize,
				CFrame = targetCFrame,
				Transparency = 0.2
			}):Play()
		end
	end
	
	task.delay(3, function()
		if character then
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
				end
			end
		end
	end)
end

-- LÓGICA DE MUERTE POR LAVA
local function applyLavaDeath(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
		root.Transparency = 1
		root.CanCollide = false
	end

	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")
			a1.Parent = joint.Part0
			a2.Parent = joint.Part1
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = a1
			socket.Attachment1 = a2
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = joint.Parent

			joint:Destroy()
		end
	end

	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
			TweenService:Create(part, TweenInfo.new(2), {Color = Color3.new(0, 0, 0)}):Play()
			task.delay(2, function()
				if part then TweenService:Create(part, TweenInfo.new(3), {Transparency = 1}):Play() end
			end)

			if part.Name:match("Torso") or part.Name == "Head" or part.Name:match("Arm") or part.Name:match("Leg") then
				applyLowGravity(part)
				
				local p = Instance.new("ParticleEmitter")
				p.Name = "BurnEffect"
				p.Texture = DecalManager.Get("BurnTexture") 
				p.Color = ColorSequence.new(Color3.new(0.1, 0.1, 0.1))
				p.Size = NumberSequence.new(1, 2)
				p.Rate = 25
				p.Lifetime = NumberRange.new(1, 2)
				p.Parent = part 
			end
		end
	end

	task.delay(4, function()
		if not character then return end
		for _, obj in pairs(character:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Anchored = true
				local force = obj:FindFirstChild("GravityForce")
				if force then force:Destroy() end
			elseif obj:IsA("ParticleEmitter") and obj.Name == "BurnEffect" then
				obj.Enabled = false
			end
		end
	end)
end

-- CONEXIÓN UNIFICADA (Para Players y Bots)
local function setupRagdoll(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	humanoid.BreakJointsOnDeath = false 

	humanoid.Died:Connect(function()
		if character:GetAttribute("Crushed") then
			applyCrushEffect(character)
		elseif character:GetAttribute("KilledByLava") then
			applyLavaDeath(character)
		else
			character:BreakJoints() -- Muerte normal (Ragdoll nativo de Roblox)
		end
	end)
end

-- 1. Conectar Jugadores Reales
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupRagdoll)
end)

-- 2. Conectar Bots (Usando CollectionService)
CollectionService:GetInstanceAddedSignal("Bot"):Connect(function(botModel)
	setupRagdoll(botModel)
end)

-- Inicializar bots ya existentes (si los hubiera al iniciar script)
for _, bot in ipairs(CollectionService:GetTagged("Bot")) do
	setupRagdoll(bot)
end