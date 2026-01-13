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

local sharedFolder = ReplicatedStorage:WaitForChild("shared")
local FontManager = require(sharedFolder:WaitForChild("FontManager"))
local SoundManager = require(sharedFolder:WaitForChild("SoundManager"))

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TransitionUI"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function toggleMainHUD(visible)
	local mainHUD = playerGui:FindFirstChild("MainGameHUD")
	if mainHUD then mainHUD.Enabled = visible end
end

-- FRAMES
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(1,0,1,0); mainFrame.BackgroundTransparency = 1; mainFrame.Visible = false

local roundTitle = Instance.new("TextLabel", mainFrame)
roundTitle.Size = UDim2.new(1,0,0.2,0); roundTitle.Position = UDim2.new(0,0,0.1,0)
roundTitle.BackgroundTransparency = 1; roundTitle.TextColor3 = Color3.new(1,1,1)
roundTitle.TextStrokeTransparency = 0; roundTitle.FontFace = FontManager.Get("Cartoon"); roundTitle.TextSize = 60

local rouletteFrame = Instance.new("Frame", mainFrame)
rouletteFrame.Size = UDim2.new(0.6, 0, 0.15, 0); rouletteFrame.Position = UDim2.new(0.2, 0, 0.4, 0)
rouletteFrame.BackgroundColor3 = Color3.fromRGB(0,0,0); rouletteFrame.BackgroundTransparency = 0.5
rouletteFrame.ClipsDescendants = true
Instance.new("UICorner", rouletteFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", rouletteFrame).Color = Color3.new(1,1,1)

local rouletteStrip = Instance.new("Frame", rouletteFrame)
rouletteStrip.Size = UDim2.new(1, 0, 10, 0); rouletteStrip.BackgroundTransparency = 1

local pointer = Instance.new("ImageLabel", rouletteFrame)
pointer.Size = UDim2.new(0, 40, 0, 40); pointer.Position = UDim2.new(0.5, -20, 0, -20)
pointer.BackgroundTransparency = 1; pointer.Image = "rbxassetid://13004332997"
pointer.ZIndex = 10

-- PODIO & VOTACION (Igual que antes, omito detalles repetidos para foco en ruleta)
local podiumFrame = Instance.new("Frame", mainFrame)
podiumFrame.Size = UDim2.new(0.8, 0, 0.6, 0); podiumFrame.Position = UDim2.new(0.1, 0, 0.2, 0); podiumFrame.BackgroundTransparency = 1; podiumFrame.Visible = false
local podiumTitle = Instance.new("TextLabel", podiumFrame); podiumTitle.Size = UDim2.new(1,0,0.2,0); podiumTitle.BackgroundTransparency = 1; podiumTitle.Text = "GANADORES"; podiumTitle.TextColor3 = Color3.fromRGB(255, 215, 0); podiumTitle.FontFace = FontManager.Get("Cartoon"); podiumTitle.TextSize = 50

local voteFrame = Instance.new("Frame", mainFrame)
voteFrame.Size = UDim2.new(0.8, 0, 0.5, 0); voteFrame.Position = UDim2.new(0.1, 0, 0.25, 0); voteFrame.BackgroundTransparency = 1; voteFrame.Visible = false
local voteTitle = Instance.new("TextLabel", voteFrame); voteTitle.Text = "SIGUIENTE MAPA"; voteTitle.Size = UDim2.new(1,0,0.2,0); voteTitle.BackgroundTransparency = 1; voteTitle.TextColor3 = Color3.new(1,1,1); voteTitle.FontFace = FontManager.Get("Cartoon"); voteTitle.TextSize = 40
local voteContainer = Instance.new("Frame", voteFrame); voteContainer.Size = UDim2.new(1,0,0.7,0); voteContainer.Position = UDim2.new(0,0,0.3,0); voteContainer.BackgroundTransparency = 1

-- === CAMERA ===
local cameraConnection = nil
local function setCinematicCamera(enable)
	if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
	if enable then
		local map = workspace:WaitForChild("Map", 5)
		local camPart = map and map:FindFirstChild("CamPos")
		if camPart then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = camPart.CFrame
			cameraConnection = RunService.RenderStepped:Connect(function()
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = camPart.CFrame
			end)
		end
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 24}):Play()
	else
		camera.CameraType = Enum.CameraType.Custom
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	end
end

