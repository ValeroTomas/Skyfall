local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local ShopConfig = require(sharedFolder:WaitForChild("ShopConfig"))

local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local Localization = require(sharedFolder:WaitForChild("Localization")) 

local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
local shopFunction = ReplicatedStorage:WaitForChild("ShopFunction")
local colorEvent = ReplicatedStorage:WaitForChild("ColorUpdateEvent", 5)

local toggleShopEvent = ReplicatedStorage:WaitForChild("ToggleShopEvent")

local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
local function getTxt(key, ...)
	return Localization.get(key, playerLang, ...)
end

print("🛒 ShopHUD: Menú Interno Cargado (Localizado + Audio Nuevo).")

-------------------------------------------------------------------
-- 1. UI SETUP
-------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ShopMenuUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20 

local mainBlocker = Instance.new("TextButton", screenGui)
mainBlocker.Name = "MainBlocker"
mainBlocker.Size = UDim2.new(1,0,1,0); mainBlocker.BackgroundTransparency = 1; mainBlocker.Text = ""
mainBlocker.Visible = false
mainBlocker.ZIndex = 1

-------------------------------------------------------------------
-- 2. MENÚ PRINCIPAL
-------------------------------------------------------------------
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Name = "ShopMenu"
menuFrame.Size = UDim2.new(0, 550, 0, 650)
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 45) 
menuFrame.Visible = false
menuFrame.ZIndex = 5 
Instance.new("UICorner", menuFrame)
local mStroke = Instance.new("UIStroke", menuFrame); mStroke.Thickness = 4; mStroke.Color = Color3.new(0,0,0)

local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, 0, 0, 60); title.BackgroundTransparency = 1
title.Text = getTxt("SHOP_TITLE")
title.Font = Enum.Font.LuckiestGuy; title.TextSize = 40
title.TextColor3 = Color3.fromRGB(255, 200, 50); title.Position = UDim2.new(0,0,0,5)
title.ZIndex = 6
local tStroke = Instance.new("UIStroke", title); tStroke.Thickness = 2

local scroll = Instance.new("ScrollingFrame", menuFrame)
scroll.Size = UDim2.new(1, -30, 1, -80); scroll.Position = UDim2.new(0, 15, 0, 70)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 8
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 200)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 6
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 12)

-------------------------------------------------------------------
-- 3. SELECTOR RGB
-------------------------------------------------------------------
local rgbBlocker = Instance.new("TextButton", screenGui)
rgbBlocker.Name = "RGBBlocker"
rgbBlocker.Size = UDim2.new(1,0,1,0)
rgbBlocker.BackgroundColor3 = Color3.new(0,0,0)
rgbBlocker.BackgroundTransparency = 0.5
rgbBlocker.Text = ""
rgbBlocker.Visible = false
rgbBlocker.ZIndex = 20

local rgbFrame = Instance.new("Frame", screenGui)
rgbFrame.Name = "RGBSelector"
rgbFrame.Size = UDim2.new(0, 350, 0, 400)
rgbFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
rgbFrame.AnchorPoint = Vector2.new(0.5, 0.5)
rgbFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
rgbFrame.Visible = false
rgbFrame.ZIndex = 25 
Instance.new("UICorner", rgbFrame)
local rStroke = Instance.new("UIStroke", rgbFrame); rStroke.Thickness = 4; rStroke.Color = Color3.new(0,0,0)

local rgbTitle = Instance.new("TextLabel", rgbFrame)
rgbTitle.Size = UDim2.new(1,0,0,50); rgbTitle.BackgroundTransparency = 1
rgbTitle.Text = getTxt("COLOR_SELECTOR")
rgbTitle.TextColor3 = Color3.new(1,1,1)
rgbTitle.Font = Enum.Font.LuckiestGuy; rgbTitle.TextSize = 28
rgbTitle.ZIndex = 26
local rgbTStroke = Instance.new("UIStroke", rgbTitle); rgbTStroke.Thickness = 2

