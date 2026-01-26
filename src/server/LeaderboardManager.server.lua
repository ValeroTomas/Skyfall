local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- CONFIGURACIÓN
local UPDATE_INTERVAL = 15 
local DATA_VERSION = "BETA1.8" 
local MAX_ITEMS = 50 

-- Referencias
local WinsODS = DataStoreService:GetOrderedDataStore("GlobalWins_" .. DATA_VERSION)
local CoinsODS = DataStoreService:GetOrderedDataStore("GlobalCoins_" .. DATA_VERSION)
local estadoValue = ReplicatedStorage:WaitForChild("EstadoRonda")

-- Estética Títulos
local COLOR_WINS_1 = Color3.fromRGB(255, 220, 0)   
local COLOR_WINS_2 = Color3.fromRGB(255, 140, 0)   
local COLOR_COINS_1 = Color3.fromRGB(0, 255, 100)  
local COLOR_COINS_2 = Color3.fromRGB(0, 150, 50)   
local FONT_ID = "rbxassetid://12187370000" -- Fuente Cartoon

local nameCache = {}
local function getUsername(userId)
	if nameCache[userId] then return nameCache[userId] end
	local success, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	if success then nameCache[userId] = name; return name else return "Unknown" end
end

-- TABLA PARA MULTIPLES CARTELES
local activeBoards = {}
local currentMode = "Wins"

-- 1. CONSTRUCTOR DE INTERFAZ
local function setupBoardUI(boardPart)
	local oldGui = boardPart:FindFirstChild("LeaderboardUI")
	if oldGui then oldGui:Destroy() end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardUI"
	surfaceGui.Parent = boardPart
	surfaceGui.Face = Enum.NormalId.Front 

	surfaceGui.AlwaysOnTop = false 
	surfaceGui.LightInfluence = 0 
	surfaceGui.ZOffset = 1
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 30 

	local canvas = Instance.new("CanvasGroup", surfaceGui)
	-- [CLAVE PARA EL EFECTO TV] Anclamos el Canvas al centro para que colapse hacia el medio
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	-- Agregamos un brillo sutil que usaremos en la animación
	canvas.GroupColor3 = Color3.new(1, 1, 1)

	local bg = Instance.new("Frame", canvas)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	bg.BorderSizePixel = 0

	local titleLabel = Instance.new("TextLabel", bg)
	titleLabel.Size = UDim2.new(1, 0, 0.16, 0) 
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(1,1,1)
	titleLabel.TextScaled = true
	titleLabel.FontFace = Font.new(FONT_ID, Enum.FontWeight.Heavy)
	titleLabel.Text = "LOADING..."
	local titleStroke = Instance.new("UIStroke", titleLabel); titleStroke.Thickness = 5

	local container = Instance.new("ScrollingFrame", bg)
	container.Size = UDim2.new(0.95, 0, 0.78, 0)
	container.Position = UDim2.new(0.025, 0, 0.18, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	container.Active = true 
	container.ScrollBarThickness = 35 
	container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.new(0, 0, 0, 0)

	local listLayout = Instance.new("UIListLayout", container)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 12) 

	table.insert(activeBoards, {
		part = boardPart,
		gui = surfaceGui,
		canvas = canvas,
		container = container,
		titleLabel = titleLabel
	})

	print("✅ LeaderboardManager: Interfaz montada.")
end

-- 2. DETECTOR DE MAPA
local function checkForLeaderboard()
	local map = Workspace:FindFirstChild("Map")
	if map then
		activeBoards = {}
		for _, child in ipairs(map:GetDescendants()) do
			if child.Name == "GlobalLeaderboard" and child:IsA("BasePart") then
				setupBoardUI(child)
			end
		end
	end
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then task.wait(1); checkForLeaderboard() end
end)
checkForLeaderboard()

-- 3. GUARDADO DE DATOS
local function savePlayerStats(player)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local coins = ls:FindFirstChild("Coins")
		local wins = ls:FindFirstChild("Wins")
		if coins then pcall(function() CoinsODS:SetAsync(player.UserId, coins.Value) end) end
		if wins then pcall(function() WinsODS:SetAsync(player.UserId, wins.Value) end) end
	end
end

Players.PlayerRemoving:Connect(savePlayerStats)
task.spawn(function()
	while true do task.wait(120); for _, p in ipairs(Players:GetPlayers()) do savePlayerStats(p) end end
end)

-- 4. RENDERIZADO DE BARRAS
local function createRow(rank, name, value, isWins)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -35, 0, 200) 
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 15)

	local rowStroke = Instance.new("UIStroke", row)
	rowStroke.Thickness = 3; rowStroke.Color = Color3.new(0,0,0); rowStroke.Transparency = 0.5

	if rank == 1 then row.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
	elseif rank == 2 then row.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
	elseif rank == 3 then row.BackgroundColor3 = Color3.fromRGB(160, 80, 40)
	else row.BackgroundColor3 = Color3.fromRGB(50, 55, 70) end

	local pad = Instance.new("UIPadding", row)
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)

	local rLabel = Instance.new("TextLabel", row)
	rLabel.Size = UDim2.new(0.12, 0, 1, 0); rLabel.BackgroundTransparency = 1
	rLabel.Text = "#" .. rank; rLabel.TextScaled = true
	rLabel.TextColor3 = Color3.new(1,1,1)
	rLabel.FontFace = Font.new(FONT_ID, Enum.FontWeight.Heavy)
	local rStroke = Instance.new("UIStroke", rLabel); rStroke.Thickness = 5

	local nLabel = Instance.new("TextLabel", row)
	nLabel.Size = UDim2.new(0.55, 0, 1, 0); nLabel.Position = UDim2.new(0.15, 0, 0, 0)
	nLabel.BackgroundTransparency = 1; nLabel.Text = name
	nLabel.TextColor3 = Color3.new(1,1,1); nLabel.TextScaled = true
	nLabel.TextXAlignment = Enum.TextXAlignment.Left; nLabel.FontFace = Font.new(FONT_ID, Enum.FontWeight.Bold)
	local nStroke = Instance.new("UIStroke", nLabel); nStroke.Thickness = 5

	local vLabel = Instance.new("TextLabel", row)
	vLabel.Size = UDim2.new(0.25, 0, 1, 0); vLabel.Position = UDim2.new(0.72, 0, 0, 0)
	vLabel.BackgroundTransparency = 1; vLabel.Text = tostring(value)
	vLabel.TextColor3 = Color3.new(1,1,1); vLabel.TextScaled = true
	vLabel.TextXAlignment = Enum.TextXAlignment.Right; vLabel.FontFace = Font.new(FONT_ID, Enum.FontWeight.Heavy)
	local vStroke = Instance.new("UIStroke", vLabel); vStroke.Thickness = 5

	return row
