local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local SoundManager = {}

-- 1. BASE DE DATOS DE SONIDOS
local SOUNDS = {
	-- UI & HUD
	["CoinPop"]           = {Id = "rbxassetid://1169755927",       Vol = 2,   Group = "UI"},
	["AbilityReady"]      = {Id = "rbxassetid://137818744150574",  Vol = 0.5, Group = "UI"},
	["AbilityError"]      = {Id = "rbxassetid://90683869968677",   Vol = 0.5, Group = "UI"},
	["InsufficientFunds"] = {Id = "rbxassetid://90683869968677",   Vol = 1,   Group = "UI"},
	["Countdown"]         = {Id = "rbxassetid://1837831424",       Vol = 1,   Group = "UI"},
	["Go"]                = {Id = "rbxassetid://1837829473",       Vol = 1.5, Group = "UI"},
	["StaminaFull"]       = {Id = "rbxassetid://9114374439",       Vol = 1,   Group = "UI"},
	["StaminaEmpty"]      = {Id = "rbxassetid://140910216",       Vol = 1,   Group = "UI"},

	-- TIENDA
	["BuyUpgrade"]        = {Id = "rbxassetid://88761861442974",   Vol = 1,   Group = "UI"},
	["UnlockSkill"]       = {Id = "rbxassetid://87197772183227",   Vol = 1,   Group = "UI"},

	-- HABILIDADES
	["Dash"]              = {Id = "rbxassetid://9117879142",       Vol = 0.6, Group = "SFX"},
	["Push"]              = {Id = "rbxassetid://12222124",         Vol = 0.7, Group = "SFX"},

	-- JUEGO / AMBIENTE
	["Squish"]            = {Id = "rbxassetid://93903966058481",   Vol = 2,   Group = "SFX"},
	["LavaBurn"]          = {Id = "rbxassetid://105821519640087",  Vol = 0.4, Group = "SFX", Looped = true},
	["LavaBurn2"]         = {Id = "rbxassetid://78977014679422",   Vol = 0.4, Group = "SFX", Looped = true},
	["LavaAmbient"]       = {Id = "rbxassetid://318794788",        Vol = 0.3, Group = "SFX", Looped = true},
	["LavaRock"]          = {Id = "rbxassetid://124807383431117",  Vol = 0.5, Group = "SFX"},
	["LavaSmash"]         = {Id = "rbxassetid://8275560362",       Vol = 1,   Group = "SFX"},
	
	-- IMPACTOS
	["BlockImpact"]       = {Id = "rbxassetid://8828710739",       Vol = 1.5, Group = "SFX", Min = 50, Max = 500},
	["BlockBlink"]        = {Id = "rbxassetid://2124207508",       Vol = 0.5, Group = "SFX", Min = 20, Max = 200},

	-- MÚSICA
	["WaitingMusic"]      = {Id = "rbxassetid://1835782117",       Vol = 0.5, Group = "Music", Looped = true},
	["RoundMusic"]        = {Id = "rbxassetid://9044545570",       Vol = 0.5, Group = "Music", Looped = true},
	["VictoryMusic"]      = {Id = "rbxassetid://1844449787",       Vol = 0.6, Group = "Music", Looped = true},
}

-- 2. INICIALIZACIÓN DE GRUPOS Y CACHÉ
local groups = {}
local templateCache = {} 

local function setupGroups()
	local names = {"SFX", "UI", "Music"}
	for _, name in ipairs(names) do
		-- Intentamos buscar primero para no duplicar si el servidor ya lo creó
		local g = SoundService:FindFirstChild(name)
		if not g then
			g = Instance.new("SoundGroup")
			g.Name = name
			g.Parent = SoundService
		end
		groups[name] = g
	end
end
setupGroups()

-- 3. GENERAR INSTANCIAS (Para Pantalla de Carga)
function SoundManager.GetAssets()
	local assetsToLoad = {}
	
	for name, data in pairs(SOUNDS) do
		if not templateCache[name] then
			local s = Instance.new("Sound")
			s.Name = name
			s.SoundId = data.Id
			s.Volume = data.Vol
			s.SoundGroup = groups[data.Group]
			s.Looped = data.Looped or false
			
			if data.Min then s.RollOffMinDistance = data.Min end
			if data.Max then s.RollOffMaxDistance = data.Max end
			
			templateCache[name] = s
		end
		table.insert(assetsToLoad, templateCache[name])
	end
	
	return assetsToLoad
end

-- 4. REPRODUCIR
function SoundManager.Play(soundName, parent)
	local template = templateCache[soundName]
	
	-- Fallback: Si no está en caché (ej: Primera vez que suena en el Server)
	if not template then 
		local data = SOUNDS[soundName]
		if not data then
			warn("⚠️ SoundManager: Sonido no existe -> " .. tostring(soundName))
			return nil
		end
		
		local s = Instance.new("Sound")
		s.Name = soundName
		s.SoundId = data.Id
		s.Volume = data.Vol
		s.SoundGroup = groups[data.Group]
		s.Looped = data.Looped or false
		
		if data.Min then s.RollOffMinDistance = data.Min end
		if data.Max then s.RollOffMaxDistance = data.Max end
		
		template = s
		templateCache[soundName] = s 
	end
	
	-- Clonamos para reproducir independientemente
	local sound = template:Clone()
	
	if parent then
		sound.Parent = parent 
	else
		sound.Parent = SoundService 
	end
	
	sound:Play()
	
	-- LIMPIEZA AUTOMÁTICA (DEBRIS)
	if not sound.Looped then
		-- CORRECCIÓN CRÍTICA:
		-- Usamos math.max(..., 5) para dar un margen de seguridad de 5 segundos mínimo.
		-- Esto evita que si TimeLength es 0 (aún cargando), el sonido se borre instantáneamente.
		local safeTime = math.max(sound.TimeLength, 5) + 2
		Debris:AddItem(sound, safeTime)
	end
	
	return sound
end

-- 5. MÚSICA
local currentTrack = nil

function SoundManager.PlayMusic(musicName, fadeTime)
	fadeTime = fadeTime or 1
	
	-- Evitar reinicios si ya suena la misma música
	if currentTrack and currentTrack.Name == musicName then return end
	
	-- Apagar música anterior
	if currentTrack then
		local oldTrack = currentTrack
		currentTrack = nil 
		local tween = TweenService:Create(oldTrack, TweenInfo.new(fadeTime), {Volume = 0})
		tween:Play()
		tween.Completed:Connect(function() oldTrack:Destroy() end)
	end
	
	-- Iniciar nueva música
	if musicName then
		local newTrack = SoundManager.Play(musicName) 
		if newTrack then
			newTrack.Name = musicName
			newTrack.Looped = true -- Forzamos Looped por seguridad
			
			local targetVol = newTrack.Volume
			newTrack.Volume = 0
			TweenService:Create(newTrack, TweenInfo.new(fadeTime), {Volume = targetVol}):Play()
			
			currentTrack = newTrack
		end
	end
end

return SoundManager