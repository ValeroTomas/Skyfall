local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local matchStatusEvent = ReplicatedStorage:WaitForChild("MatchStatusEvent")
local voteEvent = ReplicatedStorage:WaitForChild("VoteMapEvent")

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local DecalManager = require(sharedFolder:WaitForChild("DecalManager")) 
local Localization = require(sharedFolder:WaitForChild("Localization"))

local playerLang = LocalizationService.RobloxLocaleId:sub(1, 2)

-- ==============================================================================
-- CONFIGURACIÓN DE CÁMARA (HARDCODED)
-- ==============================================================================
local FIXED_CAM_POS = CFrame.new(
	129.825714, 121.266335, -108.599609, 
	-0.674188375, -0.341998994, 0.654604554, 
	0, 0.886326253, 0.463062048, 
	-0.738559783, 0.312191039, -0.597550392
)
-- ==============================================================================

-- UI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TransitionUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function toggleMainHUD(visible)
	local mainHUD = playerGui:FindFirstChild("MainGameHUD")
	if mainHUD then mainHUD.Enabled = visible end
	local buttonsHUD = playerGui:FindFirstChild("HUDButtons")
	if buttonsHUD then buttonsHUD.Enabled = visible end
end

local function setMouseState(enabled)
	if enabled then
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

-- [HELPER] ANIMACIÓN
local function AnimateEntrance(guiObject, delayTime, offsetData)
	guiObject.Visible = true
	local startPos = offsetData and offsetData.Start or UDim2.new(guiObject.Position.X.Scale, 0, guiObject.Position.Y.Scale + 0.1, 0)
	local endPos = offsetData and offsetData.End or guiObject.Position
	guiObject.Position = startPos
	if guiObject:IsA("CanvasGroup") or guiObject:IsA("Frame") or guiObject:IsA("TextLabel") then
		guiObject.BackgroundTransparency = 1 
		if guiObject:IsA("TextLabel") then guiObject.TextTransparency = 1 end
	end
	task.delay(delayTime or 0, function()
		TweenService:Create(guiObject, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = endPos}):Play()
		if guiObject:IsA("CanvasGroup") then TweenService:Create(guiObject, TweenInfo.new(0.4), {GroupTransparency = 0}):Play()
		elseif guiObject:IsA("TextLabel") then TweenService:Create(guiObject, TweenInfo.new(0.4), {TextTransparency = 0, BackgroundTransparency = 1}):Play()
		elseif guiObject:IsA("Frame") then 
			local t = guiObject:GetAttribute("OriginalTransp") or 0.5
			TweenService:Create(guiObject, TweenInfo.new(0.4), {BackgroundTransparency = t}):Play() 
		end
	end)
end

-- === FRAMES BASE ===
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(1,0,1,0); mainFrame.BackgroundTransparency = 1; mainFrame.Visible = false

-- === PANTALLA DE CARGA ===
local loadingFrame = Instance.new("Frame", screenGui)
loadingFrame.Name = "LoadingFrame"
loadingFrame.Size = UDim2.new(1, 0, 1, 0)
loadingFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
loadingFrame.ZIndex = 100 
loadingFrame.Visible = false 

-- Título del Juego
local loadingGameTitle = Instance.new("Frame", loadingFrame)
loadingGameTitle.Size = UDim2.new(0, 500, 0, 150)
loadingGameTitle.Position = UDim2.new(0.5, 0, 0.4, 0)
loadingGameTitle.AnchorPoint = Vector2.new(0.5, 0.5)
loadingGameTitle.BackgroundTransparency = 1
loadingGameTitle.ZIndex = 105 

local lblSurvive = Instance.new("TextLabel", loadingGameTitle)
lblSurvive.Text = "SURVIVE THE"
lblSurvive.Size = UDim2.new(1,0,0.3,0); lblSurvive.Position = UDim2.new(0,0,0,0)
lblSurvive.BackgroundTransparency = 1; lblSurvive.TextColor3 = Color3.new(1,1,1)
lblSurvive.FontFace = FontManager.Get("Cartoon"); lblSurvive.TextSize = 30
lblSurvive.ZIndex = 105 
local sStroke = Instance.new("UIStroke", lblSurvive); sStroke.Thickness = 2; sStroke.Name = "Stroke"

