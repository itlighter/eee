--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/XXXXXXXX/XXXXXXXX" -- ganti webhook

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- Exclude list full path
local excludeFullPath = {
    ["Workspace.Purchasable.Delta.Enchanted Sluice"] = true,
    ["Workspace.Purchasable.RiverTown.Merchant's Potion"] = true,
    ["Workspace.Purchasable.StarterTown"] = true,
    ["Workspace.Purchasable.RiverTown"] = true,
    ["Workspace.Purchasable.Delta"] = true,
    ["Workspace.Purchasable.Cavern"] = true,
    ["Workspace.Purchasable.Frozen Peak"] = true,
    ["Workspace.Purchasable.Volcano"] = true
}

-- fungsi ambil semua properti dari instance
local function getProperties(instance)
    local props = {}
    local success, propertyNames = pcall(function()
        return instance:GetAttributes()
    end)
    
    -- ambil Attributes dulu
    if success then
        for k, v in pairs(propertyNames) do
            props[k] = v
        end
    end
    
    -- ambil properti yang umum via pcall
    local ignore = {ClassName=true, Name=true, Parent=true} -- contoh ignore biar ga kepakai
    for _, prop in ipairs({"Name","Position","Size","Anchored","CanCollide","Transparency","Material","Color","CFrame"}) do
        if pcall(function() return instance[prop] end) and not ignore[prop] then
            props[prop] = instance[prop]
        end
    end
    
    return props
end

-- ambil semua anak langsung kecuali exclude
local function getChildrenProperties()
    local results = {}

    for _, child in ipairs(Workspace.Purchasable:GetChildren()) do
        local path = child:GetFullName()
        if not excludeFullPath[path] then
            results[child.Name] = getProperties(child)
        end
    end

    return results
end

-- kirim ke discord
local function sendToDiscord(childrenProps)
    local req = (http_request or request or syn.request)
    if not req then
        warn("Exploit environment tidak support http_request")
        return
    end

    local lines = {}
    for childName, props in pairs(childrenProps) do
        local propLines = {}
        for k, v in pairs(props) do
            table.insert(propLines, k .. ": " .. tostring(v))
        end
        table.insert(lines, "**" .. childName .. "**\n" .. table.concat(propLines, "\n"))
    end

    local content
    if #lines > 0 then
        content = table.concat(lines, "\n\n")
    else
        content = "No stocks available"
    end

    local data = { content = content }

    req({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
end

-- langsung ambil dan kirim
local childrenProps = getChildrenProperties()
sendToDiscord(childrenProps)
