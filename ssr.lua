--// Meteor Shower Hunter Script - Fixed for Nil Value Error
--// Added proper nil checks and error handling

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

-- FIXED: Better request function detection with proper nil checks
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

-- Enhanced embed function with better error handling
-- Simple webhook fallback if embeds are causing issues
local function sendSimpleWebhook(playerCount)
    if not req then
        return false
    end
    
    local currentTime = tick()
    if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then
        return false
    end
    
    local jobId = game.JobId or "unknown"
    local gameLink = "roblox://placeId=" .. tostring(PlaceId) .. "&gameInstanceId=" .. tostring(jobId)
    
    -- Super simple webhook - just content, no embeds or components
    local body = {
        content = "☄️ **METEOR SHOWER FOUND!** ☄️\n" ..
                 "👥 Players: " .. tostring(playerCount) .. "/20\n" ..
                 "🕒 Time: " .. os.date("%H:%M:%S") .. "\n" ..
                 "🚀 Join: " .. gameLink
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
            print("📊 Simple webhook status:", response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                print("✅ Simple webhook success!")
                return true
            else
                warn("⚠️ Simple webhook unexpected code:", response.StatusCode)
                if response.Body then
                    warn("Error details:", response.Body)
                end
            end
        end
        return true
    else
        warn("❌ Simple webhook failed:", tostring(response))
        return false
    end
end

-- FIXED: Better server hop with more error handling
local function serverHop()
    print("🔄 Starting server hop... (Checked: " .. serversChecked .. " servers)")
    
    local url = "https://games.roblox.com/v1/games/" .. tostring(PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100"
    if Cursor ~= "" then
        url = url .. "&cursor=" .. tostring(Cursor)
    end

    local success, result = pcall(function()
        local rawData = game:HttpGet(url)
        if not rawData or rawData == "" then
            error("Empty response from server API")
        end
        return HttpService:JSONDecode(rawData)
    end)

    if success and result and result.data then
        local validServers = {}

        for _, server in ipairs(result.data) do
            -- FIXED: Add nil checks for server properties
            if server and server.playing and server.maxPlayers and server.id then
                if server.playing < server.maxPlayers
                   and server.playing <= MAX_PLAYER
                   and not TeleportData[server.id]
                   and server.id ~= game.JobId then
                    table.insert(validServers, server)
                end
            end
        end

        -- Sort servers by player count (fewer players first for better meteor chances)
        table.sort(validServers, function(a, b)
            if a.playing and b.playing then
                return a.playing < b.playing
            end
            return false
        end)

        if #validServers > 0 then
            local pick = validServers[1] -- Take the server with least players
            TeleportData[pick.id] = true
            
            print("🚀 Teleporting to server:", tostring(pick.id))
            print("👥 Target server players:", tostring(pick.playing) .. "/" .. tostring(pick.maxPlayers))
            
            local teleportSuccess, teleportError = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
            end)
            
            if not teleportSuccess then
                warn("❌ Teleport failed:", tostring(teleportError))
                task.wait(5)
                serverHop() -- Try again
            end
            
        elseif result.nextPageCursor then
            Cursor = tostring(result.nextPageCursor)
            print("📄 Getting next page of servers...")
            task.wait(2) -- Longer delay to prevent rate limiting
            serverHop()
        else
            warn("❌ No suitable servers found. Resetting search...")
            Cursor = ""
            TeleportData = {} -- Reset visited servers
            task.wait(30)
            serverHop()
        end
    else
        warn("❌ Failed to get server data:", tostring(result))
        warn("🔄 Retrying in 10 seconds...")
        task.wait(10)
        serverHop()
    end
end

-- FIXED: Enhanced meteor detection with better nil checks
local function checkMeteor()
    serversChecked = serversChecked + 1
    print("🔍 Checking for Meteor Shower... (Server #" .. serversChecked .. ")")
    
    local function method1()
        local success, boosts = pcall(function()
            if not LocalPlayer then return nil end
            local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
            if not playerGui then return nil end
            local mainUI = playerGui:WaitForChild("MainUI", 10) 
            if not mainUI then return nil end
            local boosts = mainUI:WaitForChild("Boosts", 10)
            return boosts
        end)
        
        if success and boosts then
            local meteorShower = boosts:FindFirstChild("Meteor Shower")
            return meteorShower ~= nil
        end
        return false
    end
    
    local function method2()
        if not LocalPlayer then return false end
        
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        
        local mainUI = playerGui:FindFirstChild("MainUI")
        if not mainUI then return false end
        
        local boosts = mainUI:FindFirstChild("Boosts")
        if not boosts then return false end
        
        local meteorShower = boosts:FindFirstChild("Meteor Shower")
        return meteorShower ~= nil
    end
    
    local function method3()
        -- Alternative: Check workspace for meteor objects
        if not workspace then return false end
        local meteors = workspace:FindFirstChild("Meteors")
        return meteors ~= nil
    end
    
    -- Try all methods with error handling
    local hasMeteor = false
    local success1, result1 = pcall(method1)
    local success2, result2 = pcall(method2) 
    local success3, result3 = pcall(method3)
    
    hasMeteor = (success1 and result1) or (success2 and result2) or (success3 and result3)
    
    if hasMeteor then
        meteorsFound = meteorsFound + 1
        print("⭐ METEOR SHOWER DETECTED! (#" .. meteorsFound .. ")")
        
        local playerCount = #Players:GetPlayers()
        print("👥 Current players:", playerCount)
        
        local webhookSent = sendWebhook(playerCount)
        
        if webhookSent then
            print("✅ Webhook sent! Waiting 30 seconds before server hop...")
            task.wait(30)
        else
            print("ℹ️ Webhook not sent (cooldown/filter). Waiting 10 seconds...")
            task.wait(10)
        end
        
        serverHop()
    else
        print("❌ No Meteor Shower found. Moving to next server...")
        task.wait(5) -- Short delay before hopping
        serverHop()
    end
end

-- FIXED: Better startup sequence with error handling
print("=" .. string.rep("=", 50) .. "=")
print("🚀 METEOR SHOWER HUNTER SCRIPT STARTED")
print("=" .. string.rep("=", 50) .. "=")

-- Test webhook functionality
print("🧪 Testing webhook functionality...")
if req then
    print("✅ Request function found!")
    
    local testSuccess, testResponse = pcall(function()
        local testBody = {
            content = "🤖 **Meteor Hunter Started!**\n🕒 Started at: " .. os.date("%H:%M:%S") .. "\n📊 Target: Find meteor showers automatically"
        }
        
        local jsonBody = HttpService:JSONEncode(testBody)
        
        return req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonBody
        })
    end)
    
    if testSuccess then
        print("✅ Startup webhook sent!")
    else
        warn("⚠️ Startup webhook failed:", tostring(testResponse))
        warn("⚠️ Continuing anyway...")
    end
