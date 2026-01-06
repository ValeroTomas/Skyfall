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
		
		-- VALIDACIÓN DE DEPENDENCIAS (Lógica Nueva)
		if upgradeName == "DoubleJumpColor" and upgrades.DoubleJump ~= true then
			return false, "Requiere Doble Salto"
		end
		
		if (upgradeName:match("Push") and upgradeName ~= "PushUnlock") and upgrades.PushUnlock ~= true then
			return false, "Desbloquea Empuje primero"
		end
		
		if (upgradeName:match("Dash") and upgradeName ~= "DashUnlock") and upgrades.DashUnlock ~= true then
			return false, "Desbloquea Esquive primero"
		end

		-- OBTENER PRECIO
		if ShopConfig.SpecialItems[upgradeName] or upgradeName:match("Unlock") or upgradeName == "DoubleJump" then
			-- Precio único (Booleanos o Cosméticos)
			if currentLevel == true then return false, "Ya tienes esto" end
			price = ShopConfig.Prices[upgradeName]
		else
			-- Niveles
			currentLevel = currentLevel or 1
			if currentLevel >= ShopConfig.MAX_LEVEL then return false, "Max Level" end
			price = ShopConfig.Prices[upgradeName][currentLevel]
		end
		
		if not price then return false, "Error precio" end
		
		-- TRANSACCIÓN
		if coins >= price then
			setStat:Fire(player, "Coins", coins - price)
			
			if ShopConfig.SpecialItems[upgradeName] then
				-- Es un cosmético (Color), damos permiso temporal para el selector
				player:SetAttribute("PendingColorChange_" .. (upgradeName == "DoubleJumpColor" and "DoubleJump" or "Dash"), true)
				-- Marcamos como comprado en la base de datos también
				setStat:Fire(player, "Upgrades", upgradeName, true)
				return true, "SELECT_COLOR" -- Avisamos al cliente que abra el selector
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

-- Evento para guardar el color elegido
local colorEvent = Instance.new("RemoteEvent")
colorEvent.Name = "ColorUpdateEvent"
colorEvent.Parent = ReplicatedStorage

colorEvent.OnServerEvent:Connect(function(player, itemType, r, g, b)
	-- Guardar el color en el PlayerData (Simplificado: Guardamos componentes o asumimos guardado)
	print("🎨 Color guardado: ", itemType, r, g, b)
	
	-- Consumir permiso
	player:SetAttribute("PendingColorChange_" .. itemType, nil)
	
	-- Aquí podrías guardar {R=r, G=g, B=b} en la DB si adaptas PlayerDataHandler
end)