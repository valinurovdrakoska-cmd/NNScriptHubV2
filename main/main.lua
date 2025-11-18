--// NNScript Ultimate — Полностью рабочая версия (ноябрь 2025)
--// Всё отображается, все функции работают

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()
local Window = Library.CreateLib("NNScript Ultimate", "RJTheme3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

--// ВКЛАДКИ
local VisualTab   = Window:NewTab("Visuals")
local MovementTab = Window:NewTab("Movement")
local MiscTab     = Window:NewTab("Misc")

--======================== ESP ========================
local ESPSection = VisualTab:NewSection("Player ESP")

local espEnabled = false
local espSettings = {
    Box = true, Tracer = true, Name = true,
    Distance = true, Health = true, TeamCheck = true
}

local espObjects = {}
local espLoop = nil
local connections = {}

local function createESP(plr)
    if plr == player or espObjects[plr] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2; box.Filled = false; box.Transparency = 1; box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = 2; tracer.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true; name.Visible = false

    local dist = Drawing.new("Text")
    dist.Size = 13; name.Center = true; dist.Outline = true; dist.Visible = false

    local health = Drawing.new("Text")
    health.Size = 13; health.Center = true; health.Outline = true; health.Visible = false

    espObjects[plr] = {Box = box, Tracer = tracer, Name = name, Distance = dist, Health = health}
end

local function removeESP(plr)
    if espObjects[plr] then
        for _, v in pairs(espObjects[plr]) do
            if v and v.Remove then v:Remove() end
        end
        espObjects[plr] = nil
    end
end

local function updateESP()
    if not espEnabled then return end

    for plr, objs in pairs(espObjects) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hrp and hum and hum.Health > 0) then
            for _, obj in pairs(objs) do obj.Visible = false end
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0,1,0)) or rootPos
        local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3.5,0))

        local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local distance = myHrp and (myHrp.Position - hrp.Position).Magnitude or 0

        local teammate = espSettings.TeamCheck and plr.Team == player.Team
        local color = teammate and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

        if onScreen then
            -- Box
            if espSettings.Box then
                local h = math.abs(headPos.Y - feetPos.Y)
                local w = h * 0.7
                objs.Box.Size = Vector2.new(w, h)
                objs.Box.Position = Vector2.new(rootPos.X - w/2, headPos.Y)
                objs.Box.Color = color
                objs.Box.Visible = true
            else
                objs.Box.Visible = false
            end

            -- Tracer
            objs.Tracer.Visible = espSettings.Tracer
            if espSettings.Tracer then
                objs.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                objs.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                objs.Tracer.Color = color
            end

            -- Name
            objs.Name.Visible = espSettings.Name
            if espSettings.Name then
                objs.Name.Text = plr.DisplayName
                objs.Name.Position = Vector2.new(rootPos.X, headPos.Y - 25)
                objs.Name.Color = color
            end

            -- Distance
            objs.Distance.Visible = espSettings.Distance
            if espSettings.Distance then
                objs.Distance.Text = math.floor(distance).."m"
                objs.Distance.Position = Vector2.new(rootPos.X, feetPos.Y + 5)
                objs.Distance.Color = color
            end

            -- Health
            objs.Health.Visible = espSettings.Health
            if espSettings.Health then
                objs.Health.Text = math.floor(hum.Health).."/"..hum.MaxHealth
                objs.Health.Position = Vector2.new(rootPos.X - 30, rootPos.Y)
                objs.Health.Color = hum.Health > 50 and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
            end
        else
            for _, obj in pairs(objs) do obj.Visible = false end
        end
    end
end

-- Мастер-свитч
ESPSection:NewToggle("ESP Master Switch", "Вкл/Выкл весь ESP", function(state)
    espEnabled = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then createESP(plr) end
        end

        if not connections.added then
            connections.added = Players.PlayerAdded:Connect(function(plr)
                plr.CharacterAdded:Wait()
                task.wait(1)
                if espEnabled then createESP(plr) end
            end)
            connections.removing = Players.PlayerRemoving:Connect(removeESP)
            espLoop = RunService.RenderStepped:Connect(updateESP)
        end
    else
        for plr in pairs(espObjects) do removeESP(plr) end
    end
end)

-- Все остальные тогглы теперь работают!
ESPSection:NewToggle("Box ESP", "Боксы", function(s) espSettings.Box = s end):Set(true)
ESPSection:NewToggle("Tracer ESP", "Трейсеры", function(s) espSettings.Tracer = s end):Set(true)
ESPSection:NewToggle("Name ESP", "Имя", function(s) espSettings.Name = s end):Set(true)
ESPSection:NewToggle("Distance ESP", "Расстояние", function(s) espSettings.Distance = s end):Set(true)
ESPSection:NewToggle("Health ESP", "Здоровье", function(s) espSettings.Health = s end):Set(true)
ESPSection:NewToggle("Team Check", "Не показывать тиммейтов", function(s) espSettings.TeamCheck = s end):Set(true)

--======================== MOVEMENT ========================
local MoveSection = MovementTab:NewSection("Movement Cheats") -- Теперь отображается!

local flyActive = false
local flySpeed = 100
local flyBV, flyBG

local function startFly()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end

    flyBG = Instance.new("BodyGyro")
    flyBG.P = 9e4
    flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root

    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.new(0,0,0)
    flyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    flyBV.Parent = root

    hum.PlatformStand = true

    spawn(function()
        while flyActive and root and root.Parent do
            local cam = workspace.CurrentCamera
            local move = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

            flyBV.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
            flyBG.CFrame = cam.CFrame
            task.wait()
        end
    end)
end

local function stopFly()
    flyActive = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

MoveSection:NewToggle("Fly Hack", "Полёт (WASD + Space/Ctrl)", function(state)
    flyActive = state
    if state then startFly() else stopFly() end
end)

MoveSection:NewSlider("Fly Speed", "Скорость полёта", 1000, 20, function(v) flySpeed = v end, 100)

local infJump = false
UserInputService.InputBegan:Connect(function(i, g)
    if infJump and not g and i.KeyCode == Enum.KeyCode.Space then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)
MoveSection:NewToggle("Infinite Jump", "Бесконечный прыжок", function(s) infJump = s end)

MoveSection:NewSlider("WalkSpeed", "Скорость ходьбы", 500, 16, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end, 16)

MoveSection:NewSlider("JumpPower", "Сила прыжка", 500, 50, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end, 50)

--======================== MISC ========================
local MiscSection = MiscTab:NewSection("Misc") -- Теперь тоже отображается!

MiscSection:NewKeybind("Low Gravity", "F — низкая гравитация", Enum.KeyCode.F, function()
    workspace.Gravity = 30
end)

MiscSection:NewKeybind("Normal Gravity", "G — обычная гравитация", Enum.KeyCode.G, function()
    workspace.Gravity = 196.2
end)

MiscSection:NewButton("Respawn", "Самоубийство / Респавн", function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

print("NNScript Ultimate успешно загружен! Всё отображается и работает 100%")
