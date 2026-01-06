local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local spectatingIndex = 1
local isSpectating = false
local targetPlayer = nil

-- EVENTO
local function fireSpectateEvent(name)
	local event = ReplicatedStorage:FindFirstChild("SpectateUpdateEvent")
	if event then
		if event:IsA("BindableEvent") then
			event:Fire(name)
		elseif event:IsA("RemoteEvent") then
			local bridge = ReplicatedStorage:FindFirstChild("LocalSpectateBridge")
			if bridge then bridge:Fire(name) end
		end
	end
end

local function getAlivePlayers()
	local alive = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
			table.insert(alive, p)
		end
	end
	return alive
end

local function updateCamera()
	-- CORRECCIÓN: Verificar primero si YO estoy vivo.
	-- Si estoy vivo, no debo spectear a nadie, cancelamos la operación.
	local myChar = player.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	
	if myHum and myHum.Health > 0 then
		isSpectating = false
		camera.CameraSubject = myHum
		fireSpectateEvent(nil)
		return -- Salimos de la función aquí mismo
	end

	-- Lógica normal de spectador
	local alivePlayers = getAlivePlayers()
	
	if #alivePlayers > 0 then
		if spectatingIndex > #alivePlayers then spectatingIndex = 1 end
		if spectatingIndex < 1 then spectatingIndex = #alivePlayers end
		
		targetPlayer = alivePlayers[spectatingIndex]
		if targetPlayer and targetPlayer.Character then
			local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
			if targetHum then
				camera.CameraSubject = targetHum
				isSpectating = true
				fireSpectateEvent(targetPlayer.Name)
			end
		end
	else
		-- Si no hay nadie más vivo, miramos nuestro cadáver o ubicación
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			camera.CameraSubject = player.Character.Humanoid
		end
		isSpectating = false
		fireSpectateEvent(nil)
	end
end

player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	
	-- Reseteo forzoso al nacer
	isSpectating = false
	fireSpectateEvent(nil)
	camera.CameraSubject = humanoid
	
	humanoid.Died:Connect(function()
		task.wait(2.5) 
		-- Al pasar los 2.5s, updateCamera ahora revisará si ya reviviste antes de cambiar la cámara
		updateCamera()
	end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not isSpectating then return end
	
	local inputType = input.UserInputType
	local keyCode = input.KeyCode
	
	-- Bloquear controles de spectador si el jugador revivió pero isSpectating quedó en true por error
	if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
		isSpectating = false
		camera.CameraSubject = player.Character.Humanoid
		return
	end
	
	if keyCode == Enum.KeyCode.Left or keyCode == Enum.KeyCode.ButtonL1 or inputType == Enum.UserInputType.MouseButton1 then
		spectatingIndex -= 1
		updateCamera()
	elseif keyCode == Enum.KeyCode.Right or keyCode == Enum.KeyCode.ButtonR1 or inputType == Enum.UserInputType.MouseButton2 then
		spectatingIndex += 1
		updateCamera()
	end
end)