local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local spectatingIndex = 1
local isSpectating = false

-- EVENTO
local function fireSpectateEvent(name)
	local event = ReplicatedStorage:FindFirstChild("SpectateUpdateEvent")
	if event then
		if event:IsA("BindableEvent") then event:Fire(name)
		elseif event:IsA("RemoteEvent") then 
			local bridge = ReplicatedStorage:FindFirstChild("LocalSpectateBridge")
			if bridge then bridge:Fire(name) end
		end
	end
end

local function getSpectateTargets()
	local targets = {}
	-- 1. Jugadores Reales
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local h = p.Character:FindFirstChild("Humanoid")
			if h and h.Health > 0 then
				table.insert(targets, {Name = p.Name, Hum = h})
			end
		end
	end
	-- 2. Bots
	for _, bot in ipairs(CollectionService:GetTagged("Bot")) do
		local h = bot:FindFirstChild("Humanoid")
		if h and h.Health > 0 then
			table.insert(targets, {Name = bot.Name, Hum = h})
		end
	end
	return targets
end

local function updateCamera()
	-- PRIORIDAD: Mi propio personaje si está vivo
	local myChar = player.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	
	if myHum and myHum.Health > 0 then
		isSpectating = false
		camera.CameraSubject = myHum
		fireSpectateEvent(nil)
		return
	end

	-- MODO ESPECTADOR
	local targets = getSpectateTargets()
	
	if #targets > 0 then
		if spectatingIndex > #targets then spectatingIndex = 1 end
		if spectatingIndex < 1 then spectatingIndex = #targets end
		
		local t = targets[spectatingIndex]
		if t and t.Hum then
			camera.CameraSubject = t.Hum
			isSpectating = true
			fireSpectateEvent(t.Name)
		end
	else
		-- NADIE VIVO: Mirar mi cadáver o resetear
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			camera.CameraSubject = player.Character.Humanoid
		end
		isSpectating = false
		fireSpectateEvent(nil)
	end
end

local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	-- Reseteo forzoso al nacer
	isSpectating = false
	fireSpectateEvent(nil)
	
	-- [CRÍTICO] Forzar la cámara al humanoide inmediatamente
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	
	humanoid.Died:Connect(function()
		task.wait(2.5) 
		updateCamera()
	end)
end

player.CharacterAdded:Connect(setupCharacter)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	local myChar = player.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	if myHum and myHum.Health > 0 then return end -- Si vivo, no cambiar cámara
	
	local kc = input.KeyCode
	if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.ButtonL1 or input.UserInputType == Enum.UserInputType.MouseButton1 then
		spectatingIndex = spectatingIndex - 1
		updateCamera()
	elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.ButtonR1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
		spectatingIndex = spectatingIndex + 1
		updateCamera()
	end
end)

-- [FIX] VERIFICACIÓN INICIAL (Si el personaje cargó antes que el script)
task.spawn(function()
	if player.Character then
		setupCharacter(player.Character)
	end
end)