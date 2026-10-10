local PlaceID = game.PlaceId
local CoreGui = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--==================================================
-- Lucky Block Version Prompt GUI
--==================================================

local function ShowLuckyBlockVersionPrompt()
    local PromptGui = Instance.new("ScreenGui")
    PromptGui.Name = "GustavLuckyBlockPrompt"
    PromptGui.ResetOnSpawn = false
    PromptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    PromptGui.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.fromOffset(360, 180)
    Main.Position = UDim2.new(0.5, -180, 0.5, -90)
    Main.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Main.BorderSizePixel = 0
    Main.Parent = PromptGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Main
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.fromOffset(0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Gustav Client"
    Title.TextColor3 = Color3.fromRGB(245, 245, 250)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.Parent = Main
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -40, 0, 50)
    Desc.Position = UDim2.fromOffset(20, 50)
    Desc.BackgroundTransparency = 1
    Desc.Text = "Do u wanna load the old or the new version?"
    Desc.TextColor3 = Color3.fromRGB(210, 210, 220)
    Desc.Font = Enum.Font.GothamMedium
    Desc.TextSize = 15
    Desc.TextWrapped = true
    Desc.Parent = Main
    
    local NewBtn = Instance.new("TextButton")
    NewBtn.Size = UDim2.new(0.5, -30, 0, 42)
    NewBtn.Position = UDim2.fromOffset(20, 115)
    NewBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    NewBtn.BorderSizePixel = 0
    NewBtn.Text = "New (Recommended)"
    NewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NewBtn.Font = Enum.Font.GothamBold
    NewBtn.TextSize = 13
    NewBtn.AutoButtonColor = false
    NewBtn.Parent = Main
    
    local NewCorner = Instance.new("UICorner")
    NewCorner.CornerRadius = UDim.new(0, 8)
    NewCorner.Parent = NewBtn
    
    local OldBtn = Instance.new("TextButton")
    OldBtn.Size = UDim2.new(0.5, -30, 0, 42)
    OldBtn.Position = UDim2.new(0.5, 10, 0, 115)
    OldBtn.BackgroundColor3 = Color3.fromRGB(55, 100, 180)
    OldBtn.BorderSizePixel = 0
    OldBtn.Text = "Old"
    OldBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OldBtn.Font = Enum.Font.GothamBold
    OldBtn.TextSize = 15
    OldBtn.AutoButtonColor = false
    OldBtn.Parent = Main
    
    local OldCorner = Instance.new("UICorner")
    OldCorner.CornerRadius = UDim.new(0, 8)
    OldCorner.Parent = OldBtn
    
    NewBtn.Activated:Connect(function()
        PromptGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/luckyblock_new.lua"))()
    end)
    
    OldBtn.Activated:Connect(function()
        PromptGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/luckyblockbattlegrounds.lua"))()
    end)
end

--==================================================
-- Dev Version Prompt GUI
--==================================================

local function ShowDevVersionPrompt()
    local PromptGui = Instance.new("ScreenGui")
    PromptGui.Name = "GustavDevPrompt"
    PromptGui.ResetOnSpawn = false
    PromptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    PromptGui.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.fromOffset(360, 180)
    Main.Position = UDim2.new(0.5, -180, 0.5, -90)
    Main.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Main.BorderSizePixel = 0
    Main.Parent = PromptGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Main
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.fromOffset(0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Gustav Client"
    Title.TextColor3 = Color3.fromRGB(245, 245, 250)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.Parent = Main
    
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -40, 0, 50)
    Desc.Position = UDim2.fromOffset(20, 50)
    Desc.BackgroundTransparency = 1
    Desc.Text = "This game is not supported.\nDo you wanna load the dev version?"
    Desc.TextColor3 = Color3.fromRGB(210, 210, 220)
    Desc.Font = Enum.Font.GothamMedium
    Desc.TextSize = 15
    Desc.TextWrapped = true
    Desc.Parent = Main
    
    local YesBtn = Instance.new("TextButton")
    YesBtn.Size = UDim2.new(0.5, -30, 0, 42)
    YesBtn.Position = UDim2.fromOffset(20, 115)
    YesBtn.BackgroundColor3 = Color3.fromRGB(55, 170, 80)
    YesBtn.BorderSizePixel = 0
    YesBtn.Text = "Yes"
    YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    YesBtn.Font = Enum.Font.GothamBold
    YesBtn.TextSize = 15
    YesBtn.AutoButtonColor = false
    YesBtn.Parent = Main
    
    local YesCorner = Instance.new("UICorner")
    YesCorner.CornerRadius = UDim.new(0, 8)
    YesCorner.Parent = YesBtn
    
    local NoBtn = Instance.new("TextButton")
    NoBtn.Size = UDim2.new(0.5, -30, 0, 42)
    NoBtn.Position = UDim2.new(0.5, 10, 0, 115)
    NoBtn.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
    NoBtn.BorderSizePixel = 0
    NoBtn.Text = "No"
    NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoBtn.Font = Enum.Font.GothamBold
    NoBtn.TextSize = 15
    NoBtn.AutoButtonColor = false
    NoBtn.Parent = Main
    
    local NoCorner = Instance.new("UICorner")
    NoCorner.CornerRadius = UDim.new(0, 8)
    NoCorner.Parent = NoBtn
    
    YesBtn.Activated:Connect(function()
        PromptGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/gch.dev.lua"))()
    end)
    
    NoBtn.Activated:Connect(function()
        PromptGui:Destroy()
    end)
end

--==================================================
-- Spiele Liste (Supported Games)
--==================================================

local SupportedGames = {
    -- (Lift Rock)
    [102555956950143] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/1liftrock.lua"))()
    end,
    
    -- Millionaire Empire Tycoon
    [6677985923] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/millionaireempiretycoon.lua"))()
    end,

    -- lucky block battlegrounds
    [662417684] = function()
        ShowLuckyBlockVersionPrompt()
    end,

    -- Rivals
    [17625359962] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/KiciaHookHub_Rivals.lua"))()
    end,

    -- Wings & Brainrot / Cosmic Game
    [84332574190497] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/wings_brainrot.lua"))()
    end,

    -- fall for shit brainrots just tp script its ass ngl
    [86368783421928] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/fall-for-brainrots.lua"))()
    end,

    -- jetpack shit brainrot thingy
    [80234914611737] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/jetpack-brainrot-shit.lua"))()
    end,

    -- 99 Nights Helper
    [79546208627805] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/99.lua"))()
    end,
}

--==================================================
-- Ausführung
--==================================================

-- Universelle Erkennung für Spiele (wie DOORS / 99 Nights)
local isDoors = (game.GameId == 3351636250) or ReplicatedStorage:FindFirstChild("GameData")
local isRivals = (game.GameId == 6035872082) -- Rivals Game ID Fallback
local is99 = (game.PlaceId == 79546208627805) or ReplicatedStorage:FindFirstChild("RemoteEvents")

if isDoors then
    print("Gustav Client: DOORS detected! Loading script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/doors.lua"))()
elseif isRivals or is99 or SupportedGames[PlaceID] then
    print("Gustav Client: Game supported! Loading script...")
    if isRivals and not SupportedGames[PlaceID] then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/KiciaHookHub_Rivals.lua"))()
    elseif is99 and not SupportedGames[PlaceID] then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/refs/heads/main/99.lua"))()
    else
        SupportedGames[PlaceID]()
    end
else
    warn("Gustav Client: This game is not supported! (Place ID: " .. tostring(PlaceID) .. ")")
    ShowDevVersionPrompt()
end
