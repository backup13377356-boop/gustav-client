local PlaceID = game.PlaceId
local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

-- Funktion für die Custom Notification unten rechts
local function ShowNotSupportedNotification()
    -- Erstelle das ScreenGui
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "GustavNotif"
    NotifGui.Parent = CoreGui
    
    -- Erstelle das Haupt-Fenster (Frame)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 70)
    -- Startposition: Außerhalb des Bildschirms unten rechts
    Frame.Position = UDim2.new(1, 20, 1, -90)
    Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Frame.BorderSizePixel = 0
    Frame.Parent = NotifGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    -- Titel
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 25)
    Title.Position = UDim2.fromOffset(10, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "Gustav Client"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    
    -- Beschreibung
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -20, 0, 25)
    Desc.Position = UDim2.fromOffset(10, 30)
    Desc.BackgroundTransparency = 1
    Desc.Text = "This game is not supported"
    Desc.TextColor3 = Color3.fromRGB(170, 55, 65) -- Rote Textfarbe
    Desc.Font = Enum.Font.GothamMedium
    Desc.TextSize = 14
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Frame
    
    -- Animation: Slidet rein
    local TweenIn = TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -280, 1, -90)})
    TweenIn:Play()
    
    -- Wartet 4 Sekunden, slidet raus und löscht sich selbst
    task.delay(4, function()
        local TweenOut = TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 1, -90)})
        TweenOut:Play()
        task.wait(0.5)
        NotifGui:Destroy()
    end)
end

--==================================================
-- Game Checker
--==================================================

local SupportedGames = {
    -- Dein Spiel
    [102555956950143] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/1liftrock.lua"))()
    end,
}

if SupportedGames[PlaceID] then
    -- Spiel ist in der Liste -> Script ausführen
    SupportedGames[PlaceID]()
else
    -- Spiel ist NICHT in der Liste -> Notification unten rechts anzeigen
    ShowNotSupportedNotification()
end
