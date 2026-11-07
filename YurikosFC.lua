-- language: Lua | executor: Delta / KRNL / Synapse
-- Grow a Garden | Anubis Quest — full plant type lookup

local RS = game:GetService("ReplicatedStorage")
local GE = RS:WaitForChild("GameEvents")

local CollectRE = GE:WaitForChild("Crops"):WaitForChild("Collect")
local SubmitRE  = GE:WaitForChild("Events")
                   :WaitForChild("AnubisEvent")
                   :WaitForChild("AncientArc")
                   :WaitForChild("Submit")

-- ══════════════════════════
-- PLANT TYPE LOOKUP TABLE
-- source: stealthygaming.com/all-plant-types-grow-a-garden-roblox
-- ══════════════════════════
local PLANT_TYPES = {
    -- Berry
    ["strawberry"]={"berry","fruit","sweet","summer"},
    ["blueberry"]={"berry","fruit","sweet","summer"},
    ["sunbulb"]={"berry","sour"},
    ["raspberry"]={"berry","fruit","sweet"},
    ["blue raspberry"]={"berry","fruit","sweet"},
    ["cranberry"]={"berry","fruit","sour"},
    ["lingonberry"]={"berry","woody","prehistoric"},
    ["pyracantha"]={"berry","flower","stalky"},
    ["willowberry"]={"berry","fruit","woody"},
    ["celestiberry"]={"berry","fruit","leafy","night"},
    ["grape"]={"berry","fruit","sweet"},
    ["elder strawberry"]={"berry","fruit","sweet"},
    ["white mulberry"]={"berry","fruit"},

    -- Blossom
    ["bone blossom"]={"blossom","flower","prehistoric"},
    ["candy blossom"]={"blossom","flower","candy","sweet"},
    ["cherry blossom"]={"blossom","flower"},
    ["moon blossom"]={"blossom","flower","night","woody","leafy"},

    -- Candy
    ["chocolate carrot"]={"candy","vegetable","summer","root"},
    ["easter egg"]={"candy","sweet"},
    ["red lollipop"]={"candy","sweet"},
    ["sugarglaze"]={"candy","sweet","stalky"},
    ["candy sunflower"]={"candy","sweet","flower"},

    -- Flower (61 total)
    ["artichoke"]={"flower","vegetable","leafy"},
    ["bee balm"]={"flower","leafy"},
    ["briar rose"]={"flower","spicy"},
    ["broccoli"]={"flower","vegetable"},
    ["burning bud"]={"flower","stalky"},
    ["calla lily"]={"flower"},
    ["crocus"]={"flower"},
    ["crown of thorns"]={"flower","prickly"},
    ["cyclamen"]={"flower","leafy"},
    ["daffodil"]={"flower"},
    ["dandelion"]={"flower","stalky"},
    ["delphinium"]={"flower","summer"},
    ["dezen"]={"flower","zen"},
    ["ember lily"]={"flower","spicy"},
    ["firework flower"]={"flower","magical"},
    ["flare daisy"]={"flower","zen"},
    ["foxglove"]={"flower","toxic"},
    ["grand volcania"]={"flower","spicy","stalky","prehistoric"},
    ["hinomai"]={"flower","stalky","zen"},
    ["honeysuckle"]={"flower","leafy"},
    ["horned melon"]={"flower","prickly","sour"},
    ["lavender"]={"flower"},
    ["liberty lily"]={"flower"},
    ["lilac"]={"flower","leafy"},
    ["lily of the valley"]={"flower","stalky","leafy"},
    ["lotus"]={"flower","stalky"},
    ["manuka flower"]={"flower"},
    ["monoblooma"]={"flower","zen"},
    ["moonflower"]={"flower","night","leafy"},
    ["nightshade"]={"flower","night","toxic"},
    ["noble flower"]={"flower","leafy"},
    ["orange tulip"]={"flower"},
    ["paradise petal"]={"flower","prehistoric"},
    ["parasol flower"]={"flower","tropical","summer","leafy"},
    ["peace lily"]={"flower","summer"},
    ["pink lily"]={"flower","leafy"},
    ["pixie faern"]={"flower","fruit","sweet","leafy","magical"},
    ["purple dahlia"]={"flower","leafy"},
    ["rafflesia"]={"flower","leafy","toxic"},
    ["rose"]={"flower"},
    ["rosy delight"]={"flower","leafy","summer"},
    ["sakura bush"]={"flower","zen"},
    ["serenity"]={"flower","leafy","zen"},
    ["soft sunshine"]={"flower","zen"},
    ["spirit flower"]={"flower","magical"},
    ["stonebite"]={"flower","stalky","prehistoric"},
    ["succulent"]={"flower"},
    ["suncoil"]={"flower"},
    ["sunflower"]={"flower","leafy"},
    ["taro flower"]={"flower","vegetable","zen","root"},
    ["tranquil bloom"]={"flower","leafy","magical","zen"},
    ["untold bell"]={"flower","stalky","leafy","vegetable","sweet","magical"},
    ["urchin plant"]={"flower","stalky","leafy"},
    ["veinpetal"]={"flower","stalky"},
    ["zenflare"]={"flower","zen"},
    ["flare melon"]={"sour","stalky"},

    -- Fruit (56 total)
    ["ackee"]={"fruit","tropical","toxic"},
    ["apple"]={"fruit","woody","leafy"},
    ["avocado"]={"fruit","woody","summer"},
    ["banana"]={"fruit","tropical","sweet","summer"},
    ["bitter melon"]={"fruit"},
    ["blood banana"]={"fruit","night","leafy"},
    ["canary melon"]={"fruit","sweet"},
    ["cantaloupe"]={"fruit","leafy","summer"},
    ["cocomango"]={"fruit","tropical","woody","sweet","sour"},
    ["coconut"]={"fruit","tropical","woody"},
    ["cocovine"]={"fruit","tropical","woody","stalky"},
    ["corn"]={"fruit","vegetable","stalky","violet corn"},
    ["crown melon"]={"fruit","sweet"},
    ["dragon fruit"]={"fruit","prickly","tropical"},
    ["durian"]={"fruit","prickly","tropical","woody"},
    ["eggplant"]={"fruit","vegetable","leafy"},
    ["feijoa"]={"fruit","woody","summer"},
    ["grand tomato"]={"fruit","vegetable","leafy"},
    ["green apple"]={"fruit","woody","leafy","summer"},
    ["guanabana"]={"fruit","summer"},
    ["hive fruit"]={"fruit","woody","leafy"},
    ["kiwi"]={"fruit","woody","leafy","sour","summer"},
    ["lemon"]={"fruit","sour"},
    ["lime"]={"fruit","sour"},
    ["loquat"]={"fruit","woody","summer"},
    ["mango"]={"fruit","tropical","woody","leafy"},
    ["mangosteen"]={"fruit","woody","leafy","sour"},
    ["maple apple"]={"fruit","woody","sweet","zen"},
    ["moon mango"]={"fruit","night","leafy"},
    ["moon melon"]={"fruit","night","sweet"},
    ["nectarine"]={"fruit","woody","leafy"},
    ["papaya"]={"fruit","tropical","spicy","woody"},
    ["passionfruit"]={"fruit","tropical","sour","summer"},
    ["peach"]={"fruit","woody","leafy","sweet","summer"},
    ["pear"]={"fruit","woody","leafy","sweet","summer"},
    ["pineapple"]={"fruit","prickly","tropical","sweet","leafy","summer"},
    ["pricklefruit"]={"fruit","prickly","stalky"},
    ["prickly pear"]={"fruit","prickly","summer"},
    ["pumpkin"]={"fruit","vegetable","leafy"},
    ["starfruit"]={"fruit","tropical","leafy","sweet","sour","night"},
    ["sugar apple"]={"fruit","woody","leafy","sweet","summer"},
    ["tomato"]={"fruit","vegetable","leafy","summer"},
    ["traveler's fruit"]={"fruit","leafy","woody","summer"},
    ["violet corn"]={"fruit","vegetable","stalky"},
    ["watermelon"]={"fruit","tropical","leafy","summer","sweet"},
    ["spiked mango"]={"fruit","prickly","woody","sweet","zen"},

    -- Fungus
    ["duskpuff"]={"fungus","woody"},
    ["glowshroom"]={"fungus","stalky","night"},
    ["horned dinoshroom"]={"fungus","prehistoric","spicy","stalky","prickly","toxic"},
    ["mega mushroom"]={"fungus","stalky"},
    ["merica mushroom"]={"fungus"},
    ["mushroom"]={"fungus","stalky"},
    ["nectarshade"]={"fungus"},
    ["sinisterdrip"]={"fungus","toxic"},

    -- Prickly extras
    ["aloe vera"]={"prickly","summer"},
    ["cactus"]={"prickly"},
    ["glowthorn"]={"prickly","night","toxic"},
    ["nectar thorn"]={"prickly","sweet"},
    ["princess thorn"]={"prickly","leafy"},
    ["twisted tangle"]={"prickly"},
    ["venus fly trap"]={"prickly"},

    -- Vegetable extras
    ["badlands pepper"]={"vegetable","spicy"},
    ["beanstalk"]={"vegetable","leafy","stalky"},
    ["bell pepper"]={"vegetable","summer"},
    ["brussels sprout"]={"vegetable","stalky","leafy"},
    ["carrot"]={"vegetable","root","summer"},
    ["cauliflower"]={"vegetable","leafy","summer"},
    ["dragon pepper"]={"vegetable","spicy"},
    ["jalapeno"]={"vegetable","spicy"},
    ["king cabbage"]={"vegetable","leafy","magical"},
    ["mandrake"]={"vegetable","root","magical","leafy"},
    ["mint"]={"vegetable","night"},
    ["mutant carrot"]={"vegetable","stalky","root"},
    ["onion"]={"vegetable","root"},
    ["pepper"]={"vegetable","spicy"},
    ["potato"]={"vegetable","root"},
    ["purple cabbage"]={"vegetable","leafy"},
    ["radish"]={"vegetable","root","spicy"},
    ["rhubarb"]={"vegetable","root","woody"},
    ["romanesco"]={"vegetable","sweet"},
    ["snaparino beanarini"]={"vegetable"},
    ["tall asparagus"]={"vegetable","stalky","root"},
    ["wild carrot"]={"vegetable","root","summer"},

    -- Spicy extras
    ["cacao"]={"spicy","woody"},
    ["taco fern"]={"spicy"},

    -- Woody extras
    ["aetherfruit"]={"woody","leafy","magical"},
    ["amberheart"]={"woody","magical"},
    ["aurora vine"]={"woody","root","magical"},
    ["bamboo"]={"woody","stalky"},
    ["bendboo"]={"woody","stalky"},
    ["boneboo"]={"woody","stalky","prehistoric"},
    ["giant pinecone"]={"woody","leafy"},
    ["gleamroot"]={"woody","night"},
    ["glowpod"]={"woody","leafy","night"},
    ["lucky bamboo"]={"woody","stalky","zen"},

    -- Tropical extras
    ["poseidon plant"]={"stalky","tropical"},

    -- Zen extras
    ["enkaku"]={"zen"},
    ["zen rocks"]={"zen"},

    -- Night extras
    ["lightshoot"]={"night","stalky"},

    -- Magical extras
    ["cursed fruit"]={"magical","spicy","toxic"},
    ["emerald bud"]={"magical"},
    ["fossilight"]={"magical","prehistoric"},
    ["golden egg"]={"magical"},
    ["soul fruit"]={"magical"},
    ["wispwing"]={"magical"},

    -- Prehistoric extras
    ["amber spine"]={"prehistoric","toxic"},
    ["horsetail"]={"prehistoric","root"},

    -- Leafy extras
    ["elephant ears"]={"leafy","stalky","summer"},
    ["firefly fern"]={"leafy","prehistoric","stalky"},
    ["lumira"]={"leafy"},
    ["mint"]={"leafy","vegetable","night"},
    ["pitcher plant"]={"leafy","stalky","summer","toxic"},
    ["spring onion"]={"stalky","root"},
    ["twisted tangle"]={"prickly","leafy"},
}

