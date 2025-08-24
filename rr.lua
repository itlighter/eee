-- Test webhook dengan pesan yang kamu minta

local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1409010090517856297/mwsigy2jqmKyqbDp1DAgIrQp_40Ef6n4VUX8iFq0l1fWwzj22Ce2zz8mF9ezTAs5422k"

-- Cari request function

local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

if not req then

    warn("❌ No request function available")

    return

end

print("🔄 Sending test webhook message...")

-- Pesan yang kamu minta

local body = {
    content = "☄️ Meteor Shower Found!\n/20\n[🚀 **Click to Join Server**]("roblox://placeId=129827112113663&gameInstanceId=0f2d6fe3-94dc-407a-81ff-bce58be34563")"
}

local success, response = pcall(function()

    return req({

        Url = WEBHOOK_URL,

        Method = "POST",

        Headers = {["Content-Type"] = "application/json"},

        Body = HttpService:JSONEncode(body)

    })

end)

print("\n=== WEBHOOK TEST RESULTS ===")

if success then

    print("✅ Request sent successfully!")

else

    warn("❌ Request failed:", tostring(response))

end

print("=== END TEST ===")

-- Alternative dengan button yang bisa diklik

print("\n🔄 Sending enhanced version with clickable button...")

local enhancedBody = {

    content = "☄️ Meteor Shower Found! ☄️\n👥 Players: 14/20",

    components = {

        {

            type = 1,

            components = {

                {

                    type = 2,

                    label = "🚀 Join Server",

                    style = 5,

                    url = "roblox://placeId=129827112113663&gameInstanceId=0f2d6fe3-94dc-407a-81ff-bce58be34563"

                }

            }

        }

    }

}

local success2, response2 = pcall(function()

    return req({

        Url = WEBHOOK_URL,

        Method = "POST",

        Headers = {["Content-Type"] = "application/json"},

        Body = HttpService:JSONEncode(enhancedBody)

    })

end)

if success2 then

    print("✅ Enhanced webhook sent!")

    if response2 and response2.StatusCode then

        print("📊 Enhanced Status:", response2.StatusCode)

    end

else

    warn("❌ Enhanced webhook failed:", tostring(response2))

end
