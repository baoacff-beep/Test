-- ==========================================================
-- 🏴‍☠️ BLOX FRUITS - NVB HUB (FIXED UI & OPTIMIZED SPEED)
-- ==========================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Danh sách lưu lại các Server đã ghé qua để tránh bị lặp lại server cũ
local VisitedServers = {}
table.insert(VisitedServers, game.JobId)

-- 1. Tự động chọn phe Hải tặc ngay khi vào game
task.spawn(function()
    pcall(function()
        if not LocalPlayer.Team then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
        end
    end)
end)

-- Lấy số dư tiền chuẩn của nhân vật
local function GetCurrentBeli()
    local success, beli = pcall(function()
        return LocalPlayer.Data.Beli.Value
    end)
    if success then return beli end
    return 0
end

local sessionStartBeli = GetCurrentBeli()

-- Tạo giao diện (UI) trực quan và khắc phục triệt để lỗi không hiển thị
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("NVBHubChest") then PlayerGui.NVBHubChest:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NVBHubChest"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999 -- Đảm bảo UI luôn hiển thị ở lớp trên cùng

-- Nút Thu nhỏ / Mở rộng Menu (Floating Toggle Button)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 38)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 200)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "⚡ NVB HUB MENU"
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 8)
UICornerBtn.Parent = ToggleButton

local UIStrokeBtn = Instance.new("UIStroke")
UIStrokeBtn.Color = Color3.fromRGB(0, 255, 200)
UIStrokeBtn.Thickness = 1.5
UIStrokeBtn.Parent = ToggleButton

-- Khung Menu Chính (Được ép hiện hiển thị rõ ràng)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0, 20, 0, 70)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true -- Ép hiển thị, không sợ bị ẩn
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 200)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Tiêu đề Giao diện
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 35)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "⚡ NVB HUB - CHEST FARM"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 6
TitleLabel.Parent = MainFrame

-- Nút Đóng Menu (Close Button - X)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 26, 0, 26)
CloseButton.Position = UDim2.new(1, -32, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 12
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.ZIndex = 6
CloseButton.Parent = MainFrame

local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 6)
UICornerClose.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Dòng trạng thái
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Trạng thái: Đang khởi tạo..."
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 6
StatusLabel.Parent = MainFrame

-- Ô hiển thị tiền kiếm được trong Server này
local ServerMoneyLabel = Instance.new("TextLabel")
ServerMoneyLabel.Size = UDim2.new(1, -20, 0, 25)
ServerMoneyLabel.Position = UDim2.new(0, 10, 0, 75)
ServerMoneyLabel.BackgroundTransparency = 1
ServerMoneyLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
ServerMoneyLabel.TextSize = 12
ServerMoneyLabel.Font = Enum.Font.GothamBold
ServerMoneyLabel.Text = "💰 Tiền ở Server này: 0 Beli"
ServerMoneyLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerMoneyLabel.ZIndex = 6
ServerMoneyLabel.Parent = MainFrame

-- Ô hiển thị Tổng số tiền thực tế hiện có của người chơi
local TotalMoneyLabel = Instance.new("TextLabel")
TotalMoneyLabel.Size = UDim2.new(1, -20, 0, 25)
TotalMoneyLabel.Position = UDim2.new(0, 10, 0, 110)
TotalMoneyLabel.BackgroundTransparency = 1
TotalMoneyLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
TotalMoneyLabel.TextSize = 12
TotalMoneyLabel.Font = Enum.Font.GothamBold
TotalMoneyLabel.Text = "💎 Tổng số tiền của bạn: 0 Beli"
TotalMoneyLabel.TextXAlignment = Enum.TextXAlignment.Left
TotalMoneyLabel.ZIndex = 6
TotalMoneyLabel.Parent = MainFrame

-- Hàm định dạng số có dấu phẩy
local function formatNumber(amount)
    local formatted = tostring(amount)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Cập nhật thông số tiền liên tục
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local currentBeli = GetCurrentBeli()
            local currentServerEarned = currentBeli - sessionStartBeli
            
            ServerMoneyLabel.Text = "💰 Tiền ở Server này: " .. formatNumber(currentServerEarned) .. " Beli"
            TotalMoneyLabel.Text = "💎 Tổng số tiền của bạn: " .. formatNumber(currentBeli) .. " Beli"
        end)
    end
end)

local function IsVisited(id)
    for _, v in ipairs(VisitedServers) do
        if v == id then return true end
    end
    return false
end

-- Hàm Smart Server Hop
local function ServerHop()
    StatusLabel.Text = "🔄 Đang tìm Server mới có rương..."
    task.wait(0.5)
    
    local PlaceId = game.PlaceId
    local apiUrl = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, response = pcall(function()
        return game:HttpGet(apiUrl)
    end)
    
    if success and response then
        local servers = HttpService:JSONDecode(response)
        if servers and servers.data then
            for _, server in ipairs(servers.data) do
                if type(server) == "table" and server.playing and server.maxPlayers then
                    if server.playing >= 2 and server.playing < server.maxPlayers - 2 and not IsVisited(server.id) then
                        table.insert(VisitedServers, server.id)
                        StatusLabel.Text = "🚀 Đang chuyển đến Server mới..."
                        TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                        task.wait(4)
                    end
                end
            end
        end
    end
    
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

-- Chống trọng lực và giữ trạng thái tàng hình/xuyên tường an toàn
RunService.Stepped:Connect(function()
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(11)
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end)

-- Hàm quét và thu thập toàn bộ rương với tốc độ chuẩn 0.10s
local function AutoChest()
    -- Dừng chờ 3 giây khi vừa vào server mới để toàn bộ rương kịp load đầy đủ
    task.wait(3)
    
    local chests = {}
    
    -- Quét toàn bộ Workspace để tìm tất cả các loại rương
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower():find("chest") and v:IsA("BasePart") then
            table.insert(chests, v)
        end
    end
    
    -- Nếu tổng số rương quét được quá ít (< 3), đổi server ngay
    if #chests < 3 then
        StatusLabel.Text = "⚠️ Server này quá ít rương! Đang đổi..."
        task.wait(0.5)
        ServerHop()
        return
    end

    StatusLabel.Text = "🎯 Đã quét được " .. #chests .. " rương. Đang thu thập..."
    
    for i, chest in ipairs(chests) do
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and chest and chest.Parent then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                
                -- Teleport chuẩn xác lên trên rương
                hrp.CFrame = chest.CFrame + Vector3.new(0, 3, 0)
                
                -- Kích hoạt chạm rương để nhận tiền
                if firetouchinterest then
                    firetouchinterest(hrp, chest, 0)
                    firetouchinterest(hrp, chest, 1)
                end
                
                -- Tốc độ chuẩn xác (0.10s mỗi rương) giúp mượt mà và không bị mất rương
                task.wait(0.10)
                StatusLabel.Text = "📦 Đã nhặt: " .. i .. " / " .. #chests .. " rương"
            end
        end)
    end
    
    -- Sau khi vét sạch toàn bộ rương trong server này -> Cập nhật tiền và đổi server mới
    sessionStartBeli = GetCurrentBeli()
    ServerHop()
end

-- Khởi chạy vòng lặp chính
task.spawn(function()
    repeat task.wait(1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    task.wait(1)
    while true do
        AutoChest()
        task.wait(0.5)
    end
end)
