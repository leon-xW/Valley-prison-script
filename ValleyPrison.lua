local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Valley Prison | V2",
   LoadingTitle = "loding",
   LoadingSubtitle = "Raycast Precision Enabled",
   ConfigurationSaving = {Enabled = false}
})

-- الإعدادات
local Settings = {
    Aimbot = false,
    FOV = 150,
    TeamCheck = true,
    WallCheck = false,
    ESP_Enabled = false
}

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- [1] POV Circle (UI Based)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local FOVFrame = Instance.new("Frame", ScreenGui)
FOVFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
FOVFrame.Visible = false
local UIStroke = Instance.new("UIStroke", FOVFrame)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255, 0, 0)
local UICorner = Instance.new("UICorner", FOVFrame)
UICorner.CornerRadius = UDim.new(1, 0)

-- [2] Mobile Toggle Button
local ToggleGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local ToggleBtn = Instance.new("TextButton", ToggleGui)
ToggleBtn.Size = UDim2.new(0, 90, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 0, 200)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleBtn.Text = "Aim: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", ToggleBtn)

ToggleBtn.MouseButton1Click:Connect(function()
    Settings.Aimbot = not Settings.Aimbot
    ToggleBtn.Text = Settings.Aimbot and "Aim: ON" or "Aim: OFF"
    ToggleBtn.BackgroundColor3 = Settings.Aimbot and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- [3] Fixed Wall Check Function (Raycast Method)
local function IsVisible(TargetPart)
    if not Settings.WallCheck then return true end -- إذا كان الفحص مغلقاً، نعتبره مرئياً دائماً
    
    local Character = TargetPart.Parent
    local RayOrigin = Camera.CFrame.Position
    local RayDirection = (TargetPart.Position - RayOrigin).Unit * (TargetPart.Position - RayOrigin).Magnitude
    
    local RayParams = RaycastParams.new()
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, Character, Camera} -- تجاهل لاعبك والهدف نفسه والكاميرا
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.IgnoreWater = true
    
    local Result = workspace:Raycast(RayOrigin, RayDirection, RayParams)
    
    if Result then
        -- إذا اصطدم الشعاع بشيء ما (جدار مثلاً) قبل الوصول للهدف
        return false
    end
    return true
end

-- [4] Highlight ESP System
local function ApplyESP(Player)
    if Player == LocalPlayer then return end
    local function Update()
        local Char = Player.Character
        if Char then
            local Highlight = Char:FindFirstChild("ESPHighlight") or Instance.new("Highlight", Char)
            Highlight.Name = "ESPHighlight"
            Highlight.Enabled = Settings.ESP_Enabled
            Highlight.FillColor = Player.TeamColor.Color
            Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    Player.CharacterAdded:Connect(Update)
    if Player.Character then Update() end
end
for _, v in pairs(Players:GetPlayers()) do ApplyESP(v) end
Players.PlayerAdded:Connect(ApplyESP)

-- [5] Targeting Logic
local function GetClosest()
    local Target = nil
    local MaxDist = Settings.FOV
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
            
            local Pos, OnScreen = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if OnScreen then
                local Dist = (Vector2.new(Pos.X, Pos.Y) - Center).Magnitude
                if Dist < MaxDist then
                    -- استدعاء فحص الجدار المطور هنا
                    if IsVisible(v.Character.Head) then
                        Target = v
                        MaxDist = Dist
                    end
                end
            end
        end
    end
    return Target
end

-- [6] Tabs
local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visuals")

CombatTab:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Callback = function(Value) Settings.Aimbot = Value end,
})

CombatTab:CreateToggle({
   Name = "Show POV",
   CurrentValue = false,
   Callback = function(Value) FOVFrame.Visible = Value end,
})

CombatTab:CreateSlider({
   Name = "POV Size",
   Range = {50, 800},
   Increment = 1,
   CurrentValue = 150,
   Callback = function(Value) 
       Settings.FOV = Value 
       FOVFrame.Size = UDim2.new(0, Value * 2, 0, Value * 2)
   end,
})

CombatTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = true,
   Callback = function(Value) Settings.TeamCheck = Value end,
})

CombatTab:CreateToggle({
   Name = "Wall Check (Well Check)",
   CurrentValue = false,
   Callback = function(Value) Settings.WallCheck = Value end,
})

VisualTab:CreateToggle({
   Name = "Enable Highlight ESP",
   CurrentValue = false,
   Callback = function(Value) 
       Settings.ESP_Enabled = Value 
       for _, p in pairs(Players:GetPlayers()) do
           if p.Character and p.Character:FindFirstChild("ESPHighlight") then
               p.Character.ESPHighlight.Enabled = Value
           end
       end
   end,
})

-- [7] Main Loop
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot then
        local Target = GetClosest()
        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Target.Character.Head.Position)
        end
    end
end)
