-- UILibrary.lua
-- A modern, professional UI library for Roblox scripts

local UILibrary = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Drag and Drop Interface Builder
local InterfaceBuilder = {
    dragging = false,
    selectedElement = nil,
    gridSize = 10,
    snapToGrid = true
}

function InterfaceBuilder:enableDragAndDrop(element)
    element.Draggable = true
    
    element.DragBegan:Connect(function()
        self.dragging = true
        self.selectedElement = element
        
        -- Create guidelines
        self:createGuidelines()
    end)
    
    element.DragEnded:Connect(function(x, y)
        self.dragging = false
        self.selectedElement = nil
        
        -- Cleanup guidelines
        self:removeGuidelines()
        
        -- Snap to grid if enabled
        if self.snapToGrid then
            local newX = math.round(x / self.gridSize) * self.gridSize
            local newY = math.round(y / self.gridSize) * self.gridSize
            element.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    
    return element
end

function InterfaceBuilder:createGuidelines()
    -- Create visual guidelines for alignment
    local guidelines = Instance.new("Frame")
    guidelines.Name = "Guidelines"
    guidelines.BackgroundTransparency = 0.8
    guidelines.BorderSizePixel = 0
    guidelines.ZIndex = 999
    guidelines.Parent = self.selectedElement.Parent
    
    -- Add grid lines
    if self.snapToGrid then
        for i = 0, self.selectedElement.Parent.AbsoluteSize.X, self.gridSize do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, 1, 1, 0)
            line.Position = UDim2.new(0, i, 0, 0)
            line.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            line.BackgroundTransparency = 0.8
            line.Parent = guidelines
        end
    end
end

function InterfaceBuilder:removeGuidelines()
    local guidelines = self.selectedElement.Parent:FindFirstChild("Guidelines")
    if guidelines then
        guidelines:Destroy()
    end
end

-- Responsive Design System
local ResponsiveDesign = {
    breakpoints = {
        small = 600,
        medium = 900,
        large = 1200
    },
    currentBreakpoint = "large"
}

function ResponsiveDesign:setBreakpoints(breakpoints)
    self.breakpoints = breakpoints
end

function ResponsiveDesign:addResponsiveElement(element, styles)
    local function updateStyle()
        local viewportSize = workspace.CurrentCamera.ViewportSize.X
        local newBreakpoint = "large"
        
        for breakpoint, size in pairs(self.breakpoints) do
            if viewportSize <= size then
                newBreakpoint = breakpoint
                break
            end
        end
        
        if styles[newBreakpoint] then
            for property, value in pairs(styles[newBreakpoint]) do
                element[property] = value
            end
        end
        
        self.currentBreakpoint = newBreakpoint
    end
    
    -- Update style initially
    updateStyle()
    
    -- Update style when viewport size changes
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateStyle)
    
    return element
end

-- Plugin system
local plugins = {}

function UILibrary.registerPlugin(name, plugin)
    if type(plugin) ~= "table" or not plugin.init then
        error("Plugin must be a table with an init function")
    end
    plugins[name] = plugin
end

function UILibrary.getPlugin(name)
    return plugins[name]
end

-- Animation manager
local AnimationManager = {
    animations = {},
    easingStyles = {
        linear = function(t) return t end,
        smooth = function(t) return t * t * (3 - 2 * t) end,
        bounce = function(t)
            if t < 1/2.75 then return 7.5625 * t * t
            elseif t < 2/2.75 then t = t - 1.5/2.75; return 7.5625 * t * t + 0.75
            elseif t < 2.5/2.75 then t = t - 2.25/2.75; return 7.5625 * t * t + 0.9375
            else t = t - 2.625/2.75; return 7.5625 * t * t + 0.984375 end
        end
    }
}

function AnimationManager:createAnimation(object, properties, duration, style)
    local animation = {
        object = object,
        properties = properties,
        duration = duration,
        style = self.easingStyles[style] or self.easingStyles.smooth,
        startTime = tick(),
        initialValues = {}
    }
    
    for property, targetValue in pairs(properties) do
        animation.initialValues[property] = object[property]
    end
    
    table.insert(self.animations, animation)
    return animation
end

function AnimationManager:update()
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        local elapsed = tick() - anim.startTime
        local progress = math.min(elapsed / anim.duration, 1)
        local easedProgress = anim.style(progress)
        
        for property, targetValue in pairs(anim.properties) do
            local initial = anim.initialValues[property]
            anim.object[property] = initial:Lerp(targetValue, easedProgress)
        end
        
        if progress >= 1 then
            table.remove(self.animations, i)
        end
    end
end

-- State management system
local StateManager = {
    states = {},
    listeners = {}
}

function StateManager:setState(key, value)
    self.states[key] = value
    if self.listeners[key] then
        for _, callback in ipairs(self.listeners[key]) do
            callback(value)
        end
    end
end

function StateManager:getState(key)
    return self.states[key]
end

function StateManager:subscribe(key, callback)
    if not self.listeners[key] then
        self.listeners[key] = {}
    end
    table.insert(self.listeners[key], callback)
    
    return function()
        local listeners = self.listeners[key]
        for i, listener in ipairs(listeners) do
            if listener == callback then
                table.remove(listeners, i)
                break
            end
        end
    end
end

-- Add to UILibrary
UILibrary.AnimationManager = AnimationManager
UILibrary.StateManager = StateManager

-- Notification system
function UILibrary.createNotification(title, message, duration)
    duration = duration or 3
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 250, 0, 80)
    notification.Position = UDim2.new(1, -270, 1, -100)
    notification.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    notification.BorderSizePixel = 0
    notification.Parent = game:GetService("CoreGui")
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 12
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = notification
    
    -- Animation
    notification.Position = UDim2.new(1, 0, 1, -100)
    TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -270, 1, -100)
    }):Play()
    
    -- Auto close
    task.delay(duration, function()
        local closeTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 0, 1, -100)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    return notification
end

-- Loading screen component
function UILibrary.createLoadingScreen(text, parent)
    local loadingScreen = Instance.new("Frame")
    loadingScreen.Name = "LoadingScreen"
    loadingScreen.Size = UDim2.new(1, 0, 1, 0)
    loadingScreen.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    loadingScreen.BackgroundTransparency = 0.2
    loadingScreen.ZIndex = 1000
    loadingScreen.Parent = parent or game:GetService("CoreGui")

    local loadingContainer = Instance.new("Frame")
    loadingContainer.Size = UDim2.new(0, 200, 0, 100)
    loadingContainer.Position = UDim2.new(0.5, -100, 0.5, -50)
    loadingContainer.BackgroundTransparency = 1
    loadingContainer.ZIndex = 1001
    loadingContainer.Parent = loadingScreen

    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(0, 40, 0, 40)
    spinner.Position = UDim2.new(0.5, -20, 0, 0)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://4456891"  -- Loading spinner asset
    spinner.ZIndex = 1002
    spinner.Parent = loadingContainer

    local loadingText = Instance.new("TextLabel")
    loadingText.Size = UDim2.new(1, 0, 0, 20)
    loadingText.Position = UDim2.new(0, 0, 0.7, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = text or "Loading..."
    loadingText.Font = Enum.Font.GothamBold
    loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingText.TextSize = 16
    loadingText.ZIndex = 1002
    loadingText.Parent = loadingContainer

    -- Animate spinner
    local rotation = 0
    local connection = RunService.RenderStepped:Connect(function()
        rotation = rotation + 5
        spinner.Rotation = rotation
    end)

    -- Return API
    return {
        setProgress = function(progress)
            loadingText.Text = string.format("Loading... %d%%", progress * 100)
        end,
        setText = function(newText)
            loadingText.Text = newText
        end,
        destroy = function()
            connection:Disconnect()
            loadingScreen:Destroy()
        end
    }
end

-- Utility functions
local function createShadow(parent, offset)
    local shadow = Instance.new("ImageLabel")
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, offset or 30, 1, offset or 30)
    shadow.ZIndex = -1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = parent
    return shadow
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