local lblSkyfall = Instance.new("TextLabel", loadingGameTitle)
lblSkyfall.Text = "SKYFALL!"
lblSkyfall.Size = UDim2.new(1,0,0.7,0); lblSkyfall.Position = UDim2.new(0,0,0.3,0)
lblSkyfall.BackgroundTransparency = 1; lblSkyfall.TextColor3 = Color3.new(1,1,1)
lblSkyfall.FontFace = FontManager.Get("Cartoon"); lblSkyfall.TextSize = 85
lblSkyfall.ZIndex = 105 
local skyGrad = Instance.new("UIGradient", lblSkyfall); skyGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))}; skyGrad.Rotation = 90
local skyStroke = Instance.new("UIStroke", lblSkyfall); skyStroke.Thickness = 4; skyStroke.Color = Color3.fromRGB(80, 40, 0); skyStroke.Name = "Stroke"

-- Texto Cargando
local loadingText = Instance.new("TextLabel", loadingFrame)
loadingText.Text = "CARGANDO..."
loadingText.Size = UDim2.new(1, 0, 0.1, 0)
loadingText.Position = UDim2.new(0, 0, 0.85, 0)
loadingText.BackgroundTransparency = 1
loadingText.TextColor3 = Color3.fromRGB(200, 200, 200)
loadingText.FontFace = Font.fromEnum(Enum.Font.GothamBold); loadingText.TextSize = 22
loadingText.ZIndex = 105 

-- COMPONENTES DE TRANSICIÓN
local roundTitle = Instance.new("TextLabel", mainFrame)
roundTitle.Size = UDim2.new(1,0,0.2,0); roundTitle.Position = UDim2.new(0,0,0.1,0); roundTitle.BackgroundTransparency = 1; roundTitle.Text = "RONDA 1"; roundTitle.TextColor3 = Color3.new(1,1,1); roundTitle.FontFace = FontManager.Get("Cartoon"); roundTitle.TextSize = 75
local rtGrad = Instance.new("UIGradient", roundTitle); rtGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 20))}; rtGrad.Rotation = 90
local rtStroke = Instance.new("UIStroke", roundTitle); rtStroke.Thickness = 6; rtStroke.Color = Color3.fromRGB(40, 0, 10); rtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

-- [MODIFICADO] Ruleta más angosta (0.35 de ancho)
local rouletteFrame = Instance.new("Frame", mainFrame)
rouletteFrame.Size = UDim2.new(0.35, 0, 0.18, 0) 
rouletteFrame.Position = UDim2.new(0.325, 0, 0.4, 0) -- Centrado (1 - 0.35)/2
rouletteFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
rouletteFrame.ClipsDescendants = true
rouletteFrame.ZIndex = 5
rouletteFrame:SetAttribute("OriginalTransp", 0.5)

Instance.new("UICorner", rouletteFrame).CornerRadius = UDim.new(0, 12)
local rfStroke = Instance.new("UIStroke", rouletteFrame); rfStroke.Color = Color3.fromRGB(150, 150, 160); rfStroke.Thickness = 4

local rouletteStrip = Instance.new("Frame", rouletteFrame)
rouletteStrip.Size = UDim2.new(1, 0, 10, 0)
rouletteStrip.BackgroundTransparency = 1
rouletteStrip.ZIndex = 15 

local shadowOverlay = Instance.new("Frame", rouletteFrame)
shadowOverlay.Name = "ShadowOverlay"
shadowOverlay.Size = UDim2.new(1, 0, 1, 0)
shadowOverlay.BackgroundColor3 = Color3.new(0,0,0)
shadowOverlay.BorderSizePixel = 0
shadowOverlay.ZIndex = 10
local shadowGrad = Instance.new("UIGradient", shadowOverlay)
shadowGrad.Rotation = 90
shadowGrad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.0, 0.1), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1.0, 0.1)}

local pointer = Instance.new("ImageLabel", rouletteFrame)
pointer.Size = UDim2.new(0, 50, 0, 50)
pointer.Position = UDim2.new(0, 10, 0.5, 0)
pointer.AnchorPoint = Vector2.new(0.5, 0.5)
pointer.BackgroundTransparency = 1
pointer.Image = "rbxassetid://13004332997"
pointer.Rotation = -90
pointer.ZIndex = 25
pointer.ImageColor3 = Color3.fromRGB(255, 200, 50)

