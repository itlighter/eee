local WEBHOOK_URL = "https://discord.com/api/webhooks/1408117042258907196/3oTINE7iMaUWGMtvHf22XViEI9Fd3CeifOnzdiE9_3QU8BPHKalaps3ej3aq0riV9Opf"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Resolve UserId -> DisplayName + Level (exclude Money)
local function resolveFinder(userId)
    local player = Players:GetPlayerByUserId(userId)
    if not player then return string.format("UserId: %d (offline)", userId) end

    local leaderstats = player:FindFirstChild("leaderstats")
    local level = leaderstats and leaderstats:FindFirstChild("Level") and leaderstats.Level.Value or "N/A"

    return string.format("%s | Level: %s | UserId: %d", player.DisplayName, level, userId)
end

--// Format argumen
local function formatValue(v)
    local t = typeof(v)
    if t == "Instance" then
        return string.format("[Instance: %s (%s)]", v.Name, v.ClassName)
    elseif t == "Vector3" then
        return string.format("[Vector3: %.2f, %.2f, %.2f]", v.X, v.Y, v.Z)
    elseif t == "CFrame" then return "[CFrame]"
    elseif t == "Color3" then
        return string.format("[Color3: R=%.2f G=%.2f B=%.2f]", v.R, v.G, v.B)
    elseif t == "table" then
        local parts = {}
        for k, v2 in pairs(v) do
            if k == "Finder" and typeof(v2) == "number" then
                table.insert(parts, string.format("%s = %s", k, resolveFinder(v2)))
            else
                table.insert(parts, string.format("%s = %s", k, formatValue(v2)))
            end
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif t == "function" then return "[Function]"
    elseif t == "userdata" then return "[Userdata]"
    else return tostring(v)
    end
end

local function formatArgs(args)
    local out = {}
    for i, v in ipairs(args) do
        table.insert(out, string.format("[%d] = %s", i, formatValue(v)))
    end
    return #out > 0 and table.concat(out, "\n") or "[No Arguments]"
end

--// Kirim ke Discord
local function sendToDiscord(sourceName, obj, args, type)
    local colors = { RemoteEvent = 3447003, RemoteFunction = 5763719, Dynamic = 15844367 }
    local data = {
        username = "Remote Logger",
        embeds = {{
            title = string.format("[%s] %s", sourceName, obj:GetFullName()),
            description = "```lua\n"..formatArgs(args).."\n```",
            color = colors[type] or 0,
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    local body = HttpService:JSONEncode(data)
    local request = (http_request or request or syn.request)
    if request then
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body })
    end
end

--// Blacklist (nama atau path lengkap)
local blacklist = {
    "TimeSyncEvent",
    "TweenCommunication",
    "ReplicatedStorage.Remotes.Misc.SystemMessage", -- exclude full path
}

local function isBlacklisted(obj)
    for _, b in ipairs(blacklist) do
        if string.find(obj.Name, b) or string.find(obj:GetFullName(), b) then
            return true
        end
    end
    return false
end

--// Hook Remotes
local function hookRemotes(parent, sourceName)
    for _, obj in ipairs(parent:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not isBlacklisted(obj) then
            if obj:IsA("RemoteEvent") then
                obj.OnClientEvent:Connect(function(...)
                    sendToDiscord(sourceName, obj, {...}, obj.ClassName)
                end)
            else
                local old
                local success, callback = pcall(function() return rawget(obj, "OnClientInvoke") end)
                if success then old = callback end
                obj.OnClientInvoke = function(...)
                    sendToDiscord(sourceName, obj, {...}, obj.ClassName)
                    if old then return old(...) end
                    return nil
                end
            end
        end
    end
end

-- Hook static (exclude PlayerGui)
hookRemotes(game.ReplicatedStorage, "ReplicatedStorage")
hookRemotes(workspace, "Workspace")

-- Hook dynamic
game.DescendantAdded:Connect(function(obj)
    if isBlacklisted(obj) then return end
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                sendToDiscord("Dynamic", obj, {...}, "Dynamic")
            end)
        else
            local old
            local success, callback = pcall(function() return rawget(obj, "OnClientInvoke") end)
            if success then old = callback end
            obj.OnClientInvoke = function(...)
                sendToDiscord("Dynamic", obj, {...}, "Dynamic")
                if old then return old(...) end
                return nil
            end
        end
    end
end)