-- ══════════════════════════
-- CHECK IF PLANT MATCHES TYPE
-- ══════════════════════════
local function plantMatchesType(plantName, wantedType)
    if not wantedType or wantedType == "" then return true end
    local key = plantName:lower()
    local wantLower = wantedType:lower()
    local types = PLANT_TYPES[key]
    if not types then
        -- fallback: cek partial match nama
        return key:find(wantLower, 1, true) ~= nil
    end
    for _, t in ipairs(types) do
        if t:find(wantLower, 1, true) then return true end
    end
    return false
end

-- ══════════════════════════
-- CONFIG
-- ══════════════════════════
local CFG = {
    autoCollect  = false,
    autoSubmit   = false,
    collectDelay = 0.8,
    submitDelay  = 3.5,
}
local lastCollect, lastSubmit = 0, 0

-- ══════════════════════════
-- READ NPC WANT
-- ══════════════════════════
local function readNPCWant()
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
-- GET TOKEN
-- ══════════════════════════
local function getToken()
    local ok, val = pcall(function()
        return GE.Events.AnubisEvent.AncientArc:FindFirstChild("Token")
    end)
    if ok and val and val:IsA("IntValue") then return val.Value end
    return 3
end

-- ══════════════════════════
-- COLLECT — nil instance + full type filter
-- ══════════════════════════
local function doCollect()
    if tick() - lastCollect < CFG.collectDelay then return end
    lastCollect = tick()
    if not getnilinstances then setStatus("❌ getnilinstances tidak support") return end

    local want  = readNPCWant()
    local count = 0

    -- dapatkan semua nama tanaman valid dari Plants_Physical
    local validNames = {}
    local pp = workspace:FindFirstChild("Farm")
    if pp then pp = pp:FindFirstChild("Farm") end
    if pp then pp = pp:FindFirstChild("Important") end
    if pp then pp = pp:FindFirstChild("Plants_Physical") end
    if pp then
        for _, p in ipairs(pp:GetChildren()) do
            validNames[p.Name:lower()] = true
        end
    end

    for _, v in ipairs(getnilinstances()) do
        if v.ClassName == "Model" then
            local nameLower = v.Name:lower()
            -- harus ada di farm player
            local inFarm = next(validNames) == nil or validNames[nameLower]
            if inFarm and plantMatchesType(v.Name, want) then
                pcall(function() CollectRE:FireServer({v}) end)
                count = count + 1
                task.wait(0.05)
            end
        end
    end

    local label = want or "all"
    setStatus(count > 0
        and "✓ collected "..count.." "..label
        or  "menunggu "..label.." harvest")