local previewContainer = Instance.new("Frame", rgbFrame)
previewContainer.Size = UDim2.new(0, 80, 0, 80)
previewContainer.Position = UDim2.new(0.5, 0, 0.25, 0)
previewContainer.AnchorPoint = Vector2.new(0.5, 0.5)
previewContainer.BackgroundColor3 = Color3.new(0,0,0)
previewContainer.ZIndex = 26
Instance.new("UICorner", previewContainer).CornerRadius = UDim.new(1,0)

local preview = Instance.new("Frame", previewContainer)
preview.Size = UDim2.new(0.85, 0, 0.85, 0)
preview.AnchorPoint = Vector2.new(0.5, 0.5); preview.Position = UDim2.new(0.5,0,0.5,0)
preview.BackgroundColor3 = Color3.new(1,1,1)
preview.ZIndex = 27
Instance.new("UICorner", preview).CornerRadius = UDim.new(1,0)

local currentItemToColor = nil
local rVal, gVal, bVal = 255, 255, 255

local function createFancySlider(yPos, labelText, mainColor, callback)
	local container = Instance.new("Frame", rgbFrame)
	container.Size = UDim2.new(0.8, 0, 0, 30)
	container.Position = UDim2.new(0.5, 0, yPos, 0)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 26
	
	local lab = Instance.new("TextLabel", container)
	lab.Size = UDim2.new(0, 30, 1, 0)
	lab.BackgroundTransparency = 1
	lab.Text = labelText
	lab.Font = Enum.Font.LuckiestGuy; lab.TextSize = 24
	lab.TextColor3 = mainColor
	lab.ZIndex = 27
	local lStroke = Instance.new("UIStroke", lab); lStroke.Thickness = 2
	
	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(1, -40, 0, 10)
	track.Position = UDim2.new(1, 0, 0.5, 0); track.AnchorPoint = Vector2.new(1, 0.5)
	track.BackgroundColor3 = Color3.new(1,1,1)
	track.ZIndex = 27
	Instance.new("UICorner", track)
	
	local grad = Instance.new("UIGradient", track)
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1, mainColor)
	}
	
	local knob = Instance.new("TextButton", track)
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(1, 0, 0.5, 0)
	knob.Text = ""
	knob.BackgroundColor3 = Color3.new(1,1,1)
	knob.ZIndex = 28
	Instance.new("UICorner", knob, UDim.new(1,0))
	local kStroke = Instance.new("UIStroke", knob); kStroke.Thickness = 2; kStroke.Color = Color3.new(0,0,0)
	
	local dragging = false
	knob.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			knob.Position = UDim2.new(relX, 0, 0.5, 0)
			callback(relX)
		end
	end)
end

local function updatePreview() 
	preview.BackgroundColor3 = Color3.new(rVal, gVal, bVal) 
end

createFancySlider(0.48, "R", Color3.fromRGB(255, 50, 50), function(v) rVal = v; updatePreview() end)
createFancySlider(0.63, "G", Color3.fromRGB(50, 255, 50), function(v) gVal = v; updatePreview() end)
createFancySlider(0.78, "B", Color3.fromRGB(50, 80, 255), function(v) bVal = v; updatePreview() end)

local confirmColor = Instance.new("TextButton", rgbFrame)
confirmColor.Size = UDim2.new(0, 140, 0, 45); confirmColor.Position = UDim2.new(0.5, 0, 0.96, 0)
confirmColor.AnchorPoint = Vector2.new(0.5, 1); confirmColor.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
confirmColor.Text = getTxt("BTN_CONFIRM") 
confirmColor.Font = Enum.Font.LuckiestGuy; confirmColor.TextSize = 22
confirmColor.TextColor3 = Color3.new(1,1,1)
confirmColor.ZIndex = 27
Instance.new("UICorner", confirmColor)
local cBtnStroke = Instance.new("UIStroke", confirmColor); cBtnStroke.Thickness = 2; cBtnStroke.Color = Color3.new(0,0,0)

