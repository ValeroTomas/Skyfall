local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local matchStatusEvent = ReplicatedStorage:WaitForChild("MatchStatusEvent")
local voteEvent = ReplicatedStorage:WaitForChild("VoteMapEvent")

-- ASSETS
local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))
local FontManager = require(sharedFolder:WaitForChild("FontManager"))

-- UI CREATION (Procedural para no depender de StarterGui manual)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TransitionUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

-- == 1. MARCOS ==
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(1,0,1,0)
mainFrame.BackgroundTransparency = 1
mainFrame.Visible = false

-- TITULO RONDA
local roundTitle = Instance.new("TextLabel", mainFrame)
roundTitle.Size = UDim2.new(1,0,0.2,0)
roundTitle.Position = UDim2.new(0,0,0.1,0)
roundTitle.BackgroundTransparency = 1
roundTitle.Text = "RONDA 1"
roundTitle.TextColor3 = Color3.new(1,1,1)
roundTitle.TextStrokeTransparency = 0
roundTitle.FontFace = FontManager.Get("Cartoon")
roundTitle.TextSize = 60

-- RULETA EVENTO
local rouletteFrame = Instance.new("Frame", mainFrame)
rouletteFrame.Size = UDim2.new(0.6, 0, 0.15, 0)
rouletteFrame.Position = UDim2.new(0.2, 0, 0.4, 0)
rouletteFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
rouletteFrame.BackgroundTransparency = 0.5
rouletteFrame.ClipsDescendants = true
Instance.new("UICorner", rouletteFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", rouletteFrame).Color = Color3.new(1,1,1)

local rouletteStrip = Instance.new("Frame", rouletteFrame)
rouletteStrip.Size = UDim2.new(1, 0, 10, 0) -- Alto para contener muchas opciones
rouletteStrip.BackgroundTransparency = 1

local pointer = Instance.new("ImageLabel", rouletteFrame)
pointer.Size = UDim2.new(0, 40, 0, 40)
pointer.Position = UDim2.new(0.5, -20, 0, -20)
pointer.BackgroundTransparency = 1
pointer.Image = "rbxassetid://13004332997" -- Flecha hacia abajo (o similar)
pointer.Rotation = 0

-- PODIO
local podiumFrame = Instance.new("Frame", mainFrame)
podiumFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
podiumFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
podiumFrame.BackgroundTransparency = 1
podiumFrame.Visible = false

local podiumTitle = Instance.new("TextLabel", podiumFrame)
podiumTitle.Size = UDim2.new(1,0,0.2,0)
podiumTitle.BackgroundTransparency = 1
podiumTitle.Text = "MAXIMOS GANADORES"
podiumTitle.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dorado
podiumTitle.TextStrokeTransparency = 0
podiumTitle.FontFace = FontManager.Get("Cartoon")
podiumTitle.TextSize = 50

-- VOTACION
local voteFrame = Instance.new("Frame", mainFrame)
voteFrame.Size = UDim2.new(0.8, 0, 0.5, 0)
voteFrame.Position = UDim2.new(0.1, 0, 0.25, 0)
voteFrame.BackgroundTransparency = 1
voteFrame.Visible = false

local voteTitle = Instance.new("TextLabel", voteFrame)
voteTitle.Text = "VOTA EL SIGUIENTE MAPA"
voteTitle.Size = UDim2.new(1,0,0.2,0); voteTitle.BackgroundTransparency = 1
voteTitle.TextColor3 = Color3.new(1,1,1); voteTitle.TextStrokeTransparency = 0
voteTitle.FontFace = FontManager.Get("Cartoon"); voteTitle.TextSize = 40

local voteContainer = Instance.new("Frame", voteFrame)
voteContainer.Size = UDim2.new(1,0,0.7,0); voteContainer.Position = UDim2.new(0,0,0.3,0)
voteContainer.BackgroundTransparency = 1
local voteLayout = Instance.new("UIListLayout", voteContainer)
voteLayout.FillDirection = Enum.FillDirection.Horizontal
voteLayout.Padding = UDim.new(0, 20)
voteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- === LOGICA CAMARA ===
local function setCinematicCamera(enable)
	if enable then
		camera.CameraType = Enum.CameraType.Scriptable
		local camPart = workspace.Map:FindFirstChild("CamPos")
		if camPart then
			-- Tween suave hacia la posicion
			TweenService:Create(camera, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {CFrame = camPart.CFrame}):Play()
		end
		TweenService:Create(blur, TweenInfo.new(1), {Size = 24}):Play()
	else
		camera.CameraType = Enum.CameraType.Custom
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	end
end

-- === LOGICA RULETA ===
local function spinRoulette(targetText, duration)
	rouletteFrame.Visible = true
	rouletteStrip:ClearAllChildren()
	rouletteStrip.Position = UDim2.new(0,0,0,0)
	
	local listLayout = Instance.new("UIListLayout", rouletteStrip)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	
	-- Generar lista falsa
	local fillers = {"LLUVIA DE MAGMA", "BLOQUES DE HIELO", "PATATA CALIENTE", "NORMAL", "GRAVEDAD CERO", "TODO EXPLOTA"}
	local items = {}
	
	-- Llenar tira (50 items, el 45 es el ganador)
	local winnerIndex = 45
	for i = 1, 55 do
		local txt = fillers[math.random(1, #fillers)]
		if i == winnerIndex then txt = targetText end
		
		local label = Instance.new("TextLabel", rouletteStrip)
		label.Size = UDim2.new(1, 0, 0, 60) -- Alto de cada item
		label.BackgroundTransparency = 1
		label.Text = txt
		label.TextColor3 = (i == winnerIndex) and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(200, 200, 200)
		label.TextSize = 30
		label.FontFace = FontManager.Get("Cartoon")
		label.TextStrokeTransparency = 0
	end
	
	-- Calcular posición final
	-- Queremos que el winnerIndex quede en el centro del frame
	-- Centro del frame = FrameHeight / 2
	-- Posicion del item = (Index - 1) * ItemHeight + (ItemHeight/2)
	-- Offset = CentroFrame - PosicionItem
	
	local itemHeight = 60
	local frameHeight = rouletteFrame.AbsoluteSize.Y
	local targetY = (frameHeight / 2) - ((winnerIndex - 1) * itemHeight + (itemHeight / 2))
	
	-- Sonido loop
	SoundManager.Play("RouletteSpin") -- Asegurate de tener este sonido o usa uno genérico
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(rouletteStrip, tweenInfo, {Position = UDim2.new(0, 0, 0, targetY)})
	tween:Play()
	
	tween.Completed:Wait()
	SoundManager.Play("RouletteStop")
	
	-- Parpadeo del ganador
	task.wait(0.5)
	rouletteFrame.Visible = false
end

-- === LOGICA PODIO ===
local function showPodium(data)
	podiumFrame.Visible = true
	-- Limpiar anterior
	for _, c in pairs(podiumFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	
	-- Crear filas Top 1, 2, 3
	for i, winner in ipairs(data) do
		if i > 3 then break end
		
		local row = Instance.new("Frame", podiumFrame)
		row.Size = UDim2.new(1, 0, 0.2, 0)
		row.Position = UDim2.new(0, 0, 0.25 + (i-1)*0.22, 0)
		row.BackgroundColor3 = Color3.new(0,0,0)
		row.BackgroundTransparency = 0.5
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
		
		local rankTxt = Instance.new("TextLabel", row)
		rankTxt.Size = UDim2.new(0.2, 0, 1, 0)
		rankTxt.BackgroundTransparency = 1
		rankTxt.Text = "#" .. i
		rankTxt.TextColor3 = (i==1) and Color3.fromRGB(255, 215, 0) or ((i==2) and Color3.fromRGB(192, 192, 192) or Color3.fromRGB(205, 127, 50))
		rankTxt.TextSize = 35; rankTxt.FontFace = FontManager.Get("Cartoon"); rankTxt.TextStrokeTransparency = 0
		
		local nameTxt = Instance.new("TextLabel", row)
		nameTxt.Size = UDim2.new(0.5, 0, 1, 0); nameTxt.Position = UDim2.new(0.2, 0, 0, 0)
		nameTxt.BackgroundTransparency = 1; nameTxt.Text = winner.Name
		nameTxt.TextColor3 = Color3.new(1,1,1); nameTxt.TextSize = 30; nameTxt.FontFace = FontManager.Get("Cartoon"); nameTxt.TextXAlignment = Enum.TextXAlignment.Left; nameTxt.TextStrokeTransparency = 0
		
		local winsTxt = Instance.new("TextLabel", row)
		winsTxt.Size = UDim2.new(0.3, 0, 1, 0); winsTxt.Position = UDim2.new(0.7, 0, 0, 0)
		winsTxt.BackgroundTransparency = 1; winsTxt.Text = winner.Wins .. " WINS"
		winsTxt.TextColor3 = Color3.fromRGB(100, 255, 100); winsTxt.TextSize = 30; winsTxt.FontFace = FontManager.Get("Cartoon"); winsTxt.TextStrokeTransparency = 0
	end
end

-- === LOGICA VOTACION ===
local function showVoting(mapList)
	voteFrame.Visible = true
	voteContainer:ClearAllChildren()
	voteLayout.Parent = voteContainer
	
	local hasVoted = false
	
	for _, map in ipairs(mapList) do
		local btn = Instance.new("TextButton", voteContainer)
		btn.Size = UDim2.new(0, 150, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		btn.Text = map.Name
		btn.TextColor3 = Color3.new(1,1,1)
		btn.FontFace = FontManager.Get("Cartoon")
		btn.TextSize = 24
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", btn).Color = Color3.new(1,1,1)
		
		btn.MouseButton1Click:Connect(function()
			if hasVoted then return end
			hasVoted = true
			SoundManager.Play("ShopButton")
			
			-- Efecto selección
			btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			voteEvent:FireServer(map.Id)
			
			-- Deshabilitar otros
			for _, other in pairs(voteContainer:GetChildren()) do
				if other:IsA("GuiButton") and other ~= btn then
					other.AutoButtonColor = false
					other.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
					other.TextTransparency = 0.5
				end
			end
		end)
	end
end

-- === HANDLER PRINCIPAL ===
matchStatusEvent.OnClientEvent:Connect(function(status, data)
	if status == "TRANSITION" then
		-- Iniciar Transición de Ronda
		mainFrame.Visible = true
		podiumFrame.Visible = false
		voteFrame.Visible = false
		
		setCinematicCamera(true)
		
		roundTitle.Text = "RONDA " .. data.Round
		
		-- Girar ruleta
		task.spawn(function()
			spinRoulette(data.TargetEvent, data.Duration)
		end)
		
	elseif status == "PREPARE" then
		-- Fin de transición, volver a cámara jugador
		setCinematicCamera(false)
		mainFrame.Visible = false
		
	elseif status == "PODIUM" then
		-- Mostrar Podio
		mainFrame.Visible = true
		rouletteFrame.Visible = false
		voteFrame.Visible = false
		setCinematicCamera(true)
		
		showPodium(data)
		
	elseif status == "VOTING" then
		-- Mostrar Votación
		podiumFrame.Visible = false
		showVoting(data)
		
	elseif status == "MAP_RESULT" then
		-- Mostrar resultado (Reusamos el titulo de votacion)
		voteTitle.Text = "MAPA ELEGIDO: " .. data.Name
		voteContainer.Visible = false
		task.wait(2)
		mainFrame.Visible = false
		setCinematicCamera(false)
		
	elseif status == "WAITING" then
		mainFrame.Visible = false
		setCinematicCamera(false)
	end
end)