-- Add more utility functions
local function createStroke(parent, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or Color3.fromRGB(60, 60, 70)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function createRipple(parent, x, y)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Position = UDim2.new(0, x, 0, y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = parent
    
    createCorner(ripple, 999)
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(ripple, tweenInfo, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- Component creation functions
function UILibrary.createWindow(title, size, theme)
    local window = {}
    local tabs = {}
    local activeTab = nil
    local isVisible = true
    
    -- Add keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            -- Toggle UI visibility with Right Shift
            if input.KeyCode == Enum.KeyCode.RightShift then
                isVisible = not isVisible
                screenGui.Enabled = isVisible
            end
            
            -- Quick tab switching with number keys
            if input.KeyCode.Name:match("^[1-9]$") then
                local tabNumber = tonumber(input.KeyCode.Name)
                local tabNames = {}
                for name, _ in pairs(tabs) do
                    table.insert(tabNames, name)
                end
                table.sort(tabNames)
                
                if tabNames[tabNumber] then
                    local tabButton = tabs[tabNames[tabNumber]].button
                    tabButton:Fire("MouseButton1Click")
                end
            end
        end
    end)
    
    -- Theme settings
    local themes = {
        Dark = {
            Background = Color3.fromRGB(25, 25, 30),
            SecondaryBackground = Color3.fromRGB(30, 30, 40),
            ElementBackground = Color3.fromRGB(35, 35, 45),
            TextColor = Color3.fromRGB(240, 240, 255),
            AccentColor = Color3.fromRGB(40, 120, 255),
            SuccessColor = Color3.fromRGB(40, 180, 120),
            WarningColor = Color3.fromRGB(255, 140, 40),
            ErrorColor = Color3.fromRGB(255, 70, 70)
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 245),
            SecondaryBackground = Color3.fromRGB(230, 230, 235),
            ElementBackground = Color3.fromRGB(220, 220, 225),
            TextColor = Color3.fromRGB(30, 30, 40),
            AccentColor = Color3.fromRGB(40, 120, 255),
            SuccessColor = Color3.fromRGB(40, 180, 120),
            WarningColor = Color3.fromRGB(255, 140, 40),
            ErrorColor = Color3.fromRGB(255, 70, 70)
        },
        Midnight = {
            Background = Color3.fromRGB(15, 15, 25),
            SecondaryBackground = Color3.fromRGB(20, 20, 35),
            ElementBackground = Color3.fromRGB(25, 25, 40),
            TextColor = Color3.fromRGB(220, 220, 255),
            AccentColor = Color3.fromRGB(100, 80, 255),
            SuccessColor = Color3.fromRGB(40, 180, 120),
            WarningColor = Color3.fromRGB(255, 140, 40),
            ErrorColor = Color3.fromRGB(255, 70, 70)
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 245),
            SecondaryBackground = Color3.fromRGB(230, 230, 235),
            ElementBackground = Color3.fromRGB(220, 220, 225),
            TextColor = Color3.fromRGB(30, 30, 40),
            AccentColor = Color3.fromRGB(40, 120, 255),
            SuccessColor = Color3.fromRGB(40, 180, 120),
            WarningColor = Color3.fromRGB(255, 140, 40),
            ErrorColor = Color3.fromRGB(255, 70, 70)
        },
        Midnight = {
            Background = Color3.fromRGB(15, 15, 25),
            SecondaryBackground = Color3.fromRGB(20, 20, 35),
            ElementBackground = Color3.fromRGB(25, 25, 40),
            TextColor = Color3.fromRGB(220, 220, 255),
            AccentColor = Color3.fromRGB(100, 80, 255),
            SuccessColor = Color3.fromRGB(40, 180, 120),
            WarningColor = Color3.fromRGB(255, 140, 40),
            ErrorColor = Color3.fromRGB(255, 70, 70)
        }
    }
    
    local currentTheme = themes[theme or "Dark"]
    
    -- Create ScreenGui with protected mode for executors
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProfessionalUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    
    -- Enhanced parenting logic for executor compatibility
    local function tryParent()
        local success = pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
            elseif protect_gui then
                protect_gui(screenGui)
                screenGui.Parent = game:GetService("CoreGui")
            else
                screenGui.Parent = game:GetService("CoreGui")
            end
        end)
        
        if not success then
            pcall(function()
                screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
    end
    
    tryParent()
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = size or UDim2.new(0, 500, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -(size and size.X.Offset or 500)/2, 0.5, -(size and size.Y.Offset or 350)/2)
    mainFrame.BackgroundColor3 = currentTheme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    createCorner(mainFrame, 10)
    createShadow(mainFrame)
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = currentTheme.SecondaryBackground
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    createCorner(titleBar, 10)
    
    -- Create title text
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = title or "Professional UI"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = currentTheme.TextColor
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.BackgroundColor3 = currentTheme.ErrorColor
    closeButton.BackgroundTransparency = 0.8
    closeButton.Text = "✕"
    closeButton.TextColor3 = currentTheme.TextColor
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    createCorner(closeButton, 15)
    
    closeButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(closeButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.5
        }):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(closeButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.8
        }):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Create minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -70, 0.5, -15)
    minimizeButton.BackgroundColor3 = currentTheme.WarningColor
    minimizeButton.BackgroundTransparency = 0.8
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = currentTheme.TextColor
    minimizeButton.TextSize = 16
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.AutoButtonColor = false
    minimizeButton.Parent = titleBar
    
    createCorner(minimizeButton, 15)
    
    local minimized = false
    local originalSize = mainFrame.Size
    
    minimizeButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(minimizeButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.5
        }):Play()
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(minimizeButton, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.8
        }):Play()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 40)
            }):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = originalSize
            }):Play()
        end
    end)
    
    -- Create tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 120, 1, -50)
    tabContainer.Position = UDim2.new(0, 10, 0, 45)
    tabContainer.BackgroundColor3 = currentTheme.SecondaryBackground
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    createCorner(tabContainer, 8)
    
    -- Create tab buttons container
    local tabButtonsContainer = Instance.new("ScrollingFrame")
    tabButtonsContainer.Size = UDim2.new(1, -10, 1, -10)
    tabButtonsContainer.Position = UDim2.new(0, 5, 0, 5)
    tabButtonsContainer.BackgroundTransparency = 1
    tabButtonsContainer.ScrollBarThickness = 2
    tabButtonsContainer.ScrollBarImageColor3 = currentTheme.AccentColor
    tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabButtonsContainer.Parent = tabContainer
    
    -- Create content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -150, 1, -50)
    contentContainer.Position = UDim2.new(0, 140, 0, 45)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    -- Add methods
    function window:addTab(name, icon)
        local tab = {}
        
        -- Create tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Size = UDim2.new(1, -10, 0, 36)
        tabButton.Position = UDim2.new(0, 5, 0, #tabs * 41)
        tabButton.BackgroundColor3 = currentTheme.ElementBackground
        tabButton.BackgroundTransparency = 0.5
        tabButton.Text = name
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextColor3 = currentTheme.TextColor
        tabButton.TextSize = 14
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabButtonsContainer
        
        createCorner(tabButton, 6)
        
        -- Add icon if provided
        if icon then
            local iconImage = Instance.new("ImageLabel")
            iconImage.Size = UDim2.new(0, 20, 0, 20)
            iconImage.Position = UDim2.new(0, 8, 0.5, -10)
            iconImage.BackgroundTransparency = 1
            iconImage.Image = icon
            iconImage.Parent = tabButton
            
            tabButton.Text = "    " .. name
            tabButton.TextXAlignment = Enum.TextXAlignment.Left
        end
        
        -- Create content frame for this tab
        local contentFrame = Instance.new("ScrollingFrame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.BorderSizePixel = 0
        contentFrame.ScrollBarThickness = 2
        contentFrame.ScrollBarImageColor3 = currentTheme.AccentColor
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentFrame.Visible = false
        contentFrame.Parent = contentContainer
        
        -- Handle tab button click
        tabButton.MouseButton1Click:Connect(function()
            if activeTab then
                -- Deactivate current tab
                TweenService:Create(tabs[activeTab].button, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.5,
                    BackgroundColor3 = currentTheme.ElementBackground
                }):Play()
                tabs[activeTab].content.Visible = false
            end
            
            -- Activate this tab
            TweenService:Create(tabButton, TweenInfo.new(0.2), {
                BackgroundTransparency = 0,
                BackgroundColor3 = currentTheme.AccentColor
            }):Play()
            contentFrame.Visible = true
            activeTab = name
            
            -- Add ripple effect
            local x, y = Mouse.X - tabButton.AbsolutePosition.X, Mouse.Y - tabButton.AbsolutePosition.Y
            createRipple(tabButton, x, y)
        end)
        
        -- Store tab data
        tabs[name] = {
            button = tabButton,
            content = contentFrame
        }
        
        -- If this is the first tab, activate it
        if #tabs == 0 then
            tabButton.BackgroundTransparency = 0
            tabButton.BackgroundColor3 = currentTheme.AccentColor
            contentFrame.Visible = true
            activeTab = name
        end
        
        -- Section creation function
        function tab:addSection(sectionName)
            local section = {}
            local elements = {}
            
            -- Create section container
            local sectionContainer = Instance.new("Frame")
            sectionContainer.Size = UDim2.new(1, -20, 0, 40)
            sectionContainer.Position = UDim2.new(0, 10, 0, contentFrame.CanvasSize.Y.Offset + 10)
            sectionContainer.BackgroundColor3 = currentTheme.SecondaryBackground
            sectionContainer.BorderSizePixel = 0
            sectionContainer.AutomaticSize = Enum.AutomaticSize.Y
            sectionContainer.Parent = contentFrame
            
            createCorner(sectionContainer, 8)
            
            -- Create section title
            local sectionTitle = Instance.new("TextLabel")
            sectionTitle.Size = UDim2.new(1, -20, 0, 30)
            sectionTitle.Position = UDim2.new(0, 10, 0, 5)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Text = sectionName
            sectionTitle.Font = Enum.Font.GothamSemibold
            sectionTitle.TextColor3 = currentTheme.TextColor
            sectionTitle.TextSize = 14
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            sectionTitle.Parent = sectionContainer
            
            -- Create tooltip function
            local function createTooltip(parent, text)
                local tooltip = Instance.new("Frame")
                tooltip.Name = "Tooltip"
                tooltip.Size = UDim2.new(0, 200, 0, 30)
                tooltip.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                tooltip.BorderSizePixel = 0
                tooltip.Visible = false
                tooltip.ZIndex = 100
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = tooltip
                
                local tooltipText = Instance.new("TextLabel")
                tooltipText.Size = UDim2.new(1, -10, 1, 0)
                tooltipText.Position = UDim2.new(0, 5, 0, 0)
                tooltipText.BackgroundTransparency = 1
                tooltipText.Text = text
                tooltipText.Font = Enum.Font.Gotham
                tooltipText.TextColor3 = Color3.fromRGB(255, 255, 255)
                tooltipText.TextSize = 12
                tooltipText.TextWrapped = true
                tooltipText.Parent = tooltip
                
                parent.MouseEnter:Connect(function()
                    tooltip.Position = UDim2.new(0, Mouse.X + 10, 0, Mouse.Y + 10)
                    tooltip.Parent = game:GetService("CoreGui")
                    tooltip.Visible = true
                end)
                
                parent.MouseLeave:Connect(function()
                    tooltip.Visible = false
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        tooltip.Position = UDim2.new(0, Mouse.X + 10, 0, Mouse.Y + 10)
                    end
                end)
                
                return tooltip
            end
            
            -- Create elements container
            local elementsContainer = Instance.new("Frame")
            elementsContainer.Size = UDim2.new(1, -20, 0, 0)
            elementsContainer.Position = UDim2.new(0, 10, 0, 35)
            elementsContainer.BackgroundTransparency = 1
            elementsContainer.AutomaticSize = Enum.AutomaticSize.Y
            elementsContainer.Parent = sectionContainer
            
            -- Update section height
            local function updateSectionHeight()
                local height = 0
                for _, element in pairs(elements) do
                    height = height + element.Size.Y.Offset + 5
                end
                elementsContainer.Size = UDim2.new(1, -20, 0, height)
            end
            
            -- Button creation function
            function section:addButton(text, callback)
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, 0, 0, 40)
                button.Position = UDim2.new(0, 0, 0, #elements * 45)
                button.BackgroundColor3 = currentTheme.ElementBackground
                button.Text = text
                button.Font = Enum.Font.Gotham
                button.TextColor3 = currentTheme.TextColor
                button.TextSize = 14
                button.AutoButtonColor = false
                button.Parent = elementsContainer
                
                createCorner(button, 6)
                
                -- Hover effect
                button.MouseEnter:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(
                            currentTheme.ElementBackground.R * 1.1,
                            currentTheme.ElementBackground.G * 1.1,
                            currentTheme.ElementBackground.B * 1.1
                        )
                    }):Play()
                end)
                
                button.MouseLeave:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = currentTheme.ElementBackground
                    }):Play()
                end)
                
                button.MouseButton1Down:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.1), {
                        BackgroundColor3 = currentTheme.AccentColor
                    }):Play()
                end)
                
                button.MouseButton1Up:Connect(function()
                    TweenService:Create(button, TweenInfo.new(0.1), {
                        BackgroundColor3 = Color3.fromRGB(
                            currentTheme.ElementBackground.R * 1.1,
                            currentTheme.ElementBackground.G * 1.1,
                            currentTheme.ElementBackground.B * 1.1
                        )
                    }):Play()
                end)
                
                button.MouseButton1Click:Connect(function()
                    local x, y = Mouse.X - button.AbsolutePosition.X, Mouse.Y - button.AbsolutePosition.Y
                    createRipple(button, x, y)
                    
                    if callback then
                        callback()
                    end
                end)
                
                table.insert(elements, button)
                updateSectionHeight()
                
                return button
            end
            
            -- Toggle creation function
            function section:addToggle(text, default, callback)
                local toggleContainer = Instance.new("Frame")
                toggleContainer.Size = UDim2.new(1, 0, 0, 40)
                toggleContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                toggleContainer.BackgroundColor3 = currentTheme.ElementBackground
                toggleContainer.Parent = elementsContainer
                
                createCorner(toggleContainer, 6)
                
                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Size = UDim2.new(1, -60, 1, 0)
                toggleLabel.Position = UDim2.new(0, 10, 0, 0)
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Text = text
                toggleLabel.Font = Enum.Font.Gotham
                toggleLabel.TextColor3 = currentTheme.TextColor
                toggleLabel.TextSize = 14
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                toggleLabel.Parent = toggleContainer
                
                local toggleButton = Instance.new("Frame")
                toggleButton.Size = UDim2.new(0, 40, 0, 20)
                toggleButton.Position = UDim2.new(1, -50, 0.5, -10)
                toggleButton.BackgroundColor3 = default and currentTheme.AccentColor or Color3.fromRGB(60, 60, 70)
                toggleButton.Parent = toggleContainer
                
                createCorner(toggleButton, 10)
                
                local toggleIndicator = Instance.new("Frame")
                toggleIndicator.Size = UDim2.new(0, 16, 0, 16)
                toggleIndicator.Position = UDim2.new(0, default and 20 or 2, 0.5, -8)
                toggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                toggleIndicator.Parent = toggleButton
                
                createCorner(toggleIndicator, 8)
                
                local toggled = default or false
                
                local function updateToggle()
                    TweenService:Create(toggleButton, TweenInfo.new(0.2), {
                        BackgroundColor3 = toggled and currentTheme.AccentColor or Color3.fromRGB(60, 60, 70)
                    }):Play()
                    
                    TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {
                        Position = UDim2.new(0, toggled and 20 or 2, 0.5, -8)
                    }):Play()
                    
                    if callback then
                        callback(toggled)
                    end
                end
                
                toggleContainer.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        toggled = not toggled
                        updateToggle()
                    end
                end)
                
                table.insert(elements, toggleContainer)
                updateSectionHeight()
                
                -- Return toggle API
                return {
                    setValue = function(value)
                        toggled = value
                        updateToggle()
                    end,
                    getValue = function()
                        return toggled
                    end
                }
            end
            
            -- Slider creation function
            function section:addSlider(text, min, max, default, callback)
                local sliderContainer = Instance.new("Frame")
                sliderContainer.Size = UDim2.new(1, 0, 0, 60)
                sliderContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                sliderContainer.BackgroundColor3 = currentTheme.ElementBackground
                sliderContainer.Parent = elementsContainer
                
                createCorner(sliderContainer, 6)
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Size = UDim2.new(1, -20, 0, 30)
                sliderLabel.Position = UDim2.new(0, 10, 0, 0)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Text = text
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.TextColor3 = currentTheme.TextColor
                sliderLabel.TextSize = 14
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderContainer
                
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Size = UDim2.new(0, 50, 0, 30)
                valueLabel.Position = UDim2.new(1, -60, 0, 0)
                valueLabel.BackgroundTransparency = 1
                valueLabel.Text = tostring(default)
                valueLabel.Font = Enum.Font.Gotham
                valueLabel.TextColor3 = currentTheme.TextColor
                valueLabel.TextSize = 14
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.Parent = sliderContainer
                
                local sliderBackground = Instance.new("Frame")
                sliderBackground.Size = UDim2.new(1, -20, 0, 6)
                sliderBackground.Position = UDim2.new(0, 10, 0, 40)
                sliderBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                sliderBackground.Parent = sliderContainer
                
                createCorner(sliderBackground, 3)
                
                local sliderFill = Instance.new("Frame")
                sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                sliderFill.BackgroundColor3 = currentTheme.AccentColor
                sliderFill.Parent = sliderBackground
                
                createCorner(sliderFill, 3)
                
                local sliderKnob = Instance.new("Frame")
                sliderKnob.Size = UDim2.new(0, 16, 0, 16)
                sliderKnob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, -8)
                sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sliderKnob.Parent = sliderBackground
                
                createCorner(sliderKnob, 8)
                createShadow(sliderKnob, 10)
                
                local value = default
                
                local function updateSlider(newValue)
                    value = math.clamp(newValue, min, max)
                    local percent = (value - min) / (max - min)
                    
                    TweenService:Create(sliderFill, TweenInfo.new(0.1), {
                        Size = UDim2.new(percent, 0, 1, 0)
                    }):Play()
                    
                    TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
                        Position = UDim2.new(percent, 0, 0.5, -8)
                    }):Play()
                    
                    valueLabel.Text = tostring(math.round(value * 100) / 100)
                    
                    if callback then
                        callback(value)
                    end
                end
                
                local dragging = false
                
                sliderBackground.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local percent = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
                        updateSlider(min + (max - min) * percent)
                    end
                end)
                
                sliderBackground.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local percent = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
                        updateSlider(min + (max - min) * percent)
                    end
                end)
                
                table.insert(elements, sliderContainer)
                updateSectionHeight()
                
                -- Return slider API
                return {
                    setValue = function(value)
                        updateSlider(value)
                    end,
                    getValue = function()
                        return value
                    end
                }
            end
            
            -- Dropdown creation function
            function section:addDropdown(text, options, default, callback)
                local dropdownContainer = Instance.new("Frame")
                dropdownContainer.Size = UDim2.new(1, 0, 0, 70)
                dropdownContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                dropdownContainer.BackgroundColor3 = currentTheme.ElementBackground
                dropdownContainer.Parent = elementsContainer
                
                local searchBox = Instance.new("TextBox")
                searchBox.Size = UDim2.new(1, -20, 0, 25)
                searchBox.Position = UDim2.new(0, 10, 0, 5)
                searchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                searchBox.PlaceholderText = "Search..."
                searchBox.Text = default or ""
                searchBox.Font = Enum.Font.Gotham
                searchBox.TextColor3 = currentTheme.TextColor
                searchBox.TextSize = 14
                searchBox.Parent = dropdownContainer
                
                createCorner(searchBox, 4)
                createStroke(searchBox, 1, Color3.fromRGB(60, 60, 70))
                
                createCorner(dropdownContainer, 6)
                
                local dropdownLabel = Instance.new("TextLabel")
                dropdownLabel.Size = UDim2.new(1, -20, 0, 40)
                dropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                dropdownLabel.BackgroundTransparency = 1
                dropdownLabel.Text = text
                dropdownLabel.Font = Enum.Font.Gotham
                dropdownLabel.TextColor3 = currentTheme.TextColor
                dropdownLabel.TextSize = 14
                dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                dropdownLabel.Parent = dropdownContainer
                
                local selectedOption = default or options[1] or "Select..."
                
                local dropdownButton = Instance.new("TextButton")
                dropdownButton.Size = UDim2.new(0, 120, 0, 30)
                dropdownButton.Position = UDim2.new(1, -130, 0.5, -15)
                dropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                dropdownButton.Text = selectedOption
                dropdownButton.Font = Enum.Font.Gotham
                dropdownButton.TextColor3 = currentTheme.TextColor
                dropdownButton.TextSize = 12
                dropdownButton.AutoButtonColor = false
                dropdownButton.Parent = dropdownContainer
                
                createCorner(dropdownButton, 4)
                
                local dropdownArrow = Instance.new("TextLabel")
                dropdownArrow.Size = UDim2.new(0, 20, 0, 20)
                dropdownArrow.Position = UDim2.new(1, -25, 0.5, -10)
                dropdownArrow.BackgroundTransparency = 1
                dropdownArrow.Text = "▼"
                dropdownArrow.Font = Enum.Font.Gotham
                dropdownArrow.TextColor3 = currentTheme.TextColor
                dropdownArrow.TextSize = 12
                dropdownArrow.Parent = dropdownButton
                
                local dropdownMenu = Instance.new("Frame")
                dropdownMenu.Size = UDim2.new(0, 120, 0, 0)
                dropdownMenu.Position = UDim2.new(1, -130, 1, 5)
                dropdownMenu.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                dropdownMenu.BorderSizePixel = 0
                dropdownMenu.ClipsDescendants = true
                dropdownMenu.Visible = false
                dropdownMenu.ZIndex = 10
                dropdownMenu.Parent = dropdownContainer
                
                createCorner(dropdownMenu, 4)
                
                local dropdownLayout = Instance.new("UIListLayout")
                dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
                dropdownLayout.Padding = UDim.new(0, 2)
                dropdownLayout.Parent = dropdownMenu
                
                local dropdownPadding = Instance.new("UIPadding")
                dropdownPadding.PaddingTop = UDim.new(0, 2)
                dropdownPadding.PaddingBottom = UDim.new(0, 2)
                dropdownPadding.Parent = dropdownMenu
                
                local menuOpen = false
                
                local function toggleMenu()
                    menuOpen = not menuOpen
                    
                    if menuOpen then
                        dropdownMenu.Visible = true
                        TweenService:Create(dropdownMenu, TweenInfo.new(0.2), {
                            Size = UDim2.new(0, 120, 0, math.min(#options * 30, 150))
                        }):Play()
                        TweenService:Create(dropdownArrow, TweenInfo.new(0.2), {
                            Rotation = 180
                        }):Play()
                    else
                        TweenService:Create(dropdownMenu, TweenInfo.new(0.2), {
                            Size = UDim2.new(0, 120, 0, 0)
                        }):Play()
                        TweenService:Create(dropdownArrow, TweenInfo.new(0.2), {
                            Rotation = 0
                        }):Play()
                        wait(0.2)
                        dropdownMenu.Visible = false
                    end
                end
                
                dropdownButton.MouseButton1Click:Connect(toggleMenu)
                
                -- Create option buttons
                for i, option in ipairs(options) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Size = UDim2.new(1, -4, 0, 26)
                    optionButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                    optionButton.BackgroundTransparency = 0.5
                    optionButton.Text = option
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.TextColor3 = currentTheme.TextColor
                    optionButton.TextSize = 12
                    optionButton.ZIndex = 11
                    optionButton.Parent = dropdownMenu
                    
                    createCorner(optionButton, 4)
                    
                    optionButton.MouseEnter:Connect(function()
                        TweenService:Create(optionButton, TweenInfo.new(0.1), {
                            BackgroundTransparency = 0.2
                        }):Play()
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        TweenService:Create(optionButton, TweenInfo.new(0.1), {
                            BackgroundTransparency = 0.5
                        }):Play()
                    end)
                    
                    optionButton.MouseButton1Click:Connect(function()
                        selectedOption = option
                        dropdownButton.Text = option
                        toggleMenu()
                        
                        if callback then
                            callback(option)
                        end
                    end)
                end
                
                table.insert(elements, dropdownContainer)
                updateSectionHeight()
                
                -- Return dropdown API
                return {
                    setValue = function(value)
                        if table.find(options, value) then
                            selectedOption = value
                            dropdownButton.Text = value
                            
                            if callback then
                                callback(value)
                            end
                        end
                    end,
                    getValue = function()
                        return selectedOption
                    end,
                    addOption = function(option)
                        if not table.find(options, option) then
                            table.insert(options, option)
                            
                            local optionButton = Instance.new("TextButton")
                            optionButton.Size = UDim2.new(1, -4, 0, 26)
                            optionButton.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                            optionButton.BackgroundTransparency = 0.5
                            optionButton.Text = option
                            optionButton.Font = Enum.Font.Gotham
                            optionButton.TextColor3 = currentTheme.TextColor
                            optionButton.TextSize = 12
                            optionButton.ZIndex = 11
                            optionButton.Parent = dropdownMenu
                            
                            createCorner(optionButton, 4)
                            
                            optionButton.MouseEnter:Connect(function()
                                TweenService:Create(optionButton, TweenInfo.new(0.1), {
                                    BackgroundTransparency = 0.2
                                }):Play()
                            end)
                            
                            optionButton.MouseLeave:Connect(function()
                                TweenService:Create(optionButton, TweenInfo.new(0.1), {
                                    BackgroundTransparency = 0.5
                                }):Play()
                            end)
                            
                            optionButton.MouseButton1Click:Connect(function()
                                selectedOption = option
                                dropdownButton.Text = option
                                toggleMenu()
                                
                                if callback then
                                    callback(option)
                                end
                            end)
                        end
                    end,
                    removeOption = function(option)
                        local index = table.find(options, option)
                        if index then
                            table.remove(options, index)
                            
                            -- Remove the option button
                            for _, child in pairs(dropdownMenu:GetChildren()) do
                                if child:IsA("TextButton") and child.Text == option then
                                    child:Destroy()
                                    break
                                end
                            end
                            
                            -- If the selected option was removed, select the first option
                            if selectedOption == option then
                                selectedOption = options[1] or "Select..."
                                dropdownButton.Text = selectedOption
                                
                                if callback then
                                    callback(selectedOption)
                                end
                            end
                        end
                    end
                }
            end
            
            -- Input field creation function
            function section:addTextbox(text, placeholder, default, callback)
                local textboxContainer = Instance.new("Frame")
                textboxContainer.Size = UDim2.new(1, 0, 0, 40)
                textboxContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                textboxContainer.BackgroundColor3 = currentTheme.ElementBackground
                textboxContainer.Parent = elementsContainer
                
                createCorner(textboxContainer, 6)
                
                local textboxLabel = Instance.new("TextLabel")
                textboxLabel.Size = UDim2.new(0.5, -15, 1, 0)
                textboxLabel.Position = UDim2.new(0, 10, 0, 0)
                textboxLabel.BackgroundTransparency = 1
                textboxLabel.Text = text
                textboxLabel.Font = Enum.Font.Gotham
                textboxLabel.TextColor3 = currentTheme.TextColor
                textboxLabel.TextSize = 14
                textboxLabel.TextXAlignment = Enum.TextXAlignment.Left
                textboxLabel.Parent = textboxContainer
                
                local textbox = Instance.new("TextBox")
                textbox.Size = UDim2.new(0.5, -15, 0, 30)
                textbox.Position = UDim2.new(0.5, 5, 0.5, -15)
                textbox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                textbox.PlaceholderText = placeholder or "Enter text..."
                textbox.Text = default or ""
                textbox.Font = Enum.Font.Gotham
                textbox.TextColor3 = currentTheme.TextColor
                textbox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
                textbox.TextSize = 12
                textbox.ClearTextOnFocus = false
                textbox.Parent = textboxContainer
                
                createCorner(textbox, 4)
                createStroke(textbox, 1, Color3.fromRGB(60, 60, 70))
                
                textbox.Focused:Connect(function()
                    TweenService:Create(textbox, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                    }):Play()
                end)
                
                textbox.FocusLost:Connect(function(enterPressed)
                    TweenService:Create(textbox, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                    }):Play()
                    
                    if callback then
                        callback(textbox.Text, enterPressed)
                    end
                end)
                
                table.insert(elements, textboxContainer)
                updateSectionHeight()
                
                -- Return textbox API
                return {
                    setValue = function(value)
                        textbox.Text = value
                        
                        if callback then
                            callback(value, false)
                        end
                    end,
                    getValue = function()
                        return textbox.Text
                    end
                }
            end
            
            -- Color picker creation function
            function section:addColorPicker(text, default, callback)
                local colorPickerContainer = Instance.new("Frame")
                colorPickerContainer.Size = UDim2.new(1, 0, 0, 40)
                colorPickerContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                colorPickerContainer.BackgroundColor3 = currentTheme.ElementBackground
                colorPickerContainer.Parent = elementsContainer
                
                createCorner(colorPickerContainer, 6)
                
                local colorPickerLabel = Instance.new("TextLabel")
                colorPickerLabel.Size = UDim2.new(1, -60, 1, 0)
                colorPickerLabel.Position = UDim2.new(0, 10, 0, 0)
                colorPickerLabel.BackgroundTransparency = 1
                colorPickerLabel.Text = text
                colorPickerLabel.Font = Enum.Font.Gotham
                colorPickerLabel.TextColor3 = currentTheme.TextColor
                colorPickerLabel.TextSize = 14
                colorPickerLabel.TextXAlignment = Enum.TextXAlignment.Left
                colorPickerLabel.Parent = colorPickerContainer
                
                local colorDisplay = Instance.new("Frame")
                colorDisplay.Size = UDim2.new(0, 30, 0, 30)
                colorDisplay.Position = UDim2.new(1, -40, 0.5, -15)
                colorDisplay.BackgroundColor3 = default or Color3.fromRGB(255, 255, 255)
                colorDisplay.Parent = colorPickerContainer
                
                createCorner(colorDisplay, 4)
                createStroke(colorDisplay, 1, Color3.fromRGB(60, 60, 70))
                
                local colorPickerButton = Instance.new("TextButton")
                colorPickerButton.Size = UDim2.new(1, 0, 1, 0)
                colorPickerButton.BackgroundTransparency = 1
                colorPickerButton.Text = ""
                colorPickerButton.Parent = colorDisplay
                
                -- Color picker popup
                local pickerPopup = Instance.new("Frame")
                pickerPopup.Size = UDim2.new(0, 200, 0, 220)
                pickerPopup.Position = UDim2.new(1, -210, 0, 45)
                pickerPopup.BackgroundColor3 = currentTheme.SecondaryBackground
                pickerPopup.BorderSizePixel = 0
                pickerPopup.Visible = false
                pickerPopup.ZIndex = 100
                pickerPopup.Parent = screenGui
                
                createCorner(pickerPopup, 6)
                createShadow(pickerPopup)
                
                -- Color picker title
                local pickerTitle = Instance.new("TextLabel")
                pickerTitle.Size = UDim2.new(1, 0, 0, 30)
                pickerTitle.BackgroundTransparency = 1
                pickerTitle.Text = "Color Picker"
                pickerTitle.Font = Enum.Font.GothamBold
                pickerTitle.TextColor3 = currentTheme.TextColor
                pickerTitle.TextSize = 14
                pickerTitle.Parent = pickerPopup
                
                -- Color saturation/value picker
                local saturationPicker = Instance.new("ImageLabel")
                saturationPicker.Size = UDim2.new(0, 180, 0, 180)
                saturationPicker.Position = UDim2.new(0.5, -90, 0, 35)
                saturationPicker.Image = "rbxassetid://4155801252"
                saturationPicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                saturationPicker.ZIndex = 101
                saturationPicker.Parent = pickerPopup
                
                createCorner(saturationPicker, 4)
                
                -- Hue slider
                local hueSlider = Instance.new("Frame")
                hueSlider.Size = UDim2.new(0, 180, 0, 20)
                hueSlider.Position = UDim2.new(0.5, -90, 0, 220)
                hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueSlider.ZIndex = 101
                hueSlider.Parent = pickerPopup
                
                createCorner(hueSlider, 4)
                
                local hueGradient = Instance.new("UIGradient")
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                hueGradient.Parent = hueSlider
                
                -- Saturation picker cursor
                local saturationCursor = Instance.new("Frame")
                saturationCursor.Size = UDim2.new(0, 10, 0, 10)
                saturationCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                saturationCursor.Position = UDim2.new(1, 0, 0, 0)
                saturationCursor.BackgroundTransparency = 1
                saturationCursor.ZIndex = 102
                saturationCursor.Parent = saturationPicker
                
                local saturationCursorInner = Instance.new("Frame")
                saturationCursorInner.Size = UDim2.new(1, 0, 1, 0)
                saturationCursorInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                saturationCursorInner.ZIndex = 102
                saturationCursorInner.Parent = saturationCursor
                
                createCorner(saturationCursorInner, 999)
                createStroke(saturationCursorInner, 1, Color3.fromRGB(0, 0, 0))
                
                -- Hue slider cursor
                local hueCursor = Instance.new("Frame")
                hueCursor.Size = UDim2.new(0, 5, 1, 0)
                hueCursor.Position = UDim2.new(0, 0, 0, 0)
                hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueCursor.ZIndex = 102
                hueCursor.Parent = hueSlider
                
                createStroke(hueCursor, 1, Color3.fromRGB(0, 0, 0))
                
                -- Apply button
                local applyButton = Instance.new("TextButton")
                applyButton.Size = UDim2.new(0, 180, 0, 30)
                applyButton.Position = UDim2.new(0.5, -90, 0, 245)
                applyButton.BackgroundColor3 = currentTheme.AccentColor
                applyButton.Text = "Apply"
                applyButton.Font = Enum.Font.Gotham
                applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                applyButton.TextSize = 14
                applyButton.ZIndex = 101
                applyButton.Parent = pickerPopup
                
                createCorner(applyButton, 4)
                
                -- Color picker variables
                local hue, saturation, value = 0, 1, 1
                local selectedColor = default or Color3.fromRGB(255, 0, 0)
                local pickerOpen = false
                
                -- Update color display
                local function updateColorDisplay()
                    colorDisplay.BackgroundColor3 = selectedColor
                    
                    if callback then
                        callback(selectedColor)
                    end
                end
                
                -- Convert HSV to RGB
                local function hsvToRgb(h, s, v)
                    local r, g, b
                    
                    local i = math.floor(h * 6)
                    local f = h * 6 - i
                    local p = v * (1 - s)
                    local q = v * (1 - f * s)
                    local t = v * (1 - (1 - f) * s)
                    
                    i = i % 6
                    
                    if i == 0 then r, g, b = v, t, p
                    elseif i == 1 then r, g, b = q, v, p
                    elseif i == 2 then r, g, b = p, v, t
                    elseif i == 3 then r, g, b = p, q, v
                    elseif i == 4 then r, g, b = t, p, v
                    elseif i == 5 then r, g, b = v, p, q
                    end
                    
                    return Color3.fromRGB(r * 255, g * 255, b * 255)
                end
                
                -- Update color from HSV values
                local function updateColor()
                    selectedColor = hsvToRgb(hue, saturation, value)
                    saturationPicker.BackgroundColor3 = hsvToRgb(hue, 1, 1)
                    updateColorDisplay()
                end
                
                -- Handle saturation picker input
                local saturationDragging = false
                
                saturationPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        saturationDragging = true
                        local position = Vector2.new(
                            math.clamp(input.Position.X - saturationPicker.AbsolutePosition.X, 0, saturationPicker.AbsoluteSize.X),
                            math.clamp(input.Position.Y - saturationPicker.AbsolutePosition.Y, 0, saturationPicker.AbsoluteSize.Y)
                        )
                        
                        saturation = position.X / saturationPicker.AbsoluteSize.X
                        value = 1 - (position.Y / saturationPicker.AbsoluteSize.Y)
                        
                        saturationCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
                        updateColor()
                    end
                end)
                
                saturationPicker.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        saturationDragging = false
                    end
                end)
                
                -- Handle hue slider input
                local hueDragging = false
                
                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                        local position = math.clamp(input.Position.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                        
                        hue = position / hueSlider.AbsoluteSize.X
                        hueCursor.Position = UDim2.new(hue, 0, 0, 0)
                        updateColor()
                    end
                end)
                
                hueSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = false
                    end
                end)
                
                -- Handle mouse movement
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if saturationDragging then
                            local position = Vector2.new(
                                math.clamp(input.Position.X - saturationPicker.AbsolutePosition.X, 0, saturationPicker.AbsoluteSize.X),
                                math.clamp(input.Position.Y - saturationPicker.AbsolutePosition.Y, 0, saturationPicker.AbsoluteSize.Y)
                            )
                            
                            saturation = position.X / saturationPicker.AbsoluteSize.X
                            value = 1 - (position.Y / saturationPicker.AbsoluteSize.Y)
                            
                            saturationCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
                            updateColor()
                        elseif hueDragging then
                            local position = math.clamp(input.Position.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                            
                            hue = position / hueSlider.AbsoluteSize.X
                            hueCursor.Position = UDim2.new(hue, 0, 0, 0)
                            updateColor()
                        end
                    end
                end)
                
                -- Toggle color picker
                colorPickerButton.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    pickerPopup.Visible = pickerOpen
                    
                    if pickerOpen then
                        -- Position the popup
                        local buttonAbsolutePosition = colorPickerContainer.AbsolutePosition
                        local buttonAbsoluteSize = colorPickerContainer.AbsoluteSize
                        
                        pickerPopup.Position = UDim2.new(0, buttonAbsolutePosition.X + buttonAbsoluteSize.X - pickerPopup.Size.X.Offset,
                                                        0, buttonAbsolutePosition.Y + buttonAbsoluteSize.Y)
                    end
                end)
                
                -- Apply button click
                applyButton.MouseButton1Click:Connect(function()
                    pickerOpen = false
                    pickerPopup.Visible = false
                    updateColorDisplay()
                end)
                
                -- Close picker when clicking outside
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and pickerOpen then
                        local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
                        if not (mousePosition.X >= pickerPopup.AbsolutePosition.X and
                                mousePosition.X <= pickerPopup.AbsolutePosition.X + pickerPopup.AbsoluteSize.X and
                                mousePosition.Y >= pickerPopup.AbsolutePosition.Y and
                                mousePosition.Y <= pickerPopup.AbsolutePosition.Y + pickerPopup.AbsoluteSize.Y) and
                           not (mousePosition.X >= colorDisplay.AbsolutePosition.X and
                                mousePosition.X <= colorDisplay.AbsolutePosition.X + colorDisplay.AbsoluteSize.X and
                                mousePosition.Y >= colorDisplay.AbsolutePosition.Y and
                                mousePosition.Y <= colorDisplay.AbsolutePosition.Y + colorDisplay.AbsoluteSize.Y) then
                            pickerOpen = false
                            pickerPopup.Visible = false
                        end
                    end
                end)
                
                table.insert(elements, colorPickerContainer)
                updateSectionHeight()
                
                -- Return color picker API
                return {
                    setValue = function(color)
                        selectedColor = color
                        updateColorDisplay()
                    end,
                    getValue = function()
                        return selectedColor
                    end
                }
            end
            
            -- Label creation function
            function section:addLabel(text)
                local labelContainer = Instance.new("Frame")
                labelContainer.Size = UDim2.new(1, 0, 0, 30)
                labelContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                labelContainer.BackgroundColor3 = currentTheme.ElementBackground
                labelContainer.Parent = elementsContainer
                
                createCorner(labelContainer, 6)
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.Font = Enum.Font.Gotham
                label.TextColor3 = currentTheme.TextColor
                label.TextSize = 14
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = labelContainer
                
                table.insert(elements, labelContainer)
                updateSectionHeight()
                
                -- Return label API
                return {
                    setText = function(newText)
                        label.Text = newText
                    end,
                    getText = function()
                        return label.Text
                    end
                }
            end
            
            -- Keybind creation function
            function section:addKeybind(text, default, callback, changedCallback)
                local keybindContainer = Instance.new("Frame")
                keybindContainer.Size = UDim2.new(1, 0, 0, 40)
                keybindContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                pickerPopup.BackgroundColor3 = currentTheme.SecondaryBackground
                pickerPopup.BorderSizePixel = 0
                pickerPopup.Visible = false
                pickerPopup.ZIndex = 100
                pickerPopup.Parent = screenGui
                
                createCorner(pickerPopup, 6)
                createShadow(pickerPopup)
                
                -- Color picker title
                local pickerTitle = Instance.new("TextLabel")
                pickerTitle.Size = UDim2.new(1, 0, 0, 30)
                pickerTitle.BackgroundTransparency = 1
                pickerTitle.Text = "Color Picker"
                pickerTitle.Font = Enum.Font.GothamBold
                pickerTitle.TextColor3 = currentTheme.TextColor
                pickerTitle.TextSize = 14
                pickerTitle.Parent = pickerPopup
                
                -- Color saturation/value picker
                local saturationPicker = Instance.new("ImageLabel")
                saturationPicker.Size = UDim2.new(0, 180, 0, 180)
                saturationPicker.Position = UDim2.new(0.5, -90, 0, 35)
                saturationPicker.Image = "rbxassetid://4155801252"
                saturationPicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                saturationPicker.ZIndex = 101
                saturationPicker.Parent = pickerPopup
                
                createCorner(saturationPicker, 4)
                
                -- Hue slider
                local hueSlider = Instance.new("Frame")
                hueSlider.Size = UDim2.new(0, 180, 0, 20)
                hueSlider.Position = UDim2.new(0.5, -90, 0, 220)
                hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueSlider.ZIndex = 101
                hueSlider.Parent = pickerPopup
                
                createCorner(hueSlider, 4)
                
                local hueGradient = Instance.new("UIGradient")
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                hueGradient.Parent = hueSlider
                
                -- Saturation picker cursor
                local saturationCursor = Instance.new("Frame")
                saturationCursor.Size = UDim2.new(0, 10, 0, 10)
                saturationCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                saturationCursor.Position = UDim2.new(1, 0, 0, 0)
                saturationCursor.BackgroundTransparency = 1
                saturationCursor.ZIndex = 102
                saturationCursor.Parent = saturationPicker
                
                local saturationCursorInner = Instance.new("Frame")
                saturationCursorInner.Size = UDim2.new(1, 0, 1, 0)
                saturationCursorInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                saturationCursorInner.ZIndex = 102
                saturationCursorInner.Parent = saturationCursor
                
                createCorner(saturationCursorInner, 999)
                createStroke(saturationCursorInner, 1, Color3.fromRGB(0, 0, 0))
                
                -- Hue slider cursor
                local hueCursor = Instance.new("Frame")
                hueCursor.Size = UDim2.new(0, 5, 1, 0)
                hueCursor.Position = UDim2.new(0, 0, 0, 0)
                hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueCursor.ZIndex = 102
                hueCursor.Parent = hueSlider
                
                createStroke(hueCursor, 1, Color3.fromRGB(0, 0, 0))
                
                -- Apply button
                local applyButton = Instance.new("TextButton")
                applyButton.Size = UDim2.new(0, 180, 0, 30)
                applyButton.Position = UDim2.new(0.5, -90, 0, 245)
                applyButton.BackgroundColor3 = currentTheme.AccentColor
                applyButton.Text = "Apply"
                applyButton.Font = Enum.Font.Gotham
                applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                applyButton.TextSize = 14
                applyButton.ZIndex = 101
                applyButton.Parent = pickerPopup
                
                createCorner(applyButton, 4)
                
                -- Color picker variables
                local hue, saturation, value = 0, 1, 1
                local selectedColor = default or Color3.fromRGB(255, 0, 0)
                local pickerOpen = false
                
                -- Update color display
                local function updateColorDisplay()
                    colorDisplay.BackgroundColor3 = selectedColor
                    
                    if callback then
                        callback(selectedColor)
                    end
                end
                
                -- Convert HSV to RGB
                local function hsvToRgb(h, s, v)
                    local r, g, b
                    
                    local i = math.floor(h * 6)
                    local f = h * 6 - i
                    local p = v * (1 - s)
                    local q = v * (1 - f * s)
                    local t = v * (1 - (1 - f) * s)
                    
                    i = i % 6
                    
                    if i == 0 then r, g, b = v, t, p
                    elseif i == 1 then r, g, b = q, v, p
                    elseif i == 2 then r, g, b = p, v, t
                    elseif i == 3 then r, g, b = p, q, v
                    elseif i == 4 then r, g, b = t, p, v
                    elseif i == 5 then r, g, b = v, p, q
                    end
                    
                    return Color3.fromRGB(r * 255, g * 255, b * 255)
                end
                
                -- Update color from HSV values
                local function updateColor()
                    selectedColor = hsvToRgb(hue, saturation, value)
                    saturationPicker.BackgroundColor3 = hsvToRgb(hue, 1, 1)
                    updateColorDisplay()
                end
                
                -- Handle saturation picker input
                local saturationDragging = false
                
                saturationPicker.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        saturationDragging = true
                        local position = Vector2.new(
                            math.clamp(input.Position.X - saturationPicker.AbsolutePosition.X, 0, saturationPicker.AbsoluteSize.X),
                            math.clamp(input.Position.Y - saturationPicker.AbsolutePosition.Y, 0, saturationPicker.AbsoluteSize.Y)
                        )
                        
                        saturation = position.X / saturationPicker.AbsoluteSize.X
                        value = 1 - (position.Y / saturationPicker.AbsoluteSize.Y)
                        
                        saturationCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
                        updateColor()
                    end
                end)
                
                saturationPicker.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        saturationDragging = false
                    end
                end)
                
                -- Handle hue slider input
                local hueDragging = false
                
                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                        local position = math.clamp(input.Position.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                        
                        hue = position / hueSlider.AbsoluteSize.X
                        hueCursor.Position = UDim2.new(hue, 0, 0, 0)
                        updateColor()
                    end
                end)
                
                hueSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = false
                    end
                end)
                
                -- Handle mouse movement
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if saturationDragging then
                            local position = Vector2.new(
                                math.clamp(input.Position.X - saturationPicker.AbsolutePosition.X, 0, saturationPicker.AbsoluteSize.X),
                                math.clamp(input.Position.Y - saturationPicker.AbsolutePosition.Y, 0, saturationPicker.AbsoluteSize.Y)
                            )
                            
                            saturation = position.X / saturationPicker.AbsoluteSize.X
                            value = 1 - (position.Y / saturationPicker.AbsoluteSize.Y)
                            
                            saturationCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
                            updateColor()
                        elseif hueDragging then
                            local position = math.clamp(input.Position.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                            
                            hue = position / hueSlider.AbsoluteSize.X
                            hueCursor.Position = UDim2.new(hue, 0, 0, 0)
                            updateColor()
                        end
                    end
                end)
                
                -- Toggle color picker
                colorPickerButton.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    pickerPopup.Visible = pickerOpen
                    
                    if pickerOpen then
                        -- Position the popup
                        local buttonAbsolutePosition = colorPickerContainer.AbsolutePosition
                        local buttonAbsoluteSize = colorPickerContainer.AbsoluteSize
                        
                        pickerPopup.Position = UDim2.new(0, buttonAbsolutePosition.X + buttonAbsoluteSize.X - pickerPopup.Size.X.Offset,
                                                        0, buttonAbsolutePosition.Y + buttonAbsoluteSize.Y)
                    end
                end)
                
                -- Apply button click
                applyButton.MouseButton1Click:Connect(function()
                    pickerOpen = false
                    pickerPopup.Visible = false
                    updateColorDisplay()
                end)
                
                -- Close picker when clicking outside
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and pickerOpen then
                        local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
                        if not (mousePosition.X >= pickerPopup.AbsolutePosition.X and
                                mousePosition.X <= pickerPopup.AbsolutePosition.X + pickerPopup.AbsoluteSize.X and
                                mousePosition.Y >= pickerPopup.AbsolutePosition.Y and
                                mousePosition.Y <= pickerPopup.AbsolutePosition.Y + pickerPopup.AbsoluteSize.Y) and
                           not (mousePosition.X >= colorDisplay.AbsolutePosition.X and
                                mousePosition.X <= colorDisplay.AbsolutePosition.X + colorDisplay.AbsoluteSize.X and
                                mousePosition.Y >= colorDisplay.AbsolutePosition.Y and
                                mousePosition.Y <= colorDisplay.AbsolutePosition.Y + colorDisplay.AbsoluteSize.Y) then
                            pickerOpen = false
                            pickerPopup.Visible = false
                        end
                    end
                end)
                
                table.insert(elements, colorPickerContainer)
                updateSectionHeight()
                
                -- Return color picker API
                return {
                    setValue = function(color)
                        selectedColor = color
                        updateColorDisplay()
                    end,
                    getValue = function()
                        return selectedColor
                    end
                }
            end
            
            -- Label creation function
            function section:addLabel(text)
                local labelContainer = Instance.new("Frame")
                labelContainer.Size = UDim2.new(1, 0, 0, 30)
                labelContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                labelContainer.BackgroundColor3 = currentTheme.ElementBackground
                labelContainer.Parent = elementsContainer
                
                createCorner(labelContainer, 6)
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -20, 1, 0)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.Font = Enum.Font.Gotham
                label.TextColor3 = currentTheme.TextColor
                label.TextSize = 14
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = labelContainer
                
                table.insert(elements, labelContainer)
                updateSectionHeight()
                
                -- Return label API
                return {
                    setText = function(newText)
                        label.Text = newText
                    end,
                    getText = function()
                        return label.Text
                    end
                }
            end
            
            -- Keybind creation function
            function section:addKeybind(text, default, callback, changedCallback)
                local keybindContainer = Instance.new("Frame")
                keybindContainer.Size = UDim2.new(1, 0, 0, 40)
                keybindContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                keybindContainer.BackgroundColor3 = currentTheme.ElementBackground
                keybindContainer.BackgroundColor3 = currentTheme.ElementBackground
                keybindContainer.Parent = elementsContainer
                
                createCorner(keybindContainer, 6)
                
                local keybindLabel = Instance.new("TextLabel")
                keybindLabel.Size = UDim2.new(0.5, -15, 1, 0)
                keybindLabel.Position = UDim2.new(0, 10, 0, 0)
                keybindLabel.BackgroundTransparency = 1
                keybindLabel.Text = text
                keybindLabel.Font = Enum.Font.Gotham
                keybindLabel.TextColor3 = currentTheme.TextColor
                keybindLabel.TextSize = 14
                keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                keybindLabel.Parent = keybindContainer
                
                local keybindButton = Instance.new("TextButton")
                keybindButton.Size = UDim2.new(0.5, -15, 0, 30)
                keybindButton.Position = UDim2.new(0.5, 5, 0.5, -15)
                keybindButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                keybindButton.Text = default and default.Name or "None"
                keybindButton.Font = Enum.Font.Gotham
                keybindButton.TextColor3 = currentTheme.TextColor
                keybindButton.TextSize = 12
                keybindButton.Parent = keybindContainer
                
                createCorner(keybindButton, 4)
                createStroke(keybindButton, 1, Color3.fromRGB(60, 60, 70))
                
                local selectedKey = default
                local listening = false
                
                keybindButton.MouseButton1Click:Connect(function()
                    if listening then return end
                    
                    listening = true
                    keybindButton.Text = "..."
                    
                    local connection
                    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
                            selectedKey = input.KeyCode
                            keybindButton.Text = input.KeyCode.Name
                            
                            if changedCallback then
                                changedCallback(selectedKey)
                            end
                            
                            listening = false
                            connection:Disconnect()
                        end
                    end)
                end)
                
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed and selectedKey and input.KeyCode == selectedKey then
                        if callback then
                            callback(selectedKey)
                        end
                    end
                end)
                
                table.insert(elements, keybindContainer)
                updateSectionHeight()
                
                -- Return keybind API
                return {
                    setKey = function(key)
                        selectedKey = key
                        keybindButton.Text = key and key.Name or "None"
                        
                        if changedCallback then
                            changedCallback(selectedKey)
                        end
                    end,
                    getKey = function()
                        return selectedKey
                    end
                }
            end
            
            -- Slider creation function
            function section:addSlider(text, min, max, default, precision, callback)
                local sliderContainer = Instance.new("Frame")
                sliderContainer.Size = UDim2.new(1, 0, 0, 50)
                sliderContainer.Position = UDim2.new(0, 0, 0, #elements * 45)
                sliderContainer.BackgroundColor3 = currentTheme.ElementBackground
                sliderContainer.Parent = elementsContainer
                
                createCorner(sliderContainer, 6)
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Size = UDim2.new(1, -20, 0, 20)
                sliderLabel.Position = UDim2.new(0, 10, 0, 5)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Text = text
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.TextColor3 = currentTheme.TextColor
                sliderLabel.TextSize = 14
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.Parent = sliderContainer
                
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Size = UDim2.new(0, 50, 0, 20)
                valueLabel.Position = UDim2.new(1, -60, 0, 5)
                valueLabel.BackgroundTransparency = 1
                valueLabel.Text = tostring(default or min)
                valueLabel.Font = Enum.Font.Gotham
                valueLabel.TextColor3 = currentTheme.TextColor
                valueLabel.TextSize = 14
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.Parent = sliderContainer
                
                local sliderBackground = Instance.new("Frame")
                sliderBackground.Size = UDim2.new(1, -20, 0, 10)
                sliderBackground.Position = UDim2.new(0, 10, 0, 30)
                sliderBackground.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                sliderBackground.Parent = sliderContainer
                
                createCorner(sliderBackground, 999)
                
                local sliderFill = Instance.new("Frame")
                sliderFill.Size = UDim2.new(0, 0, 1, 0)
                sliderFill.BackgroundColor3 = currentTheme.AccentColor
                sliderFill.Parent = sliderBackground
                
                createCorner(sliderFill, 999)
                
                local sliderButton = Instance.new("TextButton")
                sliderButton.Size = UDim2.new(1, 0, 1, 0)
                sliderButton.BackgroundTransparency = 1
                sliderButton.Text = ""
                sliderButton.Parent = sliderBackground
                
                -- Slider variables
                local value = default or min
                local dragging = false
                precision = precision or 1
                
                -- Update slider visuals
                local function updateSlider()
                    local percent = (value - min) / (max - min)
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    valueLabel.Text = tostring(value)
                    
                    if callback then
                        callback(value)
                    end
                end
                
                -- Initialize slider
                updateSlider()
                
                -- Handle slider input
                sliderButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        
                        local position = input.Position.X - sliderBackground.AbsolutePosition.X
                        local percent = math.clamp(position / sliderBackground.AbsoluteSize.X, 0, 1)
                        
                        value = min + (max - min) * percent
                        value = math.floor(value * (10 ^ precision)) / (10 ^ precision)
                        value = math.clamp(value, min, max)
                        
                        updateSlider()
                    end
                end)
                
                sliderButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                        local position = input.Position.X - sliderBackground.AbsolutePosition.X
                        local percent = math.clamp(position / sliderBackground.AbsoluteSize.X, 0, 1)
                        
                        value = min + (max - min) * percent
                        value = math.floor(value * (10 ^ precision)) / (10 ^ precision)
                        value = math.clamp(value, min, max)
                        
                        updateSlider()
                    end
                end)
                
                table.insert(elements, sliderContainer)
                updateSectionHeight()
                
                -- Return slider API
                return {
                    setValue = function(newValue)
                        value = math.clamp(newValue, min, max)
                        value = math.floor(value * (10 ^ precision)) / (10 ^ precision)
                        updateSlider()
                    end,
                    getValue = function()
                        return value
                    end,
                    setMin = function(newMin)
                        min = newMin
                        value = math.clamp(value, min, max)
                        updateSlider()
                    end,
                    setMax = function(newMax)
                        max = newMax
                        value = math.clamp(value, min, max)
                        updateSlider()
                    end
                }
            end
            
            return section
        end
        
        return tab
    end
    
    -- Return window API
    return {
        getTab = function(name)
            for _, tab in pairs(tabs) do
                if tab.name == name then
                    return tab.object
                end
            end
        end,
        setTheme = function(theme)
            currentTheme = theme
            -- Update UI elements with new theme
            -- This would require updating all existing elements
        end
    }
