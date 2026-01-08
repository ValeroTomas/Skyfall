local VipList = {}

-- LISTA DE AMIGOS VIP (IDs que entran gratis)
-- Formato: [ID_DE_ROBLOX] = true,
VipList.Users = {
	[4866854573] = true, -- Puedes añadir más filas así
	[10170907800] = true,
	[10285292624] = true,
}

-- Función para verificar si es VIP
function VipList.IsVip(userId)
	return VipList.Users[userId] == true
end

return VipList