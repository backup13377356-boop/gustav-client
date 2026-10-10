local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- Config & File Saving
--==================================================

local CONFIG_FILE = "gustav_client_cosmic_config.json"
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

local currentKey = Enum.KeyCode.RightControl
if config.ToggleKey and config.ToggleKey ~= "None" then
    pcall(function()
        currentKey = Enum.KeyCode[config.ToggleKey]
    end)
elseif config.ToggleKey == "None" then
    currentKey = nil
end

local listeningForKey = false

--==================================================
-- State & Movement / Farm Logic
--==================================================

local unloaded = false
local tpWalkEnabled = false
local tpWalkSpeed = 16
local tpWalkConnection = nil

local autoFarmCosmicActive = false
local autoMoneyActive = false
local autoUpgradeActive = false
local autoSpeedActive = false
local autoRebirthActive = false

local cosmicPos = CFrame.new(34, 3, 6126)
local basePos = CFrame.new(45, 3, -29)

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

-- 1. Auto Farm Cosmic Loop
task.spawn(function()
    while true do
        task.wait(0.8)
        if unloaded then break end
        if autoFarmCosmicActive then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Teleport to Cosmic Area
                    root.CFrame = cosmicPos

                    -- Wait for items to load in Cosmic folder (max 3 seconds)
                    local cosmicFolder = nil
                    local children = {}
                    local startWait = tick()

                    repeat
                        task.wait(0.2)
                        local itemSpawners = Workspace:FindFirstChild("ItemSpawners")
                        cosmicFolder = itemSpawners and itemSpawners:FindFirstChild("Cosmic")
                        if cosmicFolder then
                            children = cosmicFolder:GetChildren()
                        end
                    until (#children > 0) or (tick() - startWait > 3) or unloaded

                    if unloaded then return end

                    if cosmicFolder and #children > 0 then
                        local item = children[math.random(1, #children)]
                        local targetPart = nil
                        if item:IsA("BasePart") then
                            targetPart = item
                        elseif item:IsA("Model") then
                            targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        end
                        
                        if targetPart then
                            root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.4)

                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or targetPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                pcall(function()
                                    fireproximityprompt(prompt)
                                end)
                            end

                            task.wait(1.0)
                        end
                    end

                    if unloaded then return end

                    -- Return to Base
                    root.CFrame = basePos
                    task.wait(0.5)

                    -- Fire PlaceBestRequested Event
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local placeBestEvent = remotes and remotes:FindFirstChild("PlaceBestRequested")
                    if placeBestEvent then
                        placeBestEvent:FireServer()
                    end

                    task.wait(1.0)
                end
            end)
        end
    end
end)

-- 2. Auto Money Loop
task.spawn(function()
    while true do
        task.wait(1.0)
        if unloaded then break end
        if autoMoneyActive then
            pcall(function()
                local plots = Workspace:FindFirstChild("Plots")
                local myPlot = plots and plots:FindFirstChild("Plot_" .. Player.Name)
                if not myPlot and plots then
                    myPlot = plots:FindFirstChild("Plot_gustabder67")
                end
                
                if myPlot then
                    local actionButtons = myPlot:FindFirstChild("ActionButtons")
                    local banerModel = actionButtons and actionButtons:FindFirstChild("BanerModel")
                    local baner = banerModel and banerModel:FindFirstChild("Baner")
                    local collectPrompt = baner and baner:FindFirstChild("CollectActionPrompt")
                    
                    if collectPrompt then
                        pcall(function()
                            fireproximityprompt(collectPrompt)
                        end)
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Upgrade All Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if unloaded then break end
        if autoUpgradeActive then
            pcall(function()
                local plots = Workspace:FindFirstChild("Plots")
                local myPlot = plots and plots:FindFirstChild("Plot_" .. Player.Name)
                if not myPlot and plots then
                    myPlot = plots:FindFirstChild("Plot_gustabder67")
                end
                
                if myPlot then
                    local actionButtons = myPlot:FindFirstChild("ActionButtons")
                    local banerModel = actionButtons and actionButtons:FindFirstChild("BanerModel")
                    local baner = banerModel and banerModel:FindFirstChild("Baner")
                    local upgradePrompt = baner and baner:FindFirstChild("UpgradeAllActionPrompt")
                    
                    if upgradePrompt then
                        pcall(function()
                            fireproximityprompt(upgradePrompt)
                        end)
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Speed Loop
task.spawn(function()
    while true do
        task.wait(2.0)
        if unloaded then break end
        if autoSpeedActive then
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local upgradeEvent = remotes and remotes:FindFirstChild("UpgradeRequested")
                if upgradeEvent then
                    upgradeEvent:FireServer("Speed", 20)
                end
            end)
        end
    end
end)

-- 5. Auto Rebirth Loop
task.spawn(function()
    while true do
        task.wait(3.0)
        if unloaded then break end
        if autoRebirthActive then
            pcall(function()
                local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
                local rebirthEvent = eventsFolder and eventsFolder:FindFirstChild("RequestRebirth")
                if rebirthEvent then
                    rebirthEvent:FireServer(nil)
                end
            end)
        end
    end
end)

--==================================================
-- Main GUI Setup (Gustav Client Theme)
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavClientCosmic"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- Main Window[cite: 1]
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(520, 540)
Main.Position = UDim2.new(0.5, -260, 0.5, -270)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- Top Bar[cite: 1]
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
Title.Text = "Gustav Client | Cosmic Farm"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button[cite: 1]
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 40, 0, 40)
MinimizeButton.Position = UDim2.new(1, -45, 0, 7)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
MinimizeButton.TextSize = 30
MinimizeButton.Font = Enum.Font.GothamMedium
MinimizeButton.Parent = TopBar

MinimizeButton.Activated:Connect(function()
    Main.Visible = false
end)

-- Sidebar[cite: 1]
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

-- Content Frame[cite: 1]
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -135, 1, -55)
Content.Position = UDim2.fromOffset(135, 55)
Content.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Content.BorderSizePixel = 0
Content.Parent = Main

--==================================================
-- Helper Functions[cite: 1]
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
-- Tabs[cite: 1]
--==================================================

local CosmicTab = CreateTabButton("Cosmic")
CosmicTab.LayoutOrder = 1

local MovementTab = CreateTabButton("Movement")
MovementTab.LayoutOrder = 2

local SettingsTab = CreateTabButton("Settings")
SettingsTab.LayoutOrder = 3

--==================================================
-- Cosmic Page
--==================================================

local CosmicPage = Instance.new("Frame")
CosmicPage.Size = UDim2.new(1, -30, 1, -30)
CosmicPage.Position = UDim2.fromOffset(15, 15)
CosmicPage.BackgroundTransparency = 1
CosmicPage.Parent = Content

local CosmicTitle = CreateLabel(
    CosmicPage,
    "Cosmic Farm Manager",
    UDim2.new(1, 0, 0, 30),
    UDim2.fromOffset(0, 0)
)
CosmicTitle.TextSize = 20
CosmicTitle.Font = Enum.Font.GothamBold

-- Auto Farm Cosmic Toggle
local AutoFarmCosmicBtn = CreateToggle(
    CosmicPage,
    "Auto Farm Cosmic: OFF",
    UDim2.fromOffset(0, 38)
)

AutoFarmCosmicBtn.Activated:Connect(function()
    if unloaded then return end
    autoFarmCosmicActive = not autoFarmCosmicActive
    if autoFarmCosmicActive then
        AutoFarmCosmicBtn.Text = "Auto Farm Cosmic: ON"
        AutoFarmCosmicBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoFarmCosmicBtn.Text = "Auto Farm Cosmic: OFF"
        AutoFarmCosmicBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

-- Auto Money Toggle
local AutoMoneyBtn = CreateToggle(
    CosmicPage,
    "Auto Money: OFF",
    UDim2.fromOffset(0, 86)
)

AutoMoneyBtn.Activated:Connect(function()
    if unloaded then return end
    autoMoneyActive = not autoMoneyActive
    if autoMoneyActive then
        AutoMoneyBtn.Text = "Auto Money: ON"
        AutoMoneyBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoMoneyBtn.Text = "Auto Money: OFF"
        AutoMoneyBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

-- Auto Upgrade All Toggle
local AutoUpgradeBtn = CreateToggle(
    CosmicPage,
    "Auto Upgrade All: OFF",
    UDim2.fromOffset(0, 134)
)

AutoUpgradeBtn.Activated:Connect(function()
    if unloaded then return end
    autoUpgradeActive = not autoUpgradeActive
    if autoUpgradeActive then
        AutoUpgradeBtn.Text = "Auto Upgrade All: ON"
        AutoUpgradeBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoUpgradeBtn.Text = "Auto Upgrade All: OFF"
        AutoUpgradeBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

-- Auto Speed Toggle
local AutoSpeedBtn = CreateToggle(
    CosmicPage,
    "Auto Speed: OFF",
    UDim2.fromOffset(0, 182)
)

AutoSpeedBtn.Activated:Connect(function()
    if unloaded then return end
    autoSpeedActive = not autoSpeedActive
    if autoSpeedActive then
        AutoSpeedBtn.Text = "Auto Speed: ON"
        AutoSpeedBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoSpeedBtn.Text = "Auto Speed: OFF"
        AutoSpeedBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

-- Auto Rebirth Toggle
local AutoRebirthBtn = CreateToggle(
    CosmicPage,
    "Auto Rebirth: OFF",
    UDim2.fromOffset(0, 230)
)

AutoRebirthBtn.Activated:Connect(function()
    if unloaded then return end
    autoRebirthActive = not autoRebirthActive
    if autoRebirthActive then
        AutoRebirthBtn.Text = "Auto Rebirth: ON"
        AutoRebirthBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoRebirthBtn.Text = "Auto Rebirth: OFF"
        AutoRebirthBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

-- TP to Base Button
local TPBaseBtn = Instance.new("TextButton")
TPBaseBtn.Size = UDim2.new(1, 0, 0, 36)
TPBaseBtn.Position = UDim2.fromOffset(0, 278)
TPBaseBtn.BackgroundColor3 = Color3.fromRGB(50, 28, 80)
TPBaseBtn.BorderSizePixel = 0
TPBaseBtn.Text = "TP to Base (45, 3, -29)"
TPBaseBtn.TextColor3 = Color3.fromRGB(255, 200, 255)
TPBaseBtn.TextSize = 13
TPBaseBtn.Font = Enum.Font.GothamBold
TPBaseBtn.AutoButtonColor = false
TPBaseBtn.Parent = CosmicPage

local tpBaseCorner = Instance.new("UICorner")
tpBaseCorner.CornerRadius = UDim.new(0, 8)
tpBaseCorner.Parent = TPBaseBtn

TPBaseBtn.Activated:Connect(function()
    if unloaded then return end
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = basePos
    end
end)

-- Live Scrolling Frame for Cosmic Items
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -324)
ScrollFrame.Position = UDim2.fromOffset(0, 320)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(168, 85, 247)
ScrollFrame.Parent = CosmicPage

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local function updateCosmicList()
    if unloaded then return end
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local itemSpawners = Workspace:FindFirstChild("ItemSpawners")
    local cosmicFolder = itemSpawners and itemSpawners:FindFirstChild("Cosmic")
    
    if not cosmicFolder then
        local errLbl = Instance.new("TextLabel")
        errLbl.Size = UDim2.new(1, 0, 0, 30)
        errLbl.BackgroundTransparency = 1
        errLbl.Text = "Waiting for 'Cosmic' folder..."
        errLbl.TextColor3 = Color3.fromRGB(200, 100, 100)
        errLbl.TextSize = 12
        errLbl.Font = Enum.Font.Gotham
        errLbl.Parent = ScrollFrame
        return
    end

    local children = cosmicFolder:GetChildren()
    if #children == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 30)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "No spawners in Cosmic."
        emptyLbl.TextColor3 = Color3.fromRGB(130, 115, 160)
        emptyLbl.TextSize = 12
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.Parent = ScrollFrame
        return
    end

    for _, item in ipairs(children) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. item.Name .. " (" .. item.ClassName .. ")"
        btn.TextColor3 = Color3.fromRGB(243, 235, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Parent = ScrollFrame

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        btn.Activated:Connect(function()
            if unloaded then return end
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local targetPart = nil
                if item:IsA("BasePart") then
                    targetPart = item
                elseif item:IsA("Model") then
                    targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                end
                
                if targetPart then
                    root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or targetPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                    end
                end
            end
        end)
    end
end

task.spawn(function()
    while not unloaded do
        task.wait(1)
        updateCosmicList()
    end
end)

--==================================================
-- Movement Page[cite: 1]
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

-- TP Walk Toggle[cite: 1]
local TPWalkButton = CreateToggle(
    MovementPage,
    "TP Walk: OFF",
    UDim2.fromOffset(0, 45)
)

-- TP Walk Speed Slider[cite: 1]
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
-- Settings Page[cite: 1]
--==================================================

local SettingsPage = Instance.new("ScrollingFrame")
SettingsPage.Size = UDim2.new(1, -20, 1, -20)
SettingsPage.Position = UDim2.fromOffset(10, 10)
SettingsPage.BackgroundTransparency = 1
SettingsPage.BorderSizePixel = 0
SettingsPage.ScrollBarThickness = 5
SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 220)
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

local initialKeyText = (config.ToggleKey and config.ToggleKey ~= "None") and config.ToggleKey or "None"
local KeybindButton = CreateToggle(
    SettingsPage,
    "Toggle UI Key: " .. initialKeyText,
    UDim2.fromOffset(0, 95)
)
KeybindButton.Size = UDim2.new(1, -10, 0, 42)

if config.ToggleKey and config.ToggleKey ~= "None" then
    KeybindButton.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
end

local ClearKeybindButton = Instance.new("TextButton")
ClearKeybindButton.Size = UDim2.new(1, -10, 0, 38)
ClearKeybindButton.Position = UDim2.fromOffset(0, 145)
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
UnloadButton.Position = UDim2.fromOffset(0, 190)
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
-- Keybind Logic[cite: 1]
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

    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        if currentKey and input.KeyCode == currentKey then
            Main.Visible = not Main.Visible
        end
    end
end)

--==================================================
-- Tab Switching[cite: 1]
--==================================================

local function ShowTab(tab)
    CosmicPage.Visible = (tab == "Cosmic")
    MovementPage.Visible = (tab == "Movement")
    SettingsPage.Visible = (tab == "Settings")

    if tab == "Cosmic" then
        CosmicTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    elseif tab == "Movement" then
        CosmicTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    else
        CosmicTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        MovementTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        SettingsTab.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
    end
end

CosmicTab.Activated:Connect(function() ShowTab("Cosmic") end)
MovementTab.Activated:Connect(function() ShowTab("Movement") end)
SettingsTab.Activated:Connect(function() ShowTab("Settings") end)

--==================================================
-- Unload[cite: 1]
--==================================================

UnloadButton.Activated:Connect(function()
    unloaded = true
    tpWalkEnabled = false
    autoFarmCosmicActive = false
    autoMoneyActive = false
    autoUpgradeActive = false
    autoSpeedActive = false
    autoRebirthActive = false

    updateTPWalk()

    if KeyInputConnection then
        KeyInputConnection:Disconnect()
    end

    Gui:Destroy()
end)

--==================================================
-- Dragging Logic[cite: 1]
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
-- Start[cite: 1]
--==================================================

ShowTab("Cosmic")
