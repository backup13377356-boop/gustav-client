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

local CONFIG_FILE = "gustav_dev_config.json"
local config = {
    ToggleKey = "RightControl"
}

local function LoadConfig()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(result) == "table" then
            if result.ToggleKey ~= nil then
                config.ToggleKey = result.ToggleKey
            end
        end
    end
end

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
        end)
    end
end

LoadConfig()

local currentKey = (config.ToggleKey and config.ToggleKey ~= "None" and Enum.KeyCode[config.ToggleKey]) or nil
local listeningForKey = false

--==================================================
-- State & Variables
--==================================================

local unloaded = false

-- Movement & Camera State
local tpWalkEnabled = false
local tpWalkSpeed = 16
local tpWalkConnection = nil
local unlockZoomEnabled = true
local forceMouseVisible = true

-- RenderStepped for Camera Zoom & Mouse Cursor Lock
RunService.RenderStepped:Connect(function()
    if unloaded then return end

    if unlockZoomEnabled then
        Player.CameraMaxZoomDistance = 100000
    end

    if forceMouseVisible then
        UserInputService.MouseIconEnabled = true
    end
end)

local function updateTPWalk()
    if tpWalkConnection then
        tpWalkConnection:Disconnect()
        tpWalkConnection = nil
    end

    if tpWalkEnabled and not unloaded then
        tpWalkConnection = RunService.Heartbeat:Connect(function(deltaTime)
            local character = Player.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                local moveDir = humanoid.MoveDirection
                hrp.CFrame = hrp.CFrame + (moveDir * (tpWalkSpeed * deltaTime))
            end
        end)
    end
end

--==================================================
-- Main GUI Setup
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavDevVer"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(520, 400)
Main.Position = UDim2.new(0.5, -260, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gustav Dev Ver"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Sidebar
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

-- Content Frame
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

local function CreateToggle(parent, text, position)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.Position = position
    Button.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    return Button
end

local function CreateScriptButton(parent, text, position, url, rawBool)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 40)
    Button.Position = position
    Button.BackgroundColor3 = Color3.fromRGB(45, 100, 180)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    Button.Activated:Connect(function()
        if unloaded then return end
        pcall(function()
            if rawBool then
                loadstring(game:HttpGet(url, true))()
            else
                loadstring(game:HttpGet(url))()
            end
        end)
        
        -- Kleines Feedback
        local oldText = Button.Text
        Button.Text = "Executed!"
        Button.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
        task.delay(1, function()
            Button.Text = oldText
            Button.BackgroundColor3 = Color3.fromRGB(45, 100, 180)
        end)
    end)

    return Button
end

--==================================================
-- Tabs
--==================================================

local ScriptsTab = CreateTabButton("Scripts")
ScriptsTab.LayoutOrder = 1

local MovementTab = CreateTabButton("Movement")
MovementTab.LayoutOrder = 2

local SettingsTab = CreateTabButton("Settings")
SettingsTab.LayoutOrder = 3

--==================================================
-- Scripts Page
--==================================================

local ScriptsPage = Instance.new("ScrollingFrame")
ScriptsPage.Size = UDim2.new(1, -20, 1, -20)
ScriptsPage.Position = UDim2.fromOffset(10, 10)
ScriptsPage.BackgroundTransparency = 1
ScriptsPage.BorderSizePixel = 0
ScriptsPage.ScrollBarThickness = 4
ScriptsPage.CanvasSize = UDim2.new(0, 0, 0, 310)
ScriptsPage.Parent = Content

local ScriptsTitle = CreateLabel(
    ScriptsPage,
    "Developer Scripts",
    UDim2.new(1, 0, 0, 25),
    UDim2.fromOffset(0, 0)
)
ScriptsTitle.TextSize = 20
ScriptsTitle.Font = Enum.Font.GothamBold

