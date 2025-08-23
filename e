--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408441169028972797/_ls8aguNPMDTgrO6yJ6l72p5CXjUD56md_gy6t7xN0Lkf69pqhxaHFTddOtwkX1a3W0Q" -- ganti webhook

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Exclude list (pakai full path string biar gampang cek)
local excludeList = {
    ["Workspace.Purchasable.Delta.Enchanted Sluice"] = true,
    ["Workspace.Purchasable.RiverTown.Merchant's Potion"] = true,
    ["Workspace.Purchasable.StarterTown"] = true,
    ["Workspace.Purchasable.RiverTown"] = true,
    ["Workspace.Purchasable.Delta"] = true,
    ["Workspace.Purchasable.Cavern"] = true,
    ["Workspace.Purchasable.Frozen Peak"] = true,
    ["Workspace.Purchasable.Volcano"] = true
}

-- fungsi format angka dengan comma separator
local function formatNumber(number)
    if not number or type(number) ~= "number" then
        return tostring(number or "N/A")
    end
    
    local formatted = tostring(number)
    local k = #formatted
    
    -- Tambahkan comma setiap 3 digit dari belakang
    while k > 3 do
        formatted = formatted:sub(1, k-3) .. "," .. formatted:sub(k-2)
        k = k - 3
    end
    
    return formatted
end

-- fungsi ambil harga dari ShopItem
local function getItemPrice(item)
    local shopItem = item:FindFirstChild("ShopItem")
    if shopItem then
        local shardPrice = shopItem:GetAttribute("ShardPrice")
        local regularPrice = shopItem:GetAttribute("Price")
        
        if shardPrice then
            return shardPrice, "S" -- ShardPrice: harga di depan, currency "S" di belakang
        elseif regularPrice then
            return regularPrice, "$" -- Price: currency "$" di depan, harga di belakang
        end
    end
    return nil, nil
end

-- fungsi kirim ke discord
local function sendToDiscord(location, itemsList)
    local req = (http_request or request or syn.request)
    if not req then
        warn("Exploit environment tidak support http_request")
        return
    end

    -- format list ke bentuk nomor dengan harga
    local stockLines = {}
    for i, itemData in ipairs(itemsList) do
        local line = i .. ". " .. itemData.name
        if itemData.price and itemData.currency then
            local formattedPrice = formatNumber(itemData.price)
            if itemData.currency == "$" then
                line = line .. " - " .. itemData.currency .. formattedPrice
            else -- "S" currency
                line = line .. " - " .. formattedPrice .. " " .. itemData.currency
            end
        end
        table.insert(stockLines, line)
    end

    local content = "Trader Location : " .. location .. "\n\nStocks :\n" .. table.concat(stockLines, "\n")

    local data = {
        content = content
    }

    req({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(data)
    })
end

-- fungsi ambil semua anak langsung kecuali exclude dengan harga
local function getChildrenList()
    local results = {}

    for _, child in ipairs(Workspace.Purchasable:GetChildren()) do
        local path = child:GetFullName()
        if not excludeList[path] then
            local price, currency = getItemPrice(child)
            table.insert(results, {
                name = child.Name,
                price = price,
                currency = currency
            })
        end
    end

    return results
end

-- listen ke Notification event
local notificationEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Info"):WaitForChild("Notification")

notificationEvent.OnClientEvent:Connect(function(...)
    local args = {...}
    local message = args[1]

    if typeof(message) == "string" and message:find("The wandering trader has arrived") then
        -- cari lokasi setelah kata "at"
        local location = message:match("at (.+)!")
        if not location then
            location = "Unknown"
        end

        task.delay(10, function()
            local children = getChildrenList()
            sendToDiscord(location, children)
        end)
    end
end)
