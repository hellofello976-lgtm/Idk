-- Roblox Aimbot Menu with Aim Silent Integration
-- Complete system: toggles drive feature hooks

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Game Services (Aim Silent)
local reps = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local runs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local lplr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- Config State
local Config = {
    -- Main Tab
    aimbotEnabled = false,
    aimSilent = false,
    fovCircle = true,
    fovValue = 100,
    teamCheck = true,
    wallCheck = true,
    teamCheckType = "Friendly",
    
    -- Visual Tab
    espEnabled = false,
    espLine = true,
    espLineType = "Top",
    espLineColor = Color3.fromRGB(255, 0, 0),
    espBox = true,
    espBoxType = "2D+Filled",
    espBoxColor = Color3.fromRGB(0, 255, 0),
    espHealth = true,
    espHealthPos = "Left",
    espHealthColor = Color3.fromRGB(0, 255, 0),
    espName = true,
    espNamePos = "Top",
    espNameColor = Color3.fromRGB(255, 255, 255),
    espDistance = true,
    espDistancePos = "Bottom",
    espDistanceColor = Color3.fromRGB(255, 255, 0),
    espSkeleton = false,
    
    -- Extra Tab
    flyEnabled = false,
    flySpeed = 50,
    speedVelocity = 100,
    toNearest = false,
    toNearestType = "Enemy",
    autoHeal = false,
    infHealth = false,
    autoKill = false,
    
    -- Aim Silent Settings
    HitPart = "Head",
    FOVRadius = 300,
    ShowFOV = true
}

-- Aim Silent Hook Variables
local originalGetEntitiesFromRaycast = nil
local originalUseItem = nil
local aimSilentHook = nil

-- Load Game Modules (Safe)
local U = nil
local EL = nil
local GU = nil
local gun = nil

pcall(function()
    U = require(reps:WaitForChild("Modules"):WaitForChild("Utility"))
end)
pcall(function()
    EL = require(reps:WaitForChild("Modules"):WaitForChild("EnumLibrary"))
end)
pcall(function()
    GU = require(reps:WaitForChild("Modules"):WaitForChild("GameplayUtility"))
end)
pcall(function()
    local e = pcall(require, lplr.PlayerScripts.Modules.ItemTypes.Gun)
    if e then gun = require(lplr.PlayerScripts.Modules.ItemTypes.Gun) end
end)

-- FOV Circle
local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1
FOV.Filled = false

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 500)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Header Bar
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 30)
HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "AIMBOT MENU"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -65, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.Parent = HeaderBar

CloseBtn.MouseButton1Click:Connect(function()
    if aimSilentHook then aimSilentHook() end
    ScreenGui:Destroy()
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(1, -32, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "_"
MinBtn.Parent = HeaderBar

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 350, 0, 30) or UDim2.new(0, 350, 0, 500)
end)

-- Drag Handler
local dragging = false
local dragStart = nil
local frameStart = nil

HeaderBar.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = Mouse.Position
        frameStart = MainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Mouse.Move:Connect(function()
    if dragging and dragStart and frameStart then
        local delta = Mouse.Position - dragStart
        MainFrame.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-- Tab System
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 30)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local function CreateTabButton(name, position)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.Text = name
    btn.Parent = TabContainer
    return btn
end

local MainTabBtn = CreateTabButton("Main", UDim2.new(0, 0, 0, 0))
local VisualTabBtn = CreateTabButton("Visual", UDim2.new(0, 110, 0, 0))
local ExtraTabBtn = CreateTabButton("Extra", UDim2.new(0, 220, 0, 0))

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -65)
ContentFrame.Position = UDim2.new(0, 0, 0, 65)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Aim Silent Functions
local function CFD(origin, part)
    if not U or not part then return nil end
    local cf = part.CFrame
    local d = {}
    d[utf8.char(1)] = {
        [utf8.char(0)] = U:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
        [utf8.char(1)] = U:EncodeCFrame(cf),
        [utf8.char(2)] = part,
        [utf8.char(3)] = U:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
    }
    return d
end

local function targetPlayer()
    local center = cam.ViewportSize / 2
    local bestPart, bestDist = nil, Config.FOVRadius
    for _, entity in cs:GetTagged("Entity") do
        if entity == lplr.Character then continue end
        local part = entity:FindFirstChild(Config.HitPart, true)
        if not part or not part:IsA("BasePart") then continue end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist, bestPart = d, part end
    end
    return bestPart
