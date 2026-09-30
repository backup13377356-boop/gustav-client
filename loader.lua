local PlaceID = game.PlaceId
local StarterGui = game:GetService("StarterGui")

-- Hier speichern wir alle unterstützten Spiele ab
local SupportedGames = {
    
    --  (Lift Rock)
    [102555956950143] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/1liftrock.lua"))()
    end,
    
    -- Millionaire Empire Tycoon
    [6677985923] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/backup13377356-boop/gustav-client/main/millionaireempiretycoon.lua"))()
    end,

}

-- Prüfen, ob die aktuelle PlaceID in unserer Liste existiert
if SupportedGames[PlaceID] then
    
    -- Wenn ja: Führe das entsprechende Script aus
    print("Gustav Client: Game supported! Loading script...")
    SupportedGames[PlaceID]()
    
else
    
    -- Wenn nein: Zeige Fehler an
    local errorMessage = "This game is not supported! (Place ID: " .. tostring(PlaceID) .. ")"
    
    -- Warnung in der F9 Konsole ausgeben
    warn("Gustav Client: " .. errorMessage)
    
    -- In-Game Notification senden (mit pcall, falls StarterGui noch nicht ganz geladen ist)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Gustav Client",
            Text = "This game is not supported!",
            Icon = "rbxassetid://1", -- Optionales leeres Icon
            Duration = 10 -- Bleibt 10 Sekunden auf dem Bildschirm
        })
    end)
    
end