end

-- Theme Designer and Accessibility Features
local ThemeDesigner = {
    themes = {},
    activeTheme = nil,
    listeners = {}
}

function ThemeDesigner:createTheme(name, colors)
    self.themes[name] = colors
    return colors
end

function ThemeDesigner:setTheme(name)
    if not self.themes[name] then
        error("Theme '" .. name .. "' does not exist")
    end
    
    self.activeTheme = name
    local theme = self.themes[name]
    
    -- Notify listeners
    for _, callback in ipairs(self.listeners) do
        callback(theme)
    end
end

function ThemeDesigner:getTheme(name)
    return self.themes[name or self.activeTheme]
end

function ThemeDesigner:onThemeChange(callback)
    table.insert(self.listeners, callback)
    
    return function()
        for i, listener in ipairs(self.listeners) do
            if listener == callback then
                table.remove(self.listeners, i)
                break
            end
        end
    end
end

-- Accessibility Features
local Accessibility = {
    settings = {
        highContrast = false,
        largeText = false,
        screenReader = false,
        reducedMotion = false
    },
    listeners = {}
}

function Accessibility:setSetting(key, value)
    if self.settings[key] ~= nil then
        self.settings[key] = value
        
        -- Notify listeners
        if self.listeners[key] then
            for _, callback in ipairs(self.listeners[key]) do
                callback(value)
            end
        end
    end
