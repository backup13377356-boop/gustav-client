local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------------ CONFIG & SAVING
local CONFIG_FILE = "gustav_client_99nights_config.json"
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

------------------------------------------------------------------ ITEM DB
local ITEM_DB = {
    Food      = { "Carrot","Berry","Corn","Stew","Steak","Cooked Steak","Morsel","Cooked Morsel","Cooked Ribs","Cake" },
    Fuel      = { "Log","Coal","Oil Barrel","Fuel Canister","Chair","Sapling" },
    Scraps    = { "Broken Microwave","Broken Fan","Tyre","Old Car Engine" },
    Anvil     = { "Anvil Base","Anvil Front","Anvil Back" },
    Chests    = { "Item Chest","Item Chest2","Item Chest3","Item Chest4","Item Chest5","StoneChest1","StoneChest2","Volcanic Chest1","Volcanic Chest2","Stronghold Diamond Chest" },
    KidItems  = { "Kraken Kid's Kraken Toy","Squid Kid's Pocket Watch","Kraken Kid's Seashell","Dino Kid's Crayon","Koala Kid's Koala Toy","Kraken Kid's Koala Toy","Squid Kid's Lunchbox","Koala Kid's Dreamcatcher","Koala Kid's Lunchbox" },
    Trophies  = { "Wolf Pelt","Alpha Wolf Pelt","Bunny Foot","Scorpion Shell","Mammoth Tusk","Cultist King Antler" },
    Ammo      = { "Rifle Ammo","Revolver Ammo" },
    Gear      = { "Rifle","Riot Shield","Impact Grenade","Old Flashlight","Strong Flashlight","Old Taming Flute","Old Rod","Leather Body","Iron Body" },
    Bags      = { "Giant Sack","Good Sack","Infernal Sack" },
    Blueprints= { "Log Wall Blueprint","Lava Mine Blueprint" },
    Currency  = { "Coin Stack","Gem of the Forest Fragment" },
    Meds      = { "Bandage", "Med Kit", "Medkit", "First Aid", "Medical" },
    Misc      = { "Basketball","Seed Box" },
}
local CATEGORY_LABELS = {
    Food = "🍖 Food", Fuel = "🔥 Fuel (burnables)", Scraps = "🔩 Scraps (bench)",
    Anvil = "⚒ Anvil Parts", Chests = "🎁 Chests (all)", KidItems = "🧸 Kid Items (quest)",
    Trophies = "🏆 Trophies / Pelts", Ammo = "🔫 Ammo", Gear = "⚔ Weapons & Gear",
    Bags = "🎒 Sacks", Blueprints = "📜 Blueprints", Currency = "💰 Coins & Gems",
    Meds = "🩹 Meds", Misc = "📦 Misc",
}
local CATEGORY_ORDER = { "Food","Fuel","Scraps","Anvil","Chests","KidItems","Trophies","Ammo","Gear","Bags","Blueprints","Currency","Meds","Misc" }

-------------------------------------------------------------------- CONFIG
local CONFIG = {
    FuelInterval   = 3.0,
    EatInterval    = 3.0,
    EatHealthMin   = 60,

    DefaultRange   = 60,
    TreeRange      = 100,
    TeleportHeight = 1.2,
    DefaultSpeed   = 16,
    MaxSpeed       = 300,
    DefaultJump    = 50,
    MaxJump        = 300,

    WorldScanInterval = 6.0,
    FuelSkipDistance  = 8,
    MaxTreeESP        = 30,
    MaxTreesCached    = 80,
    ShowRangeCircle   = true,
    Debug             = true,

    HitsPerTree  = 6,
    ChopInterval = 0.35,
    EquipDelay   = 0.25,

    AttackPlayers = false,
    Blacklist     = { "child" },

    ExcludeFuelKeywords = { "log", "chair" },
    TreeKeywords        = { "tree", "oak", "pine", "birch", "palm" },
    ScrapKeywords       = { "broken","tyre","tire","engine","anvil","scrap","metal" },
    LogKeywords         = { "log","wood","plank" },
    ChestKeywords       = { "chest" },
    KidKeywords         = { "child" },
    KidToyKeyword       = "kid's",

    GameTools = {
        ["Old Axe"]    = "1_8982038982",
        ["Good Axe"]   = "112_8982038982",
        ["Strong Axe"] = "116_8982038982",
        ["Chainsaw"]   = "647_8992824875",
        ["Spear"]      = "196_8999010016",
        ["Knife"]      = "324_8999010016",
    },
    ToolPriority = { "Chainsaw", "Strong Axe", "Good Axe", "Spear", "Old Axe", "Knife" },
}

--------------------------------------------------------------------- STATE
local State = {
    AutoFuel = false, AutoAttack = false, GodMode = false,
    ReserveLogs = true, AutoEat = false,
    ChopTrees = false, TreeMode = "aura", BigTrees = "chainsaw",
    InfiniteJump = false, Noclip = false, AntiAFK = true,
    DiamondESP = false, ChestESP = false, TreeESP = false,
    Destination = "player",
    Weapon = "Auto",
    AttackSpeed = 2, AuraTargets = 5, ShowCircle = true,
    Range = CONFIG.DefaultRange, TreeRange = CONFIG.TreeRange,
    WalkSpeed = CONFIG.DefaultSpeed, JumpPower = CONFIG.DefaultJump,
    TeleportHeight = CONFIG.TeleportHeight, HitsPerTree = CONFIG.HitsPerTree,
    Target = nil, Chopping = false, lastEquip = 0,
    MobCount = 0, FuelCount = 0, DiamondCount = 0, MedCount = 0,
    TreesChopped = 0,
    Message = "",
}
local unloaded = false

------------------------------------------------------------------- HELPERS
local function dprint(...)
    if CONFIG.Debug then print("[Helper]", ...) end
end

local function setStatus(msg)
    State.Message = msg
    dprint(msg)
    task.delay(4, function()
        if State.Message == msg then State.Message = "" end
    end)
end

local function create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    inst.Parent = parent
    return inst
end