local podiumFrame = Instance.new("Frame", mainFrame); podiumFrame.Size = UDim2.new(0.8, 0, 0.6, 0); podiumFrame.Position = UDim2.new(0.1, 0, 0.2, 0); podiumFrame.BackgroundTransparency = 1; podiumFrame.Visible = false
local podiumTitle = Instance.new("TextLabel", podiumFrame); podiumTitle.Size = UDim2.new(1,0,0.15,0); podiumTitle.Position = UDim2.new(0,0,0,0); podiumTitle.BackgroundTransparency = 1; podiumTitle.Text = "TOP 3"; podiumTitle.TextColor3 = Color3.new(1,1,1); podiumTitle.FontFace = FontManager.Get("Cartoon"); podiumTitle.TextSize = 65; local ptGrad = Instance.new("UIGradient", podiumTitle); ptGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0))}; ptGrad.Rotation = 90; local ptStroke = Instance.new("UIStroke", podiumTitle); ptStroke.Thickness = 5; ptStroke.Color = Color3.fromRGB(80, 40, 0)
local podiumContainer = Instance.new("Frame", podiumFrame); podiumContainer.Size = UDim2.new(1, 0, 0.8, 0); podiumContainer.Position = UDim2.new(0, 0, 0.2, 0); podiumContainer.BackgroundTransparency = 1

local voteFrame = Instance.new("Frame", mainFrame); voteFrame.Size = UDim2.new(0.9, 0, 0.6, 0); voteFrame.Position = UDim2.new(0.05, 0, 0.2, 0); voteFrame.BackgroundTransparency = 1; voteFrame.Visible = false
local voteTitle = Instance.new("TextLabel", voteFrame); voteTitle.Text = "VOTA EL MAPA"; voteTitle.Size = UDim2.new(1,0,0.15,0); voteTitle.BackgroundTransparency = 1; voteTitle.TextColor3 = Color3.new(1,1,1); voteTitle.FontFace = FontManager.Get("Cartoon"); voteTitle.TextSize = 55; local vtGrad = Instance.new("UIGradient", voteTitle); vtGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 200))}; vtGrad.Rotation = 90; local vtStroke = Instance.new("UIStroke", voteTitle); vtStroke.Thickness = 4; vtStroke.Color = Color3.fromRGB(0, 50, 80)
local voteContainer = Instance.new("Frame", voteFrame); voteContainer.Size = UDim2.new(1,0,0.8,0); voteContainer.Position = UDim2.new(0,0,0.2,0); voteContainer.BackgroundTransparency = 1

-- === CAMERA MANAGER ===
local cameraConnection = nil
local activeCinematic = false

local function setCinematicCamera(enable)
	if not enable then
		activeCinematic = false
		if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
		camera.CameraType = Enum.CameraType.Custom
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
		return
	end
	if activeCinematic then return end
	activeCinematic = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = FIXED_CAM_POS
	if cameraConnection then cameraConnection:Disconnect() end
	cameraConnection = RunService.RenderStepped:Connect(function() camera.CameraType = Enum.CameraType.Scriptable; camera.CFrame = FIXED_CAM_POS end)
	TweenService:Create(blur, TweenInfo.new(1), {Size = 24}):Play()
end

