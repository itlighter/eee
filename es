local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Cari ItemSpots
local map = workspace:FindFirstChild("Map")
local merchant = map and map:FindFirstChild("TravelingMerchant")
local itemSpots = merchant and merchant:FindFirstChild("ItemSpots")

if not itemSpots then
    warn("ItemSpots tidak ditemukan!")
    return
end

print("Scanning references to ItemSpots...")

-- 1️⃣ Scan ObjectValue / Instance yang menunjuk ke ItemSpots
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("ObjectValue") and obj.Value == itemSpots then
        print("[ObjectValue reference] " .. obj:GetFullName())
    elseif obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") then
        for _, prop in pairs({"Parent"}) do
            if obj[prop] == itemSpots then
                print("[Property reference] " .. obj:GetFullName() .. " -> " .. prop)
            end
        end
    end
end

-- 2️⃣ Hook RemoteEvent / RemoteFunction di sekitar TravelingMerchant
local function hookRemotes(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                for i, v in ipairs(args) do
                    if v == itemSpots then
                        print("[RemoteEvent arg] " .. obj:GetFullName() .. " argument #" .. i .. " references ItemSpots")
                    end
                end
            end)
        elseif obj:IsA("RemoteFunction") then
            local old
            local success, callback = pcall(function() return rawget(obj, "OnClientInvoke") end)
            if success then old = callback end
            obj.OnClientInvoke = function(...)
                local args = {...}
                for i, v in ipairs(args) do
                    if v == itemSpots then
                        print("[RemoteFunction arg] " .. obj:GetFullName() .. " argument #" .. i .. " references ItemSpots")
                    end
                end
                if old then return old(...) end
                return nil
            end
        end
    end
end

-- Hook di TravelingMerchant & ItemSpots
hookRemotes(merchant)
hookRemotes(itemSpots)

-- 3️⃣ Optional: scan Remote baru yang spawn
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        hookRemotes(obj.Parent or obj)
    end
end)
