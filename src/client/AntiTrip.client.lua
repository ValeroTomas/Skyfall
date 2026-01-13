local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- [FIX] Wait for the character properly
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Reset physics states
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

print("🛡️ Sistema de Estabilidad: Activado (Anti-Trip)")

-- Handle respawns
player.CharacterAdded:Connect(function(newChar)
    local newHum = newChar:WaitForChild("Humanoid")
    newHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    newHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end)