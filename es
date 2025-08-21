--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408117042258907196/3oTINE7iMaUWGMtvHf22XViEI9Fd3CeifOnzdiE9_3QU8BPHKalaps3ej3aq0riV9Opf" -- ganti dengan webhook lo

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

-- Cari ItemSpots
local map = workspace:FindFirstChild("Map")
local merchant = map and map:FindFirstChild("TravelingMerchant")
local itemSpots = merchant and merchant:FindFirstChild("ItemSpots")

if not itemSpots then
    warn("ItemSpots tidak ditemukan!")
    return
end

-- Fungsi kirim log ke Discord
local function sendToDiscord(title, description)
    local data = {
        username = "ItemSpots Logger",
        embeds = {{
            title = title,
            description = description,
            color = 15844367,
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    local body = HttpService:JSONEncode(data)
    local request = (http_request or request or syn.request)
    if request then
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = body
        })
    end
end

-- Scan ObjectValue yang refer ke ItemSpots
local function scanObjectValues()
    local logs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ObjectValue") and obj.Value == itemSpots then
            table.insert(logs, "[ObjectValue reference] " .. obj:GetFullName())
        end
    end
    if #logs > 0 then
        sendToDiscord("ObjectValue references to ItemSpots", table.concat(logs, "\n"))
    end
end

-- Hook RemoteEvent/RemoteFunction di sekitar TravelingMerchant
local function hookRemotes(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                local logs = {}
                for i, v in ipairs(args) do
                    if v == itemSpots then
                        table.insert(logs, "[RemoteEvent arg] " .. obj:GetFullName() .. " argument #" .. i .. " references ItemSpots")
                    end
                end
                if #logs > 0 then
                    sendToDiscord("RemoteEvent references to ItemSpots", table.concat(logs, "\n"))
                end
            end)
        elseif obj:IsA("RemoteFunction") then
            local old
            local success, callback = pcall(function() return rawget(obj, "OnClientInvoke") end)
            if success then old = callback end
            obj.OnClientInvoke = function(...)
                local args = {...}
                local logs = {}
                for i, v in ipairs(args) do
                    if v == itemSpots then
                        table.insert(logs, "[RemoteFunction arg] " .. obj:GetFullName() .. " argument #" .. i .. " references ItemSpots")
                    end
                end
                if #logs > 0 then
                    sendToDiscord("RemoteFunction references to ItemSpots", table.concat(logs, "\n"))
                end
                if old then return old(...) end
                return nil
            end
        end
    end
end

-- Hook dan scan hanya ketika Notification dipanggil
local notif = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Info"):WaitForChild("Notification")
if notif and notif:IsA("RemoteEvent") then
    notif.OnClientEvent:Connect(function(message)
        sendToDiscord("Notification Triggered", message)
        scanObjectValues()
        hookRemotes(merchant)
    end)
else
    warn("RemoteEvent Notification tidak ditemukan!")
end