-- === RULETA LOGICA ===
local function spinRoulette(targetText, duration)
	rouletteFrame.Visible = true
	-- IMPORTANTE: Resetear posición antes de llenar
	rouletteStrip.Position = UDim2.new(0,0,0,0) 
	rouletteStrip:ClearAllChildren()
	
	local listLayout = Instance.new("UIListLayout", rouletteStrip)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
	local fillers = {"LLUVIA DE MAGMA", "BLOQUES DE HIELO", "PATATA CALIENTE", "NORMAL", "GRAVEDAD CERO", "TODO EXPLOTA"}
	local winnerIndex = 45 -- El item que queremos que quede en el centro
	local itemHeight = 60
	
	for i = 1, 55 do
		local txt = fillers[math.random(1, #fillers)]
		if i == winnerIndex then txt = targetText end
		
		local label = Instance.new("TextLabel", rouletteStrip)
		label.LayoutOrder = i
		label.Size = UDim2.new(1, 0, 0, itemHeight)
		label.BackgroundTransparency = 1
		label.Text = txt
		label.TextColor3 = (i == winnerIndex) and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(150, 150, 150)
		label.TextSize = 30
		label.FontFace = FontManager.Get("Cartoon")
		label.TextStrokeTransparency = 0
	end
	
	-- Esperar a que UI se actualice
	task.wait() 
	
	-- CÁLCULO PRECISO
	-- Queremos que el CENTRO del Item ganador coincida con el CENTRO del frame contenedor.
	-- Posición Y del Item Ganador (Centro) = (winnerIndex - 1) * itemHeight + (itemHeight / 2)
	-- Posición Y del Centro del Frame = FrameHeight / 2
	-- Offset necesario = CentroFrame - CentroItem
	
	local frameHeight = rouletteFrame.AbsoluteSize.Y
	if frameHeight == 0 then frameHeight = 100 end -- Fallback
	
	local itemCenterY = ((winnerIndex - 1) * itemHeight) + (itemHeight / 2)
	local frameCenterY = frameHeight / 2
	local targetY = frameCenterY - itemCenterY
	
	-- Reproducir sonido con ID directo
	local s = Instance.new("Sound", workspace)
	s.SoundId = "rbxassetid://9060598839"
	s.PlayOnRemove = true
	s:Destroy()
	
	local tween = TweenService:Create(rouletteStrip, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, targetY)})
	tween:Play()
	
	tween.Completed:Wait()
	
	local s2 = Instance.new("Sound", workspace)
	s2.SoundId = "rbxassetid://4612375233"
	s2.PlayOnRemove = true
	s2:Destroy()
	
	task.wait(1)
	rouletteFrame.Visible = false
end

-- (Funciones showPodium y showVoting se mantienen iguales, omitidas por brevedad pero inclúyelas si copias todo)
-- INCLUYE AQUÍ showPodium y showVoting del script anterior.

local function showPodium(data)
	podiumFrame.Visible = true
	for _, c in pairs(podiumFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local layout = Instance.new("UIListLayout", podiumFrame); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	podiumTitle.Parent = podiumFrame; local spacer = Instance.new("Frame", podiumFrame); spacer.Size = UDim2.new(1,0,0.2,0); spacer.BackgroundTransparency = 1; spacer.LayoutOrder = 0
	for i, winner in ipairs(data) do
		if i > 3 then break end
		local row = Instance.new("Frame", podiumFrame); row.LayoutOrder = i; row.Size = UDim2.new(1, 0, 0.2, 0); row.BackgroundColor3 = Color3.new(0,0,0); row.BackgroundTransparency = 0.5
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
		local t = Instance.new("TextLabel", row); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.Text = "#" .. i .. " " .. winner.Name .. " (" .. winner.Wins .. " Wins)"; t.TextColor3 = Color3.new(1,1,1); t.TextSize = 24; t.FontFace = FontManager.Get("Cartoon")
	end
end

local function showVoting(mapList)
	voteFrame.Visible = true; voteContainer:ClearAllChildren()
	local l = Instance.new("UIListLayout", voteContainer); l.FillDirection = Enum.FillDirection.Horizontal; l.Padding = UDim.new(0,20); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local voted = false
	for _, m in ipairs(mapList) do
		local b = Instance.new("TextButton", voteContainer); b.Size = UDim2.new(0,150,1,0); b.Text = m.Name; b.BackgroundColor3 = Color3.fromRGB(40,40,60); b.TextColor3 = Color3.new(1,1,1); b.FontFace = FontManager.Get("Cartoon"); b.TextSize = 24
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
		b.MouseButton1Click:Connect(function() if voted then return end; voted = true; b.BackgroundColor3 = Color3.fromRGB(0,200,100); voteEvent:FireServer(m.Id) end)
	end
end

matchStatusEvent.OnClientEvent:Connect(function(status, data)
	if status == "TRANSITION" then
		toggleMainHUD(false)
		mainFrame.Visible = true; podiumFrame.Visible = false; voteFrame.Visible = false
		setCinematicCamera(true)
		roundTitle.Text = "RONDA " .. data.Round
		task.spawn(function() spinRoulette(data.TargetEvent, data.Duration) end)
		
	elseif status == "PREPARE" then
		toggleMainHUD(true)
		setCinematicCamera(false)
		mainFrame.Visible = false
		
	elseif status == "PODIUM" then
		toggleMainHUD(false)
		mainFrame.Visible = true; rouletteFrame.Visible = false; voteFrame.Visible = false
		setCinematicCamera(true)
		showPodium(data)
		
	elseif status == "VOTING" then
		toggleMainHUD(false)
		podiumFrame.Visible = false
		showVoting(data)
		
	elseif status == "MAP_RESULT" then
		voteTitle.Text = "MAPA ELEGIDO: " .. data.Name; voteContainer.Visible = false
		task.wait(2)
		mainFrame.Visible = false; setCinematicCamera(false); toggleMainHUD(true)
		
	elseif status == "WAITING" then
		mainFrame.Visible = false; setCinematicCamera(false); toggleMainHUD(true)
	end
end)