-- === RULETA MEJORADA (Tick por ítem) ===
local function spinRoulette(targetKey, duration)
	rouletteFrame.Visible = true
	AnimateEntrance(rouletteFrame, 0.2)
	
	rouletteStrip.Position = UDim2.new(0,0,0,0)
	rouletteStrip:ClearAllChildren()
	rouletteStrip.Size = UDim2.new(1, 0, 0, 3500)
	
	local listLayout = Instance.new("UIListLayout", rouletteStrip)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
	-- [MODIFICADO] Lista de relleno con KEYS de localización
	local fillers = {
		"EVENT_MAGMA", 
		"EVENT_ICE", 
		"EVENT_POTATO", 
		"EVENT_NORMAL", 
		"EVENT_GRAVITY"
	}
	
	local winnerIndex = 45
	local itemHeight = 60 -- Altura exacta de cada item
	local winnerLabel = nil 
	
	for i = 1, 55 do
		-- Seleccionar clave aleatoria o la ganadora
		local txtKey = fillers[math.random(1, #fillers)]
		if i == winnerIndex then txtKey = targetKey end
		
		-- [TRADUCCIÓN] Obtener texto real
		local translatedText = Localization.get(txtKey, playerLang)
		
		local label = Instance.new("TextLabel", rouletteStrip)
		label.LayoutOrder = i
		label.Size = UDim2.new(1, 0, 0, itemHeight)
		label.BackgroundTransparency = 1
		label.Text = translatedText
		label.TextColor3 = Color3.fromRGB(240, 240, 245)
		label.TextSize = 28
		label.FontFace = FontManager.Get("Cartoon")
		label.TextStrokeTransparency = 1
		label.ZIndex = 16 
		
		local s = Instance.new("UIStroke", label); s.Thickness = 2.5; s.Color = Color3.fromRGB(20, 20, 30) 
		if i == winnerIndex then winnerLabel = label end
	end
	
	task.wait() 
	
	-- Cálculo de posición final
	local frameHeight = rouletteFrame.AbsoluteSize.Y; if frameHeight == 0 then frameHeight = 100 end
	local itemCenterY = ((winnerIndex - 1) * itemHeight) + (itemHeight / 2)
	local frameCenterY = frameHeight / 2
	local targetY = frameCenterY - itemCenterY
	
	-- [LÓGICA DEL TICK]
	local tween = TweenService:Create(rouletteStrip, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, targetY)})
	tween:Play()
	
	local lastIndex = 0
	local tickConnection
	
	-- Usamos RenderStepped para chequear la posición en cada frame y hacer el sonido
	tickConnection = RunService.RenderStepped:Connect(function()
		local currentY = math.abs(rouletteStrip.Position.Y.Offset)
		local currentIndex = math.floor(currentY / itemHeight)
		
		if currentIndex > lastIndex then
			SoundManager.Play("RouletteTick") -- Sonido corto (Tick)
			lastIndex = currentIndex
		end
	end)
	
	tween.Completed:Wait()
	if tickConnection then tickConnection:Disconnect() end
	
	SoundManager.Play("RouletteStop")
	
	if winnerLabel then
		local grad = Instance.new("UIGradient", winnerLabel)
		grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 0))}
		grad.Rotation = 90
		local wStroke = winnerLabel:FindFirstChild("UIStroke")
		if wStroke then wStroke.Thickness = 4; wStroke.Color = Color3.fromRGB(60, 30, 0) end
		
		TweenService:Create(winnerLabel, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {TextSize = 48}):Play()
		task.spawn(function() 
			for k = 1, 8 do 
				winnerLabel.Rotation = (k % 2 == 0) and 4 or -4
				task.wait(0.05) 
			end
			winnerLabel.Rotation = 0 
		end)
	end
	
	task.wait(2)
	rouletteFrame.Visible = false
end

-- === PODIO ===
local function createPodiumPlate(rank, data, parent)
	local config = {}
	if rank == 1 then config = {Pos = UDim2.new(0.5, 0, 0.1, 0), Size = UDim2.new(0.35, 0, 0.35, 0), Color1 = Color3.fromRGB(255, 220, 0), Color2 = Color3.fromRGB(255, 140, 0), Stroke = Color3.fromRGB(150, 80, 0), Scale = 1.1}
	elseif rank == 2 then config = {Pos = UDim2.new(0.15, 0, 0.3, 0), Size = UDim2.new(0.3, 0, 0.3, 0), Color1 = Color3.fromRGB(220, 220, 230), Color2 = Color3.fromRGB(130, 130, 140), Stroke = Color3.fromRGB(60, 60, 70), Scale = 0.9}
	elseif rank == 3 then config = {Pos = UDim2.new(0.85, 0, 0.35, 0), Size = UDim2.new(0.3, 0, 0.3, 0), Color1 = Color3.fromRGB(205, 127, 50), Color2 = Color3.fromRGB(140, 70, 20), Stroke = Color3.fromRGB(70, 30, 0), Scale = 0.85} end
	
	local plate = Instance.new("Frame", parent); plate.Size = UDim2.new(0, 0, 0, 0); plate.Position = config.Pos; plate.AnchorPoint = Vector2.new(0.5, 0); plate.BackgroundColor3 = Color3.new(1,1,1); plate.BorderSizePixel = 0
	Instance.new("UICorner", plate).CornerRadius = UDim.new(0, 12); local grad = Instance.new("UIGradient", plate); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, config.Color1), ColorSequenceKeypoint.new(1, config.Color2)}; grad.Rotation = 45; local str = Instance.new("UIStroke", plate); str.Thickness = 4; str.Color = config.Stroke
	local rankTxt = Instance.new("TextLabel", plate); rankTxt.Size = UDim2.new(0.3, 0, 1, 0); rankTxt.Position = UDim2.new(0, 10, 0, 0); rankTxt.BackgroundTransparency = 1; rankTxt.Text = "#" .. rank; rankTxt.TextColor3 = Color3.new(1,1,1); rankTxt.TextStrokeTransparency = 0.5; rankTxt.TextStrokeColor3 = config.Stroke; rankTxt.FontFace = FontManager.Get("Cartoon"); rankTxt.TextSize = 40 * config.Scale
	local infoFrame = Instance.new("Frame", plate); infoFrame.Size = UDim2.new(0.65, 0, 0.8, 0); infoFrame.Position = UDim2.new(0.3, 0, 0.1, 0); infoFrame.BackgroundTransparency = 1
	local nameTxt = Instance.new("TextLabel", infoFrame); nameTxt.Size = UDim2.new(1, 0, 0.6, 0); nameTxt.BackgroundTransparency = 1; nameTxt.Text = data.Name; nameTxt.TextColor3 = Color3.new(1,1,1); nameTxt.TextScaled = true; nameTxt.FontFace = FontManager.Get("Cartoon"); local nStr = Instance.new("UIStroke", nameTxt); nStr.Thickness = 2.5; nStr.Color = Color3.new(0,0,0)
	local winsTxt = Instance.new("TextLabel", infoFrame); winsTxt.Size = UDim2.new(1, 0, 0.4, 0); winsTxt.Position = UDim2.new(0, 0, 0.6, 0); winsTxt.BackgroundTransparency = 1; winsTxt.Text = data.Wins .. " WINS"; winsTxt.TextColor3 = Color3.fromRGB(255, 255, 200); winsTxt.TextSize = 22 * config.Scale; winsTxt.FontFace = FontManager.Get("Cartoon"); local wStr = Instance.new("UIStroke", winsTxt); wStr.Thickness = 2; wStr.Color = Color3.new(0,0,0)
	TweenService:Create(plate, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = config.Size}):Play()
	return plate
