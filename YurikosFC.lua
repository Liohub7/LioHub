-- language: Lua | executor: Delta / KRNL / Synapse
-- Grow a Garden | Dynamic NPC Quest — ikut rotasi NPC otomatis

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local GE      = RS:WaitForChild("GameEvents")
local LP      = Players.LocalPlayer

-- ══════════════════════════
-- REMOTES
-- ══════════════════════════
local SubmitRE   = GE:WaitForChild("SubmitFoodService_RE")
local FoodCritRE = GE:WaitForChild("FoodCriticService_RE")
local CollectRE  = GE:WaitForChild("Crops"):WaitForChild("Collect")

-- ══════════════════════════
-- CONFIG
-- ══════════════════════════
local CFG = {
    autoSubmit  = false,
    autoCollect = false,
    submitDelay = 2.5,
    collectDelay = 3.0,
    scanDelay   = 1.0,  -- seberapa sering cek tipe yang diminta NPC
}

local lastSubmit, lastCollect = 0, 0
local currentWant = "unknown"  -- tipe tanaman yang diminta NPC saat ini

-- ══════════════════════════
-- FIND NPC
-- ══════════════════════════
local function findQuestNPC()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") then
            local n = v.Name:lower()
            -- Archeologist Archie, food critic, any NPC with thought bubble
            if n:find("archie") or n:find("archaeolog") or n:find("food") 
            or n:find("critic") or n:find("anubis") or n:find("quest") then
                return v
            end
        end
    end
    -- fallback: cari NPC yang punya BillboardGui dengan teks "Looking for"
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            for _, lbl in ipairs(v:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Text:find("Looking for") then
                    return v.Parent
                end
            end
        end
    end
    return nil
end

-- ══════════════════════════
-- READ WHAT NPC WANTS
-- baca thought bubble text, extract tipe tanaman
-- ══════════════════════════
local function readNPCWant()
    -- coba baca dari workspace langsung (StringValue di NPC atau folder)
    local function scanForWantText(root)
        for _, v in ipairs(root:GetDescendants()) do
            -- cek StringValue
            if v:IsA("StringValue") then
                local match = v.Value:match("[Ll]ooking for (.+) [Pp]lants?")
                if match then return match:gsub("!",""):gsub("%s+$","") end
                -- kadang langsung nama tipe saja
                if v.Name:lower():find("want") or v.Name:lower():find("request") 
                or v.Name:lower():find("type") then
                    if #v.Value > 0 then return v.Value end
                end
            end
            -- cek TextLabel (thought bubble)
            if v:IsA("TextLabel") then
                local t = v.Text
                if t and #t > 0 then
                    local match = t:match("[Ll]ooking for (.+) [Pp]lants?")
                    if match then return match:gsub("!",""):gsub("%s+$","") end
                    match = t:match("[Ll]ooking for (.+)!")
                    if match then return match:gsub("%s+$","") end
                end
            end
        end
        return nil
    end

    -- scan NPC dulu
    local npc = findQuestNPC()
    if npc then
        local w = scanForWantText(npc)
        if w then return w end
    end

    -- scan seluruh workspace kalau tidak ketemu di NPC
    return scanForWantText(workspace)
end

-- ══════════════════════════
-- READ KG PROGRESS
-- ══════════════════════════
local function readProgress()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("TextLabel") then
            local cur, max = v.Text:match("([%d%.]+)kg/([%d%.]+)kg")
            if cur and max then
                return tonumber(cur), tonumber(max)
            end
        end
    end
    return nil, nil
end

-- ══════════════════════════
-- FIND MY FARM
-- ══════════════════════════
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

-- ══════════════════════════
-- COLLECT MATCHING CROPS
-- filter berdasarkan currentWant
-- ══════════════════════════
local function doCollect()
    if tick() - lastCollect < CFG.collectDelay then return end
    lastCollect = tick()

    local farm = getMyFarm()
    if not farm then setStatus("farm tidak ditemukan") return end

    local batch = {}
    local wantLower = currentWant:lower()

    for _, v in ipairs(farm:GetDescendants()) do
        if v:IsA("Model") then
            local nameLower = v.Name:lower()
            -- filter: kalau currentWant unknown, collect semua
            -- kalau sudah diketahui, collect yang cocok saja
            local match = (wantLower == "unknown")
                or nameLower:find(wantLower, 1, true)
                -- partial match untuk kategori (Vegetable, Fruit, dll)
                or (wantLower:find("vegetable") and (
                    nameLower:find("carrot") or nameLower:find("tomato")
                    or nameLower:find("potato") or nameLower:find("pepper")
                    or nameLower:find("corn") or nameLower:find("pumpkin")
                    or nameLower:find("bean") or nameLower:find("kale")
                    or nameLower:find("prickly") or nameLower:find("cactus")
                    or nameLower:find("veggie") or nameLower:find("vegetable")
                ))
                or (wantLower:find("fruit") and (
                    nameLower:find("berry") or nameLower:find("apple")
                    or nameLower:find("mango") or nameLower:find("grape")
                    or nameLower:find("kiwi") or nameLower:find("melon")
                    or nameLower:find("fruit") or nameLower:find("peach")
                    or nameLower:find("cherry") or nameLower:find("plum")
                ))
                or (wantLower:find("flower") and (
                    nameLower:find("flower") or nameLower:find("rose")
                    or nameLower:find("daisy") or nameLower:find("tulip")
                    or nameLower:find("orchid") or nameLower:find("lotus")
                    or nameLower:find("blossom") or nameLower:find("bloom")
                ))
                or (wantLower:find("mushroom") and (
                    nameLower:find("mushroom") or nameLower:find("shroom")
                    or nameLower:find("fungi") or nameLower:find("fungus")
                ))

            if match then
                table.insert(batch, v)
                if #batch >= 12 then break end
            end
        end
    end

    if #batch > 0 then
        pcall(function() CollectRE:FireServer(batch) end)
        setStatus("collected " .. #batch .. " " .. currentWant)
    else
        setStatus("menunggu " .. currentWant .. " siap harvest")
    end
end

-- ══════════════════════════
-- SUBMIT KE NPC
-- ══════════════════════════
local function doSubmit()
    if tick() - lastSubmit < CFG.submitDelay then return end
    lastSubmit = tick()

    local cur, max = readProgress()

    -- kalau sudah penuh, submit
    pcall(function() SubmitRE:FireServer("Submit All") end)
    task.wait(0.1)
    pcall(function() SubmitRE:FireServer(true) end)
    task.wait(0.1)
    pcall(function() FoodCritRE:FireServer("Submit All") end)
    task.wait(0.1)
    -- coba tanpa argumen juga
    pcall(function() SubmitRE:FireServer() end)

    if cur and max then
        setStatus(string.format("submit ✓ | %.1f/%.1fkg", cur, max))
    else
        setStatus("submitted ✓")
    end
end

-- ══════════════════════════
-- GUI
-- ══════════════════════════
if game.CoreGui:FindFirstChild("QuestUI") then
    game.CoreGui.QuestUI:Destroy()
end
local guiParent = (typeof(gethui)=="function") and gethui() or game.CoreGui

local gui = Instance.new("ScreenGui")
gui.Name = "QuestUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 230, 0, 285)
main.Position = UDim2.new(0, 14, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- drag
local drag, ds, sp = false, nil, nil
main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; ds=i.Position; sp=main.Position
    end
end)
main.InputChanged:Connect(function(i)
    if drag and (i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-ds
        main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)
main.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)

-- header
local hdr = Instance.new("Frame", main)
hdr.Size = UDim2.new(1,0,0,34)
hdr.BackgroundColor3 = Color3.fromRGB(18,20,36)
hdr.BorderSizePixel = 0
Instance.new("UICorner",hdr).CornerRadius = UDim.new(0,8)

local htxt = Instance.new("TextLabel", hdr)
htxt.Size = UDim2.new(1,-10,1,0)
htxt.Position = UDim2.new(0,10,0,0)
htxt.BackgroundTransparency = 1
htxt.Font = Enum.Font.GothamBold
htxt.TextSize = 12
htxt.TextColor3 = Color3.fromRGB(200,170,80)
htxt.TextXAlignment = Enum.TextXAlignment.Left
htxt.Text = "𓂀  NPC QUEST"

-- want label (tipe yang diminta NPC)
local wantLbl = Instance.new("TextLabel", main)
wantLbl.Size = UDim2.new(1,-16,0,22)
wantLbl.Position = UDim2.new(0,8,0,38)
wantLbl.BackgroundTransparency = 1
wantLbl.Font = Enum.Font.GothamBold
wantLbl.TextSize = 12
wantLbl.TextColor3 = Color3.fromRGB(100,220,140)
wantLbl.TextXAlignment = Enum.TextXAlignment.Left
wantLbl.Text = "NPC wants: scanning..."

-- progress label
local progLbl = Instance.new("TextLabel", main)
progLbl.Size = UDim2.new(1,-16,0,18)
progLbl.Position = UDim2.new(0,8,0,60)
progLbl.BackgroundTransparency = 1
progLbl.Font = Enum.Font.Code
progLbl.TextSize = 10
progLbl.TextColor3 = Color3.fromRGB(150,160,200)
progLbl.TextXAlignment = Enum.TextXAlignment.Left
progLbl.Text = "progress: —"

-- status
local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1,-16,0,18)
statusLbl.Position = UDim2.new(0,8,1,-24)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = Enum.Font.Code
statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(80,90,130)
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Text = "ready"

function setStatus(msg) statusLbl.Text = msg end

-- toggles
local COL_OFF = Color3.fromRGB(22,25,42)
local COL_ON  = Color3.fromRGB(50,55,120)
local TXT_OFF = Color3.fromRGB(140,145,185)
local TXT_ON  = Color3.fromRGB(210,220,255)

local function makeToggle(label, yPos, onToggle)
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(1,-16,0,34)
    b.Position = UDim2.new(0,8,0,yPos)
    b.BackgroundColor3 = COL_OFF
    b.TextColor3 = TXT_OFF
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.Text = "  ○  "..label
    b.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    local s = false
    b.MouseButton1Click:Connect(function()
        s = not s
        b.BackgroundColor3 = s and COL_ON or COL_OFF
        b.TextColor3 = s and TXT_ON or TXT_OFF
        b.Text = (s and "  ●  " or "  ○  ")..label
        onToggle(s)
    end)
end

-- manual
local manBtn = Instance.new("TextButton", main)
manBtn.Size = UDim2.new(1,-16,0,30)
manBtn.Position = UDim2.new(0,8,0,86)
manBtn.BackgroundColor3 = Color3.fromRGB(70,50,15)
manBtn.TextColor3 = Color3.fromRGB(220,180,80)
manBtn.Font = Enum.Font.GothamBold
manBtn.TextSize = 11
manBtn.BorderSizePixel = 0
manBtn.Text = "⚡ Submit Now"
Instance.new("UICorner",manBtn).CornerRadius = UDim.new(0,6)
manBtn.MouseButton1Click:Connect(doSubmit)

makeToggle("Auto Submit",  124, function(on) CFG.autoSubmit  = on end)
makeToggle("Auto Collect", 166, function(on) CFG.autoCollect = on end)

-- ══════════════════════════
-- SCAN LOOP — deteksi rotasi NPC
-- ══════════════════════════
task.spawn(function()
    while true do
        task.wait(CFG.scanDelay)

        -- update wanted type
        local w = readNPCWant()
        if w and w ~= currentWant then
            currentWant = w
            wantLbl.Text = "NPC wants: " .. currentWant
            setStatus("NPC berganti → " .. currentWant)
        elseif w then
            wantLbl.Text = "NPC wants: " .. currentWant
        else
            wantLbl.Text = "NPC wants: scanning..."
        end

        -- update progress bar
        local cur, max = readProgress()
        if cur and max then
            progLbl.Text = string.format("%.1f / %.1f kg", cur, max)
        end

        -- auto actions
        if CFG.autoCollect then doCollect() end
        if CFG.autoSubmit  then doSubmit()  end
    end
end)

setStatus("loaded ✓")
print("[QuestUI] dynamic NPC scanner active")
