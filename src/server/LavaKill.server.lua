local mapParent = workspace

local function connectLava(mapModel)
	local lava = mapModel:FindFirstChild("Lava")
	if not lava then return end
	
	-- Desconectar eventos previos si fuera necesario (aunque al destruirse el mapa viejo se limpian solos)
	print("🔥 Lava conectada para el nuevo mapa")
	
	lava.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			character:SetAttribute("KilledByLava", true)
			humanoid.Health = 0
		end
	end)
end

-- 1. Conectar si ya existe el mapa al inicio
if workspace:FindFirstChild("Map") then
	connectLava(workspace.Map)
end

-- 2. Detectar cuando el RoundManager carga un mapa nuevo
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		-- Esperar un instante a que termine de clonarse todo el contenido
		task.wait(0.1) 
		connectLava(child)
	end
end)