local function matchesList(text, list)
    local lower = string.lower(text)
    for _, kw in ipairs(list) do
        if string.find(lower, string.lower(kw), 1, true) then return true end
    end
    return false
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function getHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function getPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    local p = obj:FindFirstChild("Trunk") or obj:FindFirstChild("HumanoidRootPart")
    if p then return p.Position end
    if obj.PrimaryPart then return obj.PrimaryPart.Position end
    local any = obj:FindFirstChildWhichIsA("BasePart")
    if any then return any.Position end
    return obj:GetPivot().Position
end

---------------------------------------------------------------- REFERENCES
local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local CharactersFolder = Workspace:WaitForChild("Characters", 15)
local ItemsFolder      = Workspace:WaitForChild("Items", 15)

local DamageRemote     = RemoteEvents and RemoteEvents:FindFirstChild("ToolDamageObject")
local DragOn           = RemoteEvents and RemoteEvents:FindFirstChild("RequestStartDraggingItem")
local DragOff          = RemoteEvents and RemoteEvents:FindFirstChild("StopDraggingItem")
local EquipRemote      = RemoteEvents and RemoteEvents:FindFirstChild("EquipItemHandle")
local EatRemote        = RemoteEvents and RemoteEvents:FindFirstChild("EatItemHandle")

local EnemyHandler
do
    local ok, mod = pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        local client = ps:WaitForChild("Client", 5)
        if not client then return nil end
        local m = client:WaitForChild("EnemyHandler", 5)
        if not m then return nil end
        return require(m)
    end)
    if ok then EnemyHandler = mod end
end

--------------------------------------------------------------- WEAPON API
local function findOwnedTool(name)
    local inv = LocalPlayer:FindFirstChild("Inventory")
    local t = inv and inv:FindFirstChild(name)
    if t then return t end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and bp:FindFirstChild(name) or nil
end

local function getAllWeaponNames()
    local out, seen = {}, {}
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, t in ipairs(inv:GetChildren()) do
            if not seen[t.Name] then seen[t.Name] = true table.insert(out, t.Name) end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if not seen[t.Name] then seen[t.Name] = true table.insert(out, t.Name) end
        end
    end
    table.sort(out)
    return out
end

