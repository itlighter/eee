local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Resolve Finder UserId -> Username
local function resolveFinder(userId)
    local player = Players:GetPlayerByUserId(userId)
    if player then
        return string.format("%s (UserId: %d)", player.Name, userId)
    end

    local success, result = pcall(function()
        local url = "https://users.roblox.com/v1/users/"..userId
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        return data.name
    end)

    if success and result then
        return string.format("%s (UserId: %d)", result, userId)
    end

    return string.format("UserId: %d", userId)
end

--// Utility format argumen
local function formatValue(v)
    local t = typeof(v)
    if t == "Instance" then
        return string.format("[Instance: %s (%s)]", v.Name, v.ClassName)
    elseif t == "Vector3" then
        return string.format("[Vector3: %.2f, %.2f, %.2f]", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        return "[CFrame]"
    elseif t == "Color3" then
        return string.format("[Color3: R=%.2f G=%.2f B=%.2f]", v.R, v.G, v.B)
    elseif t == "table" then
        local parts = {}
        for k, v2 in pairs(v) do
            if k == "Finder" and typeof(v2) == "number" then
                table.insert(parts, string.format("%s = %s", tostring(k), resolveFinder(v2)))
            else
                table.insert(parts, string.format("%s = %s", tostring(k), formatValue(v2)))
            end
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif t == "function" then
        return "[Function]"
    elseif t == "userdata" then
        return "[Userdata]"
    else
        return tostring(v)
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
    local colors = {
        RemoteEvent = 3447003,
        RemoteFunction = 5763719,
        Dynamic = 15844367
    }

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
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end
end

--// Blacklist
local blacklist = {
    "TimeSyncEvent",
    "TweenCommunication",
}

local function isBlacklisted(name)
    for _, b in ipairs(blacklist) do
        if string.find(name, b) then
            return true
        end
    end
    return false
end

--// Hook Remotes
local function hookRemotes(parent, sourceName)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") and not isBlacklisted(obj.Name) then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                warn("[RemoteEvent]["..sourceName.."]:", obj:GetFullName(), ...)
                sendToDiscord(sourceName, obj, args, "RemoteEvent")
            end)
        elseif obj:IsA("RemoteFunction") and not isBlacklisted(obj.Name) then
            local old
            local success, callback = pcall(function()
                return rawget(obj, "OnClientInvoke")
            end)
            if success then old = callback end

            obj.OnClientInvoke = function(...)
                local args = {...}
                warn("[RemoteFunction]["..sourceName.."]:", obj:GetFullName(), ...)
                sendToDiscord(sourceName, obj, args, "RemoteFunction")
                if old then
                    return old(...)
                end
                return nil
            end
        end
    end
end

-- Hook hanya PlayerGui & Workspace
hookRemotes(LocalPlayer:WaitForChild("PlayerGui"), "PlayerGui")
hookRemotes(workspace, "Workspace")

-- Dynamic hook tapi hanya kalau parent di PlayerGui / Workspace
game.DescendantAdded:Connect(function(obj)
    if isBlacklisted(obj.Name) then return end

    local parent = obj:FindFirstAncestorWhichIsA("PlayerGui") or obj:FindFirstAncestorWhichIsA("Workspace")
    if not parent then return end

    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local args = {...}
            warn("[RemoteEvent][Dynamic]:", obj:GetFullName(), ...)
            sendToDiscord("Dynamic", obj, args, "Dynamic")
        end)
    elseif obj:IsA("RemoteFunction") then
        local old
        local success, callback = pcall(function()
            return rawget(obj, "OnClientInvoke")
        end)
        if success then old = callback end

        obj.OnClientInvoke = function(...)
            local args = {...}
            warn("[RemoteFunction][Dynamic]:", obj:GetFullName(), ...)
            sendToDiscord("Dynamic", obj, args, "Dynamic")
            if old then
                return old(...)
            end
            return nil
        end
    end
end)