end

function Accessibility:getSetting(key)
    return self.settings[key]
end

function Accessibility:onSettingChange(key, callback)
    if not self.listeners[key] then
        self.listeners[key] = {}
    end
    
    table.insert(self.listeners[key], callback)
    
    return function()
        local listeners = self.listeners[key]
        for i, listener in ipairs(listeners) do
            if listener == callback then
                table.remove(listeners, i)
                break
            end
        end
    end
end

-- Add to UILibrary
UILibrary.InterfaceBuilder = InterfaceBuilder
UILibrary.ResponsiveDesign = ResponsiveDesign
UILibrary.ThemeDesigner = ThemeDesigner
UILibrary.Accessibility = Accessibility

-- Return library API
return {
    createWindow = createWindow,
    themes = {
        Dark = {
            MainBackground = Color3.fromRGB(30, 30, 35),
            SecondaryBackground = Color3.fromRGB(40, 40, 45),
            ElementBackground = Color3.fromRGB(50, 50, 55),
            TextColor = Color3.fromRGB(255, 255, 255),
            AccentColor = Color3.fromRGB(65, 105, 225)
        },
        Light = {
            MainBackground = Color3.fromRGB(240, 240, 245),
            SecondaryBackground = Color3.fromRGB(230, 230, 235),
            ElementBackground = Color3.fromRGB(220, 220, 225),
            TextColor = Color3.fromRGB(40, 40, 40),
            AccentColor = Color3.fromRGB(65, 105, 225)
        },
        Midnight = {
            MainBackground = Color3.fromRGB(20, 20, 30),
            SecondaryBackground = Color3.fromRGB(30, 30, 40),
            ElementBackground = Color3.fromRGB(40, 40, 50),
            TextColor = Color3.fromRGB(220, 220, 255),
            AccentColor = Color3.fromRGB(100, 90, 255)
        },
        Aqua = {
            MainBackground = Color3.fromRGB(20, 40, 50),
            SecondaryBackground = Color3.fromRGB(30, 50, 60),
            ElementBackground = Color3.fromRGB(40, 60, 70),
            TextColor = Color3.fromRGB(220, 240, 255),
            AccentColor = Color3.fromRGB(0, 180, 200)
        },
        Forest = {
            MainBackground = Color3.fromRGB(30, 40, 30),
            SecondaryBackground = Color3.fromRGB(40, 50, 40),
            ElementBackground = Color3.fromRGB(50, 60, 50),
            TextColor = Color3.fromRGB(220, 255, 220),
            AccentColor = Color3.fromRGB(50, 180, 50)
        }
    }
}
