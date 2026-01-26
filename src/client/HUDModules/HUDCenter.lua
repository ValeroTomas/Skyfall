local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local HUD_Center = {}

function HUD_Center.Init(screenGui, sharedFolder)
	local Utils = require(script.Parent.HUDUtils)
	local Localization = require(sharedFolder:WaitForChild("Localization"))
	local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
	local DecalManager = require(sharedFolder:WaitForChild("DecalManager"))
	
	local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)
	local player = Players.LocalPlayer
	local isMobile = UserInputService.TouchEnabled

	-- EVENTOS
	local countdownEvent = ReplicatedStorage:WaitForChild("CountdownEvent")
	local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")
	local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent")
	local rewardEvent = ReplicatedStorage:WaitForChild("RewardEvent") 

	local COUNTDOWN_IMAGES = {
		[3]    = DecalManager.Get("Count3"),
		[2]    = DecalManager.Get("Count2"),
		[1]    = DecalManager.Get("Count1"),
		["GO"] = DecalManager.Get("CountGo")
	}

	---------------------------------------------------------------------------------
	-- 1. CUENTA REGRESIVA
	---------------------------------------------------------------------------------
	local countdownImage = Instance.new("ImageLabel", screenGui)
	countdownImage.Name = "CountdownImage"
	countdownImage.Size = UDim2.new(0.3, 0, 0.3, 0)
	countdownImage.Position = UDim2.new(0.5, 0, 0.4, 0)
	countdownImage.AnchorPoint = Vector2.new(0.5, 0.5)
	countdownImage.BackgroundTransparency = 1; countdownImage.ImageTransparency = 1
	countdownImage.ScaleType = Enum.ScaleType.Fit; countdownImage.ZIndex = 10

	local function playCountdownPop(imageId)
		countdownImage.Image = imageId
		countdownImage.Size = UDim2.new(0, 0, 0, 0)
		countdownImage.Rotation = math.random(-15, 15) 
		countdownImage.ImageTransparency = 0
		
		local popInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		TweenService:Create(countdownImage, popInfo, {Size = UDim2.new(0.3, 0, 0.3, 0), Rotation = 0}):Play()
		
		task.delay(0.6, function()
			local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(countdownImage, fadeInfo, {Size = UDim2.new(0.4, 0, 0.4, 0), ImageTransparency = 1}):Play()
		end)
	end

	countdownEvent.OnClientEvent:Connect(function(value)
		if value == "GO" then
			SoundManager.Play("Go")
			local asset = COUNTDOWN_IMAGES["GO"]
			if asset then playCountdownPop(asset) end
		else
			SoundManager.Play("Countdown")
			local asset = COUNTDOWN_IMAGES[tonumber(value)]
			if asset then playCountdownPop(asset) end
		end
	end)

	---------------------------------------------------------------------------------
	-- 2. ANUNCIO CENTRAL (WINNER/TIE)
	---------------------------------------------------------------------------------
	local labelAnuncio = Instance.new("TextLabel", screenGui)
	labelAnuncio.Name = "AnuncioCentral"
	
	-- [AJUSTE MÓVIL] Reducimos altura para achicar la letra (TextScaled)
	local anuncioHeight = isMobile and 0.12 or 0.2
	
	labelAnuncio.Size = UDim2.new(0.8, 0, anuncioHeight, 0)
	labelAnuncio.Position = UDim2.new(0.5, 0, 0.3, 0)
	labelAnuncio.AnchorPoint = Vector2.new(0.5, 0.5)
	labelAnuncio.BackgroundTransparency = 1
	labelAnuncio.TextScaled = true; labelAnuncio.Text = ""; labelAnuncio.TextTransparency = 1
	Utils.ApplyCartoonStyle(labelAnuncio, Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 170, 0), Color3.new(0,0,0))
	local anuncioStroke = labelAnuncio:FindFirstChild("UIStroke")
	if anuncioStroke then anuncioStroke.Transparency = 1 end

	local function showAnuncio(texto) 
		labelAnuncio.Text = texto
		TweenService:Create(labelAnuncio, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
		if anuncioStroke then TweenService:Create(anuncioStroke, TweenInfo.new(0.5), {Transparency = 0}):Play() end
		
		task.delay(3.5, function()
			TweenService:Create(labelAnuncio, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			if anuncioStroke then TweenService:Create(anuncioStroke, TweenInfo.new(0.5), {Transparency = 1}):Play() end
		end)
	end

	estadoValue.Changed:Connect(function(val)
		local data = string.split(val, "|")
		local state = data[1]
		
		if state == "WINNER" then
			local winnerName = data[2] or "???"
			if winnerName == player.Name then showAnuncio(Localization.get("YOU_WON", playerLang))
			else showAnuncio(Localization.get("WINNER", playerLang, winnerName)) end
		elseif state == "NO_ONE" then showAnuncio(Localization.get("NO_ONE", playerLang))
		elseif state == "TIE" then showAnuncio(Localization.get("TIE", playerLang)) end
	end)

	---------------------------------------------------------------------------------
	-- 3. KILLFEED
	---------------------------------------------------------------------------------
	local feedFrame = Instance.new("Frame", screenGui)
	feedFrame.Name = "Killfeed"; feedFrame.Size = UDim2.new(0, 400, 0, 400) 
	feedFrame.Position = UDim2.new(1, -20, 0.5, 0); feedFrame.AnchorPoint = Vector2.new(1, 0.5)
	feedFrame.BackgroundTransparency = 1
	
	local feedLayout = Instance.new("UIListLayout", feedFrame)
	feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; feedLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	feedLayout.Padding = UDim.new(0, 4)

	-- [AJUSTE MÓVIL] Fuente más pequeña
	local feedTextSize = isMobile and 13 or 18

	local function addFeedEntry(text, styleType)
		local entry = Utils.CreateLabel("Entry", UDim2.new(1, 0, 0, 25), UDim2.new(1, 0, 0, 0), Vector2.new(1,0), feedFrame)
		entry.Text = text; entry.TextXAlignment = Enum.TextXAlignment.Right
		entry.Font = Enum.Font.GothamBold; entry.TextSize = feedTextSize 
		
		if styleType == "REWARD" then entry.TextColor3 = Color3.fromRGB(0, 255, 100) 
		elseif styleType == "BLOOM" then entry.TextColor3 = Color3.fromRGB(255, 80, 80) 
		else entry.TextColor3 = Color3.fromRGB(255, 255, 255) end
		
		local stroke = Instance.new("UIStroke", entry); stroke.Thickness = 1.5; stroke.Color = Color3.new(0,0,0)
		entry.TextTransparency = 1; stroke.Transparency = 1
		
		local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(entry, tInfo, {TextTransparency = 0}):Play()
		TweenService:Create(stroke, tInfo, {Transparency = 0}):Play()

		task.delay(5, function()
			local outInfo = TweenInfo.new(1)
			TweenService:Create(entry, outInfo, {TextTransparency = 1}):Play()
			TweenService:Create(stroke, outInfo, {Transparency = 1}):Play()
			task.wait(1); if entry then entry:Destroy() end
		end)
	end

	killfeedEvent.OnClientEvent:Connect(function(key, ...)
		local args = {...}
		local text = Localization.get(key, playerLang, ...)
		local amInvolved = false
		for _, name in ipairs(args) do if name == player.Name then amInvolved = true; break end end
		local style = amInvolved and "BLOOM" or "NORMAL"
		addFeedEntry(text, style)
	end)
	
	rewardEvent.OnClientEvent:Connect(function(amount)
		local msg = Localization.get("REWARD_MSG", playerLang, tostring(amount))
		addFeedEntry(msg, "REWARD")
	end)

	---------------------------------------------------------------------------------
	-- 4. PANTALLA DE MUERTE
	---------------------------------------------------------------------------------
	local deathFrame = Instance.new("Frame", screenGui)
	deathFrame.Name = "DeathScreen"; deathFrame.Size = UDim2.new(1, 0, 0, 250)
	deathFrame.Position = UDim2.new(0.5, 0, 0.5, 0); deathFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	deathFrame.BackgroundTransparency = 1; deathFrame.Visible = false

	-- [AJUSTE MÓVIL] Título más chico
	local titleHeight = isMobile and 60 or 80
	
	local deathTitle = Instance.new("TextLabel", deathFrame)
	deathTitle.Name = "Title"; deathTitle.Size = UDim2.new(1, 0, 0, titleHeight)
	deathTitle.Position = UDim2.new(0, 0, 0, 0); deathTitle.BackgroundTransparency = 1
	deathTitle.Text = Localization.get("YOU_DIED", playerLang); deathTitle.TextScaled = true
	Utils.ApplyCartoonStyle(deathTitle, Color3.fromRGB(255, 80, 80), Color3.fromRGB(150, 0, 0)) 
	local dtStroke = deathTitle:FindFirstChild("UIStroke")

	-- [AJUSTE MÓVIL] Fuentes reducidas
	local rankSize = isMobile and 22 or 32
	local infoSize = isMobile and 13 or 18

	local deathRank = Instance.new("TextLabel", deathFrame)
	deathRank.Name = "Rank"; deathRank.Size = UDim2.new(1, 0, 0, 40)
	deathRank.Position = UDim2.new(0, 0, 0.4, 0); deathRank.BackgroundTransparency = 1
	deathRank.Text = "..."; deathRank.TextSize = rankSize
	Utils.ApplyCartoonStyle(deathRank, Color3.new(1,1,1), Color3.new(0.7,0.7,0.7))
	local drStroke = deathRank:FindFirstChild("UIStroke")

	local deathInfo = Instance.new("TextLabel", deathFrame)
	deathInfo.Name = "Info"; deathInfo.Size = UDim2.new(1, 0, 0, 30)
	deathInfo.Position = UDim2.new(0, 0, 0.6, 0); deathInfo.BackgroundTransparency = 1
	deathInfo.Text = Localization.get("RESPAWN_INFO", playerLang); deathInfo.TextSize = infoSize
	Utils.ApplyCartoonStyle(deathInfo, Color3.new(0.9,0.9,0.9), Color3.new(0.6,0.6,0.6))
	deathInfo.Font = Enum.Font.Gotham 
	local diStroke = deathInfo:FindFirstChild("UIStroke")

	local function showDeathScreen(rank, showRankLabel)
		deathFrame.Visible = true
		deathTitle.TextTransparency = 1; if dtStroke then dtStroke.Transparency = 1 end
		deathRank.TextTransparency = 1; if drStroke then drStroke.Transparency = 1 end
		deathInfo.TextTransparency = 1; if diStroke then diStroke.Transparency = 1 end
		
		if showRankLabel then deathRank.Text = Localization.get("RANK_INFO", playerLang, tostring(rank)) end
		
		local info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(deathTitle, info, {TextTransparency = 0}):Play()
		if dtStroke then TweenService:Create(dtStroke, info, {Transparency = 0}):Play() end
		
		task.wait(0.3)
		if showRankLabel then
			TweenService:Create(deathRank, info, {TextTransparency = 0}):Play()
			if drStroke then TweenService:Create(drStroke, info, {Transparency = 0}):Play() end
		end
		
		local rawState = estadoValue.Value
		local state = string.split(rawState, "|")[1]
		if state == "STARTING" or state == "WAITING" then
			task.wait(0.2)
			TweenService:Create(deathInfo, info, {TextTransparency = 0}):Play()
			if diStroke then TweenService:Create(diStroke, info, {Transparency = 0}):Play() end
		end
		
		task.delay(4, function()
			if deathFrame.Visible then
				local outInfo = TweenInfo.new(1)
				TweenService:Create(deathTitle, outInfo, {TextTransparency = 1}):Play()
				if dtStroke then TweenService:Create(dtStroke, outInfo, {Transparency = 1}):Play() end
				TweenService:Create(deathRank, outInfo, {TextTransparency = 1}):Play()
				if drStroke then TweenService:Create(drStroke, outInfo, {Transparency = 1}):Play() end
				TweenService:Create(deathInfo, outInfo, {TextTransparency = 1}):Play()
				if diStroke then TweenService:Create(diStroke, outInfo, {Transparency = 1}):Play() end
				task.wait(1); deathFrame.Visible = false
			end
		end)
	end
	
	local function connectCharacter(char)
		local humanoid = char:WaitForChild("Humanoid")
		deathFrame.Visible = false
		humanoid.Died:Connect(function()
			task.wait(0.5)
			local rawState = estadoValue.Value
			local state = string.split(rawState, "|")[1]
			if state == "WINNER" or state == "TIE" or state == "NO_ONE" then return end
			if state == "SURVIVE" then
				local rank = player:GetAttribute("RoundRank")
				local attempts = 0
				while (not rank or rank == 0) and attempts < 10 do task.wait(0.1); rank = player:GetAttribute("RoundRank"); attempts += 1 end
				if not rank or rank == 0 then rank = "?" end
				showDeathScreen(rank, true)
			else showDeathScreen(nil, false) end
		end)
	end
	if player.Character then connectCharacter(player.Character) end
	player.CharacterAdded:Connect(connectCharacter)
end

return HUD_Center