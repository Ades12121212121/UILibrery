local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local enabled = true
local zombieFolder = workspace:FindFirstChild("Zombies") -- Ajustar según la estructura del juego

-- Crear GUI para controlar el script
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZombieKillerGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Intentar colocar en CoreGui para mayor visibilidad
pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)

if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Crear marco principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.8, -100, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Añadir esquinas redondeadas
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = mainFrame

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "Zombie Killer"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

-- Esquinas para el título
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleLabel

-- Botón de activar/desactivar
local toggleButton = Instance.new("TextButton")
toggleButton.Position = UDim2.new(0.5, -75, 0.5, 0)
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.Text = "ACTIVADO"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Parent = mainFrame

-- Esquinas para el botón
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 4)
buttonCorner.Parent = toggleButton

-- Función para encontrar zombies
local function findZombies()
    local zombies = {}
    
    -- Método 1: Buscar en carpeta específica (común en juegos organizados)
    if zombieFolder then
        for _, zombie in pairs(zombieFolder:GetChildren()) do
            if zombie:FindFirstChild("Humanoid") and zombie:FindFirstChild("HumanoidRootPart") then
                table.insert(zombies, zombie)
            end
        end
    end
    
    -- Método 2: Buscar por nombre (si no hay carpeta específica)
    if #zombies == 0 then
        for _, instance in pairs(workspace:GetDescendants()) do
            if instance:IsA("Model") and 
               (instance.Name:lower():find("zombie") or 
                instance.Name:lower():find("infected")) and
               instance:FindFirstChild("Humanoid") and 
               instance:FindFirstChild("HumanoidRootPart") then
                table.insert(zombies, instance)
            end
        end
    end
    
    -- Método 3: Buscar por propiedades específicas del juego
    if #zombies == 0 then
        for _, instance in pairs(workspace:GetDescendants()) do
            if instance:IsA("Model") and 
               instance:FindFirstChild("Humanoid") and 
               instance:FindFirstChild("HumanoidRootPart") and
               not Players:GetPlayerFromCharacter(instance) then
                -- Verificar si tiene alguna propiedad que indique que es un zombie
                if instance:FindFirstChild("ZombieScript") or 
                   (instance:FindFirstChild("Configuration") and 
                    instance.Configuration:FindFirstChild("IsZombie")) then
                    table.insert(zombies, instance)
                end
            end
        end
    end
    
    return zombies
end

-- Función para eliminar zombies
local function killZombies()
    if not enabled then return end
    
    local zombies = findZombies()
    for _, zombie in pairs(zombies) do
        local humanoid = zombie:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            -- Intentar diferentes métodos para eliminar zombies
            
            -- Método 1: Usar TakeDamage (funciona en la mayoría de juegos)
            humanoid:TakeDamage(humanoid.MaxHealth)
            
            -- Método 2: Establecer salud directamente (alternativa)
            -- humanoid.Health = 0
        end
    end
end

-- Función para alternar el estado
toggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        toggleButton.Text = "ACTIVADO"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "DESACTIVADO"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    end
end)

-- Hacer que el marco sea arrastrable
local dragging = false
local dragInput
local dragStart
local startPos

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Ejecutar la función de eliminación de zombies periódicamente
RunService.Heartbeat:Connect(function()
    killZombies()
end)

-- Buscar la carpeta de zombies si cambia
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Zombies" or child.Name:lower():find("zombie") then
        zombieFolder = child
    end
end)

-- Mensaje de inicio
print("Script de eliminación automática de zombies iniciado")
