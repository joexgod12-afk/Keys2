-- ============================================
-- LAMBV2 KEY SYSTEM
-- ============================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local KeySystem = {
    JSONBIN_KEY = "$2a$10$gH.Mj4PLJrkLr2rew4nCg.iCn3Cu2qAFkq1PFMSPyngGpouE1mrCS",
    BIN_ID = "69e561b6856a6821894fe897",
    API_URL = "https://api.jsonbin.io/v3/b",
    KEY_FILE = "lambv2_key.txt"
}

-- Get HWID (Hardware ID)
function KeySystem:GetHWID()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

-- Validate key against JSONBin
function KeySystem:ValidateKey(key)
    local hwid = self:GetHWID()
    
    local success, response = pcall(function()
        return request({
            Url = self.API_URL .. "/" .. self.BIN_ID .. "/latest",
            Method = "GET",
            Headers = {
                ["X-Access-Key"] = self.JSONBIN_KEY
            }
        })
    end)
    
    if not success or not response then
        return false, "Failed to connect to key server"
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    for _, keyData in ipairs(data.record.keys) do
        if keyData.key == key then
            -- Check if expired
            local expires = DateTime.fromIsoDate(keyData.expires)
            if DateTime.now().UnixTimestamp > expires.UnixTimestamp then
                return false, "Key expired"
            end
            
            -- Check HWID lock
            if keyData.hwid and keyData.hwid ~= hwid then
                return false, "Key locked to different device"
            end
            
            -- First use - lock HWID
            if not keyData.hwid then
                keyData.hwid = hwid
                -- Update in background
                task.spawn(function()
                    self:UpdateKey(keyData)
                end)
            end
            
            -- Save locally
            writefile(self.KEY_FILE, key)
            
            return true, "Success"
        end
    end
    
    return false, "Invalid key"
end

-- Update key data (HWID lock)
function KeySystem:UpdateKey(keyData)
    pcall(function()
        request({
            Url = self.API_URL .. "/" .. self.BIN_ID,
            Method = "PUT",
            Headers = {
                ["X-Access-Key"] = self.JSONBIN_KEY,
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                keys = {keyData} -- Simplified, would need full array
            })
        })
    end)
end

-- Check saved key
function KeySystem:CheckSavedKey()
    if isfile(self.KEY_FILE) then
        local savedKey = readfile(self.KEY_FILE)
        local valid, msg = self:ValidateKey(savedKey)
        if valid then
            return true
        end
    end
    return false
end

-- Show key UI
function KeySystem:ShowUI(callback)
    -- Check saved key first
    if self:CheckSavedKey() then
        callback(true)
        return
    end
    
    -- Create UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LambV2KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 450, 0, 320)
    frame.Position = UDim2.new(0.5, -225, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 46)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 15)
    frame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "🔐 LambV2 Key System"
    title.TextColor3 = Color3.fromRGB(233, 69, 96)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your access key to continue"
    subtitle.TextColor3 = Color3.fromRGB(136, 136, 136)
    subtitle.TextSize = 14
    subtitle.Parent = frame
    
    -- Key input
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.8, 0, 0, 45)
    input.Position = UDim2.new(0.1, 0, 0, 100)
    input.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    input.TextSize = 18
    input.Font = Enum.Font.Gotham
    input.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)
    input.Parent = frame
    
    -- Get Key button
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.35, 0, 0, 40)
    getKeyBtn.Position = UDim2.new(0.1, 0, 0, 170)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(233, 69, 96)
    getKeyBtn.Text = "Get Key"
    getKeyBtn.TextColor3 = Color3.new(1, 1, 1)
    getKeyBtn.TextSize = 16
    getKeyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 8)
    getKeyBtn.Parent = frame
    
    -- Verify button
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Size = UDim2.new(0.35, 0, 0, 40)
    verifyBtn.Position = UDim2.new(0.55, 0, 0, 170)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    verifyBtn.Text = "Verify"
    verifyBtn.TextColor3 = Color3.new(1, 1, 1)
    verifyBtn.TextSize = 16
    verifyBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 8)
    verifyBtn.Parent = frame
    
    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.8, 0, 0, 30)
    status.Position = UDim2.new(0.1, 0, 0, 230)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 14
    status.Parent = frame
    
    -- Get Key action
    getKeyBtn.MouseButton1Click:Connect(function()
        -- Open GitHub Pages key site
        local url = "https://YOUR_USERNAME.github.io/LambV2-Keys"
        print("Visit this URL to get your key: " .. url)
        status.Text = "Visit: " .. url
        status.TextColor3 = Color3.fromRGB(0, 200, 255)
    end)
    
    -- Verify action
    verifyBtn.MouseButton1Click:Connect(function()
        local key = input.Text:gsub("%s+", ""):upper()
        
        if #key < 16 then
            status.Text = "❌ Invalid key format"
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
            return
        end
        
        status.Text = "⏳ Validating..."
        status.TextColor3 = Color3.fromRGB(255, 200, 0)
        
        local valid, msg = self:ValidateKey(key)
        
        if valid then
            status.Text = "✅ Access granted!"
            status.TextColor3 = Color3.fromRGB(0, 255, 100)
            task.wait(1)
            screenGui:Destroy()
            callback(true)
        else
            status.Text = "❌ " .. msg
            status.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end

return KeySystem
