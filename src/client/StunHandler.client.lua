local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local ACTION_NAME = "FreezeMovement"

-- Función que "traga" el input (Sink) para que no haga nada
local function sinkInput(actionName, inputState, inputObject)
	return Enum.ContextActionResult.Sink
end

local isLocked = false

-- Chequeo constante en cada frame
RunService.Heartbeat:Connect(function()
	-- Leemos el Timestamp (marca de tiempo) del atributo
	local untilTime = player:GetAttribute("StunnedUntil") or 0
	local now = workspace:GetServerTimeNow() -- Hora precisa del servidor
	
	-- Si la hora actual es MENOR que la hora de fin, seguimos stuneados
	if now < untilTime then
		if not isLocked then
			isLocked = true
			
			-- BLOQUEAR MOVIMIENTO
			-- Vinculamos todas las teclas de movimiento y salto con prioridad MUY ALTA
			ContextActionService:BindActionAtPriority(
				ACTION_NAME, 
				sinkInput, 
				false, 
				Enum.ContextActionPriority.High.Value + 50, -- +50 asegura que gane a los controles de Roblox
				Enum.PlayerActions.CharacterForward,
				Enum.PlayerActions.CharacterBackward,
				Enum.PlayerActions.CharacterLeft,
				Enum.PlayerActions.CharacterRight,
				Enum.PlayerActions.CharacterJump
			)
			-- print("🔒 Controles Bloqueados (Stun activo)")
		end
	else
		-- LIBERAR MOVIMIENTO
		if isLocked then
			isLocked = false
			ContextActionService:UnbindAction(ACTION_NAME)
			-- print("🔓 Controles Liberados")
		end
	end
end)