confirmColor.MouseButton1Click:Connect(function()
	if currentItemToColor and colorEvent then
		SoundManager.Play("AbilityReady") 
		colorEvent:FireServer(currentItemToColor, rVal, gVal, bVal)
	end
	rgbFrame.Visible = false
	rgbBlocker.Visible = false
end)

-------------------------------------------------------------------
-- 4. GENERADOR DE FILAS (TIENDA)
-------------------------------------------------------------------
local rows = {}

local function createRow(titleText, upgradeKey, isBool)
	local row = Instance.new("Frame", scroll)
	row.Size = UDim2.new(1, 0, 0, 80) 
	row.BackgroundColor3 = Color3.fromRGB(45, 47, 60)
	row.ZIndex = 7
	Instance.new("UICorner", row)
	
	local nameLab = Instance.new("TextLabel", row)
	nameLab.Text = titleText
	nameLab.Size = UDim2.new(0.4, 0, 0.4, 0); nameLab.Position = UDim2.new(0, 15, 0, 10)
	nameLab.BackgroundTransparency = 1; nameLab.TextColor3 = Color3.new(1,1,1)
	nameLab.Font = Enum.Font.LuckiestGuy; nameLab.TextSize = 24 
	nameLab.TextXAlignment = Enum.TextXAlignment.Left
	nameLab.ZIndex = 8
	local nStroke = Instance.new("UIStroke", nameLab); nStroke.Thickness = 2
	
	local priceLab = Instance.new("TextLabel", row)
	priceLab.Size = UDim2.new(0.4, 0, 0.4, 0); priceLab.Position = UDim2.new(0, 15, 0.55, 0)
	priceLab.BackgroundTransparency = 1; priceLab.TextColor3 = Color3.fromRGB(255, 230, 100)
	priceLab.Font = Enum.Font.GothamBlack; priceLab.TextSize = 20
	priceLab.TextXAlignment = Enum.TextXAlignment.Left
	priceLab.Text = "..."
	priceLab.ZIndex = 8

	local buyBtn = Instance.new("TextButton", row)
	buyBtn.Size = UDim2.new(0, 100, 0, 50); buyBtn.Position = UDim2.new(1, -15, 0.5, 0)
	buyBtn.AnchorPoint = Vector2.new(1, 0.5); buyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	buyBtn.Text = getTxt("BTN_BUY") 
	buyBtn.Font = Enum.Font.GothamBlack; buyBtn.TextSize = 16
	buyBtn.ZIndex = 8
	Instance.new("UICorner", buyBtn)
	local bStroke = Instance.new("UIStroke", buyBtn); bStroke.Thickness = 2; bStroke.Color = Color3.new(0,0,0)
	
	local squares = {}
	if not isBool then
		local progressContainer = Instance.new("Frame", row)
		progressContainer.Size = UDim2.new(0, 150, 0, 25); progressContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		progressContainer.AnchorPoint = Vector2.new(0.5, 0.5); progressContainer.BackgroundTransparency = 1
		progressContainer.ZIndex = 8
		local pLayout = Instance.new("UIListLayout", progressContainer)
		pLayout.FillDirection = Enum.FillDirection.Horizontal; pLayout.Padding = UDim.new(0, 6)
		for i = 1, 5 do
			local sq = Instance.new("Frame", progressContainer)
			sq.Size = UDim2.new(0, 25, 0, 25)
			sq.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
			sq.ZIndex = 9
			Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 4)
			local sqStroke = Instance.new("UIStroke", sq); sqStroke.Thickness = 2; sqStroke.Color = Color3.new(0,0,0)
			table.insert(squares, sq)
		end
	end
	
	return {Frame = row, Btn = buyBtn, Squares = squares, PriceLabel = priceLab, Key = upgradeKey, IsBool = isBool}
end

local function addHeader(text)
	local h = Instance.new("TextLabel", scroll)
	h.Size = UDim2.new(1,0,0,40); h.BackgroundTransparency=1
	h.Text = text; h.TextColor3 = Color3.fromRGB(0, 255, 255); h.Font = Enum.Font.LuckiestGuy; h.TextSize = 28
	h.ZIndex = 7
	local hStroke = Instance.new("UIStroke", h); hStroke.Thickness = 3
