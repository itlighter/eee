--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408441169028972797/_ls8aguNPMDTgrO6yJ6l72p5CXjUD56md_gy6t7xN0Lkf69pqhxaHFTddOtwkX1a3W0Q"

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- daftar kata kunci
local keywords = {"merchant", "traveling", "wandering", "trader"}

-- fungsi untuk cek apakah nama mengandung keyword
local function hasKeyword(name)
	for _, word in ipairs(keywords) do
		if string.find(string.lower(name), word) then
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
end

-- kumpulkan semua hasil
local matches = {}
for _, service in ipairs({Workspace, ReplicatedStorage, PlayerGui}) do
	for _, objName in ipairs(getMatchingDescendants(service)) do
		table.insert(matches, objName)
	end
end

-- print hasil ke output
print("=== Ditemukan Object ===")
for _, name in ipairs(matches) do
	print(name)
end

-- siapkan pesan buat discord
local content
if #matches > 0 then
	content = "=== Ditemukan Object ===\n" .. table.concat(matches, "\n")
else
	content = "Tidak ada object yang ditemukan."
end

-- kirim ke discord pakai exploit request
local data = {content = content}
local body = HttpService:JSONEncode(data)
local request = (http_request or request or syn.request)

if request then
	request({
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = body
	})
	print("✅ Berhasil dikirim ke Discord")
else
	warn("❌ Tidak ada fungsi request yang tersedia")
end
