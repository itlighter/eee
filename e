--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408441169028972797/_ls8aguNPMDTgrO6yJ6l72p5CXjUD56md_gy6t7xN0Lkf69pqhxaHFTddOtwkX1a3W0Q"
local MAX_DISCORD_MSG = 1800 -- jaga-jaga di bawah 2000

--// Services
local HttpService = game:GetService("HttpService")

-- Kumpulan service “umum” + nanti ditambah semua anak game:GetChildren()
local PREFERRED_SERVICES = {
    "Workspace",
    "ReplicatedStorage",
    "StarterGui",
    "Players",
    "Lighting",
    "ReplicatedFirst",
    "ServerScriptService",
    "ServerStorage",
    "StarterPack",
    "SoundService",
    "TextService",
    "UserInputService",
    "TweenService",
    "CollectionService",
    "GuiService",
    "RunService",
}

-- Keywords (lowercase semua)
local keywords = {
    "merchant","traveling","wandering","trader",
    "quake","blitz","backpack","instability","enchant"
}

-- util: cek ada keyword (substring, case-insensitive)
local function hasKeyword(name)
    local lower = string.lower(name)
    for _, w in ipairs(keywords) do
        -- plain=true supaya bukan pattern; tetap substring match (biar gak “keskip”)
        if string.find(lower, w, 1, true) then
            return true
        end
    end
    return false
end

-- kumpulkan services yang benar-benar ada & bisa diakses
local serviceSet = {}
local function addServiceByName(svcName)
    local ok, svc = pcall(function() return game:GetService(svcName) end)
    if ok and svc then serviceSet[svc] = true end
end
for _, name in ipairs(PREFERRED_SERVICES) do
    addServiceByName(name)
end
-- tambahkan semua top-level instance yang terlihat di Explorer (client-side)
for _, child in ipairs(game:GetChildren()) do
    serviceSet[child] = true
end

-- Scan
local results = {}
for svc in pairs(serviceSet) do
    local ok, list = pcall(function() return svc:GetDescendants() end)
    if ok and list then
        for _, obj in ipairs(list) do
            if hasKeyword(obj.Name) then
                local line = string.format("%s | %s", obj:GetFullName(), obj.ClassName)
                table.insert(results, line)
            end
        end
    else
        -- Service tidak bisa diakses client (contoh: ServerStorage/ServerScriptService). Abaikan diam-diam.
    end
end

-- Sort biar rapi
table.sort(results, function(a,b) return a < b end)

-- Print ke output
print("=== Hasil Pencarian (descendants, semua service yang terlihat) ===")
if #results == 0 then
    print("Tidak ada object yang cocok.")
else
    for _, line in ipairs(results) do
        print(line)
    end
end

-- Kirim ke Discord (dibagi batch agar tidak melebihi limit)
local request = (http_request or request or syn.request)
local function sendDiscord(text)
    if not request then
        warn("Tidak ada fungsi request yang tersedia (http_request/request/syn.request).")
        return
    end
    local body = HttpService:JSONEncode({ content = text })
    request({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = body
    })
end

if #results == 0 then
    sendDiscord("Tidak ada object yang cocok.")
else
    local header = "=== Hasil Pencarian ===\n" ..
                   "(keywords: merchant, traveling, wandering, trader, quake, blitz, backpack, instability, enchant, book)\n"
    local chunk = header
    for i, line in ipairs(results) do
        local candidate = ((#chunk > 0) and (chunk .. line .. "\n")) or (line .. "\n")
        if #candidate > MAX_DISCORD_MSG then
            sendDiscord(chunk)
            chunk = line .. "\n"
        else
            chunk = candidate
        end
    end
    if #chunk > 0 then
        sendDiscord(chunk)
    end
end
