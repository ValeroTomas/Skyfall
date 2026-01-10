local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Esperamos un frame por seguridad para asegurar que el Humanoid cargó bien
task.wait()

-- Desactivamos los estados que provocan que el personaje se caiga solo
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

-- Opcional: PlatformStand a veces causa comportamientos raros si no se controla
-- Si no tienes mecánicas de patinetas o surf, puedes desactivarlo también:
-- humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, false)

print("🛡️ Sistema de Estabilidad: Activado (Anti-Trip)")