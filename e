--// Config
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408441169028972797/_ls8aguNPMDTgrO6yJ6l72p5CXjUD56md_gy6t7xN0Lkf69pqhxaHFTddOtwkX1a3W0Q" -- ganti
local MAX_DISCORD_MSG = 1800 -- jaga2 biar gak tembus limit 2000

--// Services
local HttpService = game:GetService("HttpService")

-- Request function
local request = (http_request or request or syn.request)

local function sendDiscord(text)
	if not request then
		warn("Tidak ada fungsi request (http_request/request/syn.request).")
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

-- Cek semua Tool
local tools = {}
for _, descendant in ipairs(game:GetDescendants()) do
	if descendant:IsA("Tool") then
		table.insert(tools, descendant)
	end
end

print("Jumlah Tool ditemukan:", #tools)

if #tools == 0 then
	sendDiscord("Tidak ada Tool ditemukan.")
else
	for _, tool in ipairs(tools) do
		local success, props = pcall(function()
			return tool:GetAttributes() -- ambil attribute custom dulu
		end)

		local text = "=== TOOL: " .. tool:GetFullName() .. " ===\n"

		-- Ambil property bawaan
		for _, prop in ipairs(tool:GetProperties()) do
			local val
			pcall(function() val = tostring(tool[prop]) end)
			if val then
				text ..= prop .. " = " .. val .. "\n"
			end
		end

		-- Tambah attributes kalau ada
		if success and props then
			for k,v in pairs(props) do
				text ..= "[Attr] " .. k .. " = " .. tostring(v) .. "\n"
			end
		end

		-- Discord chunk
		if #text > MAX_DISCORD_MSG then
			-- potong per batch
			local chunk = ""
			for line in string.gmatch(text, "([^\n]+)\n") do
				if #chunk + #line + 1 > MAX_DISCORD_MSG then
					sendDiscord(chunk)
					chunk = line .. "\n"
				else
					chunk ..= line .. "\n"
				end
			end
			if #chunk > 0 then sendDiscord(chunk) end
		else
			sendDiscord(text)
		end
	end
end
