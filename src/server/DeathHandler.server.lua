local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PlayerManager = require(script.Parent.PlayerManager)
local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent")

-- [CORRECCIÓN] Se eliminó el sistema automático de verificación por segundo
-- Ahora el RoundManager controla el tiempo exacto de los respawns.

local function setupDeath(character, playerName, isBot)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	humanoid.Died:Connect(function()
		---------------------------------------------------------------
		-- 1. CÁLCULO DE RANK (PUESTO)
		---------------------------------------------------------------
		local currentAlive = PlayerManager.GetAlivePlayers()
		local rank = #currentAlive + 1
		
		if rank == 1 then rank = 2 end
		
		-- Si es jugador, guardamos atributo en player. Si es bot, en el modelo.
		if not isBot then
			local p = Players:GetPlayerFromCharacter(character)
			if p then p:SetAttribute("RoundRank", rank) end
		else
			character:SetAttribute("RoundRank", rank) -- El bot guarda su rank en el modelo
		end
		
		print(playerName .. " eliminado. Puesto: #" .. rank)

		---------------------------------------------------------------
		-- 2. KILLFEED
		---------------------------------------------------------------
		local attackerTag = character:FindFirstChild("LastAttacker")
		local attacker = attackerTag and attackerTag.Value
		
		local cause = "LAVA"
		if character:GetAttribute("Crushed") then
			cause = "CRUSH"
		end
		
		local attackerName = nil
		if attacker then
			if attacker:IsA("Player") then attackerName = attacker.Name
			elseif attacker:IsA("Model") then attackerName = attacker.Name end -- Soporte nombre bot atacante
		end
		
		local messageKey = ""
		if attackerName then
			messageKey = (cause == "LAVA") and "DEATH_PUSH_LAVA" or "DEATH_PUSH_CRUSH"
			killfeedEvent:FireAllClients(messageKey, playerName, attackerName)
		else
			messageKey = (cause == "LAVA") and "DEATH_LAVA" or "DEATH_CRUSH"
			killfeedEvent:FireAllClients(messageKey, playerName)
		end
		
		---------------------------------------------------------------
		-- 3. LIMPIEZA DE BOTS MUERTOS
		---------------------------------------------------------------
		if isBot then
			-- Marcar el bot como muerto inmediatamente
			character:SetAttribute("IsDead", true)
			
			-- Para bots, eliminamos el modelo después de un tiempo
			task.wait(1)
			if character and character.Parent then
				character:Destroy()
			end
		end
	end)
end

-- Conectar Jugadores
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		setupDeath(char, player.Name, false)
	end)
end)

-- Conectar Bots
CollectionService:GetInstanceAddedSignal("Bot"):Connect(function(bot)
	setupDeath(bot, bot.Name, true)
end)

for _, bot in ipairs(CollectionService:GetTagged("Bot")) do
	setupDeath(bot, bot.Name, true)
end