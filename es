-- // ambil service
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // ganti dengan webhook lu
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408117042258907196/3oTINE7iMaUWGMtvHf22XViEI9Fd3CeifOnzdiE9_3QU8BPHKalaps3ej3aq0riV9Opf"

-- // fungsi buat kirim ke discord
local function sendToDiscord(message)
    local req = (http_request or request or syn.request)
    if req then
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = message})
        })
    else
        warn("Exploit lu ga support HTTP Request")
    end
end

-- // ambil folder Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- // kumpulin semua remote
local remotesList = {}
for _, obj in ipairs(remotesFolder:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        table.insert(remotesList, obj:GetFullName() .. " [" .. obj.ClassName .. "]")
    end
end

-- // gabung jadi string
local msg = "📡 **List Remote di ReplicatedStorage.Remotes**\n" .. table.concat(remotesList, "\n")

-- // kirim ke Discord
sendToDiscord(msg)