local function readToolDamage(tool)
    if not tool then return nil end
    local ok, attrs = pcall(tool.GetAttributes, tool)
    if ok and attrs then
        for k, v in pairs(attrs) do
            if type(v) == "number" then
                local lk = string.lower(k)
                if string.find(lk, "damag", 1, true) or string.find(lk, "dmg", 1, true) then
                    return v
                end
            end
        end
    end
    for _, c in ipairs(tool:GetChildren()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then
            local ln = string.lower(c.Name)
            if string.find(ln, "damag", 1, true) or string.find(ln, "dmg", 1, true) then
                return c.Value
            end
        end
    end
    return nil
end

local function getSelectedWeaponName()
    if State.Weapon ~= "Auto" then
        if findOwnedTool(State.Weapon) then return State.Weapon end
        if not State._weaponWarned then
            setStatus("⚠️ " .. State.Weapon .. " not owned — using best available")
            State._weaponWarned = true
        end
    end
    for _, name in ipairs(CONFIG.ToolPriority) do
        if findOwnedTool(name) then return name end
    end
    return nil
end

local function getGameTool()
    local name = getSelectedWeaponName()
    return name and findOwnedTool(name) or nil
end

local function getHeldToolRef(keyword)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, model in ipairs(char:GetChildren()) do
        if model:IsA("Model") then
            local tn = model:GetAttribute("ToolName")
            if tn and (not keyword or string.find(tn, keyword, 1, true)) then
                local orig = model:FindFirstChild("OriginalItem")
                if orig and orig.Value then return orig.Value end
            end
        end
    end
    return nil
end

local function ensureHeld(toolName)
    local held = getHeldToolRef(toolName)
    if held then return held end
    local item = findOwnedTool(toolName)
    if not item then return nil end
    if EquipRemote then
        pcall(function() EquipRemote:FireServer("FireAllClients", item) end)
    end
    local deadline = tick() + CONFIG.EquipDelay + 0.15
    while tick() < deadline do
        held = getHeldToolRef(toolName)
        if held then return held end
        task.wait(0.05)
    end
    return item
end

local function hasChainsaw()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, t in ipairs(inv:GetChildren()) do
            local tn = t:GetAttribute("ToolName")
            if tn and string.find(tn, "Chainsaw", 1, true) then return true end
        end
    end
    return findOwnedTool("Chainsaw") ~= nil
end

local function getHitRegId(fallbackName)
    if EnemyHandler and EnemyHandler.GetHitRegId then
        local ok, id = pcall(EnemyHandler.GetHitRegId)
        if ok and id then return id end
    end
    return CONFIG.GameTools[fallbackName or ""]
end

local function fallbackSwing()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        return true
    end
    return false
end

----------------------------------------------------------------- LANDMARKS
local MainFire, Bench, Stronghold

local function findFire()
    local map = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local known = camp and camp:FindFirstChild("MainFire")
    if known then return known end
    return Workspace:FindFirstChild("MainFire", true)
        or Workspace:FindFirstChild("Campfire", true)
end

local function findBench()
    local map = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local pools = { camp and camp:GetDescendants() or {}, Workspace:GetDescendants() }
    for _, pool in ipairs(pools) do
        for _, obj in ipairs(pool) do
            if obj:IsA("Model") and string.find(string.lower(obj.Name), "bench", 1, true) then
                return obj
            end
        end
    end
    return nil
end

local function findStronghold()
    local map = Workspace:FindFirstChild("Map")
    local direct = map and map:FindFirstChild("Stronghold", true)
        or map and map:FindFirstChild("Bunker", true)
        or Workspace:FindFirstChild("Stronghold", true)
        or Workspace:FindFirstChild("Bunker", true)
    if direct then return direct end
    if map then
        for _, obj in ipairs(map:GetChildren()) do
            if obj:IsA("Model") and matchesList(obj.Name, { "stronghold","bunker","cultist","fort" }) then
                return obj
            end
        end
    end
    return nil
end

local function getFire()
    if not (MainFire and MainFire.Parent) then MainFire = findFire() end
    return MainFire
end

local function getBench()
    if not (Bench and Bench.Parent) then Bench = findBench() end
    return Bench
end

local function getStronghold()
    if not (Stronghold and Stronghold.Parent) then Stronghold = findStronghold() end
    return Stronghold
end

local function getNearestKid()
    local root = getRoot()
    if not root then return nil end
    local folder = CharactersFolder or Workspace
    local best, bestDist = nil, math.huge
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and matchesList(model.Name, CONFIG.KidKeywords) then
            local dist = (getPosition(model) - root.Position).Magnitude
            if dist < bestDist then best, bestDist = model, dist end
        end
    end
    return best
end

-------------------------------------------------------------- WORLD CACHE
local WorldCache = { last = 0, currency = {}, chests = {}, trees = {} }

local function queryTrees()
    local ok, list = pcall(function() return Workspace:QueryDescendants("[$Resource]") end)
    if ok and type(list) == "table" and #list > 0 then
        local trees = {}
        for _, t in ipairs(list) do
            if t:IsA("Model") or t:FindFirstChild("Trunk") then table.insert(trees, t) end
        end
        if #trees > 0 then return trees end
    end
    local trees = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and matchesList(obj.Name, CONFIG.TreeKeywords)
        and obj:FindFirstChildWhichIsA("BasePart") then
            table.insert(trees, obj)
        end
    end
    return trees
end

local function refreshWorldCache(force)
    if not force and (tick() - WorldCache.last) < CONFIG.WorldScanInterval then return end
    WorldCache.last = tick()

    local currency, chests, trees = {}, {}, {}

    if State.DiamondESP and ItemsFolder then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if matchesList(item.Name, ITEM_DB.Currency) then table.insert(currency, item) end
        end
    end

    if State.ChestESP then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj)
            and matchesList(obj.Name, CONFIG.ChestKeywords) then
                table.insert(chests, obj)
            end
        end
    end

    if State.TreeESP or State.ChopTrees then
        trees = queryTrees()
        if #trees > CONFIG.MaxTreesCached then
            local root = getRoot()
            if root then
                local sorted = {}
                for _, t in ipairs(trees) do
                    local ok, pos = pcall(getPosition, t)
                    sorted[#sorted + 1] = { obj = t, d = ok and (pos - root.Position).Magnitude or math.huge }
                end
                table.sort(sorted, function(a, b) return a.d < b.d end)
                local capped = {}
                for i = 1, CONFIG.MaxTreesCached do capped[i] = sorted[i].obj end
                trees = capped
            end
        end
    end

    WorldCache.currency, WorldCache.chests, WorldCache.trees = currency, chests, trees
end

----------------------------------------------------------------------- ESP
local espPools = {
    Currency = { map = {}, color = Color3.fromRGB(80, 220, 255) },
    Chest    = { map = {}, color = Color3.fromRGB(255, 200, 60) },
    Tree     = { map = {}, color = Color3.fromRGB(90, 255, 120) },
}

local function updateESP(poolName, enabled, sourceList)
    local pool = espPools[poolName]
    for inst, hl in pairs(pool.map) do
        if not enabled or not inst.Parent then
            pcall(function() hl:Destroy() end)
            pool.map[inst] = nil
        end
    end
    if not enabled then return end
    for _, inst in ipairs(sourceList) do
        if inst.Parent and not pool.map[inst] then
            local ok, hl = pcall(function()
                return create("Highlight", {
                    FillColor = pool.color, OutlineColor = pool.color,
                    FillTransparency = 0.65, OutlineTransparency = 0,
                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                }, inst)
            end)
            if ok and hl then pool.map[inst] = hl end
        end
    end
end

----------------------------------------------------------- ITEM BRINGING
local function bringItems(items, position, label)
    if not (DragOn and DragOff) then return setStatus("❌ Drag remotes not found") end
    local moved = 0
    for _, item in ipairs(items) do
        pcall(function()
            DragOn:FireServer(item)
            item:MoveTo(position)
            DragOff:FireServer(item)
            moved = moved + 1
        end)
    end
    setStatus(("📦 Moved %d %s"):format(moved, label))
end

local function getItemsMatching(list)
    local out = {}
    if ItemsFolder then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if matchesList(item.Name, list) then table.insert(out, item) end
        end
    end
    return out
end

local FuelCache = { list = {}, last = 0 }
local function getFuelItems()
    if tick() - FuelCache.last < CONFIG.WorldScanInterval then
        local live = {}
        for _, f in ipairs(FuelCache.list) do
            if f.Parent then table.insert(live, f) end
        end
        FuelCache.list = live
        return live
    end
    FuelCache.last = tick()
    local ok, list = pcall(function() return ItemsFolder:QueryDescendants("[$BurnFuel]") end)
    if ok and type(list) == "table" then FuelCache.list = list return list end
    local fuels = {}
    for _, item in ipairs(ItemsFolder:GetDescendants()) do
        if item:GetAttribute("BurnFuel") then table.insert(fuels, item) end
    end
    FuelCache.list = fuels
    return fuels
end

local function inFrontOfMe(height, distance)
    local root = getRoot()
    if not root then return nil end
    return (root.CFrame * CFrame.new(0, height, -distance)).Position
end

local function getDestinationPosition()
    if State.Destination == "fire" then
        local fire = getFire()
        if fire then return getPosition(fire) + Vector3.new(0, 2, 0), "fire" end
        setStatus("⚠️ Fire not found — dropping at you instead")
    elseif State.Destination == "bench" then
        local bench = getBench()
        if bench then return getPosition(bench) + Vector3.new(0, 3, 0), "bench" end
        setStatus("⚠️ Bench not found — dropping at you instead")
    end
    return inFrontOfMe(-2.8, 3), "you"
end

local function bringFuel(forceFire)
    local firePos = nil
    if forceFire or State.Destination == "fire" then
        local fire = getFire()
        if not fire then return setStatus("❌ No campfire found") end
        firePos = getPosition(fire)
    end

    local all = getFuelItems()
    local fuels, skipped, already = {}, 0, 0
    for _, item in ipairs(all) do
        if State.ReserveLogs and matchesList(item.Name, CONFIG.ExcludeFuelKeywords) then
            skipped = skipped + 1
        elseif firePos then
            local ok, pos = pcall(getPosition, item)
            if ok and pos and (pos - firePos).Magnitude <= CONFIG.FuelSkipDistance then
                already = already + 1
            else
                table.insert(fuels, item)
            end
        else
            table.insert(fuels, item)
        end
    end

    State.FuelCount = #fuels
    if #fuels == 0 then
        if firePos then
            return setStatus(("✅ Fire stocked (%d near, %d kept)"):format(already, skipped))
        end
        return setStatus("⚠️ No fuel items found")
    end

    if firePos then
        bringItems(fuels, firePos, ("fuel → fire (kept %d logs/chairs)"):format(skipped))
    else
        local pos, destName = getDestinationPosition()
        if not pos then return setStatus("❌ No character") end
        bringItems(fuels, pos, ("fuel → %s"):format(destName))
    end
end

local function bringFood()
    local foods = getItemsMatching(ITEM_DB.Food)
    if #foods == 0 then return setStatus("⚠️ No food found") end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(foods, pos, ("food → %s"):format(destName))
end

local function bringScrapLogs()
    local combined = {}
    for _, kw in ipairs(CONFIG.ScrapKeywords) do table.insert(combined, kw) end
    for _, kw in ipairs(CONFIG.LogKeywords) do table.insert(combined, kw) end
    local scraps = getItemsMatching(combined)
    if #scraps == 0 then return setStatus("⚠️ No scrap/logs found") end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(scraps, pos, ("scrap/logs → %s"):format(destName))
end

local function bringMeds()
    local meds = getItemsMatching(ITEM_DB.Meds)
    State.MedCount = #meds
    if #meds == 0 then return setStatus("⚠️ No bandages found") end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(meds, pos, ("meds → %s"):format(destName))
end

local function bringCurrency()
    local gems = getItemsMatching(ITEM_DB.Currency)
    State.DiamondCount = #gems
    if #gems == 0 then return setStatus("⚠️ No coins/gems on the map") end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(gems, pos, ("coins/gems → %s 💰"):format(destName))
end

local function bringByCategory(catName)
    local keywords = ITEM_DB[catName]
    if not keywords then return setStatus("❌ Unknown category") end
    local items = {}
    if ItemsFolder then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if matchesList(item.Name, keywords) then
                if not (catName == "Fuel" and State.ReserveLogs
                and matchesList(item.Name, CONFIG.ExcludeFuelKeywords)) then
                    table.insert(items, item)
                end
            end
        end
    end
    if #items == 0 then
        return setStatus(("⚠️ No %s items on the map"):format(CATEGORY_LABELS[catName] or catName))
    end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(items, pos, ("%s ×%d → %s"):format(CATEGORY_LABELS[catName] or catName, #items, destName))
end

local function bringByExactName(itemName)
    local items = {}
    if ItemsFolder then
        local lower = string.lower(itemName)
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if string.find(string.lower(item.Name), lower, 1, true) then
                table.insert(items, item)
            end
        end
    end
    if #items == 0 then
        return setStatus(("⚠️ No '%s' on the map"):format(itemName))
    end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(items, pos, ("%s ×%d → %s"):format(itemName, #items, destName))
end

local function bringKidItems()
    local toys = getItemsMatching({ CONFIG.KidToyKeyword })
    if #toys == 0 then return setStatus("⚠️ No kid items on the map") end
    local pos, destName = getDestinationPosition()
    if not pos then return setStatus("❌ No character") end
    bringItems(toys, pos, ("kid items ×%d → %s 🧸"):format(#toys, destName))
end

local function bringEverything()
    bringFuel(false)
    task.wait(0.3)
    bringFood()
    task.wait(0.3)
    bringMeds()
    task.wait(0.3)
    bringCurrency()
    task.wait(0.3)
    bringScrapLogs()
end

local function listAllMapItems()
    if not ItemsFolder then return setStatus("❌ Items folder not found") end
    local seen, count = {}, 0
    print("========== [Helper] MAP ITEM NAMES ==========")
    for _, item in ipairs(ItemsFolder:GetChildren()) do
        if not seen[item.Name] then
            seen[item.Name] = true
            count = count + 1
            print("  " .. item.Name)
        end
    end
    print(("========== %d unique names =========="):format(count))
    setStatus(("🔍 Printed %d unique item names — F9 to view"):format(count))
end

-------------------------------------------------------------- TREE SYSTEM
local ChoppedTrees = {}

local function isBigTree(tree)
    return string.find(tostring(tree.Name), "Big", 1, true) ~= nil
end

local function treeBlocked(tree)
    if not isBigTree(tree) then return false end
    if State.BigTrees == "skip" then return true end
    return not hasChainsaw()
end

local function nearestTree(range)
    local root = getRoot()
    if not root then return nil end
    refreshWorldCache()

    local best, bestDist = nil, math.huge
    for _, tree in ipairs(WorldCache.trees) do
        if tree.Parent and (State.TreeMode == "aura" or not ChoppedTrees[tree]) then
            if not treeBlocked(tree) then
                local trunk = tree:FindFirstChild("Trunk")
                local pos = trunk and trunk.Position or getPosition(tree)
                local dist = (pos - root.Position).Magnitude
                if dist <= range and dist < bestDist then
                    best, bestDist = tree, dist
                end
            end
        end
    end
    return best
end

local function equipForTree(tree)
    local wantName
    if isBigTree(tree) and State.BigTrees == "chainsaw" then
        wantName = "Chainsaw"
    elseif State.Weapon ~= "Auto" and findOwnedTool(State.Weapon) then
        wantName = State.Weapon
    else
        for _, name in ipairs({ "Strong Axe", "Good Axe", "Old Axe" }) do
            if findOwnedTool(name) then wantName = name break end
        end
    end
    if not wantName then return nil end
    return ensureHeld(wantName)
end

local function chopTree(tree, toolRef, toolName)
    if not (DamageRemote and tree.Parent and toolRef) then return false end
    local hitId = getHitRegId(toolName)
    if not hitId then return false end
    local ok = pcall(function()
        return DamageRemote:InvokeServer(tree, toolRef, hitId, getRoot().CFrame, true)
    end)
    return ok
end

local function chopAuraTick()
    local tree = nearestTree(State.TreeRange)
    if not tree then return end

    State.Target = tree
    local toolRef = equipForTree(tree)
    if not toolRef then
        if isBigTree(tree) and (not State._bigWarn or tick() - State._bigWarn > 8) then
            setStatus("🪓 Big tree nearby but no Chainsaw — buy one or set Big Trees: Skip")
            State._bigWarn = tick()
        end
        return
    end

    local ok = chopTree(tree, toolRef, toolRef.Name)
    if ok and not tree.Parent then
        State.TreesChopped = State.TreesChopped + 1
    end
end

local function chopOnceStep()
    local char = LocalPlayer.Character
    local root = getRoot()
    if not char or not root then return end

    local best = nearestTree(math.huge)
    if not best then
        local total = 0
        for _ in pairs(ChoppedTrees) do total = total + 1 end
        setStatus(("✅ All trees chopped (%d done)"):format(total))
        State.ChopTrees = false
        State.Chopping = false
        return
    end

    State.Chopping = true
    State.Target = best

    local trunk = best:FindFirstChild("Trunk")
    local treePos = trunk and trunk.Position or getPosition(best)

    local dir = Vector3.new(root.Position.X - treePos.X, 0, root.Position.Z - treePos.Z)
    if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
    dir = dir.Unit
    local standPos = treePos + dir * 3
    char:PivotTo(CFrame.lookAt(
        Vector3.new(standPos.X, treePos.Y + 1, standPos.Z),
        Vector3.new(treePos.X, treePos.Y + 1, treePos.Z)))
    task.wait(0.15)

    local toolRef = equipForTree(best)
    if not toolRef then
        setStatus("🪓 No usable tool for this tree (big? → Chainsaw)")
        ChoppedTrees[best] = true
        State.Chopping = false
        return
    end

    for _ = 1, State.HitsPerTree do
        if not best.Parent then break end
        if not chopTree(best, toolRef, toolRef.Name) then
            fallbackSwing()
        end
        task.wait(CONFIG.ChopInterval)
    end

    ChoppedTrees[best] = true
    State.TreesChopped = State.TreesChopped + 1
    setStatus(("🪓 Chopped: %s (%d total)"):format(best.Name, State.TreesChopped))
    State.Chopping = false

    local r = getRoot()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end
end

------------------------------------------------------------------ KILL AURA
local function killAuraTick()
    local char = LocalPlayer.Character
    local root = getRoot()
    if not char or not root then
        State.MobCount = 0
        State.Target = nil
        return
    end

    local mobs = CharactersFolder and CharactersFolder:GetChildren() or {}
    local inRange = {}
    for _, mob in ipairs(mobs) do
        if mob:IsA("Model") and mob ~= char then
            local player = Players:GetPlayerFromCharacter(mob)
            if (not player or CONFIG.AttackPlayers)
            and not matchesList(mob.Name, CONFIG.Blacklist) then
                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - root.Position).Magnitude
                    if dist <= State.Range then
                        table.insert(inRange, { model = mob, dist = dist })
                    end
                end
            end
        end
    end
    table.sort(inRange, function(a, b) return a.dist < b.dist end)
    State.MobCount = #inRange

    if #inRange == 0 then State.Target = nil return end
    State.Target = inRange[1].model

    local wname = getSelectedWeaponName()
    if not wname then
        fallbackSwing()
        return
    end

    if tick() - State.lastEquip > 3 then
        local item = findOwnedTool(wname)
        if item then
            if EquipRemote then
                pcall(function() EquipRemote:FireServer("FireAllClients", item) end)
            end
            State.lastEquip = tick()
        end
    end

    local toolRef = ensureHeld(wname)
    if not toolRef then
        fallbackSwing()
        return
    end
    local hitId = getHitRegId(wname)
    if not hitId then
        fallbackSwing()
        return
    end

    local hit = 0
    for _, m in ipairs(inRange) do
        if hit >= State.AuraTargets then break end
        local part = m.model.PrimaryPart or m.model:FindFirstChildWhichIsA("BasePart")
        if part then
            pcall(function()
                DamageRemote:InvokeServer(m.model, toolRef, hitId, CFrame.new(part.Position))
            end)
        end
        hit = hit + 1
    end
end

------------------------------------------------------------------ TELEPORT
local function teleportTo(target, name)
    local char = LocalPlayer.Character
    if not char or not char.Parent then return setStatus("❌ Teleport: no character") end
    if not target then return setStatus("❌ Teleport: " .. name .. " not found") end

    local hum = getHum()
    if hum then hum.Sit = false end

    local targetCF = target:GetPivot() + Vector3.new(0, State.TeleportHeight, 0)
    for _ = 1, 5 do
        char:PivotTo(targetCF)
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if (root.Position - targetCF.Position).Magnitude < 8 then
                return setStatus(("✅ Teleported to %s (+%.1f above)"):format(name, State.TeleportHeight))
            end
        end
        task.wait(0.1)
    end
    setStatus("⚠️ Position keeps resetting — game may block teleports")
end

-------------------------------------------------------------- RANGE CIRCLE
local rangeCircle = create("Part", {
    Name = "AttackRangeVisual", Shape = Enum.PartType.Cylinder,
    Material = Enum.Material.ForceField, Transparency = 0.6,
    Anchored = true, CanCollide = false, CanQuery = false,
    CanTouch = false, CastShadow = false, CFrame = CFrame.new(0, -500, 0),
}, Workspace)

local circleRangeSet = -1
local circleClock = 0
RunService.Heartbeat:Connect(function(dt)
    if not rangeCircle then return end
    circleClock = circleClock + dt
    if circleClock < 0.1 then return end
    circleClock = 0

    local root = getRoot()
    if root and State.AutoAttack and State.ShowCircle then
        if circleRangeSet ~= State.Range then
            rangeCircle.Size = Vector3.new(0.4, State.Range * 2, State.Range * 2)
            circleRangeSet = State.Range
        end
        rangeCircle.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.9, 0))
            * CFrame.Angles(0, 0, math.rad(90))
        rangeCircle.Color = State.Target and Color3.fromRGB(80, 255, 120)
            or Color3.fromRGB(255, 70, 70)
    elseif rangeCircle.Position.Y > -400 then
        rangeCircle.CFrame = CFrame.new(0, -500, 0)
    end
end)

---------------------------------------------------- NOCLIP / JUMP / ANTI-AFK
local noclipClock = 0
RunService.Stepped:Connect(function(_, dt)
    if not State.Noclip then return end
    noclipClock = noclipClock + dt
    if noclipClock < 0.1 then return end
    noclipClock = 0
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

------------------------------------------------------------------------ GUI (GUSTAV CLIENT THEME)
local COLORS = {
    Background = Color3.fromRGB(18, 18, 24),
    Section    = Color3.fromRGB(30, 30, 40),
    Panel2     = Color3.fromRGB(35, 35, 45),
    Off        = Color3.fromRGB(42, 43, 55),
    Deep       = Color3.fromRGB(21, 21, 28),
    Accent     = Color3.fromRGB(55, 100, 180),
    Accent2    = Color3.fromRGB(168, 85, 247),
    Good       = Color3.fromRGB(55, 170, 80),
    Text       = Color3.fromRGB(245, 245, 250),
    SubText    = Color3.fromRGB(150, 150, 160),
    Stroke     = Color3.fromRGB(120, 68, 185),
}

local Gui = create("ScreenGui", { Name = "GustavClient99Nights", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)

local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(520, 420),
    Position = UDim2.new(0.5, -260, 0.5, -210),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Active = true,
}, Gui)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, Main)
create("UIStroke", { Color = COLORS.Stroke, Thickness = 1.2 }, Main)

-- Top Bar
local TopBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Color3.fromRGB(24, 24, 32),
    BorderSizePixel = 0,
}, Main)
create("UICorner", { CornerRadius = UDim.new(0, 12) }, TopBar)

create("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.fromOffset(15, 0),
    BackgroundTransparency = 1,
    Text = "Gustav Client | 99 Nights",
    TextColor3 = COLORS.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local MinimizeButton = create("TextButton", {
    Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(1, -45, 0, 7),
    BackgroundTransparency = 1,
    Text = "-",
    TextColor3 = COLORS.SubText,
    TextSize = 30,
    Font = Enum.Font.GothamMedium,
}, TopBar)

MinimizeButton.Activated:Connect(function()
    Main.Visible = false
end)

-- Sidebar
local Sidebar = create("Frame", {
    Size = UDim2.new(0, 135, 1, -55),
    Position = UDim2.fromOffset(0, 55),
    BackgroundColor3 = COLORS.Deep,
    BorderSizePixel = 0,
}, Main)

local SidebarLayout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local SidebarPadding = create("UIPadding", {
    PaddingTop = UDim.new(0, 15),
}, Sidebar)

-- Content Frame
local Content = create("Frame", {
    Size = UDim2.new(1, -135, 1, -55),
    Position = UDim2.fromOffset(135, 55),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
}, Main)

------------------------------------------------------------------ FACTORIES
local TAB_NAMES = { "Farm", "Items", "Fight", "Tree", "Move", "TP", "ESP", "Misc", "Settings" }
local tabBtns, pages, lastTab = {}, {}, "Farm"

local pageOrder = {}
local function nextOrder(page)
    pageOrder[page] = (pageOrder[page] or 0) + 1
    return pageOrder[page]
end

for i, name in ipairs(TAB_NAMES) do
    local page = create("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = COLORS.Stroke,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = (i == 1),
    }, Content)
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    pages[name] = page
end

local function CreateTabButton(text, order)
    local Button = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 36),
        BackgroundColor3 = COLORS.Section,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.SubText,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        LayoutOrder = order,
    }, Sidebar)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, Button)
    return Button
