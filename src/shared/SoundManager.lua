local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local SoundManager = {}

-- Tabla para controlar música por canales (1: Fondo, 2: Eventos)
local activeMusic = {} 

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
	["StaminaEmpty"]      = {Id = "rbxassetid://140910216",        Vol = 1,   Group = "UI"},
	["WinnerMap"]        = {Id = "rbxassetid://6161421479",       Vol = 1,   Group = "UI"},
	
	-- RULETA (UI)
	["RouletteWin"]       = {Id = "rbxassetid://126557239554258",  Vol = 1,   Group = "UI"},
	["RouletteSpin"]      = {Id = "rbxassetid://116441689318579",       Vol = 1,   Group = "UI"},
	["RouletteTick"]      = {Id = "rbxassetid://116441689318579",       Vol = 0.3,   Group = "UI"},
	["RouletteStop"]      = {Id = "rbxassetid://4612375233",       Vol = 1,   Group = "UI"},

	-- TIENDA
	["BuyUpgrade"]        = {Id = "rbxassetid://5852470908",   Vol = 1,   Group = "UI"},
	["UnlockSkill"]       = {Id = "rbxassetid://87197772183227",   Vol = 1,   Group = "UI"},
	["ShopButton"]        = {Id = "rbxassetid://5852470908",         Vol = 0.5, Group = "UI"},
	["NoMoney"]           = {Id = "rbxassetid://8968249849",   Vol = 0.7, Group = "UI"},

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
	["PotatoBeep"]        = {Id = "rbxassetid://9113880610",       Vol = 1.5, Group = "SFX"},
	["PotatoExplode"]     = {Id = "rbxassetid://5137964328",       Vol = 2,   Group = "SFX"},
	["PotatoPass"]        = {Id = "rbxassetid://17481582653",      Vol = 1,   Group = "SFX"},
	["Splash"]            = {Id = "rbxassetid://4909796009",       Vol = 1.5, Group = "SFX"},
	
	-- IMPACTOS
	["BlockImpact"]       = {Id = "rbxassetid://8828710739",       Vol = 1.5, Group = "SFX", Min = 50, Max = 500},
	["IceBlockImpact1"]   = {Id = "rbxassetid://9114857307",       Vol = 1.5, Group = "SFX", Min = 20, Max = 200},
	["IceBlockImpact2"]   = {Id = "rbxassetid://107467482558699",  Vol = 1.2, Group = "SFX", Min = 20, Max = 200},
	["BlockBlink"]        = {Id = "rbxassetid://2124207508",       Vol = 0.5, Group = "SFX", Min = 20, Max = 200},
	["BatSwing"]          = {Id = "rbxassetid://4571259077",       Vol = 3,   Group = "SFX"},
	["BatHit"]            = {Id = "rbxassetid://5148302439",       Vol = 1.5, Group = "SFX"},
	["MagmaExplosion"]    = {Id = "rbxassetid://3802269741",       Vol = 2,   Group = "SFX"},
	["MagmaSpawn1"]       = {Id = "rbxassetid://142431247",       Vol = 4,   Group = "SFX"},
	["MagmaSpawn2"]       = {Id = "rbxassetid://9066038215",       Vol = 1,   Group = "SFX"},

	-- MÚSICA
	["WaitingMusic"]      = {Id = "rbxassetid://1835782117",       Vol = 0.5, Group = "Music", Looped = true},
	["RoundMusic"]        = {Id = "rbxassetid://9044545570",       Vol = 0.5, Group = "Music", Looped = true},

	-- [CORRECCIÓN] VictoryMusic ahora NO TIENE LOOP. Suena una vez y listo.
	["VictoryMusic"]      = {Id = "rbxassetid://1844449787",       Vol = 0.6, Group = "Music", Looped = false}, 
	["IceEventStart"]     = {Id = "rbxassetid://15749927835",      Vol = 0.5, Group = "Music"},
}

-- 2. INICIALIZACIÓN DE GRUPOS Y CACHÉ
local groups = {}
local templateCache = {} 

local function setupGroups()
	local names = {"SFX", "UI", "Music"}
	for _, name in ipairs(names) do
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

-- 3. HELPER PARA OBTENER DATOS
function SoundManager.Get(name)
	if SOUNDS[name] then return SOUNDS[name].Id end
	return nil
end

-- 4. GENERAR INSTANCIAS
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

-- 5. REPRODUCIR SONIDO (SFX)
function SoundManager.Play(soundName, parent)
	local template = templateCache[soundName]
	if not template then 
		local data = SOUNDS[soundName]
		if not data then return nil end
		local s = Instance.new("Sound")
		s.Name = soundName; s.SoundId = data.Id; s.Volume = data.Vol
		s.SoundGroup = groups[data.Group]; s.Looped = data.Looped or false
		if data.Min then s.RollOffMinDistance = data.Min end
		if data.Max then s.RollOffMaxDistance = data.Max end
		template = s; templateCache[soundName] = s 
	end
	
	local sound = template:Clone()
	if parent then sound.Parent = parent else sound.Parent = SoundService end
	sound:Play()
	if not sound.Looped then
		local safeTime = math.max(sound.TimeLength, 5) + 2
		Debris:AddItem(sound, safeTime)
	end
	return sound
end

-- 6. SISTEMA DE MÚSICA
function SoundManager.PlayMusic(musicName, channel, fadeTime)
	channel = channel or 1
	fadeTime = fadeTime or 1
	
	if activeMusic[channel] and activeMusic[channel].Name == musicName then return end
	SoundManager.StopMusic(channel, fadeTime)
	
	local newTrack = SoundManager.Play(musicName)
	if newTrack then
		newTrack.Name = musicName
		newTrack.Parent = SoundService 
		local targetVol = newTrack.Volume
		newTrack.Volume = 0
		TweenService:Create(newTrack, TweenInfo.new(fadeTime), {Volume = targetVol}):Play()
		activeMusic[channel] = newTrack
	end
end

function SoundManager.StopMusic(channel, fadeTime)
	channel = channel or 1
	fadeTime = fadeTime or 0.5
	
	local oldTrack = activeMusic[channel]
	if oldTrack then
		activeMusic[channel] = nil 
		if oldTrack.Parent then
			local tween = TweenService:Create(oldTrack, TweenInfo.new(fadeTime), {Volume = 0})
			tween:Play()
			tween.Completed:Connect(function() oldTrack:Destroy() end)
		end
	end
end

return SoundManager