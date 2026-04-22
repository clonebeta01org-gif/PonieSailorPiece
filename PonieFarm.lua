--[[
    Script: PonieFarm (Fly Mode)
    Tính năng: Auto Farm quái (có thể bay lơ lửng trên đầu quái), định vị, hiển thị thông tin.
    Sử dụng thư viện Venyx UI.
--]]

-- Tải thư viện UI
local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()

-- Tạo cửa sổ chính
local Window = Venyx:CreateWindow({
    Name = "PonieFarm",
    Theme = Venyx.Themes.Dark,
    Size = UDim2.new(0, 500, 0, 450),
    Position = UDim2.new(0.5, -250, 0.5, -225)
})

-- === Tab: Auto Farm ===
local FarmTab = Window:AddTab("Auto Farm")
local FarmSection = FarmTab:AddSection("Cài đặt Auto Farm")

-- Biến trạng thái
local AutoFarmEnabled = false
local FlyModeEnabled = false
local FlyHeight = 5   -- Độ cao cách đầu quái (đơn vị Roblox)
local FarmThread = nil
local CurrentTarget = nil

-- Hàm lấy quái gần nhất (tương tự như cũ)
local function GetNearestEnemy()
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local playerPos = player.Character.HumanoidRootPart.Position
    local nearest = nil
    local minDist = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
            if not game.Players:GetPlayerFromCharacter(obj) then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if root then
                    local dist = (root.Position - playerPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest, minDist
end

-- Hàm tấn công (phím E)
local function Attack()
    local VIM = game:GetService("VirtualInputManager")
    VIM:SendKeyEvent(true, "E", false, game)
    wait(0.1)
    VIM:SendKeyEvent(false, "E", false, game)
end

-- Hàm di chuyển đến quái (kiểu mặt đất)
local function MoveToEnemyGround(enemy)
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
    if enemyRoot then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(enemyRoot.Position + Vector3.new(3, 0, 3))
    end
end

-- Hàm di chuyển đến vị trí lơ lửng trên đầu quái
local function MoveToEnemyFly(enemy, height)
    local player = game.Players.LocalPlayer
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local enemyHead = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
    if enemyHead then
        local flyPos = enemyHead.Position + Vector3.new(0, height, 0)
        player.Character.HumanoidRootPart.CFrame = CFrame.new(flyPos)
    end
end

-- Vòng lặp Auto Farm (hỗ trợ fly mode)
local function AutoFarmLoop()
    while AutoFarmEnabled do
        local enemy, dist = GetNearestEnemy()
        if enemy then
            CurrentTarget = enemy
            if FlyModeEnabled then
                -- Bay lơ lửng trên đầu quái
                MoveToEnemyFly(enemy, FlyHeight)
            else
                -- Di chuyển mặt đất
                MoveToEnemyGround(enemy)
            end
            wait(0.2)
            Attack()
            wait(0.5)
        else
            wait(1)
        end
    end
    CurrentTarget = nil
end

-- Nút bật/tắt Auto Farm
FarmSection:AddToggle({
    Name = "Auto Farm",
    Callback = function(state)
        AutoFarmEnabled = state
        if AutoFarmEnabled then
            spawn(function() AutoFarmLoop() end)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "PonieFarm",
                Text = "Đã bật Auto Farm!",
                Duration = 2
            })
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "PonieFarm",
                Text = "Đã tắt Auto Farm.",
                Duration = 2
            })
        end
    end
})

-- Nút bật/tắt Fly Mode (lơ lửng)
FarmSection:AddToggle({
    Name = "Fly Mode (Lơ lửng trên đầu quái)",
    Callback = function(state)
        FlyModeEnabled = state
        local msg = state and "Bật chế độ bay lơ lửng" or "Tắt chế độ bay lơ lửng"
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PonieFarm",
            Text = msg,
            Duration = 2
        })
    end
})

-- Thanh trượt điều chỉnh độ cao (chỉ hiệu lực khi Fly Mode bật)
FarmSection:AddSlider({
    Name = "Độ cao bay (so với đầu quái)",
    Min = 2,
    Max = 15,
    Default = 5,
    Callback = function(value)
        FlyHeight = math.floor(value)
    end
})

-- === Tab: Định vị ===
local TeleportTab = Window:AddTab("Định vị")
local TeleSection = TeleportTab:AddSection("Teleport đến quái")

TeleSection:AddButton({
    Name = "Teleport đến quái gần nhất (mặt đất)",
    Callback = function()
        local enemy, _ = GetNearestEnemy()
        if enemy then
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
                if enemyRoot then
                    player.Character.HumanoidRootPart.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 2)
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "PonieFarm",
                        Text = "Đã teleport đến quái!",
                        Duration = 1
                    })
                end
            end
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "PonieFarm",
                Text = "Không tìm thấy quái!",
                Duration = 1
            })
        end
    end
})

TeleSection:AddButton({
    Name = "Teleport lên trên đầu quái (bay)",
    Callback = function()
        local enemy, _ = GetNearestEnemy()
        if enemy then
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local enemyHead = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
                if enemyHead then
                    local flyPos = enemyHead.Position + Vector3.new(0, FlyHeight, 0)
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(flyPos)
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "PonieFarm",
                        Text = "Đã bay lên trên đầu quái!",
                        Duration = 1
                    })
                end
            end
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "PonieFarm",
                Text = "Không tìm thấy quái!",
                Duration = 1
            })
        end
    end
})

-- === Tab: About ===
local AboutTab = Window:AddTab("About")
local InfoSection = AboutTab:AddSection("Thông tin người chơi")

local playerNameLabel = InfoSection:AddLabel("Tên: Đang tải...")
local levelExpLabel = InfoSection:AddLabel("Level/EXP: Đang tải...")
local moneyLabel = InfoSection:AddLabel("Tiền: Đang tải...")

local function UpdatePlayerInfo()
    local player = game.Players.LocalPlayer
    playerNameLabel:SetText("Tên: " .. player.Name)
    
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local levelObj = stats:FindFirstChild("Level") or stats:FindFirstChild("Lv")
        local expObj = stats:FindFirstChild("Exp") or stats:FindFirstChild("XP")
        local moneyObj = stats:FindFirstChild("Money") or stats:FindFirstChild("Cash") or stats:FindFirstChild("Beli")
        
        local levelText = levelObj and tostring(levelObj.Value) or "?"
        local expText = expObj and tostring(expObj.Value) or "?"
        levelExpLabel:SetText("Level: " .. levelText .. " | EXP: " .. expText)
        
        moneyLabel:SetText("Tiền: " .. (moneyObj and tostring(moneyObj.Value) or "?"))
    else
        levelExpLabel:SetText("Level/EXP: Không tìm thấy leaderstats")
        moneyLabel:SetText("Tiền: Không tìm thấy")
    end
end

spawn(function()
    while true do
        UpdatePlayerInfo()
        wait(2)
    end
end)

InfoSection:AddButton({
    Name = "Làm mới thông tin",
    Callback = function()
        UpdatePlayerInfo()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PonieFarm",
            Text = "Đã cập nhật thông tin!",
            Duration = 1
        })
    end
})

-- Thông báo khởi động
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "PonieFarm",
    Text = "Script đã sẵn sàng! (có Fly Mode)",
    Duration = 3
})