end

local function startAimSilent()
    if not GU or not EL or not reps:FindFirstChild("Remotes") then return end
    
    originalGetEntitiesFromRaycast = GU.GetEntitiesFromRaycast
    GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
        local t = targetPlayer()
        if t then
            local dist = (t.Position - origin).Magnitude
            dir = (t.Position - origin).Unit
            if dist > maxDist then maxDist = dist + 5 end
        end
        return originalGetEntitiesFromRaycast(self, envID, params, origin, dir, maxDist, ...)
    end
    
    local UseItem = reps:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("UseItem")
    originalUseItem = UseItem.FireServer
    aimSilentHook = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
        if enumVal == EL:ToEnum("StartShooting") then
            local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
            local t = targetPlayer()
            if root and t then camdata = CFD(root.Position, t) end
        end
        return originalUseItem(self, objID, enumVal, camdata, extra)
    end))
    
    if gun and gun.IsFullyAiming then
        gun.IsFullyAiming = function() return true end
    end
end

local function stopAimSilent()
    if originalGetEntitiesFromRaycast then
        GU.GetEntitiesFromRaycast = originalGetEntitiesFromRaycast
    end
    if aimSilentHook then
        aimSilentHook()
        aimSilentHook = nil
    end
end

-- ESP System
local espObjects = {}
local function createESPObject(entity)
    if espObjects[entity] then return end
    local obj = {
        box = Drawing.new("Rectangle"),
        line = Drawing.new("Line"),
        text = Drawing.new("Text"),
        entity = entity
    }
    espObjects[entity] = obj
end

local function updateESP()
    if not Config.espEnabled then
        for _, obj in pairs(espObjects) do
            obj.box.Visible = false
            obj.line.Visible = false
            obj.text.Visible = false
        end
        return
    end
    
    for _, entity in cs:GetTagged("Entity") do
        if entity == lplr.Character then continue end
        local part = entity:FindFirstChild(Config.HitPart, true)
        if not part then continue end
        
        createESPObject(entity)
        local obj = espObjects[entity]
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        
        if onScreen then
            obj.box.Visible = Config.espBox
            obj.box.Color = Config.espBoxColor
            obj.box.Size = Vector2.new(50, 80)
            obj.box.Position = Vector2.new(sp.X - 25, sp.Y - 40)
            
            obj.line.Visible = Config.espLine
            obj.line.Color = Config.espLineColor
            obj.line.From = cam.ViewportSize / 2
            obj.line.To = Vector2.new(sp.X, sp.Y)
            
            obj.text.Visible = Config.espName
            obj.text.Color = Config.espNameColor
            obj.text.Text = entity.Name or "Unknown"
            obj.text.Position = Vector2.new(sp.X, sp.Y - 50)
            obj.text.Size = 13
        else
            obj.box.Visible = false
            obj.line.Visible = false
            obj.text.Visible = false
        end
    end
end

-- Fly System
local humanoidRootPart = nil
local flyConnection = nil

