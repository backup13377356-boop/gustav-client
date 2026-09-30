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

local CONFIG_FILE = "gustav_client_config.json"
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
-- Remote Events
--==================================================

local TrainingEvent = ReplicatedStorage.Shared.Packages.TypedRemote.TrainingTap
local RebirthEvent = ReplicatedStorage.Shared.Packages.TypedRemote.PerformRebirth
local ArmsEvent = ReplicatedStorage.Shared.Packages.TypedRemote.ArmsAction

--==================================================
-- State & Movement
--==================================================

local farming = false
local autoRebirth = false
local autoBuyArm = false
local hideMusclePopups = false
local unloaded = false

local tpWalkEnabled = false
local tpWalkSpeed = 16
local tpWalkConnection = nil

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

-- Arm IDs (1 bis 13, überspringt 9 wegen Robux)
local ARM_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13}

--==================================================
-- Muscle, Arm & Top Popup Detector
--==================================================

local HiddenMusclePopupRoots = {}
local MutedTrainingSounds = {}

local function IsMusclePopupText(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
        return false
    end

    local text = string.lower(tostring(obj.Text or ""))

    -- Reagiert auf Zahlen-Gains (+10, + 100, +1.2k, +50 Arm, etc.)
    if string.match(text, "^%s*%+%s*%d+") then
        return true
    end

    -- Reagiert auf Arm / Muscle / Bicep / Strength Popups
    if string.find(text, "arm") or string.find(text, "bicep") or string.find(text, "strength") or string.find(text, "muscle") then
        if string.find(text, "unlocked") or string.find(text, "bought") or string.find(text, "equipped") or string.find(text, "+") or string.find(text, "gained") then
            return true
        end
    end

    return false
end

local function FindMusclePopupRoot(obj)
    local current = obj

    while current and current ~= game and current ~= PlayerGui do
        if current:IsA("BillboardGui") or current:IsA("SurfaceGui") then
            return current
        end

        if (current:IsA("Frame") or current:IsA("ImageLabel") or current:IsA("CanvasGroup")) and current.Parent then
            if current.Parent:IsA("ScreenGui") or current.Parent:IsA("LayerCollector") then
                return current
            end
        end

        current = current.Parent
    end

    return obj
end

local function IsLikelyTrainingSound(obj)
    if not obj:IsA("Sound") then
        return false
    end

    local name = string.lower(obj.Name or "")
    local parentName = obj.Parent and string.lower(obj.Parent.Name or "") or ""

    return string.find(name, "pop", 1, true)
        or string.find(name, "gain", 1, true)
        or string.find(name, "train", 1, true)
        or string.find(name, "muscle", 1, true)
        or string.find(name, "strength", 1, true)
        or string.find(name, "arm", 1, true)
        or string.find(parentName, "confetti", 1, true)
        or string.find(parentName, "popup", 1, true)
end

local function MuteTrainingSound(obj)
    if not hideMusclePopups or not IsLikelyTrainingSound(obj) then
        return
    end

    if MutedTrainingSounds[obj] == nil then
        MutedTrainingSounds[obj] = obj.Volume
    end

    obj.Volume = 0
end

local function ScanForTrainingSounds(container)
    for _, obj in ipairs(container:GetDescendants()) do
        MuteTrainingSound(obj)
    end
end

local function RestoreTrainingSounds()
    for sound, volume in pairs(MutedTrainingSounds) do
        if sound and sound.Parent then
            sound.Volume = volume
        end
    end

    table.clear(MutedTrainingSounds)
end

local function HideMusclePopup(obj)
    if not hideMusclePopups then
        return
    end

    local isPopupText = IsMusclePopupText(obj)
    local objName = string.lower(obj.Name or "")
    local isPopupName = string.find(objName, "armpopup") 
        or string.find(objName, "armunlock") 
        or string.find(objName, "musclepopup")
        or string.find(objName, "gainpopup")

    if not isPopupText and not isPopupName then
        return
    end

    local root = FindMusclePopupRoot(obj)

    if root:IsA("BillboardGui") or root:IsA("SurfaceGui") then
        if root.Enabled then
            HiddenMusclePopupRoots[root] = true
            root.Enabled = false
        end
    elseif root:IsA("GuiObject") then
        if root.Visible then
            HiddenMusclePopupRoots[root] = true
            root.Visible = false
        end
    end
end

local function ScanForMusclePopups(container)
    for _, obj in ipairs(container:GetDescendants()) do
        HideMusclePopup(obj)
    end
end

local function RestoreMusclePopups()
    for root in pairs(HiddenMusclePopupRoots) do
        if root and root.Parent then
            if root:IsA("BillboardGui") or root:IsA("SurfaceGui") then
                root.Enabled = true
            elseif root:IsA("GuiObject") then
                root.Visible = true
            end
        end
    end

    table.clear(HiddenMusclePopupRoots)
end

--==================================================
-- Hide Top Popups & Rebirth / Arm Unlock Messages
--==================================================

local function HideTopPopups(obj)
    if unloaded then
        return
    end

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local text = string.lower(obj.Text or "")

        if (string.find(text, "reach level") and string.find(text, "rebirth"))
            or string.find(text, "unlocked")
            or string.find(text, "new arm")
            or string.find(text, "arm unlocked") then
            
            obj.Visible = false
            local root = FindMusclePopupRoot(obj)
            if root and root ~= PlayerGui and root ~= workspace and root:IsA("GuiObject") then
                root.Visible = false
            end
        end
    end

    if obj:IsA("GuiObject") then
        local name = string.lower(obj.Name or "")
        if string.find(name, "notification") 
            or string.find(name, "topbarpopup") 
            or string.find(name, "notice")
            or string.find(name, "armpopup")
            or string.find(name, "armunlock")
            or string.find(name, "unlockpopup") then
            obj.Visible = false
        end
    end
end

local function SetHideMusclePopups(enabled)
    hideMusclePopups = enabled

    if enabled then
        ScanForMusclePopups(PlayerGui)
        ScanForMusclePopups(workspace)
        ScanForTrainingSounds(PlayerGui)
        ScanForTrainingSounds(workspace)
    else
        RestoreMusclePopups()
        RestoreTrainingSounds()
    end
end

--==================================================
-- Existing UI Cleanup Connections
--==================================================

for _, obj in ipairs(PlayerGui:GetDescendants()) do
    HideTopPopups(obj)
end

local GuiConnection = PlayerGui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        HideTopPopups(obj)
        HideMusclePopup(obj)
        MuteTrainingSound(obj)
    end)
