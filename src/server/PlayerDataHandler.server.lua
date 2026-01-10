local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

-- [NUEVO] Referencia al evento de equipar
local equipEvent = ReplicatedStorage:FindFirstChild("EquipAbilityEvent")
if not equipEvent then
	equipEvent = Instance.new("RemoteEvent")
	equipEvent.Name = "EquipAbilityEvent"
	equipEvent.Parent = ReplicatedStorage
end

-- CONFIGURACIÓN
local DATA_VERSION = "BETA1.7" -- Incrementamos versión para asegurar datos limpios si es necesario
local MyDataStore = DataStoreService:GetDataStore("PlayerData_" .. DATA_VERSION)

local DefaultData = {
	Coins = 70000,
	Wins = 0,
	
	-- [NUEVO] Aquí guardamos el inventario activo
	Loadout = {
		Slot1 = nil,
		Slot2 = nil,
		Slot3 = nil
	},
	
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
		
		BonkUnlock = false,
		BonkStun = 1,
		BonkCooldown = 1,
		BonkColor = 1,
		
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
-- SINCRONIZADOR DE ATRIBUTOS
-------------------------------------------------------------------------------
local function syncAttributes(player, data)
	if not player or not data then return end
	
	-- 1. Sincronizar Upgrades (Stats y Desbloqueos)
	for key, level in pairs(data.Upgrades) do
		-- Stats Numéricos
		if ShopConfig.Stats[key] and type(ShopConfig.Stats[key]) == "table" then
			local safeLevel = math.clamp(level, 1, #ShopConfig.Stats[key])
			local realValue = ShopConfig.Stats[key][safeLevel]
			player:SetAttribute(key, realValue)
			
		-- Booleanos
		elseif type(level) == "boolean" then
			player:SetAttribute(key, level)
			
		-- Colores
		elseif type(level) == "table" and level.R then
			local color = Color3.new(level.R, level.G, level.B)
			player:SetAttribute(key, color)
		end
	end
	
	-- 2. [NUEVO] Sincronizar Loadout (Inventario)
	if data.Loadout then
		player:SetAttribute("EquippedSlot1", data.Loadout.Slot1)
		player:SetAttribute("EquippedSlot2", data.Loadout.Slot2)
		player:SetAttribute("EquippedSlot3", data.Loadout.Slot3)
	end
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
	syncAttributes(player, sessionData[player.UserId])
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

-- API EXTERNA (Bindables para otros scripts del server)
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
				syncAttributes(player, data)
			end
		end
	end
end)

-- [NUEVO] EVENTO REMOTO PARA GUARDAR EL INVENTARIO (Desde el Cliente)
equipEvent.OnServerEvent:Connect(function(player, slotNum, abilityName)
	local data = sessionData[player.UserId]
	if not data then return end
	
	local slotKey = "Slot" .. slotNum
	
	-- Verificar que el jugador realmente tiene desbloqueada la habilidad
	if abilityName then
		local unlockKey = abilityName .. "Unlock"
		-- Excepción para habilidades que no requieren unlock (ej. si hubiera alguna básica)
		-- Pero en tu juego Push, Dash y Bonk requieren Unlock.
		if data.Upgrades[unlockKey] == true then
			data.Loadout[slotKey] = abilityName
			player:SetAttribute("EquippedSlot" .. slotNum, abilityName)
			print(player.Name .. " equipó " .. abilityName .. " en " .. slotKey)
		else
			warn(player.Name .. " intentó equipar " .. abilityName .. " sin tenerla desbloqueada.")
		end
	else
		-- Si abilityName es nil, significa desequipar
		data.Loadout[slotKey] = nil
		player:SetAttribute("EquippedSlot" .. slotNum, nil)
		print(player.Name .. " desequipó " .. slotKey)
	end
end)