local function startFly()
    local root = lplr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    humanoidRootPart = root
    
    flyConnection = runs.RenderStepped:Connect(function()
        if not Config.flyEnabled then return end
        local speed = Config.flySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then root.CFrame = root.CFrame * CFrame.new(0, 0, -speed/60) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then root.CFrame = root.CFrame * CFrame.new(-speed/60, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then root.CFrame = root.CFrame * CFrame.new(0, 0, speed/60) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then root.CFrame = root.CFrame * CFrame.new(speed/60, 0, 0) end
    end)
end

-- Helper UI Functions
local function CreateToggle(name, config_key, parent, y_pos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 25)
    container.Position = UDim2.new(0, 10, 0, y_pos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 35, 0, 20)
    toggle.Position = UDim2.new(1, -35, 0.5, -10)
    toggle.BackgroundColor3 = Config[config_key] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Text = Config[config_key] and "ON" or "OFF"
    toggle.Parent = container
    
    toggle.MouseButton1Click:Connect(function()
        Config[config_key] = not Config[config_key]
        toggle.BackgroundColor3 = Config[config_key] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
        toggle.Text = Config[config_key] and "ON" or "OFF"
        
        -- Feature Logic Hooks
        if config_key == "aimSilent" then
            if Config.aimSilent then startAimSilent() else stopAimSilent() end
        elseif config_key == "flyEnabled" then
            if Config.flyEnabled then startFly() end
        end
    end)
    
    return container
end

local function CreateSlider(name, config_key, min_val, max_val, parent, y_pos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.Position = UDim2.new(0, 10, 0, y_pos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 15)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.Text = name .. ": " .. Config[config_key]
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 20)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBg.Parent = container
    
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local sliderDrag = false
    local function updateSlider(mouse_x)
        local relative = math.max(0, math.min(sliderBg.AbsoluteSize.X, mouse_x - sliderBg.AbsolutePosition.X))
        local percent = relative / sliderBg.AbsoluteSize.X
        Config[config_key] = math.floor(min_val + (max_val - min_val) * percent)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = name .. ": " .. Config[config_key]
    end
    
    sliderBg.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDrag = true
            updateSlider(Mouse.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDrag = false
        end
    end)
    
    Mouse.Move:Connect(function()
        if sliderDrag then updateSlider(Mouse.Position.X) end
    end)
    
    sliderFill.Size = UDim2.new((Config[config_key] - min_val) / (max_val - min_val), 0, 1, 0)
    return container
end

local function CreateComboBox(name, config_key, options, parent, y_pos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 30)
    container.Position = UDim2.new(0, 10, 0, y_pos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local combo = Instance.new("TextButton")
    combo.Size = UDim2.new(0.45, 0, 1, 0)
    combo.Position = UDim2.new(0.55, 0, 0, 0)
    combo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    combo.TextColor3 = Color3.fromRGB(200, 200, 200)
    combo.TextSize = 11
    combo.Font = Enum.Font.Gotham
    combo.Text = Config[config_key]
    combo.Parent = container
    
    local dropdown = Instance.new("Frame")
    dropdown.Name = "Dropdown"
    dropdown.Size = UDim2.new(0.45, 0, 0, #options * 25)
    dropdown.Position = UDim2.new(0.55, 0, 1, 0)
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdown.Visible = false
    dropdown.Parent = container
    
    combo.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)
    
    for i, option in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 25)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Text = option
        btn.Parent = dropdown
        
        btn.MouseButton1Click:Connect(function()
            Config[config_key] = option
            combo.Text = option
            dropdown.Visible = false
        end)
    end
    
    return container
end

local function CreateColorButton(name, config_key, parent, y_pos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 30)
    container.Position = UDim2.new(0, 10, 0, y_pos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0.45, 0, 1, 0)
    colorBtn.Position = UDim2.new(0.55, 0, 0, 0)
    colorBtn.BackgroundColor3 = Config[config_key]
    colorBtn.TextSize = 0
    colorBtn.Parent = container
    
    colorBtn.MouseButton1Click:Connect(function()
        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
            Color3.fromRGB(255, 255, 255),
        }
        for i, c in ipairs(colors) do
            if Config[config_key] == c then
                Config[config_key] = colors[i % #colors + 1]
                break
            end
        end
        colorBtn.BackgroundColor3 = Config[config_key]
    end)
    
    return container
end

-- MAIN TAB
local MainTab = Instance.new("Frame")
MainTab.Name = "MainTab"
MainTab.Size = UDim2.new(1, 0, 1, 0)
MainTab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainTab.BorderSizePixel = 0
MainTab.Parent = ContentFrame

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, 0, 1, 0)
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 6
MainScroll.Parent = MainTab

CreateToggle("Aimbot", "aimbotEnabled", MainScroll, 0)
CreateToggle("Aim Silent", "aimSilent", MainScroll, 30)
CreateToggle("FOV Circle", "fovCircle", MainScroll, 60)
CreateSlider("FOV", "fovValue", 50, 300, MainScroll, 90)
CreateToggle("Team Check", "teamCheck", MainScroll, 135)
CreateToggle("Wall Check", "wallCheck", MainScroll, 165)
CreateComboBox("Team Check Type", "teamCheckType", {"Friendly", "Enemy", "All"}, MainScroll, 195)

-- VISUAL TAB
local VisualTab = Instance.new("Frame")
VisualTab.Name = "VisualTab"
VisualTab.Size = UDim2.new(1, 0, 1, 0)
VisualTab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
VisualTab.BorderSizePixel = 0
VisualTab.Parent = ContentFrame
VisualTab.Visible = false