end

addHeader(getTxt("HEADER_JUMP"))
table.insert(rows, createRow(getTxt("ITEM_HEIGHT"), "JumpHeight"))
table.insert(rows, createRow(getTxt("ITEM_COST"), "JumpStaminaCost"))
table.insert(rows, createRow(getTxt("ITEM_DOUBLE_JUMP"), "DoubleJump", true))
table.insert(rows, createRow(getTxt("ITEM_JUMP_COLOR"), "DoubleJumpColor", true))

addHeader(getTxt("HEADER_PUSH"))
table.insert(rows, createRow(getTxt("ITEM_UNLOCK"), "PushUnlock", true))
table.insert(rows, createRow(getTxt("ITEM_DISTANCE"), "PushDistance"))
table.insert(rows, createRow(getTxt("ITEM_RANGE"), "PushRange"))
table.insert(rows, createRow(getTxt("ITEM_COOLDOWN"), "PushCooldown"))

addHeader(getTxt("HEADER_DASH"))
table.insert(rows, createRow(getTxt("ITEM_UNLOCK"), "DashUnlock", true)) 
table.insert(rows, createRow(getTxt("ITEM_DISTANCE"), "DashDistance"))
table.insert(rows, createRow(getTxt("ITEM_SPEED"), "DashSpeed"))
table.insert(rows, createRow(getTxt("ITEM_COOLDOWN"), "DashCooldown"))
table.insert(rows, createRow(getTxt("ITEM_DASH_COLOR"), "DashColor", true))

addHeader(getTxt("HEADER_STAMINA"))
table.insert(rows, createRow(getTxt("ITEM_AMOUNT"), "MaxStamina"))
table.insert(rows, createRow(getTxt("ITEM_REGEN"), "StaminaRegen"))
table.insert(rows, createRow(getTxt("ITEM_EFFICIENCY"), "StaminaDrain"))