end

for i, name in ipairs(TAB_NAMES) do
    tabBtns[name] = CreateTabButton(name, i)
    tabBtns[name].Activated:Connect(function()
        lastTab = name
        for n, page in pairs(pages) do page.Visible = (n == name) end
        for n, btn in pairs(tabBtns) do
            if n == name then
                btn.BackgroundColor3 = COLORS.Accent
                btn.TextColor3 = COLORS.Text
            else
                btn.BackgroundColor3 = COLORS.Section
                btn.TextColor3 = COLORS.SubText
            end
        end
    end)
end

-- Initialize first tab color
tabBtns["Farm"].BackgroundColor3 = COLORS.Accent
tabBtns["Farm"].TextColor3 = COLORS.Text

local function makeHeader(page, text)
    local Label = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.Stroke,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(page),
    }, page)
    return Label
end

local function makeToggle(page, labelText, callback)
    local Button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(170, 55, 65),
        BorderSizePixel = 0,
        Text = labelText .. ": OFF",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = nextOrder(page),
    }, page)
    create("UICorner", { CornerRadius = UDim.new(0, 9) }, Button)

    local state = false
    local api = {}
    function api.Set(newState)
        state = newState
        if state then
            Button.Text = labelText .. ": ON"
            Button.BackgroundColor3 = COLORS.Good
        else
            Button.Text = labelText .. ": OFF"
            Button.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
        end
        callback(state)
    end
    function api.Toggle() api.Set(not state) end
    Button.Activated:Connect(api.Toggle)
    return api
