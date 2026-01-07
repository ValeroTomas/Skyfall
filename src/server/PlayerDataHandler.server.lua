local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

-- CONFIGURACIÓN
local DATA_VERSION = "BETA1.2" -- Si cambiaste versión, asegúrate de mantener la misma
local MyDataStore = DataStoreService:GetDataStore("PlayerData_" .. DATA_VERSION)

local DefaultData = {
	Coins = 999999,
	Wins = 0,
	Upgrades = {
		JumpHeight = 1,
		JumpStaminaCost = 1,
		DoubleJump = false,
		DoubleJumpColor = 1, 
		
		PushUnlock = false,
		PushDistance = 1,
		PushRange = 1,
		PushCooldown = 1,
		
		DashUnlock = false,
		DashCooldown = 1,
		DashDistance = 1,
		DashSpeed = 1,
		DashColor = 1,
		
		MaxStamina = 1,
		StaminaRegen = 1,
		StaminaDrain = 1,
	}
}

local sessionData = {}

local eventsFolder = ServerStorage:FindFirstChild("PlayerDataEvents")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "PlayerDataEvents"
	eventsFolder.Parent = ServerStorage
end

local getFunction = Instance.new("BindableFunction")
getFunction.Name = "GetPlayerStat"
getFunction.Parent = eventsFolder

local setFunction = Instance.new("BindableEvent")
setFunction.Name = "SetPlayerStat"
setFunction.Parent = eventsFolder

-- Funciones de Utilidad
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then v = deepCopy(v) end
		copy[k] = v
	end
	return copy
end

local function reconcile(target, template)
	for k, v in pairs(template) do
		if target[k] == nil then
			if type(v) == "table" then target[k] = deepCopy(v) else target[k] = v end
		elseif type(target[k]) == "table" and type(v) == "table" then
			reconcile(target[k], v)
		end
	end
end

-------------------------------------------------------------------------------
-- SINCRONIZADOR DE ATRIBUTOS (MEJORADO PARA COLORES)
-------------------------------------------------------------------------------
local function syncAttributes(player, upgrades)
	if not player or not upgrades then return end
	
	for key, level in pairs(upgrades) do
		-- 1. Stats Numéricos (Niveles -> Valores Reales)
		if ShopConfig.Stats[key] then
			local safeLevel = math.clamp(level, 1, #ShopConfig.Stats[key])
			local realValue = ShopConfig.Stats[key][safeLevel]
			player:SetAttribute(key, realValue)
			
		-- 2. Booleanos (Desbloqueos)
		elseif type(level) == "boolean" then
			player:SetAttribute(key, level)
			
		-- 3. COLORES (Tablas RGB -> Color3) [NUEVO]
		-- Detectamos si es una tabla y tiene componente R (Rojo)
		elseif type(level) == "table" and level.R then
			local color = Color3.new(level.R, level.G, level.B)
			player:SetAttribute(key, color)
		end
	end
	
	-- print("🔄 Stats sincronizados para " .. player.Name)
end

-- CARGAR DATOS
local function setupPlayer(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function() return MyDataStore:GetAsync(key) end)

	if success and data then
		reconcile(data, DefaultData)
		sessionData[player.UserId] = data
		print("💾 Datos cargados para " .. player.Name)
	else
		sessionData[player.UserId] = deepCopy(DefaultData)
		print("✨ Jugador nuevo: " .. player.Name)
	end

	-- Leaderstats
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	
	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = sessionData[player.UserId].Coins
	coinsVal.Parent = ls

	local winsVal = Instance.new("IntValue")
	winsVal.Name = "Wins"
	winsVal.Value = sessionData[player.UserId].Wins
	winsVal.Parent = ls
	
	-- SINCRONIZACIÓN INICIAL
	syncAttributes(player, sessionData[player.UserId].Upgrades)
end

local function savePlayer(player)
	if not sessionData[player.UserId] then return end
	local key = "Player_" .. player.UserId
	
	local success, err = pcall(function() 
		MyDataStore:SetAsync(key, sessionData[player.UserId]) 
	end)
	
	if success then
		print("✅ Datos guardados para " .. player.Name)
	else
		warn("❌ Error guardando datos: " .. tostring(err))
	end
	
	sessionData[player.UserId] = nil
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function() 
	print("🛑 Servidor cerrando...")
	for _, p in ipairs(Players:GetPlayers()) do savePlayer(p) end
	task.wait(2) 
end)

-- API EXTERNA
getFunction.OnInvoke = function(player, category, subKey)
	local data = sessionData[player.UserId]
	if not data then return nil end
	if subKey and data[category] then return data[category][subKey] end
	return data[category]
end

setFunction.Event:Connect(function(player, category, subKey, value)
	local data = sessionData[player.UserId]
	if not data then return end
	
	if value == nil then 
		local val = subKey
		data[category] = val
		if category == "Coins" then player.leaderstats.Coins.Value = val end
		if category == "Wins" then player.leaderstats.Wins.Value = val end
	else
		if data[category] then
			data[category][subKey] = value
			
			-- SI ACTUALIZAMOS UPGRADES, RESINCRONIZAR ATRIBUTOS
			if category == "Upgrades" then
				syncAttributes(player, data.Upgrades)
			end
		end
	end
end)