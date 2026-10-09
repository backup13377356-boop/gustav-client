local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- Config & File Saving
--==================================================

local CONFIG_FILE = "gustav_client_blocks_config.json"
local config = { ToggleKey = "RightControl" }

local function LoadConfig()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if success and type(result) == "table" and result.ToggleKey ~= nil then
            config.ToggleKey = result.ToggleKey
        end
    end
end

local function SaveConfig()
    if writefile then
        pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
    end
end

LoadConfig()

local currentKey = Enum.KeyCode.RightControl
if config.ToggleKey and config.ToggleKey ~= "None" then
    pcall(function() currentKey = Enum.KeyCode[config.ToggleKey] end)
elseif config.ToggleKey == "None" then
    currentKey = nil
end

local listeningForKey = false
local unloaded = false

--==================================================
-- State & Movement Variables
--==================================================
local tpWalkEnabled = false
local tpWalkSpeed = 16
local tpWalkConnection = nil
local flySpeed = 50
local flying = false

local function updateTPWalk()
    if tpWalkConnection then tpWalkConnection:Disconnect() tpWalkConnection = nil end
    if tpWalkEnabled and not unloaded then
        tpWalkConnection = RunService.Heartbeat:Connect(function(deltaTime)
            local character = Player.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (tpWalkSpeed * deltaTime))
            end
        end)
    end
end

--==================================================
-- Main GUI Setup
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavClientBlocks"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(550, 400)
Main.Position = UDim2.new(0.5, -275, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gustav Client"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 40, 0, 40)
MinimizeButton.Position = UDim2.new(1, -45, 0, 7)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
MinimizeButton.TextSize = 30
MinimizeButton.Font = Enum.Font.GothamMedium
MinimizeButton.Parent = TopBar
MinimizeButton.Activated:Connect(function() Main.Visible = false end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 135, 1, -55)
Sidebar.Position = UDim2.fromOffset(0, 55)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 21, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 8)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 15)
SidebarPadding.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -135, 1, -55)
Content.Position = UDim2.fromOffset(135, 55)
Content.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Content.BorderSizePixel = 0
Content.Parent = Main

--==================================================
-- Helper Functions
--==================================================

local function CreateTabButton(text)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 42)
    Button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(210, 210, 220)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamMedium
    Button.AutoButtonColor = false
    Button.Parent = Sidebar
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    return Button
end

local function CreateLabel(parent, text, size, position)
    local Label = Instance.new("TextLabel")
    Label.Size = size
    Label.Position = position
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
    return Label
end

local function CreateButton(parent, text)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 42)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = parent
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button
    return Button
end

local function CreateToggle(parent, text)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 42)
    Button.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 15
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = parent
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 9)
    Corner.Parent = Button
    return Button
end

local function CreateSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -20, 0, 55)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.fromOffset(10, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. tostring(default)
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -20, 0, 8)
    Track.Position = UDim2.fromOffset(10, 32)
    Track.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Track.BorderSizePixel = 0
    Track.Parent = Frame
    
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, 4)
    TrackCorner.Parent = Track
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 4)
    FillCorner.Parent = Fill
    
    local dragging = false
    
    local function updateSlider(input)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        local val = math.floor(min + pct * (max - min))
        Label.Text = text .. ": " .. tostring(val)
        callback(val)
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    return Frame
end

local function CreateScriptButton(parent, text, url)
    local btn = CreateButton(parent, text)
    btn.Activated:Connect(function()
        pcall(function()
            loadstring(game:HttpGet(url))()
        end)
    end)
    return btn
end

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, -10)
    Page.Position = UDim2.fromOffset(10, 10)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.Visible = false
    Page.Parent = Content
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Page
    
    local TitleLabel = CreateLabel(Page, name, UDim2.new(1, 0, 0, 30), UDim2.new())
    TitleLabel.TextSize = 22
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.LayoutOrder = 0
    
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)
    
    return Page
end

--==================================================
-- Tabs Setup
--==================================================

local HomeTab = CreateTabButton("Home") HomeTab.LayoutOrder = 1
local BlocksTab = CreateTabButton("Blocks") BlocksTab.LayoutOrder = 2
local MovementTab = CreateTabButton("Movement") MovementTab.LayoutOrder = 3
local ScriptsTab = CreateTabButton("Scripts") ScriptsTab.LayoutOrder = 4
local SettingsTab = CreateTabButton("Settings") SettingsTab.LayoutOrder = 5

local HomePage = CreatePage("Home")
local BlocksPage = CreatePage("Lucky Blocks")
local MovementPage = CreatePage("Movement")
local ScriptsPage = CreatePage("Scripts")
local SettingsPage = CreatePage("Settings")

--==================================================
-- Home Page
--==================================================

