local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("📡 List Remote di PlayerGui:")

for _, obj in ipairs(playerGui:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
    end
end

-- listener otomatis kalau ada Remote baru dimasukin ke PlayerGui
playerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("⚡ Remote baru ditemukan di PlayerGui:", obj:GetFullName(), "[" .. obj.ClassName .. "]")
    end
end)
