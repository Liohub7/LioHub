-- language: Lua | executor: Delta / KRNL / Synapse
-- Grow a Garden | Anubis Quest — RE verified

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local GE      = RS:WaitForChild("GameEvents")
local LP      = Players.LocalPlayer

-- ══════════════════════════
-- REMOTES (verified dari scan)
-- ══════════════════════════
local SubmitRE    = GE:WaitForChild("SubmitFoodService_RE")
local FoodCritRE  = GE:WaitForChild("FoodCriticService_RE")
local CollectRE   = GE:WaitForChild("Crops"):WaitForChild("Collect")
local BuySeedRE   = GE:WaitForChild("BuyDailySeedShopStock")

-- ══════════════════════════
-- CONFIG
-- ══════════════════════════
local CFG = {
    autoSubmit  = false,
    autoCollect = false,
    autoBuy     = false,
    submitDelay = 2.5,
    collectDelay = 3.0,
    buyDelay    = 4.0,
    buyTarget   = "Prickly", -- keyword nama seed yang dibeli
}

local lastSubmit, lastCollect, lastBuy = 0, 0, 0

-- ══════════════════════════
-- ACTIONS
-- ══════════════════════════
local function doSubmit()
    if tick() - lastSubmit < CFG.submitDelay then return end
    lastSubmit = tick()

    -- coba semua format arg yang mungkin dipakai SubmitFoodService_RE
    pcall(function() SubmitRE:FireServer("Submit All") end)
    task.wait(0.1)
    pcall(function() SubmitRE:FireServer(true) end)
    task.wait(0.1)
    -- trigger dialog NPC dulu kalau perlu
    pcall(function() FoodCritRE:FireServer("Submit All") end)

    setStatus("submitted ✓")
end

local function doCollect()
    if tick() - lastCollect < CFG.collectDelay then return end
    lastCollect = tick()

    local farm = nil
    local farms = workspace:FindFirstChild("Farm") or workspace:FindFirstChild("Farms")
    if farms then
        for _, f in ipairs(farms:GetChildren()) do
            pcall(function()
                local o = f.Important.Data.Owner
                local isMe = (o:IsA("StringValue") and o.Value == LP.Name)
                          or (o:IsA("ObjectValue") and o.Value == LP)
                if isMe then farm = f end
            end)
            if farm then break end
        end
    end

    if not farm then setStatus("farm tidak ditemukan") return end

    local batch = {}
    for _, v in ipairs(farm:GetDescendants()) do
        if v:IsA("Model") then
            table.insert(batch, v)
            if #batch >= 12 then break end
        end
    end

    if #batch > 0 then
        pcall(function() CollectRE:FireServer(batch) end)
        setStatus("collected " .. #batch .. " crops ✓")
    else
        setStatus("tidak ada crop yang bisa di-collect")
    end
end

local function doBuy()
    if tick() - lastBuy < CFG.buyDelay then return end
    lastBuy = tick()

    -- scan daily shop untuk seed yang cocok
    local shopData = RS:FindFirstChild("DailySeedShop", true)
        or RS:FindFirstChild("SeedShop", true)

    -- fire dengan nama seed langsung
    pcall(function()
        BuySeedRE:FireServer(CFG.buyTarget)
    end)
    pcall(function()
        BuySeedRE:FireServer(CFG.buyTarget, 1)
    end)
    setStatus("buy attempt: " .. CFG.buyTarget)
end

-- ══════════════════════════
-- GUI
-- ══════════════════════════
if game.CoreGui:FindFirstChild("AnubisUI") then
    game.CoreGui.AnubisUI:Destroy()
end
local guiParent = (typeof(gethui)=="function") and gethui() or game.CoreGui

local gui = Instance.new("ScreenGui")
gui.Name = "AnubisUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 225, 0, 260)
main.Position = UDim2.new(0, 14, 0.28, 0)
main.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- drag (mobile safe)
local drag, ds, sp = false, nil, nil
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch
    or i.UserInputType == Enum.UserInputType.MouseButton1 then
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
htxt.Text = "𓂀  ANUBIS QUEST"

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

-- toggle
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

-- manual submit button
local manBtn = Instance.new("TextButton", main)
manBtn.Size = UDim2.new(1,-16,0,30)
manBtn.Position = UDim2.new(0,8,0,38)
manBtn.BackgroundColor3 = Color3.fromRGB(70,50,15)
manBtn.TextColor3 = Color3.fromRGB(220,180,80)
manBtn.Font = Enum.Font.GothamBold
manBtn.TextSize = 11
manBtn.BorderSizePixel = 0
manBtn.Text = "⚡ Submit Now"
Instance.new("UICorner",manBtn).CornerRadius = UDim.new(0,6)
manBtn.MouseButton1Click:Connect(function()
    doSubmit()
end)

makeToggle("Auto Submit",  80, function(on) CFG.autoSubmit  = on; setStatus(on and "auto submit: ON" or "OFF") end)
makeToggle("Auto Collect", 122, function(on) CFG.autoCollect = on; setStatus(on and "auto collect: ON" or "OFF") end)
makeToggle("Auto Buy Seed",164, function(on) CFG.autoBuy     = on; setStatus(on and "auto buy: ON — "..CFG.buyTarget or "OFF") end)

-- ══════════════════════════
-- LOOP
-- ══════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.autoSubmit  then doSubmit()  end
        if CFG.autoCollect then doCollect() end
        if CFG.autoBuy     then doBuy()     end
    end
end)

setStatus("loaded ✓")
print("[AnubisQuest] REs verified — ready")
