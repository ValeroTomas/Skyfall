local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- CONFIGURACIÓN
local DebugKey = true 
local KEY_TO_PRESS = Enum.KeyCode.P

local debugRespawnEvent = ReplicatedStorage:WaitForChild("DebugRespawnEvent")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if DebugKey and input.KeyCode == KEY_TO_PRESS then
        print("Debug: Solicitando respawn masivo al servidor...")
        debugRespawnEvent:FireServer()
    end
end)