-- Script Buttons
CreateScriptButton(ScriptsPage, "Load Infinite Yield", UDim2.fromOffset(0, 35), "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/IY.lua", false)
CreateScriptButton(ScriptsPage, "Load Cobalt", UDim2.fromOffset(0, 80), "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/Cobalt.luau", false)
CreateScriptButton(ScriptsPage, "Load Dex", UDim2.fromOffset(0, 125), "https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true)
CreateScriptButton(ScriptsPage, "Load Infinite Yield (5.9.3)", UDim2.fromOffset(0, 170), "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/IY.5.9.3", false)
CreateScriptButton(ScriptsPage, "Load Simple Spy", UDim2.fromOffset(0, 215), "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/simple%20spy.lua", false)
CreateScriptButton(ScriptsPage, "Load Vex Explorer", UDim2.fromOffset(0, 260), "https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/vex.lua", false)

--==================================================
-- Movement Page
--==================================================

local MovementPage = Instance.new("ScrollingFrame")
MovementPage.Size = UDim2.new(1, -20, 1, -20)
MovementPage.Position = UDim2.fromOffset(10, 10)
MovementPage.BackgroundTransparency = 1
MovementPage.BorderSizePixel = 0
MovementPage.ScrollBarThickness = 4
MovementPage.CanvasSize = UDim2.new(0, 0, 0, 260)
MovementPage.Visible = false
MovementPage.Parent = Content

local MovementTitle = CreateLabel(
    MovementPage,
    "Movement & Camera",
    UDim2.new(1, 0, 0, 25),
    UDim2.fromOffset(0, 0)
)
MovementTitle.TextSize = 20
MovementTitle.Font = Enum.Font.GothamBold

-- TP Walk Toggle
local TPWalkButton = CreateToggle(
    MovementPage,
    "TP Walk: OFF",
    UDim2.fromOffset(0, 35)
)
TPWalkButton.Size = UDim2.new(1, -10, 0, 38)

-- TP Walk Speed Slider
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, -10, 0, 45)
SliderFrame.Position = UDim2.fromOffset(0, 80)
SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SliderFrame.BorderSizePixel = 0
SliderFrame.Parent = MovementPage

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 8)
SliderCorner.Parent = SliderFrame

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, -20, 0, 20)
SliderLabel.Position = UDim2.fromOffset(10, 4)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "TP Walk Speed: 16"
SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
SliderLabel.TextSize = 13
SliderLabel.Font = Enum.Font.GothamMedium
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = SliderFrame

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -20, 0, 8)
SliderTrack.Position = UDim2.fromOffset(10, 28)
SliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderFrame

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(0, 4)
TrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.08, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = SliderFill

-- Camera Max Zoom Unlock Toggle
local UnlockZoomButton = CreateToggle(
    MovementPage,
    "Unlock Max Camera Zoom: ON",
    UDim2.fromOffset(0, 135)
)
UnlockZoomButton.Size = UDim2.new(1, -10, 0, 38)
UnlockZoomButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)

-- Force Mouse Cursor Toggle
local ForceMouseButton = CreateToggle(
    MovementPage,
    "Force Always Show Cursor: ON",
    UDim2.fromOffset(0, 180)
)
ForceMouseButton.Size = UDim2.new(1, -10, 0, 38)
ForceMouseButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)

local minSpeed = 1
local maxSpeed = 200
local draggingSlider = false

local function updateSlider(input)
    local trackPos = SliderTrack.AbsolutePosition.X
    local trackWidth = SliderTrack.AbsoluteSize.X
    local mouseX = input.Position.X

    local percent = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
    SliderFill.Size = UDim2.new(percent, 0, 1, 0)

    tpWalkSpeed = math.floor(minSpeed + percent * (maxSpeed - minSpeed))
    SliderLabel.Text = "TP Walk Speed: " .. tostring(tpWalkSpeed)

    if tpWalkEnabled then
        updateTPWalk()
    end
end

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

TPWalkButton.Activated:Connect(function()
    if unloaded then return end
    tpWalkEnabled = not tpWalkEnabled

    if tpWalkEnabled then
        TPWalkButton.Text = "TP Walk: ON"
        TPWalkButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        TPWalkButton.Text = "TP Walk: OFF"
        TPWalkButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
    updateTPWalk()
end)

