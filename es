local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- daftar Remote yang mau di-ignore
local blacklist = {
    "TimeSyncEvent",
}

-- fungsi cek blacklist
local function isBlacklisted(remote)
    for _, v in ipairs(blacklist) do
        if string.find(remote.Name, v) then
            return true
        end
    end
    return false
end

-- fungsi hook Remote
local function hookRemote(remote)
    if isBlacklisted(remote) then return end
    
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

-- pasang hook ke semua Remote di ReplicatedStorage
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        hookRemote(obj)
    end
end
