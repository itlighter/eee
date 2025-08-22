--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408441169028972797/_ls8aguNPMDTgrO6yJ6l72p5CXjUD56md_gy6t7xN0Lkf69pqhxaHFTddOtwkX1a3W0Q"
local MAX_DISCORD_MSG = 1800 -- jaga-jaga di bawah 2000

--// Services
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- daftar kata kunci
local keywords = {"merchant", "traveling", "wandering", "trader"}
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

-- fungsi untuk cek apakah nama mengandung keyword
-- Keywords (lowercase semua)
local keywords = {
    "merchant","traveling","wandering","trader",
    "quake","blitz","backpack","instability","enchant","book"
}

-- util: cek ada keyword (substring, case-insensitive)
local function hasKeyword(name)
	for _, word in ipairs(keywords) do
		if string.find(string.lower(name), word) then
			return true
		end
	end
	return false
    local lower = string.lower(name)
    for _, w in ipairs(keywords) do
        -- plain=true supaya bukan pattern; tetap substring match (biar gak “keskip”)
        if string.find(lower, w, 1, true) then
            return true
        end
    end
    return false
end

-- fungsi untuk ambil semua descendant yang cocok
local function getMatchingDescendants(parent)
	local results = {}
	for _, obj in ipairs(parent:GetDescendants()) do
		if hasKeyword(obj.Name) then
			table.insert(results, obj:GetFullName())
		end
	end
	return results
-- kumpulkan services yang benar-benar ada & bisa diakses
local serviceSet = {}
local function addServiceByName(svcName)
    local ok, svc = pcall(function() return game:GetService(svcName) end)
    if ok and svc then serviceSet[svc] = true end
end

-- kumpulkan semua hasil
local matches = {}
for _, service in ipairs({Workspace, ReplicatedStorage, PlayerGui}) do
	for _, objName in ipairs(getMatchingDescendants(service)) do
		table.insert(matches, objName)
	end
for _, name in ipairs(PREFERRED_SERVICES) do
    addServiceByName(name)
end
-- tambahkan semua top-level instance yang terlihat di Explorer (client-side)
for _, child in ipairs(game:GetChildren()) do
    serviceSet[child] = true
end

-- print hasil ke output
print("=== Ditemukan Object ===")
for _, name in ipairs(matches) do
	print(name)
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

-- siapkan pesan buat discord
local content
if #matches > 0 then
	content = "=== Ditemukan Object ===\n" .. table.concat(matches, "\n")
-- Sort biar rapi
table.sort(results, function(a,b) return a < b end)

-- Print ke output
print("=== Hasil Pencarian (descendants, semua service yang terlihat) ===")
if #results == 0 then
    print("Tidak ada object yang cocok.")
else
	content = "Tidak ada object yang ditemukan."
    for _, line in ipairs(results) do
        print(line)
    end
end

-- kirim ke discord pakai exploit request
local data = {content = content}
local body = HttpService:JSONEncode(data)
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

if request then
	request({
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = body
	})
	print("✅ Berhasil dikirim ke Discord")
if #results == 0 then
    sendDiscord("Tidak ada object yang cocok.")
else
	warn("❌ Tidak ada fungsi request yang tersedia")
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
