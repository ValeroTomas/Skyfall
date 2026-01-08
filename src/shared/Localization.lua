local Localization = {}

local languages = {
	--------------------------------------------------------------------------------
	-- ESPAÑOL
	--------------------------------------------------------------------------------
	["es"] = {
		-- HUD / JUEGO
		["WAITING"] = "ESPERANDO (%s/%s)",
		["STARTING"] = "INICIANDO EN %s",
		["SURVIVE"] = "¡SOBREVIVE!",
		["WINNER"] = "¡%s GANA!",
		["YOU_WON"] = "¡HAS GANADO!",
		["NO_ONE"] = "¡NADIE SOBREVIVIÓ!",
		["ALIVE"] = "%s VIVOS",
		["TIE"] = "¡EMPATE!",
		["COUNTDOWN_GO"] = "¡YA!",
		
		-- LOADING SCREEN (NUEVO)
		["LOADING_ASSETS"] = "CARGANDO RECURSOS...",
		["LOADING_COMPLETE"] = "¡LISTO!",
		
		-- Killfeed
		["DEATH_LAVA"] = "🔥 %s se cayó a la lava.",
		["DEATH_CRUSH"] = "☠️ %s fue aplastado por un bloque.",
		["DEATH_PUSH_LAVA"] = "✋🔥 %s fue empujado por %s a la lava.",
		["DEATH_PUSH_CRUSH"] = "✋☠️ %s fue empujado por %s debajo de un bloque.",
		
		-- Rewards
		["REWARD_MSG"] = "¡Has ganado %s monedas!",
		
		-- Spectator
		["SPECTATING"] = "Estás mirando a...",
		
		-- Death Screen
		["YOU_DIED"] = "¡HAS MUERTO!",
		["RANK_INFO"] = "QUEDASTE EN EL PUESTO #%s",
		["RESPAWN_INFO"] = "VOLVERÁS A APARECER CUANDO COMIENCE LA RONDA",

		-- TIENDA (SHOP)
		["SHOP_TITLE"] = "TIENDA DE MEJORAS",
		["COLOR_SELECTOR"] = "SELECCIONA COLOR",
		["BTN_CONFIRM"] = "CONFIRMAR",
		
		["BTN_BUY"] = "COMPRAR",
		["BTN_UPGRADE"] = "MEJORAR",
		["BTN_READY"] = "LISTO",
		["BTN_COLOR"] = "COLOR",
		["BTN_LOCKED"] = "🔒",
		
		["LBL_LOCKED"] = "BLOQUEADO",
		["LBL_ACQUIRED"] = "ADQUIRIDO",
		["LBL_CHANGE"] = "CAMBIAR",
		["LBL_MAX"] = "MAX",
		["LBL_ERR"] = "ERR",
		["MSG_MISSING"] = "FALTAN $",
		
		["HEADER_JUMP"] = "SALTO",
		["HEADER_PUSH"] = "EMPUJE",
		["HEADER_DASH"] = "ESQUIVE",
		["HEADER_STAMINA"] = "STAMINA",
		
		["ITEM_HEIGHT"] = "ALTURA",
		["ITEM_COST"] = "COSTE STAMINA",
		["ITEM_DOUBLE_JUMP"] = "SALTO DOBLE",
		["ITEM_JUMP_COLOR"] = "COLOR SALTO",
		["ITEM_UNLOCK"] = "DESBLOQUEAR",
		["ITEM_DISTANCE"] = "DISTANCIA",
		["ITEM_RANGE"] = "RANGO",
		["ITEM_COOLDOWN"] = "COOLDOWN",
		["ITEM_SPEED"] = "VELOCIDAD",
		["ITEM_DASH_COLOR"] = "COLOR ESQUIVE",
		["ITEM_AMOUNT"] = "CANTIDAD",
		["ITEM_REGEN"] = "RECARGA",
		["ITEM_EFFICIENCY"] = "EFICIENCIA"
	},

	--------------------------------------------------------------------------------
	-- ENGLISH
	--------------------------------------------------------------------------------
	["en"] = {
		-- HUD / GAME
		["WAITING"] = "WAITING FOR PLAYERS (%s/%s)",
		["STARTING"] = "STARTING IN %s",
		["SURVIVE"] = "SURVIVE!",
		["WINNER"] = "%s WINS!",
		["YOU_WON"] = "YOU WON!",
		["NO_ONE"] = "NO ONE SURVIVED!",
		["ALIVE"] = "%s ALIVE",
		["TIE"] = "TIE!",
		["COUNTDOWN_GO"] = "GO!",
		
		-- LOADING SCREEN (NEW)
		["LOADING_ASSETS"] = "LOADING ASSETS...",
		["LOADING_COMPLETE"] = "READY!",
		
		-- Killfeed
		["DEATH_LAVA"] = "🔥 %s fell into the lava.",
		["DEATH_CRUSH"] = "☠️ %s was crushed by a block.",
		["DEATH_PUSH_LAVA"] = "✋🔥 %s was pushed by %s into the lava.",
		["DEATH_PUSH_CRUSH"] = "✋☠️ %s was pushed by %s under a block.",
		
		-- Rewards
		["REWARD_MSG"] = "You won %s coins!",
		
		-- Spectator
		["SPECTATING"] = "Spectating...",
		
		-- Death Screen
		["YOU_DIED"] = "YOU DIED!",
		["RANK_INFO"] = "YOU PLACED RANK #%s",
		["RESPAWN_INFO"] = "YOU WILL RESPAWN WHEN THE ROUND STARTS",

		-- SHOP
		["SHOP_TITLE"] = "UPGRADE SHOP",
		["COLOR_SELECTOR"] = "COLOR SELECTOR",
		["BTN_CONFIRM"] = "CONFIRM",
		
		["BTN_BUY"] = "BUY",
		["BTN_UPGRADE"] = "UPGRADE",
		["BTN_READY"] = "OWNED",
		["BTN_COLOR"] = "COLOR",
		["BTN_LOCKED"] = "🔒",
		
		["LBL_LOCKED"] = "LOCKED",
		["LBL_ACQUIRED"] = "ACQUIRED",
		["LBL_CHANGE"] = "CHANGE",
		["LBL_MAX"] = "MAX",
		["LBL_ERR"] = "ERR",
		["MSG_MISSING"] = "NEED $",
		
		["HEADER_JUMP"] = "JUMP",
		["HEADER_PUSH"] = "PUSH",
		["HEADER_DASH"] = "DASH",
		["HEADER_STAMINA"] = "STAMINA",
		
		["ITEM_HEIGHT"] = "HEIGHT",
		["ITEM_COST"] = "STAMINA COST",
		["ITEM_DOUBLE_JUMP"] = "DOUBLE JUMP",
		["ITEM_JUMP_COLOR"] = "JUMP COLOR",
		["ITEM_UNLOCK"] = "UNLOCK",
		["ITEM_DISTANCE"] = "DISTANCE",
		["ITEM_RANGE"] = "RANGE",
		["ITEM_COOLDOWN"] = "COOLDOWN",
		["ITEM_SPEED"] = "SPEED",
		["ITEM_DASH_COLOR"] = "DASH COLOR",
		["ITEM_AMOUNT"] = "AMOUNT",
		["ITEM_REGEN"] = "REGEN",
		["ITEM_EFFICIENCY"] = "EFFICIENCY"
	}
}

function Localization.get(key, lang, ...)
	local langData = languages[lang] or languages["en"]
	local text = langData[key] or key
	local success, result = pcall(string.format, text, ...)
	return success and result or text
end

return Localization