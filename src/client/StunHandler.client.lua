local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ACTION_NAME = "FreezeMovement"

-- Función que "traga" el input (Sink) para que no haga nada
local function sinkInput(actionName, inputState, inputObject)
	return Enum.ContextActionResult.Sink
end

local function updateStunState()
	local isStunned = player:GetAttribute("IsStunned") == true
	
	if isStunned then
		-- BLOQUEAR MOVIMIENTO
		-- Vinculamos todas las teclas de movimiento y salto a una función vacía con prioridad ALTA
		ContextActionService:BindActionAtPriority(
			ACTION_NAME, 
			sinkInput, 
			false, 
			Enum.ContextActionPriority.High.Value + 50, -- Prioridad máxima
			Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight,
			Enum.PlayerActions.CharacterJump
		)
		print("Controles Bloqueados (Stun)")
	else
		-- DESBLOQUEAR
		ContextActionService:UnbindAction(ACTION_NAME)
		print("Controles Liberados")
	end
end

-- Escuchar cambios
player:GetAttributeChangedSignal("IsStunned"):Connect(updateStunState)

-- Chequeo inicial
updateStunState()