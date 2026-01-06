local map = workspace:WaitForChild("Map")
local lava = map:WaitForChild("Lava")

lava.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		character:SetAttribute("KilledByLava", true)
		humanoid.Health = 0
	end
end)