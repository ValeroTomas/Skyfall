local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local jumpEvent = ReplicatedStorage:FindFirstChild("DoubleJumpEvent")
if not jumpEvent then
	jumpEvent = Instance.new("RemoteEvent")
	jumpEvent.Name = "DoubleJumpEvent"
	jumpEvent.Parent = ReplicatedStorage
end

-- COLORES POR DEFECTO (Fallback)
local TRAIL_COLORS = {
	[0] = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
	[1] = ColorSequence.new(Color3.fromRGB(0, 255, 255)),
}

local function spawnVisuals(character, colorAttribute)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return end

	local a0 = Instance.new("Attachment", hrp)
	local a1 = Instance.new("Attachment", hrp)
	a0.Position = Vector3.new(0, 1, 0)
	a1.Position = Vector3.new(0, -1, 0)

	local trail = Instance.new("Trail")
	trail.Name = "DoubleJumpTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	
	-- LÓGICA DE COLOR INSTANTÁNEA
	local finalColorSeq
	
	if typeof(colorAttribute) == "Color3" then
		-- Si el atributo ya es un Color3 (Gracias a PlayerDataHandler nuevo)
		finalColorSeq = ColorSequence.new(colorAttribute)
	else
		-- Si no hay atributo o es viejo, usamos Celeste por defecto
		finalColorSeq = TRAIL_COLORS[1]
	end
	
	trail.Color = finalColorSeq
	trail.Transparency = NumberSequence.new(0.4, 1) 
	trail.Lifetime = 0.5 
	trail.FaceCamera = true
	trail.LightEmission = 1 
	trail.Enabled = true
	trail.Parent = hrp

	local connection
	local isActive = true

	local function stopTrail()
		if not isActive then return end
		isActive = false
		if connection then connection:Disconnect() end
		if trail then trail.Enabled = false end
		
		task.delay(trail.Lifetime + 0.1, function()
			if trail then trail:Destroy() end
			if a0 then a0:Destroy() end
			if a1 then a1:Destroy() end
		end)
	end

	connection = humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			stopTrail()
		end
	end)

	task.delay(5, function() if isActive then stopTrail() end end)
end

jumpEvent.OnServerEvent:Connect(function(player)
	if player.Character and player.Character:GetAttribute("IsExhausted") then return end

	-- CHECK RÁPIDO: Verificamos el atributo directamente en el Player
	-- Esto es mucho más rápido que invocar GetPlayerStat
	local hasDoubleJump = player:GetAttribute("DoubleJump") == true
	
	if hasDoubleJump and player.Character then
		-- Leemos el color directo del atributo
		local colorAttr = player:GetAttribute("DoubleJumpColor")
		spawnVisuals(player.Character, colorAttr)
	end
end)