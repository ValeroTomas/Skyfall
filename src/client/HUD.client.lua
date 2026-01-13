local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("shared")

-- GUI PRINCIPAL
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "MainGameHUD"
screenGui.ResetOnSpawn = false

-- CARPETA DE MÓDULOS
local modulesFolder = script.Parent:WaitForChild("HUDModules")

-- REQUERIR E INICIAR MÓDULOS
local Modules = {
	require(modulesFolder:WaitForChild("HUDCoins")),
	require(modulesFolder:WaitForChild("HUDTimer")),
	require(modulesFolder:WaitForChild("HUDAlive")),
	require(modulesFolder:WaitForChild("HUDCenter")),
	require(modulesFolder:WaitForChild("HUDSpectator")) -- [NUEVO] ¡Ahora sí funciona!
}

print("🚀 HUD: Iniciando Módulos...")

for _, module in ipairs(Modules) do
	task.spawn(function()
		module.Init(screenGui, sharedFolder)
	end)
end

print("✅ HUD: Todos los módulos cargados.")