local BtnTpCenter = CreateButton(HomePage, "TP To Center")
BtnTpCenter.Activated:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local centerPart = workspace:FindFirstChild("CenterBlocks") and workspace.CenterBlocks:FindFirstChild("Givers") and workspace.CenterBlocks.Givers:FindFirstChild("VoidGiver") and workspace.CenterBlocks.Givers.VoidGiver:FindFirstChild("ColoredParts") and workspace.CenterBlocks.Givers.VoidGiver.ColoredParts:FindFirstChild("Center")
    if centerPart then char.HumanoidRootPart.CFrame = centerPart.CFrame + Vector3.new(0, 3, 0) end
end)

local BtnTpBase = CreateButton(HomePage, "TP To Base")
BtnTpBase.Activated:Connect(function()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local basePart = workspace:FindFirstChild("tp") and workspace.tp:FindFirstChild("SpawnWalls")
    if basePart then char.HumanoidRootPart.CFrame = basePart.CFrame + Vector3.new(0, 3, 0) end
end)

local BtnTpTool = CreateButton(HomePage, "Get TP Tool")
BtnTpTool.Activated:Connect(function()
    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"
    tool.RequiresHandle = false 
    tool.Activated:Connect(function()
        local mouse = Player:GetMouse()
        if mouse.Hit and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end)
    tool.Parent = Player.Backpack
end)

local BtnReset = CreateButton(HomePage, "Reset Character")
BtnReset.Activated:Connect(function()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.Health = 0
    end
end)

--==================================================
-- Blocks Page
--==================================================

local function SpawnBlock(name)
    local event = ReplicatedStorage:WaitForChild(name, 2)
    if event then event:FireServer() end
end

local BtnLucky = CreateButton(BlocksPage, "Get Lucky Block")
BtnLucky.Activated:Connect(function() SpawnBlock("SpawnLuckyBlock") end)

local BtnSuper = CreateButton(BlocksPage, "Get Super Block")
BtnSuper.Activated:Connect(function() SpawnBlock("SpawnSuperBlock") end)

local BtnDiamond = CreateButton(BlocksPage, "Get Diamond Block")
BtnDiamond.Activated:Connect(function() SpawnBlock("SpawnDiamondBlock") end)

local BtnRainbow = CreateButton(BlocksPage, "Get Rainbow Block")
BtnRainbow.Activated:Connect(function() SpawnBlock("SpawnRainbowBlock") end)

local BtnGalaxy = CreateButton(BlocksPage, "Get Galaxy Block")
BtnGalaxy.Activated:Connect(function() SpawnBlock("SpawnGalaxyBlock") end)

local BtnHacker = CreateButton(BlocksPage, "Get Hacker Block")
BtnHacker.Activated:Connect(function()
    for i=1,5 do SpawnBlock("SpawnGalaxyBlock") end
    for i=1,5 do SpawnBlock("SpawnDiamondBlock") end
    for i=1,5 do SpawnBlock("SpawnRainbowBlock") end
end)

local BtnVoid = CreateButton(BlocksPage, "Get Void Block")
BtnVoid.Activated:Connect(function()
    for i=1,3 do SpawnBlock("SpawnGalaxyBlock") end
    for i=1,2 do SpawnBlock("SpawnRainbowBlock") end
end)

local BtnAll = CreateButton(BlocksPage, "Get All Items")
BtnAll.Activated:Connect(function()
    task.spawn(function()
        for i = 1, 20 do
            SpawnBlock("SpawnGalaxyBlock")
            SpawnBlock("SpawnRainbowBlock")
            SpawnBlock("SpawnDiamondBlock")
            SpawnBlock("SpawnSuperBlock")
            SpawnBlock("SpawnLuckyBlock")
            task.wait(0.05)
        end
    end)
end)

--==================================================
-- Movement Page
--==================================================

local FlyBtn = CreateToggle(MovementPage, "Fly: OFF")
FlyBtn.Activated:Connect(function()
    flying = not flying
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    
    if flying then
        FlyBtn.Text = "Fly: ON"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
        if hum then hum.PlatformStand = true end
        local bv = Instance.new("BodyVelocity", hrp)
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        local bg = Instance.new("BodyGyro", hrp)
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = hrp.CFrame
        
        task.spawn(function()
            while flying and char and hrp and hrp.Parent do
                local cam = workspace.CurrentCamera
                local vel = Vector3.new(0,0,0)
                local uis = UserInputService
                if uis:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector end
                bv.Velocity = vel * flySpeed
                bg.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            if hum then hum.PlatformStand = false end
        end)
    else
        FlyBtn.Text = "Fly: OFF"
        FlyBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
        if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
        if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end)

CreateSlider(MovementPage, "Fly Speed", 10, 300, 50, function(value)
    flySpeed = value
end)

local TPWalkBtn = CreateToggle(MovementPage, "TP Walk: OFF")
TPWalkBtn.Activated:Connect(function()
    tpWalkEnabled = not tpWalkEnabled
    if tpWalkEnabled then
        TPWalkBtn.Text = "TP Walk: ON"
        TPWalkBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        TPWalkBtn.Text = "TP Walk: OFF"
        TPWalkBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
    updateTPWalk()
end)

