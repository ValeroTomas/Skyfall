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
	return string.format('<br /><font size="22" color="%s"><b>%s</b></font><br />', C_SUB, text)
end

local function FmtBody(text)
	return string.format('<font size="18" color="%s">%s</font>', C_TEXT, text)
end

local function FmtSeparator()
	return string.format('<br /><br /><font color="%s">_______________________________________</font><br /><br />', C_GRAY)
end

-- 3. HISTORIAL DE PARCHES
-- Ahora cada campo de texto tiene [es] y [en]
local PATCH_LIST = {
	
	-- === PARCHE DE LANZAMIENTO ===
	{
		Version = {
			es = "VERSIÓN 0.9: PRE-RELEASE",
			en = "VERSION 0.9: PRE-RELEASE"
		},
		Content = {
			{
				Header = {
					es = "¡BIENVENIDOS A SKYFALL!",
					en = "WELCOME TO SKYFALL!"
				},
				Body = {
					es = [[
Gracias por jugar el lanzamiento anticipado. 
El objetivo es sobrevivir a la caída de bloques y a los eventos aleatorios.
¡Compite por ser el último en pie!
					]],
					en = [[
Thanks for playing the early access release. 
The goal is to survive the falling blocks and random events.
Compete to be the last one standing!
					]]
				}
			},
			{
				Header = {
					es = "NOVEDADES",
					en = "WHAT'S NEW"
				},
				Body = {
					es = [[
• <b>Mapas:</b> Pozo de Lava y Piscina Sinfín.
• <b>Eventos:</b> Lluvia de Magma, Hielo y Patata Caliente.
• <b>Tienda:</b> Compra habilidades (Empuje, Dash, Bate) y mejora tus stats.
• <b>Cosméticos:</b> ¡Personaliza los colores de tus habilidades!
					]],
					en = [[
• <b>Maps:</b> Lava Pit and Endless Pool.
• <b>Events:</b> Magma Rain, Ice, and Hot Potato.
• <b>Shop:</b> Buy abilities (Push, Dash, Bonk) and upgrade your stats.
• <b>Cosmetics:</b> Customize your ability colors!
					]]
				}
			},
			{
				Header = {
					es = "ESTADO BETA",
					en = "BETA STATUS"
				},
				Body = {
					es = [[
El juego está en desarrollo activo. 
Si encuentras errores o tienes sugerencias, no dudes en comentarlo.
					]],
					en = [[
The game is in active development. 
If you find bugs or have suggestions, feel free to share them.
					]]
				}
			}
		}
	},	
}

-- 4. GENERADOR DE TEXTO (Adaptado para idioma)
function ChangelogData.GetText(lang)
	-- Default a inglés si el idioma no es español
	if lang ~= "es" then lang = "en" end
	
	local finalString = ""
	
	for i, patch in ipairs(PATCH_LIST) do
		-- Seleccionar texto según idioma
		local vText = patch.Version[lang] or patch.Version["en"]
		finalString = finalString .. FmtTitle(vText)
		
		for _, section in ipairs(patch.Content) do
			local hText = section.Header[lang] or section.Header["en"]
			local bText = section.Body[lang] or section.Body["en"]
			finalString = finalString .. FmtSection(hText) .. FmtBody(bText)
		end
		
		if i < #PATCH_LIST then
			finalString = finalString .. FmtSeparator()
		end
	end
	
	local footerText = (lang == "es") and "¡Gracias por jugar!" or "Thanks for playing!"
	finalString = finalString .. string.format('<br /><br /><br /><font size="16" color="%s"><i>%s</i></font>', C_GRAY, footerText)
	
	return finalString
end

return ChangelogData