local VisualScroll = Instance.new("ScrollingFrame")
VisualScroll.Size = UDim2.new(1, 0, 1, 0)
VisualScroll.CanvasSize = UDim2.new(0, 0, 0, 550)
VisualScroll.BackgroundTransparency = 1
VisualScroll.ScrollBarThickness = 6
VisualScroll.Parent = VisualTab

CreateToggle("ESP Enabled", "espEnabled", VisualScroll, 0)
CreateToggle("ESP Line", "espLine", VisualScroll, 30)
CreateComboBox("Line Type", "espLineType", {"Top", "Bottom", "Side", "Center"}, VisualScroll, 60)
CreateColorButton("Line Color", "espLineColor", VisualScroll, 95)
CreateToggle("ESP Box", "espBox", VisualScroll, 130)
CreateComboBox("Box Type", "espBoxType", {"2D", "Filled", "Corner", "2D+Filled"}, VisualScroll, 160)
CreateColorButton("Box Color", "espBoxColor", VisualScroll, 195)
CreateToggle("ESP Health", "espHealth", VisualScroll, 230)
CreateComboBox("Health Pos", "espHealthPos", {"Left", "Right", "Top", "Bottom"}, VisualScroll, 260)
CreateColorButton("Health Color", "espHealthColor", VisualScroll, 295)
CreateToggle("ESP Name", "espName", VisualScroll, 330)
CreateComboBox("Name Pos", "espNamePos", {"Top", "Bottom"}, VisualScroll, 360)
CreateColorButton("Name Color", "espNameColor", VisualScroll, 395)
CreateToggle("ESP Distance", "espDistance", VisualScroll, 430)
CreateComboBox("Distance Pos", "espDistancePos", {"Top", "Bottom"}, VisualScroll, 460)
CreateColorButton("Distance Color", "espDistanceColor", VisualScroll, 495)
CreateToggle("ESP Skeleton", "espSkeleton", VisualScroll, 530)

-- EXTRA TAB
local ExtraTab = Instance.new("Frame")
ExtraTab.Name = "ExtraTab"
ExtraTab.Size = UDim2.new(1, 0, 1, 0)
ExtraTab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ExtraTab.BorderSizePixel = 0
ExtraTab.Parent = ContentFrame
ExtraTab.Visible = false

local ExtraScroll = Instance.new("ScrollingFrame")
ExtraScroll.Size = UDim2.new(1, 0, 1, 0)
ExtraScroll.CanvasSize = UDim2.new(0, 0, 0, 350)
ExtraScroll.BackgroundTransparency = 1
ExtraScroll.ScrollBarThickness = 6
ExtraScroll.Parent = ExtraTab

CreateToggle("Fly", "flyEnabled", ExtraScroll, 0)
CreateSlider("Fly Speed", "flySpeed", 10, 100, ExtraScroll, 30)
CreateToggle("Speed Velocity", "speedVelocity", ExtraScroll, 80)
CreateSlider("Velocity Value", "speedVelocity", 50, 200, ExtraScroll, 110)
CreateToggle("To Nearest", "toNearest", ExtraScroll, 160)
CreateComboBox("Nearest Type", "toNearestType", {"Enemy", "Friendly"}, ExtraScroll, 190)
CreateToggle("Auto Heal", "autoHeal", ExtraScroll, 225)
CreateToggle("Inf Health", "infHealth", ExtraScroll, 255)
CreateToggle("Auto Kill", "autoKill", ExtraScroll, 285)

-- Tab Switch Logic
MainTabBtn.MouseButton1Click:Connect(function()
    MainTab.Visible = true
    VisualTab.Visible = false
    ExtraTab.Visible = false
    MainTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

VisualTabBtn.MouseButton1Click:Connect(function()
    MainTab.Visible = false
    VisualTab.Visible = true
    ExtraTab.Visible = false
    MainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

ExtraTabBtn.MouseButton1Click:Connect(function()
    MainTab.Visible = false
    VisualTab.Visible = false
    ExtraTab.Visible = true
    MainTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    VisualTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ExtraTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)

-- Main Loop
runs.RenderStepped:Connect(function()
    -- FOV Circle
    FOV.Position = cam.ViewportSize / 2
    FOV.Radius = Config.fovValue
    FOV.Visible = Config.fovCircle
    
    -- ESP Update
    updateESP()
end)
