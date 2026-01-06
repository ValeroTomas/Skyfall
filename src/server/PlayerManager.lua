local PlayerManager = {}

function PlayerManager.GetAlivePlayers()
	local alive = {}

	for _, player in ipairs(game.Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(alive, player)
			end
		end
	end

	return alive
end

return PlayerManager
