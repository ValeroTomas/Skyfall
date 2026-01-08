local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService") 

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

-- IMPORTAMOS LA LISTA VIP DESDE SHARED
local VipList = require(sharedFolder:WaitForChild("VipList"))

-- ID DEL GAME PASS "CUSTOM COLORS!"
local GAME_PASS_ID = 1663859003 

local shopFunction = ReplicatedStorage:FindFirstChild("ShopFunction")
if not shopFunction then
	shopFunction = Instance.new("RemoteFunction")
	shopFunction.Name = "ShopFunction"
	shopFunction.Parent = ReplicatedStorage
end

local eventsFolder = ServerStorage:WaitForChild("PlayerDataEvents")
local getStat = eventsFolder:WaitForChild("GetPlayerStat")
local setStat = eventsFolder:WaitForChild("SetPlayerStat")

-- MAPEO RÁPIDO PARA PRODUCT RECEIPT
local PRODUCT_MAP = {}
for _, p in ipairs(ShopConfig.CoinProducts) do
	PRODUCT_MAP[p.ProductId] = p.Amount
end

function shopFunction.OnServerInvoke(player, action, upgradeName, extraData)
	-- 1. PEDIR DATOS
	if action == "GetData" then
		return getStat:Invoke(player, "Upgrades")
	
	-- 2. COMPRAR (Habilidades/Mejoras con Monedas)
	elseif action == "BuyUpgrade" then
		local coins = getStat:Invoke(player, "Coins") or 0
		local upgrades = getStat:Invoke(player, "Upgrades")
		local price = 0
		local currentLevel = upgrades[upgradeName]
		
		-- VALIDACIÓN DE DEPENDENCIAS
		if (upgradeName:match("Push") and upgradeName ~= "PushUnlock") and upgrades.PushUnlock ~= true then
			return false, "Desbloquea Empuje primero"
		end
		if (upgradeName:match("Dash") and upgradeName ~= "DashUnlock") and upgrades.DashUnlock ~= true then
			return false, "Desbloquea Esquive primero"
		end
		-- [NUEVO] VALIDACIÓN PARA BONK
		if (upgradeName:match("Bonk") and upgradeName ~= "BonkUnlock") and upgrades.BonkUnlock ~= true then
			return false, "Desbloquea Bonk primero"
		end

		-- PRECIO
		-- Verificamos si es item especial, desbloqueo o habilidad única
		if ShopConfig.SpecialItems[upgradeName] or upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
			if currentLevel == true then return false, "Ya tienes esto" end
			price = ShopConfig.Prices[upgradeName]
		else
			-- Es una mejora de nivel (1-5)
			currentLevel = currentLevel or 1
			if currentLevel >= ShopConfig.MAX_LEVEL then return false, "Max Level" end
			price = ShopConfig.Prices[upgradeName][currentLevel]
		end
		
		if not price then return false, "Error precio" end
		
		-- TRANSACCIÓN
		if coins >= price then
			setStat:Fire(player, "Coins", coins - price)
			
			if ShopConfig.SpecialItems[upgradeName] then
				-- Se compra el ítem especial
				setStat:Fire(player, "Upgrades", upgradeName, true)
				return true, "Compra Exitosa"
			elseif upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
				setStat:Fire(player, "Upgrades", upgradeName, true)
			else
				setStat:Fire(player, "Upgrades", upgradeName, currentLevel + 1)
			end
			
			return true, "Compra Exitosa"
		else
			return false, "Faltan Monedas"
		end
	end
	return false
end

-- EVENTO DE GUARDADO DE COLOR (VIP + GAME PASS)
local colorEvent = ReplicatedStorage:FindFirstChild("ColorUpdateEvent")
if not colorEvent then
	colorEvent = Instance.new("RemoteEvent")
	colorEvent.Name = "ColorUpdateEvent"
	colorEvent.Parent = ReplicatedStorage
end

colorEvent.OnServerEvent:Connect(function(player, itemType, r, g, b)
	local hasPass = false
	
	-- A. Check VIP
	if VipList.IsVip(player.UserId) then
		hasPass = true
		print("👑 Acceso VIP concedido a: " .. player.Name)
	else
		-- B. Check Game Pass
		local success, err = pcall(function()
			hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
		end)
	end

	if not hasPass then
		warn("⚠️ Jugador " .. player.Name .. " intentó cambiar color sin permisos.")
		return 
	end

	local upgrades = getStat:Invoke(player, "Upgrades")
	local keyToSave = nil
	
	-- Validamos que tenga la habilidad desbloqueada antes de guardar su color
	if itemType == "DoubleJump" and upgrades.DoubleJump == true then
		keyToSave = "DoubleJumpColor"
	elseif itemType == "Dash" and upgrades.DashUnlock == true then
		keyToSave = "DashColor"
	-- [NUEVO] VALIDACIÓN BONK
	elseif itemType == "Bonk" and upgrades.BonkUnlock == true then
		keyToSave = "BonkColor"
	end
	
	if keyToSave then
		local colorData = {R = r, G = g, B = b}
		setStat:Fire(player, "Upgrades", keyToSave, colorData)
		print("🎨 Color guardado para " .. player.Name .. " (" .. keyToSave .. "):", r, g, b)
		
		if player.Character then
			local newColor = Color3.new(r, g, b)
			player:SetAttribute(keyToSave, newColor)
		end
	end
end)

-- PROCESAMIENTO DE COMPRAS DE ROBUX (Developer Products)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	
	local player = Players:GetPlayerByUserId(playerId)
	
	-- Verificar si el producto comprado es uno de nuestros paquetes de monedas
	local amountToGive = PRODUCT_MAP[productId]
	
	if amountToGive and player then
		-- Entregar Monedas
		local currentCoins = getStat:Invoke(player, "Coins") or 0
		setStat:Fire(player, "Coins", currentCoins + amountToGive)
		
		print("💰 Compra procesada: " .. player.Name .. " recibió " .. amountToGive .. " monedas.")
		
		-- Feedback visual
		local rewardEvent = ReplicatedStorage:FindFirstChild("RewardEvent")
		if rewardEvent then
			rewardEvent:FireClient(player, amountToGive)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end