local HUD_Utils = {}
local TweenService = game:GetService("TweenService")

-- Función para limpiar y aplicar estilo Cartoon
function HUD_Utils.ApplyCartoonStyle(textLabel, colorTop, colorBottom, strokeColor)
	textLabel.TextColor3 = Color3.new(1, 1, 1) 
	
	-- CAMBIO DE FUENTE: Usamos FontFace para IDs personalizados
	textLabel.FontFace = Font.new("rbxassetid://12187370000")
	
	-- Limpiar efectos anteriores
	for _, child in pairs(textLabel:GetChildren()) do
		if child:IsA("UIGradient") or child:IsA("UIStroke") then child:Destroy() end
	end
	
	-- Gradiente
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, colorTop),    
		ColorSequenceKeypoint.new(1, colorBottom) 
	}
	gradient.Parent = textLabel
	
	-- Borde
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = strokeColor or Color3.fromRGB(20, 20, 20) 
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = textLabel
end

-- Creador de etiquetas base
function HUD_Utils.CreateLabel(name, size, pos, anchor, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.AnchorPoint = anchor
	label.BackgroundTransparency = 1
	label.TextSize = 22
	label.Parent = parent
	return label
end

return HUD_Utils