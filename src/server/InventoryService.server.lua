local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local equipEvent = ReplicatedStorage:FindFirstChild("EquipAbilityEvent")
if not equipEvent then
	equipEvent = Instance.new("RemoteEvent")
	equipEvent.Name = "EquipAbilityEvent"
	equipEvent.Parent = ReplicatedStorage
end

-- Mapa: Nombre Habilidad -> Nombre Atributo Unlock
local UNLOCK_MAP = {
	Push = "PushUnlock",
	Dash = "DashUnlock",
	Bonk = "BonkUnlock"
}

equipEvent.OnServerEvent:Connect(function(player, slotNumber, abilityName)
	-- Validar Slot
	if slotNumber < 1 or slotNumber > 3 then return end
	
	-- CASO 1: DESEQUIPAR (abilityName es nil)
	if not abilityName then
		player:SetAttribute("EquippedSlot" .. slotNumber, nil)
		return
	end
	
	-- CASO 2: EQUIPAR
	-- Validar si tiene la habilidad desbloqueada
	local unlockKey = UNLOCK_MAP[abilityName]
	if unlockKey and player:GetAttribute(unlockKey) == true then
		
		-- Limpieza: Si ya está equipada en otro slot, la quitamos de ahí
		for i = 1, 3 do
			if player:GetAttribute("EquippedSlot" .. i) == abilityName then
				player:SetAttribute("EquippedSlot" .. i, nil)
			end
		end
		
		-- Equipamos en el slot deseado
		player:SetAttribute("EquippedSlot" .. slotNumber, abilityName)
		print(player.Name .. " equipó " .. abilityName .. " en Slot " .. slotNumber)
	end
end)

-- CONFIGURACIÓN INICIAL (DEFAULT LOADOUT)
Players.PlayerAdded:Connect(function(player)
	-- Le damos un loadout por defecto si es nuevo (opcional)
	-- Por ahora empiezan vacíos o cargan sus datos si tuvieras DataStore
end)