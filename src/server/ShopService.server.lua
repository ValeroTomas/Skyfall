local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

local shopFunction = ReplicatedStorage:FindFirstChild("ShopFunction")
if not shopFunction then
	shopFunction = Instance.new("RemoteFunction")
	shopFunction.Name = "ShopFunction"
	shopFunction.Parent = ReplicatedStorage
end

local eventsFolder = ServerStorage:WaitForChild("PlayerDataEvents")
local getStat = eventsFolder:WaitForChild("GetPlayerStat")
local setStat = eventsFolder:WaitForChild("SetPlayerStat")

function shopFunction.OnServerInvoke(player, action, upgradeName, extraData)
	-- 1. PEDIR DATOS
	if action == "GetData" then
		return getStat:Invoke(player, "Upgrades")
	
	-- 2. COMPRAR
	elseif action == "BuyUpgrade" then
		local coins = getStat:Invoke(player, "Coins") or 0
		local upgrades = getStat:Invoke(player, "Upgrades")
		local price = 0
		local currentLevel = upgrades[upgradeName]
		
		-- VALIDACIÓN
		if upgradeName == "DoubleJumpColor" and upgrades.DoubleJump ~= true then
			return false, "Requiere Doble Salto"
		end
		if (upgradeName:match("Push") and upgradeName ~= "PushUnlock") and upgrades.PushUnlock ~= true then
			return false, "Desbloquea Empuje primero"
		end
		if (upgradeName:match("Dash") and upgradeName ~= "DashUnlock") and upgrades.DashUnlock ~= true then
			return false, "Desbloquea Esquive primero"
		end

		-- PRECIO
		if ShopConfig.SpecialItems[upgradeName] or upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
			if currentLevel == true then return false, "Ya tienes esto" end
			price = ShopConfig.Prices[upgradeName]
		else
			currentLevel = currentLevel or 1
			if currentLevel >= ShopConfig.MAX_LEVEL then return false, "Max Level" end
			price = ShopConfig.Prices[upgradeName][currentLevel]
		end
		
		if not price then return false, "Error precio" end
		
		-- TRANSACCIÓN
		if coins >= price then
			setStat:Fire(player, "Coins", coins - price)
			
			if ShopConfig.SpecialItems[upgradeName] then
				-- Autorizamos el cambio de color
				player:SetAttribute("PendingColorChange_" .. (upgradeName == "DoubleJumpColor" and "DoubleJump" or "Dash"), true)
				
				-- Marcamos la mejora como comprada (true)
				-- NOTA: El color en sí se guarda luego vía el evento ColorUpdateEvent
				setStat:Fire(player, "Upgrades", upgradeName, true)
				return true, "SELECT_COLOR"
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

-- EVENTO DE GUARDADO DE COLOR (CORREGIDO)
local colorEvent = ReplicatedStorage:FindFirstChild("ColorUpdateEvent")
if not colorEvent then
	colorEvent = Instance.new("RemoteEvent")
	colorEvent.Name = "ColorUpdateEvent"
	colorEvent.Parent = ReplicatedStorage
end

colorEvent.OnServerEvent:Connect(function(player, itemType, r, g, b)
	-- Verificamos si tiene permiso pendiente (compró el cambio de color)
	if player:GetAttribute("PendingColorChange_" .. itemType) then
		
		-- Creamos la tabla de color
		local colorData = {R = r, G = g, B = b}
		
		-- Determinamos qué clave guardar en la DB
		local keyToSave = ""
		if itemType == "DoubleJump" then
			keyToSave = "DoubleJumpColor"
		elseif itemType == "Dash" then
			keyToSave = "DashColor"
		end
		
		if keyToSave ~= "" then
			-- GUARDAMOS EL COLOR EN LA BASE DE DATOS
			setStat:Fire(player, "Upgrades", keyToSave, colorData)
			print("🎨 Color guardado para " .. player.Name .. ":", r, g, b)
		end
		
		-- Consumimos el permiso
		player:SetAttribute("PendingColorChange_" .. itemType, nil)
	end
end)