local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local jumpEvent = ReplicatedStorage:WaitForChild("DoubleJumpEvent")

-- ESTADO
local canDoubleJump = false
local hasDoubleJumped = false
local lastJumpTime = 0
local JUMP_COOLDOWN = 0.2 

local function getJumpVelocity(humanoid)
	if humanoid.UseJumpPower then
		return humanoid.JumpPower
	else
		return math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
	end
end

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	local rootPart = char:WaitForChild("HumanoidRootPart")

	humanoid.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			hasDoubleJumped = false
		elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
			if not hasDoubleJumped then
				canDoubleJump = true
			end
		end
	end)

	humanoid.Jumping:Connect(function()
		lastJumpTime = tick()
	end)

	UserInputService.JumpRequest:Connect(function()
		if tick() - lastJumpTime < JUMP_COOLDOWN then return end
		
		-- LEEMOS EL ATRIBUTO SINCRONIZADO DESDE EL SERVIDOR
		-- Si es nil o false, no entra.
		local ownsUpgrade = player:GetAttribute("CanDoubleJump") == true

		if canDoubleJump and not hasDoubleJumped and ownsUpgrade then
			
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
				
				hasDoubleJumped = true
				lastJumpTime = tick()
				
				local jumpVel = getJumpVelocity(humanoid) * 0.9
				local currentVel = rootPart.AssemblyLinearVelocity
				rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, jumpVel, currentVel.Z)
				
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				
				jumpEvent:FireServer()
			end
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)