end

local function makeButton(page, labelText, callback)
    local Button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.Section,
        BorderSizePixel = 0,
        Text = labelText,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = nextOrder(page),
    }, page)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, Button)
    Button.Activated:Connect(function()
        task.spawn(callback)
    end)
    return Button
end

local function makeSlider(page, labelText, minVal, maxVal, defaultVal, callback)
    local SliderFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = COLORS.Section,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(page),
    }, page)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, SliderFrame)

    local SliderLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 4),
        BackgroundTransparency = 1,
        Text = labelText .. ": " .. defaultVal,
        TextColor3 = COLORS.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, SliderFrame)

    local SliderTrack = create("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.fromOffset(10, 28),
        BackgroundColor3 = COLORS.Deep,
        BorderSizePixel = 0,
    }, SliderFrame)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, SliderTrack)

    local SliderFill = create("Frame", {
        Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, SliderTrack)
    create("UICorner", { CornerRadius = UDim.new(0, 4) }, SliderFill)

    local draggingSlider = false
    local function updateSlider(input)
        local trackPos = SliderTrack.AbsolutePosition.X
        local trackWidth = SliderTrack.AbsoluteSize.X
        local mouseX = input.Position.X
        local percent = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        local val = math.floor(minVal + percent * (maxVal - minVal))
        SliderLabel.Text = labelText .. ": " .. val
        callback(val)
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
end

local function makeDropdown(page, labelText, options, onChanged)
    local selected = options[1] or ""
    local DropdownBtn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.Section,
        BorderSizePixel = 0,
        Text = labelText .. ": " .. selected .. " ▼",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = nextOrder(page),
    }, page)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, DropdownBtn)

    local DropdownList = create("Frame", {
        Size = UDim2.new(1, 0, 0, math.min(#options * 36, 150)),
        BackgroundColor3 = COLORS.Panel2,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
        LayoutOrder = nextOrder(page),
    }, page)
    create("UICorner", { CornerRadius = UDim.new(0, 8) }, DropdownList)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, DropdownList)

    local function setOptions(opts)
        options = opts
        for _, c in ipairs(DropdownList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(options) do
            local optBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = COLORS.Panel2,
                BorderSizePixel = 0,
                Text = opt,
                TextColor3 = COLORS.SubText,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                ZIndex = 11,
                LayoutOrder = i,
            }, DropdownList)
            optBtn.Activated:Connect(function()
                selected = opt
                DropdownBtn.Text = labelText .. ": " .. opt .. " ▼"
                DropdownList.Visible = false
                if onChanged then onChanged(opt) end
            end)
        end
    end
    setOptions(options)

    DropdownBtn.Activated:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
    end)

    return {
        SetOptions = setOptions,
        SetDisplay = function(t)
            selected = t
            DropdownBtn.Text = labelText .. ": " .. t .. " ▼"
        end,
        Get = function() return selected end,
    }
