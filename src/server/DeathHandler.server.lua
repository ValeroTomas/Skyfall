local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerManager = require(script.Parent.PlayerManager)

local killfeedEvent = ReplicatedStorage:WaitForChild("KillfeedEvent")

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            ---------------------------------------------------------------
            -- 1. CÁLCULO DE RANK (PUESTO)
            ---------------------------------------------------------------
            local currentAlive = PlayerManager.GetAlivePlayers()
            local rank = #currentAlive + 1
            
            -- CORRECCIÓN: Si mueres y "matemáticamente" eres el 1 (porque quedan 0 vivos),
            -- en realidad NO ganaste (porque estás muerto). Te asignamos el puesto 2.
            -- Esto soluciona que aparezca "Puesto #1" cuando nadie sobrevivió.
            if rank == 1 then
                rank = 2
            end
            
            player:SetAttribute("RoundRank", rank)
            
            print(player.Name .. " eliminado. Puesto: #" .. rank)

            ---------------------------------------------------------------
            -- 2. KILLFEED
            ---------------------------------------------------------------
            local attackerTag = character:FindFirstChild("LastAttacker")
            local attacker = attackerTag and attackerTag.Value
            
            local cause = "LAVA"
            if character:GetAttribute("Crushed") then
                cause = "CRUSH"
            end
            
            local messageKey = ""
            if attacker and attacker:IsA("Player") then
                messageKey = (cause == "LAVA") and "DEATH_PUSH_LAVA" or "DEATH_PUSH_CRUSH"
                killfeedEvent:FireAllClients(messageKey, player.Name, attacker.Name)
            else
                messageKey = (cause == "LAVA") and "DEATH_LAVA" or "DEATH_CRUSH"
                killfeedEvent:FireAllClients(messageKey, player.Name)
            end
        end)
    end)
end)