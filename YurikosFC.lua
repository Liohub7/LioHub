-- Yurikos | Ghoul Garden (fixed)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "YurikosGhoul"
gui.ResetOnSpawn = false
pcall(function()
    if gethui then gui.Parent = gethui() else gui.Parent = CoreGui end
end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0.02, 0, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
title.Text = "Yurikos | Ghoul Garden"
title.TextColor3 = Color3.fromRGB(100, 180, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.9, 0, 0, 20)
status.Position = UDim2.new(0.05, 0, 1, -24)
status.BackgroundTransparency = 1
status.Text = "loading"
status.TextColor3 = Color3.fromRGB(150, 160, 180)
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.Parent = frame

local SEEDS = {
    "Halloween Webberry",
    "Halloween Candy Cluster",
    "Halloween Candy Corn Carrot",
    "Halloween Spider Shrub",
    "Halloween Witch's Broom",
    "Halloween Blood Kiwi",
    "Halloween Fang Root",
    "Halloween Pumpkin Lantern",
    "Halloween Haunted Hallow",
}

local buyOn, plantOn = {}, {}
for i = 1, #SEEDS do
    buyOn[SEEDS[i]] = false
    plantOn[SEEDS[i]] = false
end
buyOn["Halloween Candy Corn Carrot"] = true
plantOn["Halloween Candy Corn Carrot"] = true

local autoCollect, autoPlant, autoSell, autoBuy = false, false, false, false
local BuyRE, SellRE, CollectRE, PlantRE
local lastSell, lastBuy, lastPlant = 0, 0, 0
local soilCache, lastScan = {}, 0

local function picks(map)
    local t = {}
    for i = 1, #SEEDS do
        if map[SEEDS[i]] then table.insert(t, SEEDS[i]) end
    end
    return t
end

local function makeToggle(text, y, getFn, setFn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.9, 0, 0, 28)
    b.Position = UDim2.new(0.05, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
    b.Text = text .. ": OFF"
    b.TextColor3 = Color3.fromRGB(230, 235, 255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        setFn(not getFn())
        local on = getFn()
        b.Text = text .. (on and ": ON" or ": OFF")
        b.BackgroundColor3 = on and Color3.fromRGB(30, 100, 180) or Color3.fromRGB(30, 36, 50)
    end)
end

makeToggle("Collect", 32, function() return autoCollect end, function(v) autoCollect = v end)
makeToggle("Plant",   64, function() return autoPlant   end, function(v) autoPlant   = v end)
makeToggle("Sell",    96, function() return autoSell    end, function(v) autoSell    = v end)
makeToggle("Buy",    128, function() return autoBuy     end, function(v) autoBuy     = v end)

local openList = nil
local function makeDrop(label, y, map)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 26)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(28, 36, 55)
    btn.Text = label .. " (1)"
    btn.TextColor3 = Color3.fromRGB(220, 230, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(0.9, 0, 0, 100)
    list.Position = UDim2.new(0.05, 0, 0, y + 28)
    list.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ScrollBarThickness = 4
    list.ZIndex = 40
    list.CanvasSize = UDim2.new(0, 0, 0, #SEEDS * 24)
    list.Parent = frame
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)

    for i = 1, #SEEDS do
        local name = SEEDS[i]
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, -4, 0, 22)
        item.Position = UDim2.new(0, 2, 0, (i - 1) * 24)
        item.ZIndex = 41
        item.Font = Enum.Font.Gotham
        item.TextSize = 10
        item.Parent = list
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)

        local function refresh()
            if map[name] then
                item.Text = "[x] " .. name
                item.BackgroundColor3 = Color3.fromRGB(30, 90, 160)
            else
                item.Text = "[ ] " .. name
                item.BackgroundColor3 = Color3.fromRGB(30, 38, 55)
            end
            item.TextColor3 = Color3.fromRGB(210, 220, 240)
            btn.Text = label .. " (" .. tostring(#picks(map)) .. ")"
        end
        refresh()
        item.MouseButton1Click:Connect(function()
            map[name] = not map[name]
            refresh()
        end)
    end

    btn.MouseButton1Click:Connect(function()
        -- FIX: \~= → ~=
        if openList and openList ~= list then openList.Visible = false end
        list.Visible = not list.Visible
        openList = list.Visible and list or nil
    end)
end

makeDrop("Buy",   162, buyOn)
makeDrop("Plant", 194, plantOn)

task.spawn(function()
    local ge = RS:FindFirstChild("GameEvents")
    if ge then
        BuyRE     = ge:FindFirstChild("BuyEventShopStock")
        PlantRE   = ge:FindFirstChild("Plant_RE")
        local he  = ge:FindFirstChild("HalloweenEvent")
        if he then SellRE = he:FindFirstChild("HalloweenSellInventoryRE") end
        local crops = ge:FindFirstChild("Crops")
        if crops then CollectRE = crops:FindFirstChild("Collect") end
    end
    status.Text = string.format("B:%s S:%s C:%s P:%s",
        BuyRE     and "OK" or "NO",
        SellRE    and "OK" or "NO",
        CollectRE and "OK" or "NO",
        PlantRE   and "OK" or "NO")
end)

local function getMyFarm()
    local farms = workspace:FindFirstChild("Farm") or workspace:FindFirstChild("Farms")
    if not farms then return nil end
    for _, farm in ipairs(farms:GetChildren()) do
        local ok, mine = pcall(function()
            local o = farm.Important.Data.Owner
            if o:IsA("StringValue") then return o.Value == LP.Name end
            if o:IsA("ObjectValue") then return o.Value == LP end
            return false
        end)
        if ok and mine then return farm end
    end
    return nil
end

local function scanSoils()
    soilCache = {}
    local farm = getMyFarm()
    if not farm then return end
    for _, p in ipairs(farm:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = string.lower(p.Name)
            if string.find(n,"soil") or string.find(n,"plot")
            or string.find(n,"dirt") or string.find(n,"tile") then
                table.insert(soilCache, p)
            end
        end
    end
    if #soilCache < 2 then
        for _, p in ipairs(farm:GetDescendants()) do
            if p:IsA("BasePart") and p.Size.X > 2 and p.Size.Z > 2 then
                table.insert(soilCache, p)
            end
        end
    end
end

local function randomPlotPos()
    if tick() - lastScan > 8 or #soilCache == 0 then
        scanSoils(); lastScan = tick()
    end
    if #soilCache == 0 then return nil end
    local s  = soilCache[math.random(1, #soilCache)]
    local ox = (math.random() - 0.5) * math.min(s.Size.X, 6) * 0.7
    local oz = (math.random() - 0.5) * math.min(s.Size.Z, 6) * 0.7
    return s.Position + Vector3.new(ox, 0.1, oz)
end

local function isSeedTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    -- FIX: \~= → ~=
    return string.find(string.lower(tool.Name), "seed", 1, true) ~= nil
end

local function cleanSeedName(name)
    local n = name
    n = n:gsub("%s*%[.-%]$", "")
    n = n:gsub("%s+$", "")
    n = n:gsub("%s*[Ss]eed$", "")
    return n
end

local function equipSeedNamed(want)
    local char = LP.Character
    local bp   = LP:FindFirstChild("Backpack")
    if not char or not bp then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local held = char:FindFirstChildOfClass("Tool")
    if held and isSeedTool(held) and cleanSeedName(held.Name) == want then
        return true
    end
    if held then pcall(function() hum:UnequipTools() end) end

    for _, t in ipairs(bp:GetChildren()) do
        if isSeedTool(t) and cleanSeedName(t.Name) == want then
            pcall(function() hum:EquipTool(t) end)
            task.wait(0.05)
            return true
        end
    end
    return false
end

local function doPlant()
    if not PlantRE then return end
    if tick() - lastPlant < 0.8 then return end
    local list = picks(plantOn)
    if #list == 0 then return end
    local seed = list[math.random(1, #list)]
    if not equipSeedNamed(seed) then return end
    local pos = randomPlotPos()
    if not pos then return end
    lastPlant = tick()
    pcall(function() PlantRE:FireServer(pos, seed) end)
end

local function doCollect()
    if not CollectRE then return end
    local farm = getMyFarm()
    if not farm then return end
    local batch = {}
    for _, v in ipairs(farm:GetDescendants()) do
        if v:IsA("Model") and string.find(v.Name, "Halloween", 1, true) then
            table.insert(batch, v)
            if #batch >= 12 then break end
        end
    end
    if #batch == 0 then return end
    pcall(function() CollectRE:FireServer(batch) end)
end

local function doBuy()
    if not BuyRE then return end
    if tick() - lastBuy < 2.5 then return end
    lastBuy = tick()
    local list = picks(buyOn)
    for i = 1, #list do
        pcall(function() BuyRE:FireServer(list[i], "Scary Seeds") end)
        task.wait(0.35)
    end
end

local function doSell()
    if not SellRE then return end
    if tick() - lastSell < 4 then return end
    lastSell = tick()
    pcall(function() SellRE:FireServer() end)
end

task.spawn(function()
    scanSoils()
    while true do
        task.wait(0.5)
        if autoCollect then doCollect() end
        if autoPlant   then doPlant()   end
        if autoSell    then doSell()    end
        if autoBuy     then doBuy()     end
    end
end)

print("[Yurikos] Ghoul Garden ready")