end

-- ══════════════════════════
-- SUBMIT
-- ══════════════════════════
local function doSubmit()
    if tick() - lastSubmit < CFG.submitDelay then return end
    lastSubmit = tick()
    pcall(function()
        SubmitRE:FireServer({Token=getToken(), Mode="All"})
    end)
    setStatus("✓ submitted | token="..getToken())
end

-- ══════════════════════════
-- GUI
-- ══════════════════════════
if game.CoreGui:FindFirstChild("QuestUI") then game.CoreGui.QuestUI:Destroy() end
local guiParent = (typeof(gethui)=="function") and gethui() or game.CoreGui

local gui = Instance.new("ScreenGui")
gui.Name="QuestUI"; gui.ResetOnSpawn=false; gui.Parent=guiParent

local main=Instance.new("Frame")
main.Size=UDim2.new(0,232,0,295); main.Position=UDim2.new(0,14,0.22,0)
main.BackgroundColor3=Color3.fromRGB(10,12,20); main.BorderSizePixel=0
main.Active=true; main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,8)

local drag,ds,sp=false,nil,nil
main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true;ds=i.Position;sp=main.Position end
end)
main.InputChanged:Connect(function(i)
    if drag and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-ds
        main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end
end)
main.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)

local hdr=Instance.new("Frame",main)
hdr.Size=UDim2.new(1,0,0,34); hdr.BackgroundColor3=Color3.fromRGB(18,20,36); hdr.BorderSizePixel=0
Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,8)
local htxt=Instance.new("TextLabel",hdr)
htxt.Size=UDim2.new(1,-10,1,0); htxt.Position=UDim2.new(0,10,0,0)
htxt.BackgroundTransparency=1; htxt.Font=Enum.Font.GothamBold; htxt.TextSize=12
htxt.TextColor3=Color3.fromRGB(200,170,80); htxt.TextXAlignment=Enum.TextXAlignment.Left
htxt.Text="𓂀  ANUBIS QUEST"