CreateSlider(MovementPage, "TP Walk Speed", 1, 200, 16, function(value)
    tpWalkSpeed = value
end)

CreateSlider(MovementPage, "WalkSpeed", 16, 300, 16, function(value)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = value
    end
end)

CreateSlider(MovementPage, "JumpPower", 50, 500, 50, function(value)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.JumpPower = value
    end
end)

--==================================================
-- Scripts Page
--==================================================

CreateScriptButton(ScriptsPage, "Load Infinite Yield", "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/IY.lua")
CreateScriptButton(ScriptsPage, "Load Cobalt", "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/Cobalt.luau")
CreateScriptButton(ScriptsPage, "Load Dex", "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua")
CreateScriptButton(ScriptsPage, "Load Infinite Yield (5.9.3)", "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/IY.5.9.3")
CreateScriptButton(ScriptsPage, "Load Simple Spy", "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/simple%20spy.lua")
CreateScriptButton(ScriptsPage, "Load Vex Explorer", "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/vex.lua")

--==================================================
-- Settings Page
--==================================================

local RejoinBtn = CreateButton(SettingsPage, "Rejoin Server")
RejoinBtn.Activated:Connect(function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

local initialKeyText = (config.ToggleKey and config.ToggleKey ~= "None") and config.ToggleKey or "None"
local KeybindButton = CreateToggle(SettingsPage, "Toggle UI Key: " .. initialKeyText)
if config.ToggleKey and config.ToggleKey ~= "None" then
    KeybindButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
end

local ClearKeybindButton = CreateButton(SettingsPage, "Remove Keybind")
local UnloadButton = CreateButton(SettingsPage, "Unload Script")
UnloadButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)

-- Keybind Logic
KeybindButton.Activated:Connect(function()
    if unloaded then return end
    listeningForKey = true
    KeybindButton.Text = "Press Any Key..."
    KeybindButton.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
end)

ClearKeybindButton.Activated:Connect(function()
    if unloaded then return end
    listeningForKey = false
    currentKey = nil
    config.ToggleKey = "None"
    SaveConfig()
    KeybindButton.Text = "Toggle UI Key: None"
    KeybindButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
end)

local KeyInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listeningForKey = false
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                currentKey = nil
                config.ToggleKey = "None"
                KeybindButton.Text = "Toggle UI Key: None"
                KeybindButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
            else
                currentKey = input.KeyCode
                config.ToggleKey = input.KeyCode.Name
                KeybindButton.Text = "Toggle UI Key: " .. input.KeyCode.Name
                KeybindButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
            end
            SaveConfig()
        end
        return
    end
    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if currentKey and input.KeyCode == currentKey then
            Main.Visible = not Main.Visible
        end
    end
end)

--==================================================
-- Tab Switching
--==================================================
local function ShowTab(tab)
    HomePage.Visible = (tab == "Home")
    BlocksPage.Visible = (tab == "Blocks")
    MovementPage.Visible = (tab == "Movement")
    ScriptsPage.Visible = (tab == "Scripts")
    SettingsPage.Visible = (tab == "Settings")

    HomeTab.BackgroundColor3 = (tab == "Home") and Color3.fromRGB(55, 100, 180) or Color3.fromRGB(30, 30, 40)
    BlocksTab.BackgroundColor3 = (tab == "Blocks") and Color3.fromRGB(55, 100, 180) or Color3.fromRGB(30, 30, 40)
    MovementTab.BackgroundColor3 = (tab == "Movement") and Color3.fromRGB(55, 100, 180) or Color3.fromRGB(30, 30, 40)
    ScriptsTab.BackgroundColor3 = (tab == "Scripts") and Color3.fromRGB(55, 100, 180) or Color3.fromRGB(30, 30, 40)
    SettingsTab.BackgroundColor3 = (tab == "Settings") and Color3.fromRGB(55, 100, 180) or Color3.fromRGB(30, 30, 40)
end

HomeTab.Activated:Connect(function() ShowTab("Home") end)
BlocksTab.Activated:Connect(function() ShowTab("Blocks") end)
MovementTab.Activated:Connect(function() ShowTab("Movement") end)
ScriptsTab.Activated:Connect(function() ShowTab("Scripts") end)
SettingsTab.Activated:Connect(function() ShowTab("Settings") end)

--==================================================
-- Unload & Dragging
--==================================================

UnloadButton.Activated:Connect(function()
    unloaded = true
    tpWalkEnabled = false
    flying = false
    updateTPWalk()
    if KeyInputConnection then KeyInputConnection:Disconnect() end
    Gui:Destroy()
end)

local dragging = false
local dragStart, startPosition
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

ShowTab("Home")
