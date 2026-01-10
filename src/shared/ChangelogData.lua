local ChangelogData = {}

-- 1. PALETA DE COLORES
local C_TITLE = "rgb(255, 220, 0)"   -- Dorado (Título del Parche)
local C_SUB   = "rgb(0, 200, 255)"   -- Cyan (Secciones)
local C_TEXT  = "rgb(230, 230, 230)" -- Blanco (Texto)
local C_GRAY  = "rgb(150, 150, 160)" -- Gris (Pie de página / Separadores)

-- 2. HELPERS DE FORMATO HTML
local function FmtTitle(text)
	return string.format('<font size="32" color="%s"><b>%s</b></font><br />', C_TITLE, text)
end

local function FmtSection(text)
	return string.format('<br /><font size="22" color="%s"><b>%s</b></font>', C_SUB, text)
end

local function FmtBody(text)
	return string.format('<font size="18" color="%s">%s</font>', C_TEXT, text)
end

local function FmtSeparator()
	return string.format('<br /><br /><font color="%s">_______________________________________</font><br /><br />', C_GRAY)
end

-- 3. HISTORIAL DE PARCHES
-- [INSTRUCCIONES]: Para agregar un nuevo parche, copia un bloque entero dentro de las llaves {}
-- y pégalo ARRIBA del todo (dentro de PATCH_LIST) para que salga primero.
local PATCH_LIST = {
	
	-- === PARCHE MÁS NUEVO AQUÍ ===
	{
		Version = "PARCHE 0.9: TÍTULO DE PRUEBA",
		Content = {
			{
				Header = "HEADER DE PRUEBA",
				Body = [[
• Nahu se la <b>come</b>.
				]]
			},
		}
	},	
}

-- 4. GENERADOR DE TEXTO (No tocar esto)
function ChangelogData.GetText()
	local finalString = ""
	
	for i, patch in ipairs(PATCH_LIST) do
		-- Agregar Título del Parche
		finalString = finalString .. FmtTitle(patch.Version)
		
		-- Agregar cada sección del parche
		for _, section in ipairs(patch.Content) do
			finalString = finalString .. FmtSection(section.Header) .. FmtBody(section.Body)
		end
		
		-- Si no es el último parche de la lista, poner una línea separadora
		if i < #PATCH_LIST then
			finalString = finalString .. FmtSeparator()
		end
	end
	
	-- Pie de página global
	finalString = finalString .. string.format('<br /><br /><br /><font size="16" color="%s"><i>¡Gracias por jugar!</i></font>', C_GRAY)
	
	return finalString
end

return ChangelogData