end

------------------------------------------------------------------ POPULATE TABS
-- Farm Tab
local farm = pages.Farm
makeHeader(farm, "Bring Destination")
makeDropdown(farm, "Drop Item To", { "Player", "Fire", "Bench" }, function(opt)
    State.Destination = string.lower(opt)
end)
makeHeader(farm, "Fuel & Items")
makeToggle(farm, "Auto Fuel → Fire", function(on) State.AutoFuel = on if on then task.spawn(bringFuel, true) end end)
makeToggle(farm, "Reserve Logs & Chairs", function(on) State.ReserveLogs = on end)
makeToggle(farm, "Auto Eat (HP < 60%)", function(on) State.AutoEat = on end)
makeButton(farm, "Bring Fuel Now", function() bringFuel(false) end)
makeButton(farm, "Bring Food", bringFood)
makeButton(farm, "Bring Scraps & Logs", bringScrapLogs)
makeButton(farm, "Bring Bandages", bringMeds)
makeButton(farm, "Bring Coins & Gems", bringCurrency)
makeButton(farm, "Bring EVERYTHING", bringEverything)

-- Items Tab
local itemsTab = pages.Items
makeHeader(itemsTab, "Category Bring")
local catLabels, catKeyByLabel = {}, {}
for _, dbKey in ipairs(CATEGORY_ORDER) do
    table.insert(catLabels, CATEGORY_LABELS[dbKey])
    catKeyByLabel[CATEGORY_LABELS[dbKey]] = dbKey
