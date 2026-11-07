-- language: Lua | executor: Delta / KRNL / Synapse
-- Grow a Garden | Anubis Quest — collect + submit verified

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local GE      = RS:WaitForChild("GameEvents")
local LP      = Players.LocalPlayer

-- ══════════════════════════
-- REMOTES — exact paths
-- ══════════════════════════
local CollectRE = GE:WaitForChild("Crops"):WaitForChild("Collect")
local SubmitRE  = GE:WaitForChild("Events")
                   :WaitForChild("AnubisEvent")
                   :WaitForChild("AncientArc")
                   :WaitForChild("Submit")

-- Token bisa berubah tiap sesi, baca dinamis kalau ada
local function getToken()
    local ok, val = pcall(function()
        return GE.Events.AnubisEvent.AncientArc:FindFirstChild("Token")
    end)
    if ok and val and val:IsA("IntValue") then return val.Value end
    return 3  -- default dari spy
end

-- ══════════════════════════
-- CONFIG
-- ══════════════════════════
local CFG = {
    autoCollect = false,
    autoSubmit  = false,
    collectDelay = 0.8,
    submitDelay  = 3.0,
}
local lastCollect, lastSubmit = 0, 0

-- ══════════════════════════
-- READ NPC WANT
-- ══════════════════════════
local function readNPCWant()
    -- coba baca dari AnubisEvent folder dulu
    local ok, val = pcall(function()
        return GE.Events.AnubisEvent:FindFirstChild("WantedPlant")
            or GE.Events.AnubisEvent:FindFirstChild("CurrentPlant")
            or GE.Events.AnubisEvent:FindFirstChild("PlantType")
    end)
    if ok and val and typeof(val.Value)=="string" and #val.Value>0 then
        return val.Value
    end

    -- fallback: baca thought bubble TextLabel di workspace
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("TextLabel") then
            local t = v.Text or ""
            local m = t:match("[Ll]ooking for (.+) [Pp]lants?")
                   or t:match("[Ww]ants? (.+) [Pp]lants?")
            if m then return m:gsub("!",""):gsub("%s+$",""):gsub("^%s+","") end
        end
    end
    return nil
end

-- ══════════════════════════
-- COLLECT — exact format dari spy
-- satu fruit per FireServer({fruit})
-- path: Workspace.Farm.Farm.Important.Plants_Physical.[Plant].Fruits.[Model]
-- ══════════════════════════
local function doCollect()
    if tick() - lastCollect < CFG.collectDelay then return end
    lastCollect = tick()

    local plantsFolder = workspace:FindFirstChild("Farm")
    if plantsFolder then plantsFolder = plantsFolder:FindFirstChild("Farm") end
    if plantsFolder then plantsFolder = plantsFolder:FindFirstChild("Important") end
    if plantsFolder then plantsFolder = plantsFolder:FindFirstChild("Plants_Physical") end

    if not plantsFolder then
        setStatus("❌ Plants_Physical tidak ditemukan")
        return
    end

    local want = readNPCWant()
    local wantLower = want and want:lower() or ""
    local count = 0

    for _, plantModel in ipairs(plantsFolder:GetChildren()) do
        local plantName = plantModel.Name:lower()

        -- filter sesuai NPC want
        local match = (#wantLower == 0)
            or plantName:find(wantLower, 1, true)
            or wantLower:find(plantName, 1, true)

        if match then
            local fruitsFolder = plantModel:FindFirstChild("Fruits")
            if fruitsFolder then
                for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                    if fruit:IsA("Model") then
                        pcall(function()
                            CollectRE:FireServer({fruit})
                        end)
                        count = count + 1
                        task.wait(0.05)
                    end
                end
            end
        end
    end

    if count > 0 then
        setStatus("✓ collected "..count.." | ".. (want or "all"))
    else
        setStatus("menunggu harvest | want: "..(want or "unknown"))
    end
end

-- ══════════════════════════
-- SUBMIT — exact args dari SimpleSpy
-- {Token=3, Mode="All"}
-- ══════════════════════════
local function doSubmit()
    if tick() - lastSubmit < CFG.submitDelay then return end
    lastSubmit = tick()

    local token = getToken()
    pcall(function()
        SubmitRE:FireServer({
            Token = token,
            Mode  = "All"
        })
    end)
    setStatus("✓ submitted | token="..token)
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
main.Size = UDim2.new(0, 232, 0, 290)
main.Position = UDim2.new(0, 14, 0.22, 0)
main.BackgroundColor3 = Color3.fromRGB(10,12,20)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

local drag,ds,sp=false,nil,nil
main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true;ds=i.Position;sp=main.Position end
end)
main.InputChanged:Connect(function(i)
    if drag and(i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-ds
        main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end
end)
main.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)

