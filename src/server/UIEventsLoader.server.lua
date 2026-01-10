local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lista de eventos de Interfaz (BindableEvents para comunicación Cliente-Cliente)
local eventsToCreate = {
	"ToggleShopEvent",
	"ToggleInventoryEvent",
	"ToggleChangelogEvent"
}

for _, eventName in ipairs(eventsToCreate) do
	if not ReplicatedStorage:FindFirstChild(eventName) then
		local ev = Instance.new("BindableEvent")
		ev.Name = eventName
		ev.Parent = ReplicatedStorage
		print("✅ Evento UI Creado: " .. eventName)
	end
end