local wantLbl=Instance.new("TextLabel",main)
wantLbl.Size=UDim2.new(1,-16,0,20); wantLbl.Position=UDim2.new(0,8,0,38)
wantLbl.BackgroundTransparency=1; wantLbl.Font=Enum.Font.GothamBold; wantLbl.TextSize=11
wantLbl.TextColor3=Color3.fromRGB(100,220,140); wantLbl.TextXAlignment=Enum.TextXAlignment.Left
wantLbl.Text="NPC wants: scanning..."

local progLbl=Instance.new("TextLabel",main)
progLbl.Size=UDim2.new(1,-16,0,16); progLbl.Position=UDim2.new(0,8,0,58)
progLbl.BackgroundTransparency=1; progLbl.Font=Enum.Font.Code; progLbl.TextSize=10
progLbl.TextColor3=Color3.fromRGB(150,160,200); progLbl.TextXAlignment=Enum.TextXAlignment.Left
progLbl.Text="progress: —"

local statusLbl=Instance.new("TextLabel",main)
statusLbl.Size=UDim2.new(1,-16,0,18); statusLbl.Position=UDim2.new(0,8,1,-24)
statusLbl.BackgroundTransparency=1; statusLbl.Font=Enum.Font.Code; statusLbl.TextSize=10
statusLbl.TextColor3=Color3.fromRGB(80,90,130); statusLbl.TextXAlignment=Enum.TextXAlignment.Left
statusLbl.Text="ready"
function setStatus(m) statusLbl.Text=m end

