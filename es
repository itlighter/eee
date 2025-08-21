local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- function buat log remote
local function logRemote(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("📡 Remote ditemukan di PlayerGui:", obj:GetFullName(), "[" .. obj.ClassName .. "]")
    end
end

-- scan awal
for _, obj in ipairs(playerGui:GetDescendants()) do
    logRemote(obj)
end

-- listener kalau ada remote baru masuk
playerGui.DescendantAdded:Connect(function(obj)
    logRemote(obj)
end)