end

local function showPodium(data)
	podiumFrame.Visible = true; AnimateEntrance(podiumTitle, 0); AnimateEntrance(podiumContainer, 0.3); podiumContainer:ClearAllChildren(); local order = {2, 3, 1}
	task.spawn(function() for _, rank in ipairs(order) do if data[rank] then createPodiumPlate(rank, data[rank], podiumContainer); local s = Instance.new("Sound", workspace); s.SoundId = "rbxassetid://4612375233"; s.Volume = 0.5; s.PlayOnRemove = true; s:Destroy(); task.wait(0.4) end end end)
end

-- === VOTACIÓN ===
local function showVoting(mapList)
	setMouseState(true) -- LIBERAR MOUSE
	voteFrame.Visible = true; AnimateEntrance(voteTitle, 0); AnimateEntrance(voteContainer, 0.3); voteContainer:ClearAllChildren()
	local l = Instance.new("UIListLayout", voteContainer); l.FillDirection = Enum.FillDirection.Horizontal; l.HorizontalAlignment = Enum.HorizontalAlignment.Center; l.VerticalAlignment = Enum.VerticalAlignment.Center; l.Padding = UDim.new(0, 20)
	local voted = false
	for i, m in ipairs(mapList) do
		local card = Instance.new("ImageButton", voteContainer); card.Name = "MapCard_" .. m.Name; card.Size = UDim2.new(0.28, 0, 0.5, 0); card.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
		-- USAR IMAGEN DE DECALMANAGER
		card.Image = DecalManager.Get(m.Image) 
		card.AutoButtonColor = false
		local constraint = Instance.new("UIAspectRatioConstraint", card); constraint.AspectRatio = 1.777; Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12); local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(100, 100, 120); stroke.Thickness = 3
		local mapName = Instance.new("TextLabel", card); mapName.Size = UDim2.new(1, 0, 0.25, 0); mapName.Position = UDim2.new(0, 0, 0.75, 0); mapName.BackgroundColor3 = Color3.new(0,0,0); mapName.BackgroundTransparency = 0.4; mapName.Text = m.Name; mapName.TextColor3 = Color3.new(1,1,1); mapName.FontFace = FontManager.Get("Cartoon"); mapName.TextScaled = true; Instance.new("UICorner", mapName).CornerRadius = UDim.new(0, 8); local tGrad = Instance.new("UIGradient", mapName); tGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))}; tGrad.Rotation = 90; local tStroke = Instance.new("UIStroke", mapName); tStroke.Thickness = 2; tStroke.Color = Color3.new(0,0,0)
		card.MouseEnter:Connect(function() if not voted then TweenService:Create(card, TweenInfo.new(0.1), {Size = UDim2.new(0.3, 0, 0.52, 0)}):Play() end end)
		card.MouseLeave:Connect(function() if not voted then TweenService:Create(card, TweenInfo.new(0.1), {Size = UDim2.new(0.28, 0, 0.5, 0)}):Play() end end)
		card.MouseButton1Click:Connect(function() if voted then return end; voted = true; SoundManager.Play("ShopButton"); stroke.Color = Color3.fromRGB(0, 255, 100); stroke.Thickness = 6; voteEvent:FireServer(m.Id); for _, other in pairs(voteContainer:GetChildren()) do if other:IsA("GuiButton") and other ~= card then TweenService:Create(other, TweenInfo.new(0.5), {ImageTransparency = 0.8, BackgroundTransparency = 0.5}):Play() end end end)
		card.Visible = false; AnimateEntrance(card, i * 0.15)
	end
