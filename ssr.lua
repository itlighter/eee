-- Quick webhook test - run this first to check if webhooks work
local HttpService = game:GetService("HttpService")
local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k"

print("=== WEBHOOK DEBUG TEST ===")

-- Check request functions
local req_functions = {
    {"http_request", http_request},
    {"request", request},
    {"syn.request", syn and syn.request},
    {"fluxus.request", fluxus and fluxus.request}
}

local working_req = nil
for _, func_data in ipairs(req_functions) do
    local name, func = func_data[1], func_data[2]
    if func then
        print("✅ Found:", name)
        working_req = func
        break
    else
        print("❌ Missing:", name)
    end
end

if not working_req then
    warn("❌ NO REQUEST FUNCTIONS AVAILABLE!")
    warn("💡 Your executor doesn't support HTTP requests")
    return
end

-- Test the webhook
print("\n🧪 Testing webhook...")
local success, response = pcall(function()
    return working_req({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = "🧪 **TEST MESSAGE**\nIf you see this, webhooks are working!"
        })
    })
end)

if success then
    print("✅ Webhook request sent!")
    if response and response.StatusCode then
        print("📊 Status Code:", response.StatusCode)
        if response.StatusCode == 204 or response.StatusCode == 200 then
            print("🎉 SUCCESS! Check your Discord channel!")
        else
            warn("⚠️ Unexpected status code - might still work")
        end
    end
else
    warn("❌ Webhook failed:", tostring(response))
end

print("\n=== END TEST ===")