end
local catDropdown = makeDropdown(itemsTab, "Category", catLabels, nil)
makeButton(itemsTab, "Bring Whole Category", function()
    local key = catKeyByLabel[catDropdown.Get()]
    if key then bringByCategory(key) end
end)
makeButton(itemsTab, "Bring ALL Kid Items", bringKidItems)

makeHeader(itemsTab, "Specific Item")
local ALL_ITEM_NAMES, seenNames = {}, {}
for _, list in pairs(ITEM_DB) do
    for _, n in ipairs(list) do
        if not seenNames[n] then seenNames[n] = true table.insert(ALL_ITEM_NAMES, n) end
    end
end
table.sort(ALL_ITEM_NAMES)
local itemDropdown = makeDropdown(itemsTab, "Item", ALL_ITEM_NAMES, nil)
makeButton(itemsTab, "Bring Selected Item", function() bringByExactName(itemDropdown.Get()) end)
makeButton(itemsTab, "Teleport to Selected", function()
    local item = ItemsFolder and ItemsFolder:FindFirstChild(itemDropdown.Get())
    if item then teleportTo(item, itemDropdown.Get()) end
end)

-- Fight Tab
local combat = pages.Fight
makeHeader(combat, "Weapon Selection")
local weaponDropdowns = {}
local function weaponOptions()
    local list = { "Auto (Best owned)" }
    for _, n in ipairs(getAllWeaponNames()) do table.insert(list, n) end
    return list
end
local function onWeaponPicked(opt)
    State.Weapon = (opt == "Auto (Best owned)") and "Auto" or opt
    for _, dd in ipairs(weaponDropdowns) do dd.SetDisplay(opt) end
end
table.insert(weaponDropdowns, makeDropdown(combat, "Weapon", weaponOptions(), onWeaponPicked))

makeHeader(combat, "Kill Aura")
makeToggle(combat, "Kill Aura", function(on) State.AutoAttack = on end)
makeSlider(combat, "Range", 10, 200, CONFIG.DefaultRange, function(v) State.Range = v end)
makeSlider(combat, "Targets per hit", 1, 15, State.AuraTargets, function(v) State.AuraTargets = v end)
makeSlider(combat, "Speed (hits/sec)", 1, 5, State.AttackSpeed, function(v) State.AttackSpeed = v end)

-- Tree Tab
local treeTab = pages.Tree
makeHeader(treeTab, "Tree Chopper v2")
makeDropdown(treeTab, "Mode", { "Aura (chop nearby)", "Once Each (teleport)" }, function(opt)
    State.TreeMode = string.find(opt, "Aura") and "aura" or "once"
end)
makeDropdown(treeTab, "Big Trees", { "Chop with Chainsaw", "Skip" }, function(opt)
    State.BigTrees = string.find(opt, "Skip") and "skip" or "chainsaw"
end)
table.insert(weaponDropdowns, makeDropdown(treeTab, "Weapon", weaponOptions(), onWeaponPicked))
makeSlider(treeTab, "Aura Range", 10, 150, CONFIG.TreeRange, function(v) State.TreeRange = v end)
makeSlider(treeTab, "Hits Per Tree", 1, 15, CONFIG.HitsPerTree, function(v) State.HitsPerTree = v end)
makeToggle(treeTab, "Enable Tree Chopper", function(on) State.ChopTrees = on end)
makeButton(treeTab, "Reset Chopped Memory", function() ChoppedTrees = {} State.TreesChopped = 0 end)

