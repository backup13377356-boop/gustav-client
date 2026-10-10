local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local unloaded = false

local function teleportTo(pos)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

--==================================================
-- Main GUI Setup (Gustav Client Theme)
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavClientTeleport"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(360, 260)
Main.Position = UDim2.new(0.5, -180, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gustav Client | Teleporter"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.fromOffset(36, 36)
MinimizeButton.Position = UDim2.new(1, -42, 0, 7)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 210)
MinimizeButton.TextSize = 24
MinimizeButton.Font = Enum.Font.GothamMedium
MinimizeButton.Parent = TopBar

MinimizeButton.Activated:Connect(function()
    Main.Visible = false
end)

-- Content Frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -30, 1, -70)
Content.Position = UDim2.fromOffset(15, 60)
Content.BackgroundTransparency = 1
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- Helper function to create styled buttons
local function createButton(text, bgColor, textColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = textColor
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.Activated:Connect(function()
        if not unloaded then
            callback()
        end
    end)
    return btn
end

-- Home Button
createButton("Home (117, 14590, -2643)", Color3.fromRGB(55, 100, 180), Color3.fromRGB(255, 255, 255), function()
    teleportTo(Vector3.new(117, 14590, -2643))
end)

-- Trancelucend Button
createButton("Trancelucend (-1, -6923, -2149)", Color3.fromRGB(50, 28, 80), Color3.fromRGB(255, 200, 255), function()
    teleportTo(Vector3.new(-1, -6923, -2149))
end)

-- Unload Button
createButton("Unload Script", Color3.fromRGB(170, 55, 65), Color3.fromRGB(255, 255, 255), function()
    unloaded = true
    Gui:Destroy()
end)

--==================================================
-- Dragging Logic
--==================================================

local dragging = false
local dragStart, startPosition

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)
