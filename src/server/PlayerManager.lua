local PlayerManager = {}
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

function PlayerManager.GetAlivePlayers()
	local alive = {}

	-- 1. Jugadores Reales
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(alive, player)
			end
		end
	end

	-- 2. Bots (Modelos con Tag "Bot")
	for _, botModel in ipairs(CollectionService:GetTagged("Bot")) do
		-- Solo contar bots que estén activos en el juego (no templates)
		if botModel:GetAttribute("IsActive") and not botModel:GetAttribute("IsDead") then
			local humanoid = botModel:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				-- Truco: Insertamos el modelo del bot como si fuera el "Player"
				-- El resto de scripts deberán saber manejar esto (ver paso 1.2)
				table.insert(alive, botModel)
			end
		end
	end

	return alive
end

return PlayerManager