end)

local WorkspaceGuiConnection = workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        HideMusclePopup(obj)
        MuteTrainingSound(obj)
    end)
end)

--==================================================
-- Main GUI Setup
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavClient"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(520, 360)
Main.Position = UDim2.new(0.5, -260, 0.5, -180)
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
Title.Text = "Gustav Client"
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
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.Position = position
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

--==================================================
-- Tabs
--==================================================

local FarmTab = CreateTabButton("Farm")
FarmTab.LayoutOrder = 1

local MovementTab = CreateTabButton("Movement")
MovementTab.LayoutOrder = 2

local SettingsTab = CreateTabButton("Settings")
SettingsTab.LayoutOrder = 3

--==================================================
-- Farm Page
--==================================================

local FarmPage = Instance.new("Frame")
FarmPage.Size = UDim2.new(1, -30, 1, -30)
FarmPage.Position = UDim2.fromOffset(15, 15)
FarmPage.BackgroundTransparency = 1
FarmPage.Parent = Content

local FarmTitle = CreateLabel(
    FarmPage,
    "Farming",
    UDim2.new(1, 0, 0, 30),
    UDim2.fromOffset(0, 0)
)
FarmTitle.TextSize = 22
FarmTitle.Font = Enum.Font.GothamBold

local FarmButton = CreateToggle(
    FarmPage,
    "Farming: OFF",
    UDim2.fromOffset(0, 45)
)

local RebirthButton = CreateToggle(
    FarmPage,
    "Auto Rebirth: OFF",
    UDim2.fromOffset(0, 100)
)

local AutoArmButton = CreateToggle(
    FarmPage,
    "Auto Buy Arm: OFF",
    UDim2.fromOffset(0, 155)
)

--==================================================
-- Movement Page
--==================================================

local MovementPage = Instance.new("Frame")
MovementPage.Size = UDim2.new(1, -30, 1, -30)
MovementPage.Position = UDim2.fromOffset(15, 15)
MovementPage.BackgroundTransparency = 1
MovementPage.Visible = false
MovementPage.Parent = Content

local MovementTitle = CreateLabel(
    MovementPage,
    "Movement",
    UDim2.new(1, 0, 0, 30),
    UDim2.fromOffset(0, 0)
)
MovementTitle.TextSize = 22
MovementTitle.Font = Enum.Font.GothamBold

-- TP Walk Toggle
local TPWalkButton = CreateToggle(
    MovementPage,
    "TP Walk: OFF",
    UDim2.fromOffset(0, 45)
)

-- TP Walk Speed Slider
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, 0, 0, 45)
SliderFrame.Position = UDim2.fromOffset(0, 95)
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

--==================================================
-- Settings Page (ScrollingFrame)
--==================================================

local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Size = UDim2.new(1, -20, 1, -20)
SettingsPage.Position = UDim2.fromOffset(10, 10)
SettingsPage.BackgroundTransparency = 1
SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 5
SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 310)
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

-- Load Infinite Yield Button
local LoadIYButton = Instance.new("TextButton")
LoadIYButton.Size = UDim2.new(1, -10, 0, 42)
LoadIYButton.Position = UDim2.fromOffset(0, 45)
LoadIYButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LoadIYButton.BorderSizePixel = 0
LoadIYButton.Text = "Load Infinite Yield"
LoadIYButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadIYButton.TextSize = 15
LoadIYButton.Font = Enum.Font.GothamBold
LoadIYButton.AutoButtonColor = false
LoadIYButton.Parent = SettingsPage

