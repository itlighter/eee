local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ambil semua Remote di folder Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

print("📡 List Remote di ReplicatedStorage.Remotes:")

for _, obj in ipairs(remotesFolder:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
    end
end
