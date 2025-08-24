local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer

local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k" -- ganti pake webhook lu
local TeleportData = {}
local Cursor = ""
local MAX_PLAYER = 15
local MAX_RETRIES = 5 -- maksimal retry server hop

-- function kirim webhook
local function sendWebhook(playerCount)
    local req = http_request or request or syn.request
    if req then
        local jobId = game.JobId
        local gameLink = ("https://huahuajuah.github.io/redirect/?placeId=%s&gameInstanceId=%s"):format(tostring(PlaceId), tostring(jobId))
    
        local body = {
            content = "☄️ Meteor Shower Found! (" .. playerCount .. "/20)", -- cuma teks, tanpa link
            components = {
                {
                    type = 1, -- ActionRow
                    components = {
                        {
                            type = 2,       -- Button
                            label = "Join Game", -- label tombol
                            style = 5,      -- Link button
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

-- serverhop function dengan failsafe
local function serverHop()
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

        if #validServers > 0 then
            local pick = validServers[math.random(1, #validServers)]
            TeleportData[pick.id] = true
            local teleportSuccess, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
            end)
            if not teleportSuccess then
                warn("Teleport gagal: "..tostring(err)..". Mencoba server lain...")
                serverHop() -- retry server hop
            end
        elseif result.nextPageCursor then
            Cursor = result.nextPageCursor
            serverHop()
        else
            warn("Tidak ada server yang cocok.")
        end
    else
        warn("Gagal ambil data server.")
    end
end

-- versi safe server hop dengan retry limit
local function safeServerHop(retries)
    retries = retries or 0
    local success, err = pcall(serverHop)
    if not success then
        warn("ServerHop error: "..tostring(err))
        if retries < MAX_RETRIES then
            task.wait(3)
            safeServerHop(retries + 1)
        else
            warn("Melewati server hop, terlalu banyak retry")
        end
    end
end

-- cek meteor
local function checkMeteor()
    local boosts = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("Boosts")

    if boosts:FindFirstChild("Meteor Shower") then
        local playerCount = #Players:GetPlayers()
        sendWebhook(playerCount)
        task.wait(20) -- tunggu 20 detik abis kirim webhook
        safeServerHop()
    else
        task.wait(30) -- ga ketemu → tunggu 30 detik dulu
        safeServerHop()
    end
end

-- tunggu 60 detik abis join server baru
task.delay(60, function()
    checkMeteor()
end)
