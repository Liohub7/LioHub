-- Yurikos | Anubis (Submit fixed)
local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Submit = RS:WaitForChild("GameEvents"):WaitForChild("Events")
    :WaitForChild("AnubisEvent"):WaitForChild("AncientArc"):WaitForChild("Submit")

local autoQuest = false

pcall(function()
    local o = LP.PlayerGui:FindFirstChild("YurikosAnubis")
    if o then o:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "YurikosAnubis"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99
gui.Parent = LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 210, 0, 130)
frame.Position = UDim2.new(0.02, 0, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 18, 10)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(90, 60, 20)
title.Text = "Yurikos | Anubis"
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.9, 0, 0, 18)
lbl.Position = UDim2.new(0.05, 0, 1, -22)
lbl.BackgroundTransparency = 1
lbl.Text = "need: ?"
lbl.TextColor3 = Color3.fromRGB(220, 200, 160)
lbl.Font = Enum.Font.Gotham
lbl.TextSize = 11
lbl.Parent = frame

local function st(t)
    lbl.Text = t
end

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.9, 0, 0, 34)
btn.Position = UDim2.new(0.05, 0, 0, 36)
btn.BackgroundColor3 = Color3.fromRGB(50, 35, 20)
btn.Text = "Auto Quest: OFF"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 13
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
    autoQuest = not autoQuest
    if autoQuest then
        btn.Text = "Auto Quest: ON"
        btn.BackgroundColor3 = Color3.fromRGB(40, 120, 50)
    else
        btn.Text = "Auto Quest: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(50, 35, 20)
    end
end)

local function detectNeed()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, v in ipairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local t = v.Text or ""
                local m = string.match(t, "[Ll]ooking for%s+([%w%s%-]+)%s*plants?")
                if m then
                    m = string.gsub(m, "^%s+", "")
                    m = string.gsub(m, "%s+$", "")
                    return m
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("TextLabel") then
            local t = v.Text or ""
            local m = string.match(t, "[Ll]ooking for%s+([%w%s%-]+)%s*plants?")
            if m then
                m = string.gsub(m, "^%s+", "")
                m = string.gsub(m, "%s+$", "")
                return m
            end
        end
    end
    return nil
end

local function submitAll(token)
    token = token or 3
    pcall(function()
        Submit:FireServer({
            Token = token,
            Mode = "All"
        })
    end)
end

-- harvest GAG umum (Collect)
local function tryHarvest()
    pcall(function()
        local crops = RS.GameEvents:FindFirstChild("Crops")
        if crops and crops:FindFirstChild("Collect") then
            crops.Collect:FireServer()
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(1.0)
        local need = detectNeed()
        if need then
            st("need: " .. need)
        else
            st("need: ?")
        end

        if autoQuest then
            if need then
                st("harvest " .. need)
                tryHarvest()
                task.wait(0.5)
            end
            st("submit all")
            -- coba Token 1-5 (kadang beda)
            for t = 1, 5 do
                submitAll(t)
                task.wait(0.1)
            end
            task.wait(1.2)
        end
    end
end)

print("[Yurikos] Anubis Submit ready")