-------------------------------------------------------------------
-- 5. LÓGICA DE ACTUALIZACIÓN VISUAL Y SONORA
-------------------------------------------------------------------
local function refreshShopUI()
	local success, data = pcall(function() return shopFunction:InvokeServer("GetData") end)
	if not success or not data then return end

	for _, rowData in ipairs(rows) do
		local key = rowData.Key
		local lvl = data[key] or 1
		local isBool = rowData.IsBool
		
		local isLocked = false
		if key == "DoubleJumpColor" and not data.DoubleJump then isLocked = true end
		if (key:match("Push") and key ~= "PushUnlock") and not data.PushUnlock then isLocked = true end
		if (key:match("Dash") and key ~= "DashUnlock") and not data.DashUnlock then isLocked = true end

		if rowData.Conn then rowData.Conn:Disconnect() end

		if isLocked then
			rowData.Btn.Text = getTxt("BTN_LOCKED") 
			rowData.Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			rowData.Btn.AutoButtonColor = false
			rowData.PriceLabel.Text = getTxt("LBL_LOCKED") 
			rowData.PriceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			if rowData.Squares then
				for _, sq in ipairs(rowData.Squares) do sq.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end
			end
		else
			rowData.Btn.AutoButtonColor = true
			if isBool then
				if lvl == true then
					rowData.Btn.Text = getTxt("BTN_READY") 
					rowData.Btn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
					rowData.PriceLabel.Text = getTxt("LBL_ACQUIRED") 
					
					if ShopConfig.SpecialItems and ShopConfig.SpecialItems[key] then
						rowData.Btn.Text = getTxt("BTN_COLOR") 
						rowData.Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
						rowData.PriceLabel.Text = getTxt("LBL_CHANGE") 
						rowData.Conn = rowData.Btn.MouseButton1Click:Connect(function()
							currentItemToColor = (key == "DoubleJumpColor" and "DoubleJump" or "Dash")
							rgbFrame.Visible = true
							rgbBlocker.Visible = true
						end)
					end
				else
					local price = ShopConfig.Prices[key]
					rowData.PriceLabel.Text = "$" .. (price or getTxt("LBL_ERR"))
					rowData.PriceLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
					rowData.Btn.Text = getTxt("BTN_BUY") 
					rowData.Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
					
					rowData.Conn = rowData.Btn.MouseButton1Click:Connect(function()
						local s, msg = shopFunction:InvokeServer("BuyUpgrade", key)
						
						-- FEEDBACK DE SONIDO (BOOL = UNLOCK)
						if s then 
							SoundManager.Play("UnlockSkill") -- SONIDO DIFERENTE PARA DESBLOQUEOS
							if msg == "SELECT_COLOR" then
								refreshShopUI()
								currentItemToColor = (key == "DoubleJumpColor" and "DoubleJump" or "Dash")
								rgbFrame.Visible = true
								rgbBlocker.Visible = true
							else
								refreshShopUI() 
							end
						else
							SoundManager.Play("InsufficientFunds") 
							
							local oldText = rowData.Btn.Text
							local oldColor = rowData.Btn.BackgroundColor3
							rowData.Btn.Text = getTxt("MSG_MISSING") 
							rowData.Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
							task.delay(1, function()
								rowData.Btn.Text = oldText
								rowData.Btn.BackgroundColor3 = oldColor
							end)
						end
					end)
				end
			else
				for i, sq in ipairs(rowData.Squares) do
					if i <= lvl then
						sq.BackgroundColor3 = Color3.fromRGB(0, 255, 255) 
					else
						sq.BackgroundColor3 = Color3.fromRGB(80, 0, 0) 
					end
				end
				
				if lvl >= ShopConfig.MAX_LEVEL then
					rowData.PriceLabel.Text = getTxt("LBL_MAX") 
					rowData.Btn.Visible = false
				else
					local price = ShopConfig.Prices[key][lvl]
					rowData.PriceLabel.Text = "$" .. (price or "???")
					rowData.PriceLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
					rowData.Btn.Visible = true
					rowData.Btn.Text = getTxt("BTN_UPGRADE") 
					rowData.Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
					
					rowData.Conn = rowData.Btn.MouseButton1Click:Connect(function()
						local s, msg = shopFunction:InvokeServer("BuyUpgrade", key)
						
						-- FEEDBACK DE SONIDO (LEVEL = UPGRADE)
						if s then
							SoundManager.Play("BuyUpgrade") -- SONIDO PARA MEJORAS DE NIVEL
							refreshShopUI()
						else
							SoundManager.Play("InsufficientFunds")
							local oldText = rowData.Btn.Text
							local oldColor = rowData.Btn.BackgroundColor3
							rowData.Btn.Text = getTxt("MSG_MISSING")
							rowData.Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
							task.delay(1, function()
								rowData.Btn.Text = oldText
								rowData.Btn.BackgroundColor3 = oldColor
							end)
						end
					end)
				end
			end
		end
	end
end

-------------------------------------------------------------------
-- 6. CONTROL DE ESTADO
-------------------------------------------------------------------
local isOpen = false

local function toggleMenu()
	isOpen = not isOpen
	menuFrame.Visible = isOpen
	mainBlocker.Visible = isOpen 
	if isOpen then
		refreshShopUI()
	else
		rgbFrame.Visible = false
		rgbBlocker.Visible = false
	end
end

mainBlocker.MouseButton1Click:Connect(function() if isOpen then toggleMenu() end end)

toggleShopEvent.Event:Connect(toggleMenu)

local function checkGameState()
	local raw = estadoValue.Value
	local state = string.split(raw, "|")[1]
	
	if state == "SURVIVE" then
		isOpen = false
		menuFrame.Visible = false
		mainBlocker.Visible = false
		rgbFrame.Visible = false
		rgbBlocker.Visible = false
	end
end

estadoValue.Changed:Connect(checkGameState)