UnlockZoomButton.Activated:Connect(function()
    if unloaded then return end
    unlockZoomEnabled = not unlockZoomEnabled

    if unlockZoomEnabled then
        UnlockZoomButton.Text = "Unlock Max Camera Zoom: ON"
        UnlockZoomButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        UnlockZoomButton.Text = "Unlock Max Camera Zoom: OFF"
        UnlockZoomButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
        Player.CameraMaxZoomDistance = 128
    end
end)

ForceMouseButton.Activated:Connect(function()
    if unloaded then return end
    forceMouseVisible = not forceMouseVisible

    if forceMouseVisible then
        ForceMouseButton.Text = "Force Always Show Cursor: ON"
        ForceMouseButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        ForceMouseButton.Text = "Force Always Show Cursor: OFF"
        ForceMouseButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Settings Page
--==================================================

local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Size = UDim2.new(1, -20, 1, -20)
SettingsPage.Position = UDim2.fromOffset(10, 10)
SettingsPage.BackgroundTransparency = 1
SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 5
SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 180)
SettingsPage.Visible = false
SettingsPage.Parent = Content

local SettingsTitle = CreateLabel(
    SettingsPage,
    "Settings",
    UDim2.new(1, 0, 0, 30),
    UDim2.fromOffset(0, 0)
)
SettingsTitle.TextSize = 22
SettingsTitle.Font = Enum.Font.GothamBold

local initialKeyText = (config.ToggleKey and config.ToggleKey ~= "None") and config.ToggleKey or "None"
local KeybindButton = CreateToggle(
    SettingsPage,
    "Toggle UI Key: " .. initialKeyText,
    UDim2.fromOffset(0, 45)
)
KeybindButton.Size = UDim2.new(1, -10, 0, 42)

if config.ToggleKey and config.ToggleKey ~= "None" then
    KeybindButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
end

local ClearKeybindButton = Instance.new("TextButton")
ClearKeybindButton.Size = UDim2.new(1, -10, 0, 38)
ClearKeybindButton.Position = UDim2.fromOffset(0, 95)
ClearKeybindButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
ClearKeybindButton.BorderSizePixel = 0
ClearKeybindButton.Text = "Remove Keybind"
ClearKeybindButton.TextColor3 = Color3.fromRGB(200, 200, 210)
ClearKeybindButton.TextSize = 14
ClearKeybindButton.Font = Enum.Font.GothamMedium
ClearKeybindButton.AutoButtonColor = false
ClearKeybindButton.Parent = SettingsPage

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 8)
ClearCorner.Parent = ClearKeybindButton

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(1, -10, 0, 42)
UnloadButton.Position = UDim2.fromOffset(0, 140)
UnloadButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
UnloadButton.BorderSizePixel = 0
UnloadButton.Text = "Unload Script"
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.TextSize = 15
UnloadButton.Font = Enum.Font.GothamBold
UnloadButton.AutoButtonColor = false
UnloadButton.Parent = SettingsPage

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 9)
UnloadCorner.Parent = UnloadButton

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

    if not gameProcessed and currentKey and input.KeyCode == currentKey then
        Main.Visible = not Main.Visible
    end
end)

--==================================================
-- Tab Switching
--==================================================

local function ShowTab(tab)
    ScriptsPage.Visible = (tab == "Scripts")
    MovementPage.Visible = (tab == "Movement")
    SettingsPage.Visible = (tab == "Settings")

    if tab == "Scripts" then
        ScriptsTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    elseif tab == "Movement" then
        ScriptsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    else
        ScriptsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
    end
end

ScriptsTab.Activated:Connect(function()
    ShowTab("Scripts")
end)

MovementTab.Activated:Connect(function()
    ShowTab("Movement")
end)

SettingsTab.Activated:Connect(function()
    ShowTab("Settings")
end)

-- Unload Handler
UnloadButton.Activated:Connect(function()
    unloaded = true
    tpWalkEnabled = false
    unlockZoomEnabled = false
    forceMouseVisible = false

    updateTPWalk()

    if KeyInputConnection then
        KeyInputConnection:Disconnect()
    end

    Gui:Destroy()
end)

-- Dragging Logic
local dragging = false
local dragStart
local startPosition

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Start Application
ShowTab("Scripts")
