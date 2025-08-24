--// Meteor Shower Hunter Script - Fixed & Improved
--// Added proper nil checks, error handling, and safer server hop

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

-- Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k"
local MAX_PLAYER = 15
local WEBHOOK_COOLDOWN = 300 -- 5 minutes between webhooks
local MIN_PLAYERS = 5 -- Minimum players to send webhook
local MAX_PLAYERS = 18 -- Maximum players to send webhook

-- Variables
local TeleportData = {}
local Cursor = ""
local lastWebhookTime = 0
local meteorsFound = 0
local serversChecked = 0
local startTime = tick()

-- Detect working HTTP request function
local function getRequestFunction()
    local functions = {
        {"http_request", http_request},
        {"request", request},
        {"syn.request", syn and syn.request or nil},
        {"fluxus.request", fluxus and fluxus.request or nil}
    }
    
    for _, funcData in ipairs(functions) do
        local name, func = funcData[1], funcData[2]
        if func and type(func) == "function" then
            print("✅ Found working request function:", name)
            return func
        end
    end
    
    return nil
end

local req = getRequestFunction()

-- Send webhook with player count
local function sendSimpleWebhook(playerCount)
    if not req then return false end
    if playerCount < MIN_PLAYERS or playerCount > MAX_PLAYERS then
        print("ℹ️ Player count not in range for webhook.")
        return false
    end

    local currentTime = tick()
    if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then
        print("ℹ️ Webhook cooldown active.")
        return false
    end
    
    local jobId = game.JobId or "unknown"
    local redirectLink = ("https://huahuajuah.github.io/redirect/?placeId=%s&gameInstanceId=%s"):format(tostring(PlaceId), tostring(jobId))
    
    local body = {
        content = "☄️ **METEOR SHOWER FOUND!** ☄️\n" ..
                  "👥 Players: " .. tostring(playerCount) .. "/20\n" ..
                  "🕒 Time: " .. os.date("%H:%M:%S"),
        components = {
            {
                type = 1,
                components = {
                    {
                        type = 2,
                        style = 5,
                        label = "🚀 Join Server",
                        url = redirectLink
                    }
                }
            }
        }
    }
    
    local success, response = pcall(function()
        return req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end)
    
    if success then
        lastWebhookTime = currentTime
        if response and response.StatusCode then
            print("📊 Webhook status:", response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                print("✅ Webhook sent!")
                return true
            end
        end
        return true
    else
        warn("❌ Webhook failed:", tostring(response))
        return false
    end
end

-- Server hop with looping
local function serverHop()
    while true do
        print("🔄 Searching for servers... (Checked: " .. serversChecked .. " servers)")
        
        local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100"
        if Cursor ~= "" then
            url = url .. "&cursor=" .. tostring(Cursor)
        end

        local success, result = pcall(function()
            local rawData = game:HttpGet(url)
            if not rawData or rawData == "" then error("Empty response from server API") end
            return HttpService:JSONDecode(rawData)
        end)

        if success and result and result.data then
            local validServers = {}

            for _, server in ipairs(result.data) do
                if server and server.playing and server.maxPlayers and server.id then
                    if server.playing < server.maxPlayers
                       and server.playing <= MAX_PLAYER
                       and not TeleportData[server.id]
                       and server.id ~= game.JobId then
                        table.insert(validServers, server)
                    end
                end
            end

            table.sort(validServers, function(a, b)
                return (a.playing or 0) < (b.playing or 0)
            end)

            if #validServers > 0 then
                local pick = validServers[1]
                TeleportData[pick.id] = true
                print("🚀 Teleporting to server:", pick.id, "👥 Players:", pick.playing .. "/" .. pick.maxPlayers)

                local teleportSuccess, teleportError = pcall(function()
                    TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
                end)

                if not teleportSuccess then
                    warn("❌ Teleport failed:", tostring(teleportError))
                    task.wait(5)
                end
                break
            elseif result.nextPageCursor then
                Cursor = tostring(result.nextPageCursor)
                print("📄 Getting next page of servers...")
                task.wait(2)
            else
                warn("❌ No suitable servers found. Resetting search...")
                Cursor = ""
                TeleportData = {}
                task.wait(30)
            end
        else
            warn("❌ Failed to get server data:", tostring(result))
            warn("🔄 Retrying in 10 seconds...")
            task.wait(10)
        end
    end
end

-- Meteor detection
local function checkMeteor()
    serversChecked = serversChecked + 1
    print("🔍 Checking for Meteor Shower... (Server #" .. serversChecked .. ")")
    
    local hasMeteor = false
    local success1, result1 = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
        local boosts = mainUI and mainUI:FindFirstChild("Boosts")
        return boosts and boosts:FindFirstChild("Meteor Shower") ~= nil
    end)

    local success2, result2 = pcall(function()
        local meteors = workspace:FindFirstChild("Meteors")
        return meteors and #meteors:GetChildren() > 0
    end)

    hasMeteor = (success1 and result1) or (success2 and result2)

    if hasMeteor then
        meteorsFound = meteorsFound + 1
        print("⭐ METEOR SHOWER DETECTED! (#" .. meteorsFound .. ")")
        local playerCount = #Players:GetPlayers()
        print("👥 Current players:", playerCount)
        local webhookSent = sendSimpleWebhook(playerCount)

        if webhookSent then
            print("✅ Webhook sent! Waiting 30 seconds before server hop...")
            task.wait(30)
        else
            print("ℹ️ Webhook not sent (cooldown/filter). Waiting 10 seconds...")
            task.wait(10)
        end
    else
        print("❌ No Meteor Shower found. Moving to next server...")
        task.wait(5)
    end

    serverHop()
end

-- Startup
print("🚀 METEOR SHOWER HUNTER SCRIPT STARTED")
if req then
    print("✅ Request function found!")
    pcall(function()
        local testBody = {content = "🤖 **Meteor Hunter Started!**\n🕒 " .. os.date("%H:%M:%S")}
        req({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(testBody)})
    end)
else
    warn("❌ No request function available! Webhooks will not work.")
end

print("📋 CONFIGURATION:")
print("   🎯 Max players per server: " .. MAX_PLAYER)
print("   ⏰ Webhook cooldown: " .. WEBHOOK_COOLDOWN .. " seconds")
print("   👥 Player range for webhooks: " .. MIN_PLAYERS .. "-" .. MAX_PLAYERS)
print("   🔍 Starting scan in 60 seconds...")

task.wait(60)

-- Main hunting loop
spawn(function()
    while true do
        local success, errorMsg = pcall(checkMeteor)
        if not success then
            warn("❌ Error in checkMeteor:", tostring(errorMsg))
            task.wait(30)
        end
        task.wait(2)
    end
end)

-- Stats display
spawn(function()
    while true do
        task.wait(300)
        local success, errorMsg = pcall(function()
            local runtime = math.floor((tick() - startTime) / 60)
            local successRate = (meteorsFound / math.max(serversChecked, 1)) * 100
            print("\n📊 === HUNTING STATS ===")
            print("⏱️ Runtime: " .. runtime .. " minutes")
            print("🌟 Meteors found: " .. meteorsFound)
            print("🔍 Servers checked: " .. serversChecked)
            print("📈 Success rate: " .. string.format("%.2f%%", successRate))
            print("========================\n")
        end)
        if not success then warn("❌ Error in stats display:", tostring(errorMsg)) end
    end
end)
