local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local unloaded = false
local autoBrainrotActive = false
local autoCashActive = false

-- Auto Collect Cash Einstellungen
local CASH_REQUEST_DELAY = 1
local CASH_CYCLE_DELAY = 5

-- Verbindungen für den Meldungsfilter
local warningConnections = {}
local warningAddedConnection

--==================================================
-- Meldung "Paying too fast" aus der PlayerGui entfernen
--==================================================

local function watchForFastWarning(instance)
    if not (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
        return
    end

    local function checkWarning()
        if unloaded or not instance.Parent then
            return
        end

        local text = string.lower(instance.Text or "")

        if string.find(text, "paying too fast", 1, true) then
            local target = instance
            local parent = instance.Parent

            -- Wenn die Meldung in einem eigenen Frame liegt,
            -- versuchen wir auch diesen zu entfernen.
            if parent and parent:IsA("Frame") then
                local hasOtherText = false

                for _, child in ipairs(parent:GetDescendants()) do
                    if child ~= instance
                        and (child:IsA("TextLabel") or child:IsA("TextButton")) then
                        hasOtherText = true
                        break
                    end
                end

                if not hasOtherText then
                    target = parent
                end
            end

            target:Destroy()
        end
    end

    table.insert(
        warningConnections,
        instance:GetPropertyChangedSignal("Text"):Connect(checkWarning)
    )

    task.defer(checkWarning)
end

-- Bereits vorhandene Meldungen prüfen
for _, instance in ipairs(PlayerGui:GetDescendants()) do
    watchForFastWarning(instance)
end

-- Neue Meldungen ebenfalls prüfen
warningAddedConnection = PlayerGui.DescendantAdded:Connect(
    watchForFastWarning
)

--==================================================
-- Prüfen, ob der Charakter etwas in den Händen hält
--==================================================

local function hasItemInHands()
    local char = Player.Character
    if not char then
        return false
    end

    return char:FindFirstChildOfClass("Tool") ~= nil
end

--==================================================
-- Brainrot Sequence
--==================================================

local function runBrainrotSequence()
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    -- 1. Area laden
    root.CFrame = CFrame.new(-93, 59, -7840)
    task.wait(1.0)

    if unloaded then
        return
    end

    -- 2. Brainrots durchsuchen
    local brainrots = Workspace:FindFirstChild("Brainrots")

    if brainrots then
        local foldersToCheck = {
            brainrots:FindFirstChild("-2,0,-79"),
            brainrots:FindFirstChild("-1,0,-79")
        }

        local collected = false

        for _, folder in ipairs(foldersToCheck) do
            if collected or unloaded then
                break
            end

            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    if unloaded then
                        break
                    end

                    local targetPart =
                        item:IsA("BasePart") and item
                        or (
                            item:IsA("Model")
                            and (
                                item.PrimaryPart
                                or item:FindFirstChildWhichIsA("BasePart")
                            )
                        )

                    if targetPart then
                        root.CFrame =
                            targetPart.CFrame + Vector3.new(0, 2, 0)

                        task.wait(0.15)

                        local prompt =
                            item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            or targetPart:FindFirstChildWhichIsA(
                                "ProximityPrompt",
                                true
                            )

                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end

                        pcall(function()
                            firetouchinterest(root, targetPart, 0)
                            firetouchinterest(root, targetPart, 1)
                        end)

                        task.wait(0.2)

                        if hasItemInHands() then
                            collected = true
                            break
                        end
                    end
                end
            end
        end
    end

    if unloaded then
        return
    end

    -- 3. Zum nächsten Punkt teleportieren
    root.CFrame = CFrame.new(-69, 62, -96)
    task.wait(0.3)

    if unloaded then
        return
    end

    -- 4. Sanft zum Ziel fliegen
    local startCF = CFrame.new(-69, 62, -96)
    local targetCF = CFrame.new(-69, 59, 9)

    root.CFrame = startCF

    local tweenInfo = TweenInfo.new(
        1.2,
        Enum.EasingStyle.Linear
    )

    local flyTween = TweenService:Create(
        root,
        tweenInfo,
        { CFrame = targetCF }
    )

    flyTween:Play()

    while flyTween.PlaybackState == Enum.PlaybackState.Playing
        and not unloaded do
        task.wait(0.05)
    end

    if unloaded then
        flyTween:Cancel()
        return
    end

    -- 5. Items ablegen
    local currentCharacter = Player.Character

    if currentCharacter then
        local hum = currentCharacter:FindFirstChildOfClass("Humanoid")

        if hum then
            pcall(function()
                hum:UnequipTools()
            end)
        end

        for _, child in ipairs(currentCharacter:GetChildren()) do
            if child:IsA("Tool") then
                child.Parent =
                    Player:FindFirstChild("Backpack")
                    or Player:FindFirstChild("Inventory")
            end
        end
    end
end

--==================================================
-- GUI Setup
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GustavClientBrainrot"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(380, 300)
Main.Position = UDim2.new(0.5, -190, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

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
Title.Text = "Gustav Client | Brainrot Farm"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

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

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -30, 1, -70)
Content.Position = UDim2.fromOffset(15, 60)
Content.BackgroundTransparency = 1
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

--==================================================
-- Auto Brainrot Toggle
--==================================================

local AutoBrainrotBtn = Instance.new("TextButton")
AutoBrainrotBtn.Size = UDim2.new(1, 0, 0, 42)
AutoBrainrotBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
AutoBrainrotBtn.BorderSizePixel = 0
AutoBrainrotBtn.Text = "Auto Brainrot Loop: OFF"
AutoBrainrotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBrainrotBtn.TextSize = 14
AutoBrainrotBtn.Font = Enum.Font.GothamBold
AutoBrainrotBtn.AutoButtonColor = false
AutoBrainrotBtn.Parent = Content

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = AutoBrainrotBtn

AutoBrainrotBtn.Activated:Connect(function()
    if unloaded then
        return
    end

    autoBrainrotActive = not autoBrainrotActive

    if autoBrainrotActive then
        AutoBrainrotBtn.Text = "Auto Brainrot Loop: ON"
        AutoBrainrotBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    else
        AutoBrainrotBtn.Text = "Auto Brainrot Loop: OFF"
        AutoBrainrotBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    end
end)

--==================================================
-- Button-Ersteller
--==================================================

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

--==================================================
-- Run Sequence Once
--==================================================

createButton(
    "Run Sequence Once",
    Color3.fromRGB(55, 100, 180),
    Color3.fromRGB(255, 255, 255),
    function()
        task.spawn(runBrainrotSequence)
    end
)

--==================================================
-- Auto Collect Cash: RemoteFunction finden
--==================================================

local function getClaimEarnings()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local index = packages and packages:FindFirstChild("_Index")

    local packageFolder =
        index and index:FindFirstChild("sleitnick_knit@1.7.0")

    local knit = packageFolder and packageFolder:FindFirstChild("knit")
    local services = knit and knit:FindFirstChild("Services")
    local gameService = services and services:FindFirstChild("Game")
    local rf = gameService and gameService:FindFirstChild("RF")
    local event = rf and rf:FindFirstChild("ClaimEarnings")

    if event and event:IsA("RemoteFunction") then
        return event
    end

    return nil
end

--==================================================
-- Auto Collect Cash Toggle
--==================================================

local AutoCashBtn

AutoCashBtn = createButton(
    "Auto Collect Cash: OFF",
    Color3.fromRGB(170, 55, 65),
    Color3.fromRGB(255, 255, 255),
    function()
        autoCashActive = not autoCashActive

        if autoCashActive then
            AutoCashBtn.Text = "Auto Collect Cash: ON"
            AutoCashBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
        else
            AutoCashBtn.Text = "Auto Collect Cash: OFF"
            AutoCashBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
        end
    end
)

--==================================================
-- Auto Collect Cash Worker
--==================================================

local function waitWhileActive(duration)
    local elapsed = 0

    while elapsed < duration do
        if unloaded or not autoCashActive then
            return false
        end

        elapsed += task.wait(math.min(0.1, duration - elapsed))
    end

    return not unloaded and autoCashActive
end

task.spawn(function()
    while not unloaded do
        if not autoCashActive then
            task.wait(0.2)
        else
            local event = getClaimEarnings()

            if not event then
                warn("Auto Collect Cash: ClaimEarnings wurde nicht gefunden.")

                autoCashActive = false
                AutoCashBtn.Text = "Auto Collect Cash: OFF"
                AutoCashBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)

                task.wait(1)
            else
                -- IDs von 1 bis 100 nacheinander abfragen
                for i = 1, 100 do
                    if unloaded or not autoCashActive then
                        break
                    end

                    local success, err = pcall(function()
                        event:InvokeServer(tostring(i))
                    end)

                    if not success then
                        warn(
                            "ClaimEarnings bei ID "
                            .. tostring(i)
                            .. ": "
                            .. tostring(err)
                        )
                    end

                    -- Pause zwischen jeder Anfrage
                    if not waitWhileActive(CASH_REQUEST_DELAY) then
                        break
                    end
                end

                -- Pause vor dem nächsten Durchlauf
                if autoCashActive and not unloaded then
                    waitWhileActive(CASH_CYCLE_DELAY)
                end
            end
        end
    end
end)

--==================================================
-- Unload Script
--==================================================

createButton(
    "Unload Script",
    Color3.fromRGB(170, 55, 65),
    Color3.fromRGB(255, 255, 255),
    function()
        unloaded = true
        autoBrainrotActive = false
        autoCashActive = false

        if warningAddedConnection then
            warningAddedConnection:Disconnect()
        end

        for _, connection in ipairs(warningConnections) do
            connection:Disconnect()
        end

        Gui:Destroy()
    end
)

--==================================================
-- Brainrot Auto Loop
--==================================================

task.spawn(function()
    while true do
        task.wait(1.5)

        if unloaded then
            break
        end

        if autoBrainrotActive then
            pcall(runBrainrotSequence)
        end
    end
end)

--==================================================
-- Dragging
--==================================================

local dragging = false
local dragStart, startPosition

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging
        and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)
