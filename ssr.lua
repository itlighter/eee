local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local LocalPlayer = Players.LocalPlayer
local JobId = game.JobId

local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k"
local TeleportData = {}
local Cursor = ""
local MAX_PLAYER = 15
local MAX_RETRIES = 5

-- Fungsi kirim webhook dengan tombol + Markdown + fallback link
local function sendWebhook(playerCount)
    local req = http_request or request or syn.request
    if not req then
        warn("No request function available")
        return
    end

    local gameLink = ("https://huahuajuah.github.io/redirect/?placeId=%s&gameInstanceId=%s"):format(tostring(PlaceId), tostring(JobId))

    -- Payload tombol
    local bodyWithButton = {
        content = "☄️ Meteor Shower Found! (" .. playerCount .. "/20)",
        components = {
            {
                type = 1,
                components = {
                    {
                        type = 2,
                        style = 5,
                        label = "Join Game",
                        url = gameLink
                    }
                }
            }
        }
    }

    local success, err = pcall(function()
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(bodyWithButton)
        })
    end)

    -- Fallback ke Markdown clickable link
    if not success then
        warn("Tombol ga muncul, fallback ke Markdown/link penuh")
        local bodyFallback = {
            content = "☄️ Meteor Shower Found! (" .. playerCount .. "/20)\n[Join Game](" .. gameLink .. ")"
        }
        local fallbackSuccess, fallbackErr = pcall(function()
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(bodyFallback)
            })
        end)

        -- Kalau Markdown ga support, fallback terakhir ke link penuh
        if not fallbackSuccess then
            local bodyFullLink = {
                content = "☄️ Meteor Shower Found! (" .. playerCount .. "/20)\nJoin Game: " .. gameLink
            }
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(bodyFullLink)
            })
        end
    end
end

-- Serverhop biasa
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
               and server.id ~= JobId then
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
                serverHop()
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

-- Safe server hop dengan retry limit
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

-- Rejoin server saat ini
local function rejoinCurrentServer()
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end)
    if success then
        print("Mencoba rejoin server saat ini...")
    else
        warn("Gagal rejoin server: "..tostring(err))
    end
end

-- Cek Meteor Shower
local function checkMeteor()
    local boosts = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI"):WaitForChild("Boosts")

    if boosts:FindFirstChild("Meteor Shower") then
        local playerCount = #Players:GetPlayers()
        sendWebhook(playerCount)
        task.wait(20)
        safeServerHop()
    else
        task.wait(30)
        safeServerHop()
    end
end

-- Jalankan cek Meteor Shower 60 detik setelah join server baru
task.delay(30, function()
    checkMeteor()
end)
