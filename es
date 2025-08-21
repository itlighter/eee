local blacklist = {"TimeSyncEvent"}

-- cek blacklist
local function isBlacklisted(obj)
    for _, v in ipairs(blacklist) do
        if string.find(obj.Name, v) then
            return true
        end
    end
    return false
end

-- hook Remote
local function hookRemote(obj)
    if not (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then return end
    if isBlacklisted(obj) then return end

    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            print("⚡ RemoteEvent fired:", obj:GetFullName())
            for i, v in ipairs({...}) do
                print("   Arg["..i.."] =", v)
            end
        end)
    elseif obj:IsA("RemoteFunction") then
        obj.OnClientInvoke = function(...)
            print("⚡ RemoteFunction invoked:", obj:GetFullName())
            for i, v in ipairs({...}) do
                print("   Arg["..i.."] =", v)
            end
        end
    end
end

-- services penting buat scan
local services = {
    game:GetService("ReplicatedStorage"),
    game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
    game:GetService("Workspace"),
}

-- scan awal
for _, service in ipairs(services) do
    for _, obj in ipairs(service:GetDescendants()) do
        hookRemote(obj)
    end

    -- listener buat remote baru
    service.DescendantAdded:Connect(function(obj)
        hookRemote(obj)
    end)
end
