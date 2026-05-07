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
    ESP_Enabled = false,
    ESP_Distance = 500
}

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- [1] POV Circle
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

-- [3] Wall Check
local function IsVisible(TargetPart)
    if not Settings.WallCheck then return true end 
    local RayParams = RaycastParams.new()
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, TargetPart.Parent, Camera} 
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    local Result = workspace:Raycast(Camera.CFrame.Position, (TargetPart.Position - Camera.CFrame.Position).Unit * (TargetPart.Position - Camera.CFrame.Position).Magnitude, RayParams)
    return Result == nil
end

-- [4] Full Dynamic ESP Filter (Inmate, Escape, Police)
local function ApplyESP(Player)
    if Player == LocalPlayer then return end
    
    RunService.RenderStepped:Connect(function()
        local Char = Player.Character
        local MyChar = LocalPlayer.Character
        
        if Char and Char:FindFirstChild("HumanoidRootPart") and MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
            local Highlight = Char:FindFirstChild("ESPHighlight") or Instance.new("Highlight", Char)
            Highlight.Name = "ESPHighlight"
            
            local Distance = (MyChar.HumanoidRootPart.Position - Char.HumanoidRootPart.Position).Magnitude
            
            local ShouldShow = false
            local MyTeam = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
            local TargetTeam = (Player.Team and Player.Team.Name:lower()) or ""

            -- تعريف المجموعات (سجناء وهاربين ضد شرطة)
            local IsMePrisonerOrEscape = MyTeam:find("inmate") or MyTeam:find("min") or MyTeam:find("med") or MyTeam:find("max") or MyTeam:find("escape") or MyTeam:find("crim")
            local IsTargetPrisonerOrEscape = TargetTeam:find("inmate") or TargetTeam:find("min") or TargetTeam:find("med") or TargetTeam:find("max") or TargetTeam:find("escape") or TargetTeam:find("crim")
            
            local IsMeCop = MyTeam:find("police") or MyTeam:find("guard") or MyTeam:find("department") or MyTeam:find("state")
            local IsTargetCop = TargetTeam:find("police") or TargetTeam:find("guard") or TargetTeam:find("department") or TargetTeam:find("state")

            -- تنفيذ المنطق المطور
            if IsMePrisonerOrEscape then
                -- إذا كنت سجين أو هارب: أظهر فقط الشرطة (احجب كل أنواع السجناء والهاربين الآخرين)
                if IsTargetCop then
                    ShouldShow = true
                else
                    ShouldShow = false
                end
            elseif IsMeCop then
                -- إذا كنت شرطي: أظهر السجناء والهاربين فقط، واحجب زملائك الشرطة
                if IsTargetPrisonerOrEscape then
                    ShouldShow = true
                else
                    ShouldShow = false
                end
            else
                -- لأي فريق آخر غير معرف: أظهر الخصوم فقط
                ShouldShow = (MyTeam ~= TargetTeam)
            end
            
            if Settings.ESP_Enabled and ShouldShow and Distance <= Settings.ESP_Distance then
                Highlight.Enabled = true
                Highlight.FillColor = Player.TeamColor.Color
                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                Highlight.Enabled = false
            end
        elseif Char and Char:FindFirstChild("ESPHighlight") then
            Char.ESPHighlight.Enabled = false
        end
    end)
end

for _, v in pairs(Players:GetPlayers()) do ApplyESP(v) end
Players.PlayerAdded:Connect(ApplyESP)

-- [5] Targeting Logic (Aimbot)
local function GetClosest()
    local Target = nil
    local MaxDist = Settings.FOV
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            if Settings.TeamCheck then
                local MyTeam = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
                local TargetTeam = (v.Team and v.Team.Name:lower()) or ""
                
                local IsMeC = MyTeam:find("police") or MyTeam:find("guard") or MyTeam:find("department")
                local IsTargetC = TargetTeam:find("police") or TargetTeam:find("guard") or TargetTeam:find("department")
                local IsMeP = MyTeam:find("inmate") or MyTeam:find("min") or MyTeam:find("med") or MyTeam:find("max") or MyTeam:find("escape")
                local IsTargetP = TargetTeam:find("inmate") or TargetTeam:find("min") or TargetTeam:find("med") or TargetTeam:find("max") or TargetTeam:find("escape")

                if (IsMeC and IsTargetC) or (IsMeP and IsTargetP) or (LocalPlayer.Team == v.Team) then 
                    continue 
                end
            end

            local Pos, OnScreen = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if OnScreen then
                local Dist = (Vector2.new(Pos.X, Pos.Y) - Center).Magnitude
                if Dist < MaxDist then
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
local TeleportTab = Window:CreateTab("Teleport")

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
   Name = "Wall Check",
   CurrentValue = false,
   Callback = function(Value) Settings.WallCheck = Value end,
})

VisualTab:CreateToggle({
   Name = "Enable Smart ESP",
   CurrentValue = false,
   Callback = function(Value) Settings.ESP_Enabled = Value end,
})

VisualTab:CreateSlider({
   Name = "ESP Max Distance",
   Range = {0, 5000},
   Increment = 10,
   CurrentValue = 500,
   Callback = function(Value) Settings.ESP_Distance = Value end,
})

TeleportTab:CreateButton({
   Name = "Teleport to Location 1",
   Callback = function()
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
           LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(290.6114807128906, 4.999999523162842, -316.0602111816406))
       end
   end,
})

TeleportTab:CreateButton({
   Name = "Teleport 2",
   Callback = function()
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
           LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(679.9663696289062, -0.6903573274612427, -438.9139709472656))
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
