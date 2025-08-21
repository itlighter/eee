local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            print("⚡ Event:", remote:GetFullName())
            print("Args:", ...)
        end)
    elseif remote:IsA("RemoteFunction") then
        remote.OnClientInvoke = function(...)
            print("⚡ Function:", remote:GetFullName())
            print("Args:", ...)
        end
    end
end

for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        hookRemote(obj)
    end
end
