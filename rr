local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k" -- ganti pake webhook lu

-- function kirim webhook
local function sendWebhook(playerCount)
    local req = http_request or request or syn.request
    if req then
        local jobId = game.JobId
        local PlaceId = game.PlaceId
        local gameLink = "roblox://placeId=" .. PlaceId .. "&gameInstanceId=" .. jobId
    
        local body = {
            content = "☄️ Meteor Shower Found!\n" .. playerCount .. "/20\n" .. gameLink,
            components = {
                {
                    type = 1,
                    components = {
                        {
                            type = 2,
                            label = "Join Game",
                            style = 5,
                            url = gameLink
                        }
                    }
                }
            }
        }
    
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    else
        warn("No request function available")
    end
end

-- cek meteor
local function checkMeteor()
    local boosts = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("Boosts")

    if boosts:FindFirstChild("Meteor Shower") then
        local playerCount = #Players:GetPlayers()
        sendWebhook(playerCount)
    end

    -- loop lagi setelah delay
    task.delay(30, checkMeteor)
end

-- mulai loop
task.delay(5, checkMeteor) -- tunggu 5 detik dulu biar GUI siap