-- header
local hdr=Instance.new("Frame",main)
hdr.Size=UDim2.new(1,0,0,34)
hdr.BackgroundColor3=Color3.fromRGB(18,20,36)
hdr.BorderSizePixel=0
Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,8)
local htxt=Instance.new("TextLabel",hdr)
htxt.Size=UDim2.new(1,-10,1,0)
htxt.Position=UDim2.new(0,10,0,0)
htxt.BackgroundTransparency=1
htxt.Font=Enum.Font.GothamBold
htxt.TextSize=12
htxt.TextColor3=Color3.fromRGB(200,170,80)
htxt.TextXAlignment=Enum.TextXAlignment.Left
htxt.Text="𓂀  ANUBIS QUEST"

-- want label
local wantLbl=Instance.new("TextLabel",main)
wantLbl.Size=UDim2.new(1,-16,0,20)
wantLbl.Position=UDim2.new(0,8,0,38)
wantLbl.BackgroundTransparency=1
wantLbl.Font=Enum.Font.GothamBold
wantLbl.TextSize=11
wantLbl.TextColor3=Color3.fromRGB(100,220,140)
wantLbl.TextXAlignment=Enum.TextXAlignment.Left
wantLbl.Text="NPC wants: scanning..."

-- progress label
local progLbl=Instance.new("TextLabel",main)
progLbl.Size=UDim2.new(1,-16,0,16)
progLbl.Position=UDim2.new(0,8,0,58)
progLbl.BackgroundTransparency=1
progLbl.Font=Enum.Font.Code
progLbl.TextSize=10
progLbl.TextColor3=Color3.fromRGB(150,160,200)
progLbl.TextXAlignment=Enum.TextXAlignment.Left
progLbl.Text="progress: —"

-- status
local statusLbl=Instance.new("TextLabel",main)
statusLbl.Size=UDim2.new(1,-16,0,18)
statusLbl.Position=UDim2.new(0,8,1,-24)
statusLbl.BackgroundTransparency=1
statusLbl.Font=Enum.Font.Code
statusLbl.TextSize=10
statusLbl.TextColor3=Color3.fromRGB(80,90,130)
statusLbl.TextXAlignment=Enum.TextXAlignment.Left
statusLbl.Text="ready"

function setStatus(msg) statusLbl.Text=msg end

local COL_OFF=Color3.fromRGB(22,25,42)
local COL_ON=Color3.fromRGB(50,55,120)
local TXT_OFF=Color3.fromRGB(140,145,185)
local TXT_ON=Color3.fromRGB(210,220,255)

local function makeToggle(label,yPos,onToggle)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(1,-16,0,34)
    b.Position=UDim2.new(0,8,0,yPos)
    b.BackgroundColor3=COL_OFF
    b.TextColor3=TXT_OFF
    b.Font=Enum.Font.Gotham
    b.TextSize=12
    b.BorderSizePixel=0
    b.Text="  ○  "..label
    b.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local s=false
    b.MouseButton1Click:Connect(function()
        s=not s
        b.BackgroundColor3=s and COL_ON or COL_OFF
        b.TextColor3=s and TXT_ON or TXT_OFF
        b.Text=(s and"  ●  "or"  ○  ")..label
        onToggle(s)
    end)
end

-- manual buttons
local function makeManual(label,color,textColor,yPos,onClick)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(0.46,0,0,30)
    b.Position=UDim2.new(yPos,0,0,78)
    b.BackgroundColor3=color
    b.TextColor3=textColor
    b.Font=Enum.Font.GothamBold
    b.TextSize=11
    b.BorderSizePixel=0
    b.Text=label
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(onClick)
end

makeManual("⚡ Collect",Color3.fromRGB(20,60,30),Color3.fromRGB(100,220,140),0.04,doCollect)
makeManual("📤 Submit", Color3.fromRGB(60,45,10),Color3.fromRGB(220,180,80),0.52,doSubmit)

makeToggle("Auto Collect", 116, function(on) CFG.autoCollect=on end)
makeToggle("Auto Submit",  158, function(on) CFG.autoSubmit=on end)

-- ══════════════════════════
-- MAIN LOOP
-- ══════════════════════════
task.spawn(function()
    while true do
        task.wait(1)

        -- update NPC want display
        local w=readNPCWant()
        if w then wantLbl.Text="NPC wants: "..w
        else wantLbl.Text="NPC wants: scanning..." end

        -- update progress
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("TextLabel") then
                local cur,max=v.Text:match("([%d%.]+)kg/([%d%.]+)kg")
                if cur and max then
                    progLbl.Text=cur.."kg / "..max.."kg"
                    break
                end
            end
        end

        if CFG.autoCollect then doCollect() end
        if CFG.autoSubmit  then doSubmit()  end
    end
end)

setStatus("loaded ✓")
print("[AnubisQuest] collect + submit verified — ready")Lbl.BackgroundTransparency = 1
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
