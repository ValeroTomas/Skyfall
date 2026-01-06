local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local function forceSpawn(player)
	if not player or not player.Parent then return end

	task.defer(function()
		-- SOLO pedir a Roblox que cargue el character
		player:LoadCharacter()

		task.wait(0.2)

		if player.Character then
			player.Character:SetAttribute("KilledByLava", nil)
			player.Character:SetAttribute("Crushed", nil)
			print("RespawnService: Personaje recreado para " .. player.Name)
		else
			warn("RespawnService: Falló respawn de " .. player.Name)
		end
	end)
end

local function respawnAllDead()
	print("RespawnService: Forzando recreación masiva...")
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if not char or (hum and hum.Health <= 0) then
			forceSpawn(player)
		end
	end
end

_G.RespawnAllPlayers = respawnAllDead

Players.PlayerAdded:Connect(forceSpawn)

local debugRespawnEvent = ReplicatedStorage:FindFirstChild("DebugRespawnEvent")
if not debugRespawnEvent then
	debugRespawnEvent = Instance.new("RemoteEvent")
	debugRespawnEvent.Name = "DebugRespawnEvent"
	debugRespawnEvent.Parent = ReplicatedStorage
end

debugRespawnEvent.OnServerEvent:Connect(function(player)
	respawnAllDead()
end)

print("RespawnService: Sistema listo.")