end

-- 5. ACTUALIZADOR DE PANTALLA
local function updateBoard()
	if #activeBoards == 0 then return end

	local ods = (currentMode == "Wins") and WinsODS or CoinsODS
	local titleText = (currentMode == "Wins") and "🏆 TOP WINS 🏆" or "💰 TOP RICHEST 💰"
	local color1 = (currentMode == "Wins") and COLOR_WINS_1 or COLOR_COINS_1
	local color2 = (currentMode == "Wins") and COLOR_WINS_2 or COLOR_COINS_2

	local success, pages = pcall(function() return ods:GetSortedAsync(false, MAX_ITEMS) end)

	if success and pages then
		local data = pages:GetCurrentPage()
		for _, board in ipairs(activeBoards) do
			if board.container and board.container.Parent then
				for _, child in ipairs(board.container:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end

				board.titleLabel.Text = titleText
				local grad = board.titleLabel:FindFirstChild("UIGradient") or Instance.new("UIGradient", board.titleLabel)
				grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
				grad.Rotation = 90

				for rank, entry in ipairs(data) do
					local name = getUsername(entry.key)
					local row = createRow(rank, name, entry.value, (currentMode == "Wins"))
					row.Parent = board.container
				end
			end
		end
	end
end

-- 6. [NUEVO] EFECTO TV VIEJA (CRT EFFECT)
local lastStateType = ""

local function updateVisibility(state)
	local currentState = string.split(state, "|")[1]
	if currentState == lastStateType then return end
	lastStateType = currentState

	local isSurvive = (currentState == "SURVIVE")

	-- Efectos de Tween (Muy rápidos para simular la electricidad)
	local T_Flash = TweenInfo.new(0.05, Enum.EasingStyle.Linear)
	local T_CollapseY = TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
	local T_CollapseX = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local T_ExpandX = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local T_ExpandY = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out) -- Efecto rebote al encender

	-- Desvanecimiento del bloque físico (Tarda 1 segundo)
	local fadeInfoBlock = TweenInfo.new(1, Enum.EasingStyle.Linear) 

	for _, board in ipairs(activeBoards) do
		if board.part and board.canvas then

			if isSurvive then
				-- === APAGAR TV ===
				task.spawn(function()
					-- 1. Destello brillante
					TweenService:Create(board.canvas, T_Flash, {GroupColor3 = Color3.new(3,3,3)}):Play()
					task.wait(0.05)

					-- 2. Colapso Vertical (Se aplasta en una línea blanca)
					TweenService:Create(board.canvas, T_CollapseY, {Size = UDim2.new(1, 0, 0.02, 0)}):Play()
					task.wait(0.15)

					-- 3. Colapso Horizontal y Desvanecimiento
					TweenService:Create(board.canvas, T_CollapseX, {Size = UDim2.new(0, 0, 0.02, 0), GroupTransparency = 1}):Play()

					-- 4. Ocultar bloque físico y quitar colisión
					TweenService:Create(board.part, fadeInfoBlock, {Transparency = 1}):Play()
					board.part.CanCollide = false
					task.wait(0.1)
					board.canvas.Visible = false
				end)
			else
				-- === ENCENDER TV ===
				task.spawn(function()
					board.canvas.Visible = true
					board.canvas.Size = UDim2.new(0, 0, 0.02, 0) -- Empieza invisible
					board.canvas.GroupColor3 = Color3.new(2,2,2) -- Brillo de inicio

					-- 1. Aparece el bloque físico
					board.part.CanCollide = true
					TweenService:Create(board.part, fadeInfoBlock, {Transparency = 0}):Play()
					task.wait(0.5) -- Esperar a que el bloque se vea un poco antes de encender la pantalla

					-- 2. Expansión Horizontal (Línea de luz)
					TweenService:Create(board.canvas, T_ExpandX, {Size = UDim2.new(1, 0, 0.02, 0), GroupTransparency = 0}):Play()
					task.wait(0.15)

					-- 3. Expansión Vertical (Efecto elástico) y restaurar color
					TweenService:Create(board.canvas, T_ExpandY, {Size = UDim2.new(1, 0, 1, 0), GroupColor3 = Color3.new(1,1,1)}):Play()
				end)
			end
		end
	end
end

estadoValue.Changed:Connect(updateVisibility)

-- BUCLE PRINCIPAL
task.spawn(function()
	while true do
		currentMode = "Wins"; updateBoard(); task.wait(UPDATE_INTERVAL)
		currentMode = "Coins"; updateBoard(); task.wait(UPDATE_INTERVAL)
	end
end)