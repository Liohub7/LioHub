-- Yurikos | Horseman Wisp (Walk + Noclip)
local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Hunt = RS:WaitForChild("GameEvents"):WaitForChild("Events")
    :WaitForChild("Halloween2026Event"):WaitForChild("HorsemanHunt")

local autoWisp = false
local noclipConn = nil

pcall(function()
    local o = LP.PlayerGui:FindFirstChild("YurikosHorseman")
    if o then o:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "YurikosHorseman"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.02, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 18, 12)
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(80, 40, 10)
title.Text = "Yurikos | Wisp Noclip"
title.TextColor3 = Color3.fromRGB(255, 160, 60)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.9, 0, 0, 16)
lbl.Position = UDim2.new(0.05, 0, 1, -20)
lbl.BackgroundTransparency = 1
lbl.Text = "idle"
lbl.TextColor3 = Color3.fromRGB(200, 180, 150)
lbl.Font = Enum.Font.Gotham
lbl.TextSize = 11
lbl.Parent = frame

local function st(t) lbl.Text = t end

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.9, 0, 0, 34)
btn.Position = UDim2.new(0.05, 0, 0, 36)
btn.BackgroundColor3 = Color3.fromRGB(50, 35, 25)
btn.Text = "Auto Collect Wisp: OFF"
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local function setNoclip(on)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not on then
        -- restore
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
        return
    end
    noclipConn = RunService.Stepped:Connect(function()
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)
end

btn.MouseButton1Click:Connect(function()
    autoWisp = not autoWisp
    btn.Text = autoWisp and "Auto Collect Wisp: ON" or "Auto Collect Wisp: OFF"
    btn.BackgroundColor3 = autoWisp and Color3.fromRGB(40,120,50) or Color3.fromRGB(50,35,25)
    setNoclip(autoWisp)
end)

local function hrp()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function collect(id)
    pcall(function()
        Hunt.Collect:FireServer(1, id)
    end)
end

task.spawn(function()
    while true do
        task.wait(0.18)
        if not autoWisp then continue end

        local root = hrp()
        local h = hum()
        if not root or not h then continue end

        local list = {}
        for _, v in ipairs(workspace:GetDescendants()) do
            local n = string.lower(v.Name)
            if string.find(n, "wisp") then
                local p = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                if p and p.Parent then
                    table.insert(list, {
                        p = p,
                        d = (p.Position - root.Position).Magnitude
                    })
                end
            end
        end
        table.sort(list, function(a,b) return a.d < b.d end)

        if #list == 0 then
            st("no wisp")
            for id = 1, 40 do collect(id) end
            continue
        end

        local item = list[1]
        st("walk d=" .. math.floor(item.d))
        h:MoveTo(item.p.Position)

        if item.d < 14 then
            for id = 1, 40 do collect(id) end
            st("collect")
            task.wait(0.25)
        end
    end
end)

-- noclip ikut mati kalau character respawn
LP.CharacterAdded:Connect(function()
    if autoWisp then
        task.wait(0.5)
        setNoclip(true)
    end
end)

print("[Yurikos] Wisp Walk + Noclip ready")
