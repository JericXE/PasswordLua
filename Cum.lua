--=============================--
--       Configuration         --
--=============================--

local folderPath = "/storage/emulated/0/"
local filePath = folderPath .. "/a.txt"
local expiryDuration = 1 * 2 * 60 -- 6 hours

local Passkey1 = "11"
local Passkey2 = "22"
local Passkey3 = "31"

local keyLinks = {
    [1] = "https://link-hub.net/167243/passkey-11",
    [2] = "https://link-hub.net/167243/passkey-111",
    [3] = "https://link-hub.net/167243/passkey-113",
}

--=============================--
--      Utility Functions      --
--=============================--

-- Read saved keys and expiry times
function readSavedKeys()
    local keys = {}
    local expiries = {}
    local f = io.open(filePath, "r")
    if not f then return keys, expiries end

    for line in f:lines() do
        local k, v = line:match("^(Passkey%d):%s*(.+)$")
        if k and v then
            local idx = tonumber(k:match("(%d)"))
            keys[idx] = v
        end

        local ek, ev = line:match("^(Passkey%dExpiry):%s*(%d+)$")
        if ek and ev then
            local idx = tonumber(ek:match("(%d)"))
            expiries[idx] = tonumber(ev)
        end
    end
    f:close()
    return keys, expiries
end

-- Save key and expiry to file
function saveKey(step, value)
    local keys, expiries = readSavedKeys()
    keys[step] = value
    expiries[step] = os.time() + expiryDuration

    local f = io.open(filePath, "w")
    if f then
        for i = 1, 3 do
            if keys[i] then
                f:write("Passkey" .. i .. ": " .. keys[i] .. "\n")
                f:write("Passkey" .. i .. "Expiry: " .. expiries[i] .. "\n")
            end
        end
        f:close()
    else
        gg.alert("❌ [ FILE ERROR ] ❌\n\nUnable to write password file!\n📄 Path:\n" .. filePath)
    end
end

--=============================--
--         Key Prompt          --
--=============================--

-- Prompt user for the key
function askKey(step)
    local correctKeys = {Passkey1, Passkey2, Passkey3}
    local link = keyLinks[step]

    while true do
        local input = gg.prompt(
            {"🔑 Enter Key:", "🔗 Get Key"},
            {"", false},
            {"text", "checkbox"}
        )

        if not input then
            gg.toast("❌ [Cancelled] Exiting script... Please try again later.")
            os.exit()
        end

        local entered = input[1]
        local getKey = input[2]

        if getKey then
            gg.copyText(link)
            gg.toast("📋 [LINK] New link copied. Please get your key from the link.")
        elseif entered == "" or entered == nil then
            gg.alert("⚠️ [Empty Input] Password cannot be empty. Please enter a valid key.")
        elseif entered == correctKeys[step] then
            -- For Key 1 and Key 2, if the entered key is correct
            if step == 1 or step == 2 then
                gg.alert("🔑 [Validation Failed] Key validation failed. New link generated.")
                  -- Provide new link
                gg.toast("📋 New link copied to clipboard. Please get the correct key.")
            end
            saveKey(step, entered)
            gg.toast("✅ [Success] Key " .. step .. " validated successfully!")
            return entered
        else
            -- If key is wrong for any step
            gg.alert("❌ [Wrong Key] The key entered is incorrect. Please try again.")
        end
    end
end

--=============================--
--          Main Flow          --
--=============================--

-- Start the key validation process
function startKeySequence()
    local keys, expiries = readSavedKeys()
    local correctKeys = {Passkey1, Passkey2, Passkey3}

    -- Check the validity of each key in order
    for step = 1, 3 do
        local isValid = keys[step] == correctKeys[step] and expiries[step] and os.time() < expiries[step]

        if isValid then
            -- If key is already valid, skip to the next one
            gg.toast("✅ [SKIPPED] Key " .. step .. " is already validated. Skipping...")
        else
            -- If the key is invalid or missing, ask for the key
            askKey(step)
        end
    end

    -- All keys validated successfully
    gg.toast("🎉 [SUCCESS] All keys validated! Access granted. Enjoy!")
end

startKeySequence()