-- Move Tab
local move = pages.Move
makeHeader(move, "Movement / Defense")
makeToggle(move, "God Mode", function(on) State.GodMode = on end)
makeSlider(move, "Walk Speed", 16, CONFIG.MaxSpeed, CONFIG.DefaultSpeed, function(v) State.WalkSpeed = v end)
makeSlider(move, "Jump Power", 50, CONFIG.MaxJump, CONFIG.DefaultJump, function(v) State.JumpPower = v end)
makeToggle(move, "Infinite Jump", function(on) State.InfiniteJump = on end)
makeToggle(move, "Noclip", function(on) State.Noclip = on end)

-- TP Tab
local tp = pages.TP
makeHeader(tp, "Teleport Locations")
makeSlider(tp, "Land Height", 0, 10, CONFIG.TeleportHeight, function(v) State.TeleportHeight = v end)
makeButton(tp, "Teleport to Campfire", function() teleportTo(getFire(), "campfire") end)
makeButton(tp, "Teleport to Crafting Bench", function() teleportTo(getBench(), "bench") end)
makeButton(tp, "Teleport to Stronghold", function() local s = getStronghold() if s then teleportTo(s, "stronghold") end end)
makeButton(tp, "Teleport to Nearest Kid", function() local kid = getNearestKid() if kid then teleportTo(kid, kid.Name) end end)

-- ESP Tab
local esp = pages.ESP
makeHeader(esp, "Visuals")
makeToggle(esp, "Gem/Coin ESP", function(on) State.DiamondESP = on end)
makeToggle(esp, "Chest ESP", function(on) State.ChestESP = on end)
makeToggle(esp, "Tree ESP", function(on) State.TreeESP = on end)

-- Misc Tab
local misc = pages.Misc
makeHeader(misc, "Other Options")
local afkToggle = makeToggle(misc, "Anti-AFK", function(on) State.AntiAFK = on end)
afkToggle.Set(true)
makeToggle(misc, "Show Range Circle", function(on) State.ShowCircle = on end)
makeButton(misc, "List Map Items (F9)", listAllMapItems)

-- Settings Tab
local SettingsPage = pages.Settings
makeHeader(SettingsPage, "Client Settings")

local initialKeyText = (config.ToggleKey and config.ToggleKey ~= "None") and config.ToggleKey or "None"
local KeybindButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = COLORS.Section,
    BorderSizePixel = 0,
    Text = "Toggle UI Key: " .. initialKeyText,
    TextColor3 = COLORS.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, SettingsPage)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, KeybindButton)

KeybindButton.Activated:Connect(function()
    listeningForKey = true
    KeybindButton.Text = "Press Any Key..."
    KeybindButton.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
end)

local ClearKeybindButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = COLORS.Panel2,
    BorderSizePixel = 0,
    Text = "Remove Keybind",
    TextColor3 = COLORS.SubText,
    TextSize = 14,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false,
}, SettingsPage)
create("UICorner", { CornerRadius = UDim.new(0, 8) }, ClearKeybindButton)

ClearKeybindButton.Activated:Connect(function()
    listeningForKey = false
    currentKey = nil
    config.ToggleKey = "None"
    SaveConfig()
    KeybindButton.Text = "Toggle UI Key: None"
    KeybindButton.BackgroundColor3 = COLORS.Section
end)

local UnloadButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(170, 55, 65),
    BorderSizePixel = 0,
    Text = "Unload Script",
    TextColor3 = COLORS.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, SettingsPage)
create("UICorner", { CornerRadius = UDim.new(0, 9) }, UnloadButton)

UnloadButton.Activated:Connect(function()
    unloaded = true
    Gui:Destroy()
end)

------------------------------------------------------------------ KEYBIND & DRAGGING
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listeningForKey = false
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                currentKey = nil
                config.ToggleKey = "None"
                KeybindButton.Text = "Toggle UI Key: None"
            else
                currentKey = input.KeyCode
                config.ToggleKey = input.KeyCode.Name
                KeybindButton.Text = "Toggle UI Key: " .. input.KeyCode.Name
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

--------------------------------------------------------------------- LOOPS
task.spawn(function()
    while not unloaded do
        if State.AutoFuel then pcall(bringFuel, true) end
        task.wait(CONFIG.FuelInterval)
    end
end)

task.spawn(function()
    while not unloaded do
        if State.AutoAttack and not State.Chopping then
            pcall(killAuraTick)
        end
        task.wait(1 / math.max(State.AttackSpeed, 1))
    end
end)

task.spawn(function()
    while not unloaded do
        if State.ChopTrees then
            if State.TreeMode == "aura" then
                pcall(chopAuraTick)
                task.wait(CONFIG.ChopInterval)
            else
                pcall(chopOnceStep)
                task.wait(0.35)
            end
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    while not unloaded do
        local hum = getHum()
        if hum then
            if State.GodMode then
                if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
                hum.Health = math.huge
            end
            if State.WalkSpeed > 16 and hum.WalkSpeed ~= State.WalkSpeed then
                hum.WalkSpeed = State.WalkSpeed
            end
            if State.JumpPower > 50 and hum.JumpPower ~= State.JumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = State.JumpPower
            end
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while not unloaded do
        if State.AutoEat then
            local char = LocalPlayer.Character
            local hum = getHum()
            if hum and char and hum.MaxHealth ~= math.huge
            and hum.Health < hum.MaxHealth * (CONFIG.EatHealthMin / 100)
            and not char:FindFirstChildOfClass("Tool") then
                local inv = LocalPlayer:FindFirstChild("Inventory")
                local source = (inv and inv:FindFirstChildWhichIsA("Tool")) and inv
                    or LocalPlayer:FindFirstChild("Backpack")
                if source then
                    for _, item in ipairs(source:GetChildren()) do
                        if matchesList(item.Name, ITEM_DB.Food) then
                            if EatRemote then
                                pcall(function() EatRemote:FireServer("FireAllClients", item) end)
                            end
                            break
                        end
                    end
                end
            end
        end
        task.wait(CONFIG.EatInterval)
    end
end)

task.spawn(function()
    while not unloaded do
        pcall(function()
            if State.DiamondESP or State.ChestESP or State.TreeESP or State.ChopTrees then
                refreshWorldCache()
            end
            updateESP("Currency", State.DiamondESP, WorldCache.currency)
            updateESP("Chest",    State.ChestESP,   WorldCache.chests)
            updateESP("Tree",     State.TreeESP,    WorldCache.trees)
        end)
        task.wait(1)
    end
end)
