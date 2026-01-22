local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- IMPORTAR MANAGERS
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))

-- FUNCIÓN DE GRAVEDAD BAJA (Para Lava y Agua)
local function applyLowGravity(part, forceMult)
	forceMult = forceMult or 0.2 -- Default lava
	local att = Instance.new("Attachment")
	att.Name = "GravityAttachment"
	att.Parent = part

	local vf = Instance.new("VectorForce")
	vf.Name = "GravityForce"
	vf.Attachment0 = att
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	-- Compensa la gravedad para que floten lento
	vf.Force = Vector3.new(0, part.AssemblyMass * workspace.Gravity * (1 - forceMult), 0)
	vf.Parent = part

	return {att, vf}
end

-- EFECTO CRUSH (Modificado para no destruir el personaje)
local function applyCrushEffect(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	SoundManager.Play("Squish", root or character.Head)
	
	-- Marcar el personaje como "destruido visualmente" para el respawn
	character:SetAttribute("CrushedEffectApplied", true)
	
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true; part.CanCollide = false
			local oldSize = part.Size
			local targetSize = Vector3.new(oldSize.X * 1.8, 0.2, oldSize.Z * 1.8)
			local targetCFrame = part.CFrame * CFrame.new(0, -oldSize.Y / 2, 0)
			
			TweenService:Create(part, TweenInfo.new(0.15, Enum.EasingStyle.Bounce), {
				Size = targetSize, CFrame = targetCFrame, Transparency = 0.2
			}):Play()
		end
	end
	
	-- NO DESTRUIR el personaje - dejar que el sistema de respawn lo maneje
	-- En su lugar, marcarlo para limpieza futura
	task.delay(5, function() 
		if character and character.Parent then
			-- Solo limpiar si el jugador ya tiene un nuevo personaje
			local player = Players:GetPlayerFromCharacter(character)
			if player and player.Character ~= character then
				character:Destroy()
				print("RagdollSystem: Limpiando personaje aplastado antiguo de " .. player.Name)
			end
		end
	end)
end

-- EFECTO LAVA (Quema + Flota un poco)
local function applyLavaDeath(character)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then part.Transparency = 1; part.CanCollide = false end
			TweenService:Create(part, TweenInfo.new(2), {Color = Color3.new(0, 0, 0)}):Play() -- Negro
			
			if part.Name ~= "HumanoidRootPart" then
				applyLowGravity(part, 0.3) -- Gravedad 30%
				local p = Instance.new("ParticleEmitter", part)
				p.Texture = DecalManager.Get("BurnTexture"); p.Color = ColorSequence.new(Color3.new(0.1,0.1,0.1))
				p.Size = NumberSequence.new(1, 2); p.Rate = 25
			end
		end
	end
end

-- [NUEVO] EFECTO AGUA (Azul + Flota mucho)
local function applyWaterDeath(character)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then part.Transparency = 1; part.CanCollide = false end
			
			-- Cambio de color a Azul Cian suave
			TweenService:Create(part, TweenInfo.new(1), {Color = Color3.fromRGB(0, 150, 255)}):Play()
			
			if part.Name ~= "HumanoidRootPart" then
				applyLowGravity(part, 0.1) -- Gravedad muy baja (10%), flota mucho
				
				-- Burbujas
				local bubbles = Instance.new("ParticleEmitter", part)
				bubbles.Texture = "rbxassetid://243662261" -- Burbuja simple
				bubbles.Size = NumberSequence.new(0.5, 0)
				bubbles.Transparency = NumberSequence.new(0.2, 1)
				bubbles.Color = ColorSequence.new(Color3.new(1,1,1))
				bubbles.Acceleration = Vector3.new(0, 5, 0) -- Suben
				bubbles.Rate = 10; bubbles.Lifetime = NumberRange.new(1, 2)
			end
		end
	end
end

local function setupRagdoll(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	humanoid.BreakJointsOnDeath = false 

	humanoid.Died:Connect(function()
		-- Verificar causa de muerte (atributos puestos por MapHazardService)
		if character:GetAttribute("Crushed") then
			applyCrushEffect(character)
			-- NO hacer BreakJoints() aquí para mantener la integridad del personaje
		elseif character:GetAttribute("KilledByLava") then
			character:BreakJoints()
			applyLavaDeath(character)
		elseif character:GetAttribute("KilledByWater") then
			character:BreakJoints()
			applyWaterDeath(character) -- [NUEVO]
		else
			character:BreakJoints()
		end
	end)
end

Players.PlayerAdded:Connect(function(player) player.CharacterAdded:Connect(setupRagdoll) end)
CollectionService:GetInstanceAddedSignal("Bot"):Connect(setupRagdoll)
for _, bot in ipairs(CollectionService:GetTagged("Bot")) do setupRagdoll(bot) end