local COL_OFF=Color3.fromRGB(22,25,42); local COL_ON=Color3.fromRGB(50,55,120)
local TXT_OFF=Color3.fromRGB(140,145,185); local TXT_ON=Color3.fromRGB(210,220,255)

local function makeToggle(label,yPos,onToggle)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(1,-16,0,34); b.Position=UDim2.new(0,8,0,yPos)
    b.BackgroundColor3=COL_OFF; b.TextColor3=TXT_OFF
    b.Font=Enum.Font.Gotham; b.TextSize=12; b.BorderSizePixel=0
    b.Text="  ○  "..label; b.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    local s=false
    b.MouseButton1Click:Connect(function()
        s=not s; b.BackgroundColor3=s and COL_ON or COL_OFF
        b.TextColor3=s and TXT_ON or TXT_OFF
        b.Text=(s and"  ●  "or"  ○  ")..label; onToggle(s)
    end)
end

local function manualBtn(label,col,tc,xScale,onClick)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(0.46,0,0,30); b.Position=UDim2.new(xScale,0,0,78)
    b.BackgroundColor3=col; b.TextColor3=tc
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0; b.Text=label
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(onClick)
end

manualBtn("⚡ Collect",Color3.fromRGB(20,60,30),Color3.fromRGB(100,220,140),0.04,doCollect)
manualBtn("📤 Submit", Color3.fromRGB(60,45,10),Color3.fromRGB(220,180,80),0.52,doSubmit)

makeToggle("Auto Collect",116,function(on) CFG.autoCollect=on end)
makeToggle("Auto Submit", 158,function(on) CFG.autoSubmit=on end)

task.spawn(function()
    while true do
        task.wait(1)
        local w=readNPCWant()
        wantLbl.Text="NPC wants: "..(w or "scanning...")
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("TextLabel") then
                local c,m=v.Text:match("([%d%.]+)kg/([%d%.]+)kg")
                if c and m then progLbl.Text=c.."kg / "..m.."kg"; break end
            end
        end
        if CFG.autoCollect then doCollect() end
        if CFG.autoSubmit  then doSubmit()  end
    end
end)

setStatus("loaded ✓ — "..tostring(#(function() local n=0; for _ in pairs(PLANT_TYPES) do n=n+1 end; return n end()).."plants mapped")
print("[AnubisQuest] full type lookup loaded")("TextLabel", main)
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
