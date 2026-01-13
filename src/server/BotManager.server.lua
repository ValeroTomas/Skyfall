local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

local TARGET_PLAYERS = 5
local BOT_NAMES = {
	["BOT1"] = "[BOT] Phoenix",
	["BOT2"] = "[BOT] Waldo", 
	["BOT3"] = "[BOT] Nahu",
	["BOT4"] = "[BOT] Joel"
}
local ABILITIES = {"Push", "Dash", "Bonk"} 

local botsFolder = workspace:FindFirstChild("ActiveBots") or Instance.new("Folder", workspace)
botsFolder.Name = "ActiveBots"

local function getRandomLoadout(botModel)
	local slot1 = ABILITIES[math.random(1, #ABILITIES)]
	local slot2 = ABILITIES[math.random(1, #ABILITIES)]
	local slot3 = ABILITIES[math.random(1, #ABILITIES)]
	
	botModel:SetAttribute("EquippedSlot1", slot1)
	botModel:SetAttribute("EquippedSlot2", slot2)
	botModel:SetAttribute("EquippedSlot3", slot3)
	
	botModel:SetAttribute("MaxStamina", 100)
	botModel:SetAttribute("CurrentStamina", 100)
	botModel:SetAttribute("IsExhausted", false)
	botModel:SetAttribute("WantsToSprint", false)
	
	botModel:SetAttribute("DoubleJump", true)
	botModel:SetAttribute("JumpHeight", 52) -- [MEJORA] Salto base más fuerte
	
	-- [NUEVO] COLORES PARA TRAILS
	local botColors = {
		Color3.fromRGB(255, 100, 100), -- Rojo para Waldo
		Color3.fromRGB(255, 150, 50),  -- Naranja para Phoenix
		Color3.fromRGB(100, 255, 100), -- Verde para Nahu
		Color3.fromRGB(100, 150, 255)  -- Azul para Joel
	}
	-- Asignar color según el bot que se está configurando
	local botIndex = 0
	if botModel.Name == "[BOT] Waldo" then botIndex = 1
	elseif botModel.Name == "[BOT] Phoenix" then botIndex = 2
	elseif botModel.Name == "[BOT] Nahu" then botIndex = 3
	elseif botModel.Name == "[BOT] Joel" then botIndex = 4
	end
	
	if botIndex > 0 then
		local botColor = botColors[botIndex]
		botModel:SetAttribute("DoubleJumpColor", botColor)
		botModel:SetAttribute("DashColor", botColor)
	end
	
	botModel:SetAttribute("PushUnlock", true)
	botModel:SetAttribute("DashUnlock", true)
	botModel:SetAttribute("BonkUnlock", true)
	
	botModel:SetAttribute("PushCooldown", 6)
	botModel:SetAttribute("DashCooldown", 5)
	botModel:SetAttribute("BonkCooldown", 8)
	
	botModel:SetAttribute("PushDistance", 90)
	botModel:SetAttribute("DashDistance", 60)
	botModel:SetAttribute("DashSpeed", 1.5)
end

local function spawnBot()
	-- Encontrar qué bots ya están activos para evitar duplicados
	local activeBotNames = {}
	for _, activeBot in ipairs(botsFolder:GetChildren()) do
		activeBotNames[activeBot.Name] = true
	end
	
	-- Buscar un bot template que no esté ya activo
	local botTemplate = nil
	local botName = nil
	
	for i = 1, 4 do
		local template = ServerStorage:FindFirstChild("BOT" .. i)
		local name = BOT_NAMES["BOT" .. i]
		if template and name and not activeBotNames[name] then
			botTemplate = template
			botName = name
			break
		end
	end
	
	if not botTemplate then return end
	
	local bot = botTemplate:Clone()
	bot.Name = botName
	
	bot:PivotTo(CFrame.new(0, 80, 0)) 
	bot.Parent = botsFolder
	
	-- Configurar Humanoid para salto fuerte
	local hum = bot:WaitForChild("Humanoid")
	hum.UseJumpPower = true
	hum.JumpPower = 60 -- Fuerza física base
	
	-- Network Owner al servidor (Anti-Lag)
	local hrp = bot:WaitForChild("HumanoidRootPart", 5)
	if hrp then hrp:SetNetworkOwner(nil) end
	
	-- Configurar evento de muerte para limpiar correctamente
	hum.Died:Connect(function()
		-- Marcar como muerto inmediatamente
		bot:SetAttribute("IsDead", true)
		
		-- Esperar un momento antes de eliminar para permitir que el DeathHandler procese
		task.wait(2)
		if bot and bot.Parent then
			bot:Destroy()
		end
	end)
	
	-- Solo agregar el tag "Bot" cuando esté en el juego activo
	CollectionService:AddTag(bot, "Bot")
	bot:SetAttribute("IsActive", true)
	getRandomLoadout(bot)
end

local function updatePopulation()
	local rawState = estadoValue.Value
	local state = string.split(rawState, "|")[1]
	
	-- [CORRECCIÓN] Permitir spawn en WAITING y STARTING, pero no en SURVIVE
	if state == "SURVIVE" or state == "WINNER" or state == "TIE" then return end

	local humanCount = #Players:GetPlayers()
	local botCount = #botsFolder:GetChildren()
	local total = humanCount + botCount
	
	if total < TARGET_PLAYERS then
		local needed = TARGET_PLAYERS - total
		for i = 1, needed do
			spawnBot()
			task.wait(0.1)
		end
	elseif total > TARGET_PLAYERS then
		local extra = total - TARGET_PLAYERS
		local bots = botsFolder:GetChildren()
		for i = 1, extra do 
			if bots[i] then bots[i]:Destroy() end
		end
	end
end

Players.PlayerAdded:Connect(updatePopulation)
Players.PlayerRemoving:Connect(updatePopulation)

estadoValue.Changed:Connect(function(val)
	local state = string.split(val, "|")[1]
	
	-- Chequear población al cambiar de estado (Lobby o Inicio)
	if state == "WAITING" or state == "STARTING" then
		-- Limpieza preventiva
		for _, b in ipairs(botsFolder:GetChildren()) do
			local h = b:FindFirstChild("Humanoid")
			if not h or h.Health <= 0 then b:Destroy() end
		end
		task.wait(0.2)
		updatePopulation()
	end
end)