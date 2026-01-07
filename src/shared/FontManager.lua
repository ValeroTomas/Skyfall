local FontManager = {}

-- DICCIONARIO DE FUENTES
local FONTS = {
	["Cartoon"] = "rbxassetid://12187370000",
	-- Acá agregamos más en el futuro
}

-- Obtener un objeto Font utilizable
function FontManager.Get(fontName)
	local id = FONTS[fontName]
	if not id then
		warn("⚠️ FontManager: Fuente no encontrada -> " .. tostring(fontName))
		return Enum.Font.SourceSansBold -- Fallback
	end
	return Font.new(id)
end

-- Para la Pantalla de Carga (Devuelve lista de IDs)
function FontManager.GetAssets()
	local assets = {}
	for _, id in pairs(FONTS) do
		table.insert(assets, id) -- ContentProvider acepta Strings de fuentes
	end
	return assets
end

return FontManager