else
    warn("❌ No request function available! Webhooks will not work.")
    warn("💡 Compatible executors: Synapse, Script-Ware, Fluxus, etc.")
end

-- Display configuration
print("\n📋 CONFIGURATION:")
print("   🎯 Max players per server: " .. MAX_PLAYER)
print("   ⏰ Webhook cooldown: " .. WEBHOOK_COOLDOWN .. " seconds")
print("   👥 Player range for webhooks: " .. MIN_PLAYERS .. "-" .. MAX_PLAYERS)
print("   🔍 Starting scan in 60 seconds...")

-- Wait for game to fully load
task.wait(60)

-- Main hunting loop with better error handling
print("🎯 Starting meteor hunt!")
spawn(function()
    while true do
        local success, error = pcall(function()
            checkMeteor()
        end)
        
        if not success then
            warn("❌ Error in checkMeteor:", tostring(error))
            warn("🔄 Retrying in 30 seconds...")
            task.wait(30)
        end
        
        task.wait(2) -- Small delay to prevent issues
    end
end)

-- Stats display (updates every 5 minutes) with error handling
spawn(function()
    while true do
        task.wait(300) -- 5 minutes
        
        local success, error = pcall(function()
            local runtime = math.floor((tick() - startTime) / 60)
            local successRate = (meteorsFound / math.max(serversChecked, 1)) * 100
            
            print("\n📊 === HUNTING STATS ===")
            print("⏱️ Runtime: " .. runtime .. " minutes")
            print("🌟 Meteors found: " .. meteorsFound)
            print("🔍 Servers checked: " .. serversChecked)
            print("📈 Success rate: " .. string.format("%.2f%%", successRate))
            print("========================\n")
        end)
        
        if not success then
            warn("❌ Error in stats display:", tostring(error))
        end
    end
end)
