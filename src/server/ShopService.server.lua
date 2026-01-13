local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService") 

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))
local VipList = require(sharedFolder:WaitForChild("VipList"))

-- IDs
local COLOR_GAME_PASS_ID = 1663859003 
local SHINY_GAME_PASS_ID = 1669617297 -- [NUEVO]

local shopFunction = ReplicatedStorage:FindFirstChild("ShopFunction")
if not shopFunction then
	shopFunction = Instance.new("RemoteFunction")
	shopFunction.Name = "ShopFunction"
	shopFunction.Parent = ReplicatedStorage
end

-- [NUEVO] Evento para el switch de Shiny
local shinyEvent = ReplicatedStorage:FindFirstChild("ToggleShinyEvent")
if not shinyEvent then
	shinyEvent = Instance.new("RemoteEvent")
	shinyEvent.Name = "ToggleShinyEvent"
	shinyEvent.Parent = ReplicatedStorage
end

local eventsFolder = ServerStorage:WaitForChild("PlayerDataEvents")
local getStat = eventsFolder:WaitForChild("GetPlayerStat")
local setStat = eventsFolder:WaitForChild("SetPlayerStat")

local PRODUCT_MAP = {}
for _, p in ipairs(ShopConfig.CoinProducts) do
	PRODUCT_MAP[p.ProductId] = p.Amount
end

-- 1. FUNCIÓN DE TIENDA (COMPRAS NORMALES)
function shopFunction.OnServerInvoke(player, action, upgradeName)
	if action == "GetData" then
		return getStat:Invoke(player, "Upgrades")
	
	elseif action == "BuyUpgrade" then
		local coins = getStat:Invoke(player, "Coins") or 0
		local upgrades = getStat:Invoke(player, "Upgrades")
		local price = 0
		local currentLevel = upgrades[upgradeName]
		
		-- Validaciones
		if (upgradeName:match("Push") and upgradeName ~= "PushUnlock") and upgrades.PushUnlock ~= true then return false, "Locked" end
		if (upgradeName:match("Dash") and upgradeName ~= "DashUnlock") and upgrades.DashUnlock ~= true then return false, "Locked" end
		if (upgradeName:match("Bonk") and upgradeName ~= "BonkUnlock") and upgrades.BonkUnlock ~= true then return false, "Locked" end

		if ShopConfig.SpecialItems[upgradeName] or upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
			if currentLevel == true then return false, "Owned" end
			price = ShopConfig.Prices[upgradeName]
		else
			currentLevel = currentLevel or 1
			if currentLevel >= ShopConfig.MAX_LEVEL then return false, "Max" end
			price = ShopConfig.Prices[upgradeName][currentLevel]
		end
		
		if not price then return false, "Error" end
		
		if coins >= price then
			setStat:Fire(player, "Coins", coins - price)
			
			if ShopConfig.SpecialItems[upgradeName] or upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
				setStat:Fire(player, "Upgrades", upgradeName, true)
			else
				setStat:Fire(player, "Upgrades", upgradeName, currentLevel + 1)
			end
			return true, "Success"
		else
			return false, "Funds"
		end
	end
	return false
end

-- 2. GUARDADO DE COLOR (VIP / GAMEPASS)
local colorEvent = ReplicatedStorage:FindFirstChild("ColorUpdateEvent")
if not colorEvent then
	colorEvent = Instance.new("RemoteEvent")
	colorEvent.Name = "ColorUpdateEvent"
	colorEvent.Parent = ReplicatedStorage
end

colorEvent.OnServerEvent:Connect(function(player, itemType, r, g, b)
	local hasPass = false
	if VipList.IsVip(player.UserId) then hasPass = true
	else pcall(function() hasPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, COLOR_GAME_PASS_ID) end) end

	if not hasPass then return end

	local upgrades = getStat:Invoke(player, "Upgrades")
	local keyToSave = nil
	
	if itemType == "DoubleJump" and upgrades.DoubleJump == true then keyToSave = "DoubleJumpColor"
	elseif itemType == "Dash" and upgrades.DashUnlock == true then keyToSave = "DashColor"
	elseif itemType == "Bonk" and upgrades.BonkUnlock == true then keyToSave = "BonkColor"
	end
	
	if keyToSave then
		local colorData = {R = r, G = g, B = b}
		setStat:Fire(player, "Upgrades", keyToSave, colorData)
		if player.Character then
			player:SetAttribute(keyToSave, Color3.new(r, g, b))
		end
	end
end)

-- 3. [NUEVO] TOGGLE BATE BRILLANTE
shinyEvent.OnServerEvent:Connect(function(player)
	-- Validación de Acceso
	local hasAccess = false
	if VipList.IsVip(player.UserId) then hasAccess = true
	else pcall(function() hasAccess = MarketplaceService:UserOwnsGamePassAsync(player.UserId, SHINY_GAME_PASS_ID) end) end
	
	if not hasAccess then 
		warn(player.Name .. " intentó activar Shiny Bat sin permiso.")
		return 
	end
	
	-- Toggle
	local current = getStat:Invoke(player, "Upgrades", "BonkNeon")
	local newState = not current
	
	setStat:Fire(player, "Upgrades", "BonkNeon", newState)
	
	if player.Character then
		player:SetAttribute("BonkNeon", newState)
	end
	print(player.Name .. " cambió Bate Brillante a: " .. tostring(newState))
end)

-- 4. PROCESS RECEIPT
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(playerId)
	local amountToGive = PRODUCT_MAP[productId]
	
	if amountToGive and player then
		local currentCoins = getStat:Invoke(player, "Coins") or 0
		setStat:Fire(player, "Coins", currentCoins + amountToGive)
		
		local rewardEvent = ReplicatedStorage:FindFirstChild("RewardEvent")
		if rewardEvent then rewardEvent:FireClient(player, amountToGive) end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end