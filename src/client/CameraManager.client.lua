local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService") -- NUEVO SERVICIO
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- EVENTOS
local shakeEvent = ReplicatedStorage:WaitForChild("ScreenShakeEvent")

-- CONFIGURACIÓN SHAKE
local MAX_INTENSITY = 2.5
local MAX_DISTANCE = 300

-- ESTADOS
local isCursorFree = false -- Control manual (Rueda del ratón)
local shakeIntensity = 0

-- REFERENCIA A LA TIENDA
local shopFrame = nil

-----------------------------------------------------------------------
-- ANULAR CLICK DERECHO DE ROBLOX
-----------------------------------------------------------------------
-- Esta función captura el click derecho y lo "hunde" (Sink) para que
-- la cámara por defecto de Roblox no lo reciba.
local function disableRightClick(actionName, inputState, inputObject)
	return Enum.ContextActionResult.Sink
end

-- Vinculamos la acción con alta prioridad (3000) para ganarle a los scripts default
ContextActionService:BindActionAtPriority(
	"DisableRightClickCam", 
	disableRightClick, 
	false, 
	3000, 
	Enum.UserInputType.MouseButton2
)

-----------------------------------------------------------------------
-- BUSCADOR DE LA TIENDA
-----------------------------------------------------------------------
task.spawn(function()
	local shopUI = playerGui:WaitForChild("ShopMenuUI", 10)
	if shopUI then
		shopFrame = shopUI:WaitForChild("ShopMenu", 10)
		
		if shopFrame then
			shopFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				if not shopFrame.Visible then
					isCursorFree = false
				end
				updateMouseState()
			end)
		end
	end
end)

-----------------------------------------------------------------------
-- LÓGICA DE CURSOR Y CÁMARA
-----------------------------------------------------------------------
function updateMouseState()
	-- 1. ¿Está la tienda visible?
	local isShopOpen = (shopFrame and shopFrame.Visible)
	
	-- 2. Decidir estado
	if isShopOpen or isCursorFree then
		-- MODO MENÚ / LIBRE
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		-- MODO JUEGO
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

-- Detectar clic de la rueda del ratón (MouseButton3) para liberar cursor manualmente
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton3 then
		isCursorFree = not isCursorFree
		updateMouseState()
	end
end)

-- Loop Principal (RenderStepped)
RunService:BindToRenderStep("CameraManagerUpdate", Enum.RenderPriority.Camera.Value + 1, function()
	
	-- 1. Reforzar estado del Mouse
	local isShopOpen = (shopFrame and shopFrame.Visible)
	if not isShopOpen and not isCursorFree then
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end

	-- 2. Lógica de Screen Shake
	if shakeIntensity > 0 then
		local dx = (math.random() - 0.5) * shakeIntensity
		local dy = (math.random() - 0.5) * shakeIntensity
		local dz = (math.random() - 0.5) * shakeIntensity
		
		camera.CFrame = camera.CFrame * CFrame.new(dx, dy, dz)
		shakeIntensity = math.max(0, shakeIntensity - 0.1) 
	end
end)

-----------------------------------------------------------------------
-- RECEPCIÓN DE EVENTOS (SHAKE)
-----------------------------------------------------------------------
shakeEvent.OnClientEvent:Connect(function(impactPosition)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local distance = (hrp.Position - impactPosition).Magnitude
	
	if distance < MAX_DISTANCE then
		local strength = 1 - (distance / MAX_DISTANCE)
		shakeIntensity = strength * MAX_INTENSITY
	end
end)

-- Inicializar estado
updateMouseState()