local IYCorner = Instance.new("UICorner")
IYCorner.CornerRadius = UDim.new(0, 8)
IYCorner.Parent = LoadIYButton

LoadIYButton.Activated:Connect(function()
    if unloaded then return end
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end)

-- Muscle Popup Button
local MusclePopupButton = CreateToggle(
    SettingsPage,
    "Hide Muscle Popups: OFF",
    UDim2.fromOffset(0, 95)
)
MusclePopupButton.Size = UDim2.new(1, -10, 0, 42)

-- Keybind Buttons
local initialKeyText = (config.ToggleKey and config.ToggleKey ~= "None") and config.ToggleKey or "None"
local KeybindButton = CreateToggle(
    SettingsPage,
    "Toggle UI Key: " .. initialKeyText,
    UDim2.fromOffset(0, 145)
)
KeybindButton.Size = UDim2.new(1, -10, 0, 42)

if config.ToggleKey and config.ToggleKey ~= "None" then
    KeybindButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
end

local ClearKeybindButton = Instance.new("TextButton")
ClearKeybindButton.Size = UDim2.new(1, -10, 0, 38)
ClearKeybindButton.Position = UDim2.fromOffset(0, 195)
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

-- Unload Button
local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(1, -10, 0, 42)
UnloadButton.Position = UDim2.fromOffset(0, 240)
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

--==================================================
-- Keybind Logic
--==================================================

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
-- Muscle Popup Setting
--==================================================

MusclePopupButton.Activated:Connect(function()
    if unloaded then return end

    local enabled = not hideMusclePopups
    SetHideMusclePopups(enabled)

    if enabled then
        MusclePopupButton.Text = "Hide Muscle Popups: ON"
        MusclePopupButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        MusclePopupButton.Text = "Hide Muscle Popups: OFF"
        MusclePopupButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Tab Switching
--==================================================

local function ShowTab(tab)
    FarmPage.Visible = (tab == "Farm")
    MovementPage.Visible = (tab == "Movement")
    SettingsPage.Visible = (tab == "Settings")

    if tab == "Farm" then
        FarmTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    elseif tab == "Movement" then
        FarmTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    else
        FarmTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
    end
end

FarmTab.Activated:Connect(function()
    ShowTab("Farm")
end)

MovementTab.Activated:Connect(function()
    ShowTab("Movement")
end)

SettingsTab.Activated:Connect(function()
    ShowTab("Settings")
end)

--==================================================
-- Farming Loop
--==================================================

FarmButton.Activated:Connect(function()
    if unloaded then return end

    farming = not farming

    if farming then
        FarmButton.Text = "Farming: ON"
        FarmButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)

        task.spawn(function()
            while farming and not unloaded do
                TrainingEvent:FireServer(
                    Vector2.new(
                        0.38789063692092896,
                        0.42147552967071533
                    )
                )
                task.wait(0.0167)
            end
        end)
    else
        FarmButton.Text = "Farming: OFF"
        FarmButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Auto Rebirth Loop
--==================================================

RebirthButton.Activated:Connect(function()
    if unloaded then return end

    autoRebirth = not autoRebirth

    if autoRebirth then
        RebirthButton.Text = "Auto Rebirth: ON"
        RebirthButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)

        task.spawn(function()
            while autoRebirth and not unloaded do
                RebirthEvent:FireServer()
                task.wait(0.25)
            end
        end)
    else
        RebirthButton.Text = "Auto Rebirth: OFF"
        RebirthButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Auto Buy Arm Loop
--==================================================

AutoArmButton.Activated:Connect(function()
    if unloaded then return end

    autoBuyArm = not autoBuyArm

    if autoBuyArm then
        AutoArmButton.Text = "Auto Buy Arm: ON"
        AutoArmButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)

        task.spawn(function()
            while autoBuyArm and not unloaded do
                for _, armId in ipairs(ARM_IDS) do
                    if not autoBuyArm or unloaded then break end
                    ArmsEvent:FireServer("Unlock", armId)
                    task.wait(0.1)
                end
                task.wait(1)
            end
        end)
    else
        AutoArmButton.Text = "Auto Buy Arm: OFF"
        AutoArmButton.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Unload
--==================================================

UnloadButton.Activated:Connect(function()
    unloaded = true

    farming = false
    autoRebirth = false
    autoBuyArm = false
    tpWalkEnabled = false

    updateTPWalk()

    if hideMusclePopups then
        SetHideMusclePopups(false)
    else
        RestoreTrainingSounds()
    end

    if GuiConnection then
        GuiConnection:Disconnect()
    end

    if WorkspaceGuiConnection then
        WorkspaceGuiConnection:Disconnect()
    end

    if KeyInputConnection then
        KeyInputConnection:Disconnect()
    end

    Gui:Destroy()
end)

--==================================================
-- Dragging Logic
--==================================================

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

--==================================================
-- Start
--==================================================

ShowTab("Farm")