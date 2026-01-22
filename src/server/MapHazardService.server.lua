local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))

-- Buscamos eventos de mapa
local mapEventStart = ReplicatedStorage:FindFirstChild("MapEventStart") -- Opcional si quisieras olas
local cleanMapEvent = ReplicatedStorage:WaitForChild("CleanMapEvent")

local currentHazardConnection = nil

local function onHazardTouch(hit, hazardType)
	local char = hit.Parent
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	
	if hum and hum.Health > 0 and root then
		-- Evitar matar dos veces
		if char:GetAttribute("DeadByHazard") then return end
		char:SetAttribute("DeadByHazard", true)
		
		-- Marcar causa de muerte para el RagdollSystem
		if hazardType == "Water" then
			char:SetAttribute("KilledByWater", true)
			SoundManager.Play("Splash", root)
			
			-- Efecto visual simple de splash
			local splash = Instance.new("Part")
			splash.Anchored = true; splash.CanCollide = false; splash.Transparency = 1
			splash.CFrame = CFrame.new(root.Position)
			splash.Parent = workspace
			
			local p = Instance.new("ParticleEmitter", splash)
			p.Texture = "rbxassetid://243662261" -- Textura genérica (círculo/humo)
			p.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
			p.Size = NumberSequence.new(2, 4)
			p.Speed = NumberRange.new(10, 15)
			p.Acceleration = Vector3.new(0, -30, 0)
			p.SpreadAngle = Vector2.new(45, 45)
			p.Rate = 0; p:Emit(30)
			Debris:AddItem(splash, 2)
			
		else -- Lava
			char:SetAttribute("KilledByLava", true)
			SoundManager.Play("LavaBurn", root)
		end
		
		hum.Health = 0
	end
end

local function setupMapHazard()
	if currentHazardConnection then currentHazardConnection:Disconnect() end
	
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	
	-- 1. BUSCAR AGUA
	local water = map:FindFirstChild("Water")
	if water then
		print("💧 Agua detectada en el mapa")
		currentHazardConnection = water.Touched:Connect(function(hit)
			onHazardTouch(hit, "Water")
		end)
		return
	end
	
	-- 2. BUSCAR LAVA
	local lava = map:FindFirstChild("Lava")
	if lava then
		print("🔥 Lava detectada en el mapa")
		currentHazardConnection = lava.Touched:Connect(function(hit)
			onHazardTouch(hit, "Lava")
		end)
		return
	end
end

-- Monitorear cuando cambia el mapa
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		task.wait(0.1) -- Esperar a que carguen hijos
		setupMapHazard()
	end
end)

-- Inicializar si ya hay mapa
setupMapHazard()