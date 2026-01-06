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
	["LavaSmash2"]        = {Id = "rbxassetid://8275560362",       Vol = 1,   Group = "SFX"}, -- Nota: Es el mismo ID que LavaSmash, intencional?
	
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
local templateCache = {} -- Aquí guardaremos los sonidos listos para clonar

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

-- 3. PRECARGA (OPTIMIZADA)
function SoundManager.PreloadAll()
	task.spawn(function()
		local assetsToLoad = {}
		
		for name, data in pairs(SOUNDS) do
			-- Creamos el sonido "Plantilla" AHORA, no al reproducir
			local s = Instance.new("Sound")
			s.Name = name
			s.SoundId = data.Id
			s.Volume = data.Vol
			s.SoundGroup = groups[data.Group]
			s.Looped = data.Looped or false
			
			-- Configuramos distancias 3D por defecto en la plantilla
			if data.Min then s.RollOffMinDistance = data.Min end
			if data.Max then s.RollOffMaxDistance = data.Max end
			
			-- Lo guardamos en el caché
			templateCache[name] = s
			table.insert(assetsToLoad, s)
		end
		
		-- Pedimos a Roblox que descargue el audio de estas instancias
		local success, err = pcall(function()
			ContentProvider:PreloadAsync(assetsToLoad)
		end)
		
		if success then
			print("🔊 SoundManager: Assets cargados y cacheados sin delay.")
		else
			warn("⚠️ SoundManager: Error cargando sonidos: " .. tostring(err))
		end
	end)
end

-- 4. REPRODUCIR (CLONANDO)
function SoundManager.Play(soundName, parent)
	-- Buscamos en el caché (mucho más rápido que leer la tabla)
	local template = templateCache[soundName]
	
	if not template then 
		-- Fallback por si intentamos reproducir antes de que termine el Preload
		local data = SOUNDS[soundName]
		if not data then
			warn("⚠️ SoundManager: Sonido no existe -> " .. tostring(soundName))
			return nil
		end
		-- Creamos uno temporal de emergencia
		template = Instance.new("Sound")
		template.SoundId = data.Id
		template.Volume = data.Vol
		template.SoundGroup = groups[data.Group]
	end
	
	-- CLONAMOS LA PLANTILLA (Esto elimina el delay de instanciación)
	local sound = template:Clone()
	
	if parent then
		sound.Parent = parent -- Sonido 3D
	else
		sound.Parent = SoundService -- Sonido 2D
	end
	
	sound:Play()
	
	-- Limpieza automática
	if not sound.Looped then
		-- Usamos math.max para seguridad si TimeLength aún no cargó (aunque con el caché debería estar)
		local lifetime = math.max(sound.TimeLength, 1) + 1
		Debris:AddItem(sound, lifetime)
	end
	
	return sound
end

-- 5. SISTEMA DE MÚSICA
local currentTrack = nil

function SoundManager.PlayMusic(musicName, fadeTime)
	fadeTime = fadeTime or 1
	
	-- Si ya suena la misma música, no hacemos nada
	if currentTrack and currentTrack.Name == musicName then return end
	
	-- Apagar música anterior
	if currentTrack then
		local oldTrack = currentTrack
		-- Desconectamos la referencia global para que no interfiera
		currentTrack = nil 
		
		local tween = TweenService:Create(oldTrack, TweenInfo.new(fadeTime), {Volume = 0})
		tween:Play()
		tween.Completed:Connect(function()
			oldTrack:Destroy()
		end)
	end
	
	-- Iniciar nueva música
	if musicName then
		local newTrack = SoundManager.Play(musicName) -- Esto usa el sistema de clones
		if newTrack then
			newTrack.Name = musicName
			-- Fade In
			local targetVol = newTrack.Volume
			newTrack.Volume = 0
			TweenService:Create(newTrack, TweenInfo.new(fadeTime), {Volume = targetVol}):Play()
			
			currentTrack = newTrack
		end
	end
end

return SoundManager