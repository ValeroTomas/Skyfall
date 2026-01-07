local ShopConfig = {}

ShopConfig.MAX_LEVEL = 5

-- PRECIOS (Monedas) - Estos se quedan igual
ShopConfig.Prices = {
	-- SALTO
	JumpHeight = {100, 200, 350, 600, 1000},
	JumpStaminaCost = {150, 300, 500, 800, 1200},
	DoubleJump = 2500, 
	DoubleJumpColor = 5000, 
	
	-- EMPUJE
	PushUnlock = 2000, 
	PushDistance = {100, 250, 450, 700, 1100},
	PushRange = {100, 250, 450, 700, 1100},
	PushCooldown = {200, 400, 700, 1000, 1500},
	
	-- ESQUIVE
	DashUnlock = 3000, 
	DashDistance = {200, 400, 700, 1100, 1600},
	DashCooldown = {200, 400, 700, 1100, 1600},
	DashSpeed = {150, 300, 500, 800, 1200},
	DashColor = 5000, 
	
	-- STAMINA
	MaxStamina = {100, 250, 450, 750, 1200},
	StaminaRegen = {150, 300, 550, 900, 1400},
	StaminaDrain = {150, 300, 550, 900, 1400},
}

-- VALORES REALES (STATS) POR NIVEL [1 al 5]
ShopConfig.Stats = {
	-- SALTO 
	JumpHeight = {50, 60, 70, 85, 100}, 
	
	-- COSTE DE STAMINA (MULTIPLICADORES)
	-- Nivel 1 = 100% del coste, Nivel 5 = 50% del coste
	JumpStaminaCost = {1.0, 0.9, 0.8, 0.7, 0.5}, 
	
	-- EMPUJE
	PushDistance = {50, 70, 90, 120, 150},
	PushRange = {5, 7, 10, 12, 15}, 
	PushCooldown = {10, 8, 6, 4, 2}, 
	
	-- ESQUIVE
	DashDistance = {30, 45, 60, 80, 100}, 
	DashCooldown = {8, 6, 5, 4, 2}, 
	DashSpeed = {1, 1.2, 1.5, 1.8, 2.0}, 
	
	-- STAMINA
	MaxStamina = {100, 120, 150, 180, 250},
	StaminaRegen = {5, 8, 12, 18, 25}, 
	StaminaDrain = {20, 18, 16, 14, 10}, 
}

-- ITEMS ESPECIALES
ShopConfig.SpecialItems = {
	DoubleJumpColor = true, 
	DashColor = true,
	DoubleJump = true,
	PushUnlock = true,
	DashUnlock = true
}

return ShopConfig