end

matchStatusEvent.OnClientEvent:Connect(function(status, data)
	if status == "TRANSITION" then
		toggleMainHUD(false); mainFrame.Visible = true; podiumFrame.Visible = false; voteFrame.Visible = false
		roundTitle.Visible = true; roundTitle.Text = "RONDA " .. data.Round; AnimateEntrance(roundTitle, 0)
		-- [MODIFICADO] Ahora pasamos la KEY del evento
		setCinematicCamera(true); task.spawn(function() spinRoulette(data.TargetEvent, data.Duration) end)
		
	elseif status == "PREPARE" then
		toggleMainHUD(true); setCinematicCamera(false); mainFrame.Visible = false
		
	elseif status == "PODIUM" then
		toggleMainHUD(false); mainFrame.Visible = true; rouletteFrame.Visible = false; voteFrame.Visible = false; roundTitle.Visible = false; setCinematicCamera(true); showPodium(data)
		
	elseif status == "VOTING" then
		toggleMainHUD(false); podiumFrame.Visible = false; roundTitle.Visible = false
		
		-- RESETEAR ESTADO VISUAL
		voteTitle.Text = "VOTA EL MAPA"
		voteContainer.Visible = true
		
		showVoting(data)
		
	elseif status == "MAP_RESULT" then
		setMouseState(false)
		
		if data and data.Name then
			local card = voteContainer:FindFirstChild("MapCard_" .. data.Name)
			if card then
				card.ZIndex = 10 
				TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.new(0.35, 0, 0.6, 0)}):Play()
				local s = card:FindFirstChild("UIStroke")
				if s then s.Color = Color3.fromRGB(255, 215, 0); s.Thickness = 8 end
				SoundManager.Play("WinnerMap")
			end
		end
		
		voteTitle.Text = "MAPA ELEGIDO: " .. data.Name
		
		-- ESPERAR ANTES DE OCULTAR
		task.wait(3)
		
		voteContainer.Visible = false
		mainFrame.Visible = false; setCinematicCamera(false); toggleMainHUD(true)
		
	elseif status == "LOADING" then
		toggleMainHUD(false); mainFrame.Visible = false 
		loadingFrame.Visible = true; loadingFrame.BackgroundTransparency = 0 
		local mapName = (data and data.MapName) or "NIVEL"
		loadingText.Text = "CARGANDO: " .. string.upper(mapName)
		
		-- Resetear TODAS las transparencias
		for _, child in pairs(loadingFrame:GetDescendants()) do
			if child:IsA("TextLabel") then child.TextTransparency = 0 
			elseif child:IsA("ImageLabel") then child.ImageTransparency = 0 
			elseif child:IsA("UIStroke") then child.Transparency = 0 end 
		end
		setCinematicCamera(true) 
		
	elseif status == "WAITING" then
		setCinematicCamera(false)
		local fade = TweenService:Create(loadingFrame, TweenInfo.new(1), {BackgroundTransparency = 1}); fade:Play()
		
		-- Desvanecer todo (incluido Stroke)
		for _, child in pairs(loadingFrame:GetDescendants()) do
			if child:IsA("TextLabel") then TweenService:Create(child, TweenInfo.new(1), {TextTransparency = 1}):Play()
			elseif child:IsA("ImageLabel") then TweenService:Create(child, TweenInfo.new(1), {ImageTransparency = 1}):Play()
			elseif child:IsA("UIStroke") then TweenService:Create(child, TweenInfo.new(1), {Transparency = 1}):Play() end
		end
		
		fade.Completed:Connect(function() loadingFrame.Visible = false; toggleMainHUD(true) end)
	end
end)