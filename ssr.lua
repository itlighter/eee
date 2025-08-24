--// Meteor Shower Hunter Script
--// Complete version with all improvements

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

-- Get request function
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

-- Enhanced webhook function with rate limiting and better formatting
local function sendWebhook(playerCount)
    print("🔄 Attempting to send webhook...")
    
    if not req then
        warn("❌ No request function available")
        return false
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then
        local remainingTime = math.ceil(WEBHOOK_COOLDOWN - (currentTime - lastWebhookTime))
        print("⏰ Webhook on cooldown for " .. remainingTime .. " seconds")
        return false
    end
    
    -- Check player count filter
    if playerCount < MIN_PLAYERS or playerCount > MAX_PLAYERS then
        print("🚫 Skipping webhook - player count (" .. playerCount .. ") not in ideal range")
        return false
    end
    
    local jobId = game.JobId
    local gameLink = "roblox://placeId=" .. PlaceId .. "&gameInstanceId=" .. jobId
    local runtime = math.floor((tick() - startTime) / 60) -- Runtime in minutes
    
    local body = {
        content = "☄️ **METEOR SHOWER FOUND!** ☄️",
        embeds = {
            {
                title = "🌟 Meteor Shower Alert",
                color = 16776960, -- Gold color
                fields = {
                    {
                        name = "👥 Players",
                        value = playerCount .. "/20",
                        inline = true
                    },
                    {
                        name = "🕒 Time",
                        value = os.date("%H:%M:%S"),
                        inline = true
                    },
                    {
                        name = "📊 Total Found",
                        value = meteorsFound .. " meteors",
                        inline = true
                    },
                    {
                        name = "⏱️ Runtime",
                        value = runtime .. " minutes",
                        inline = true
                    },
                    {
                        name = "🔍 Servers Checked",
                        value = serversChecked .. " servers",
                        inline = true
                    },
                    {
                        name = "📈 Success Rate",
                        value = string.format("%.1f%%", (meteorsFound / math.max(serversChecked, 1)) * 100),
                        inline = true
                    }
                },
                footer = {
                    text = "Job ID: " .. jobId
                }
            }
        },
        components = {
            {
                type = 1,
                components = {
                    {
                        type = 2,
                        label = "🚀 Join Server",
                        style = 5,
                        url = gameLink
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
        print("✅ Webhook sent successfully!")
        lastWebhookTime = currentTime
        
        if response and response.StatusCode then
            print("📊 Status Code:", response.StatusCode)
            if response.StatusCode == 204 or response.StatusCode == 200 then
                print("✅ Discord confirmed receipt!")
                return true
            else
                warn("⚠️ Unexpected status code:", response.StatusCode)
            end
        end
        return true
    else
        warn("❌ Webhook request failed:", tostring(response))
        return false
    end
end

-- Smart server hop with better server selection
local function serverHop()
    print("🔄 Starting server hop... (Checked: " .. serversChecked .. " servers)")
    
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    if Cursor ~= "" then
        url = url .. "&cursor=" .. Cursor
    end

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and result and result.data then
        local validServers = {}

        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers
               and server.playing <= MAX_PLAYER
               and not TeleportData[server.id]
               and server.id ~= game.JobId then
                table.insert(validServers, server)
            end
        end

        -- Sort servers by player count (fewer players first for better meteor chances)
        table.sort(validServers, function(a, b)
            return a.playing < b.playing
        end)

        if #validServers > 0 then
            local pick = validServers[1] -- Take the server with least players
            TeleportData[pick.id] = true
            
            print("🚀 Teleporting to server:", pick.id)
            print("👥 Target server players:", pick.playing .. "/" .. pick.maxPlayers)
            
            local teleportSuccess, teleportError = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
            end)
            
            if not teleportSuccess then
                warn("❌ Teleport failed:", teleportError)
                task.wait(5)
                serverHop() -- Try again
            end
            
        elseif result.nextPageCursor then
            Cursor = result.nextPageCursor
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
        warn("❌ Failed to get server data. Retrying in 10 seconds...")
        task.wait(10)
        serverHop()
    end
end

-- Enhanced meteor detection with multiple fallback methods
local function checkMeteor()
    serversChecked = serversChecked + 1
    print("🔍 Checking for Meteor Shower... (Server #" .. serversChecked .. ")")
    
    local function method1()
        local success, boosts = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui", 10):WaitForChild("MainUI", 10):WaitForChild("Boosts", 10)
        end)
        
        if success and boosts then
            return boosts:FindFirstChild("Meteor Shower") ~= nil
        end
        return false
    end
    
    local function method2()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        
        local mainUI = playerGui:FindFirstChild("MainUI")
        if not mainUI then return false end
        
        local boosts = mainUI:FindFirstChild("Boosts")
        if not boosts then return false end
        
        return boosts:FindFirstChild("Meteor Shower") ~= nil
    end
    
    local function method3()
        -- Alternative: Check workspace for meteor objects
        local meteors = workspace:FindFirstChild("Meteors")
        return meteors ~= nil
    end
    
    -- Try all methods
    local hasMeteor = method1() or method2() or method3()
    
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

-- Startup sequence
print("=" .. string.rep("=", 50) .. "=")
print("🚀 METEOR SHOWER HUNTER SCRIPT STARTED")
print("=" .. string.rep("=", 50) .. "=")

-- Test webhook functionality
print("🧪 Testing webhook functionality...")
if req then
    print("✅ Request function found!")
    
    local testSuccess, testResponse = pcall(function()
        return req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = "🤖 **Meteor Hunter Started!**\n🕒 Started at: " .. os.date("%H:%M:%S") .. "\n📊 Target: Find meteor showers automatically"
            })
        })
    end)
    
    if testSuccess then
        print("✅ Startup webhook sent!")
    else
        warn("⚠️ Startup webhook failed, but continuing...")
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

-- Auto-restart mechanism (optional)
spawn(function()
    task.wait(7200) -- 2 hours
    print("🔄 Auto-restart triggered after 2 hours")
    if req then
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = "🔄 **Script Auto-Restart**\n📊 Found " .. meteorsFound .. " meteors in " .. serversChecked .. " servers\n⏱️ Runtime: 2 hours"
            })
        })
    end
    -- Note: Add your script reload URL here if you want auto-restart
    -- loadstring(game:HttpGet("YOUR_SCRIPT_URL"))()
end)

-- Main hunting loop
print("🎯 Starting meteor hunt!")
spawn(function()
    while true do
        local success, error = pcall(checkMeteor)
        if not success then
            warn("❌ Error in checkMeteor:", error)
            task.wait(30)
        end
        task.wait(2) -- Small delay to prevent issues
    end
end)

-- Stats display (updates every 5 minutes)
spawn(function()
    while true do
        task.wait(300) -- 5 minutes
        local runtime = math.floor((tick() - startTime) / 60)
        local successRate = (meteorsFound / math.max(serversChecked, 1)) * 100
        
        print("\n📊 === HUNTING STATS ===")
        print("⏱️ Runtime: " .. runtime .. " minutes")
        print("🌟 Meteors found: " .. meteorsFound)
        print("🔍 Servers checked: " .. serversChecked)
        print("📈 Success rate: " .. string.format("%.2f%%", successRate))
        print("========================\n")
    end
end)
