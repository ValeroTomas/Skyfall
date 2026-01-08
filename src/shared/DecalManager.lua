local DecalManager = {}

-- DICCIONARIO DE IMÁGENES
local DECALS = {
	-- HUD ICONS
	["Coin"]      = "rbxassetid://99365746352443",
	["Cart"]      = "rbxassetid://113277509630221",
	["Dash"]      = "rbxassetid://97307955533015",
	["Push"]      = "rbxassetid://76175865229928",
	["DoubleJump"] = "rbxassetid://130535017246273",
	["Bonk"]      = "rbxassetid://109551608313347",
	["3000Coins"] = "rbxassetid://99365746352443",
	["6500Coins"] = "rbxassetid://80954468299528",
	["12000Coins"] = "rbxassetid://117523493159618",
	
	-- COUNTDOWN (HUDCenter)
	["Count3"]    = "rbxassetid://82880615630562",
	["Count2"]    = "rbxassetid://106151002747016",
	["Count1"]    = "rbxassetid://81413356718779",
	["CountGo"]   = "rbxassetid://109998882050960",
	
	-- EFECTOS (Ragdoll/Particles)
	["BurnTexture"] = "rbxassetid://851359309",
	["BonkStun"] = "rbxassetid://5639840603",
	["BonkHit"] = "rbxassetid://290833006",
}

-- Obtener ID
function DecalManager.Get(name)
	return DECALS[name] or ""
end

-- Para la Pantalla de Carga
function DecalManager.GetAssets()
	local assets = {}
	for _, id in pairs(DECALS) do
		table.insert(assets, id)
	end
	return assets
end

return DecalManager