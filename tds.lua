local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CASH_PATH = game.Players.LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values.cash.amount

-- Current cash parser
local function getCash()
    local rawText = CASH_PATH.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "") -- removes $ and commas
    return tonumber(cleaned) or 0
end

_G.recordedMacro = {}
local lastTime = tick()

-- 🧠 Hook __namecall instead of .InvokeServer
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if method == "InvokeServer" and self.Name == "RemoteFunction" then
        local now = tick()
        local delta = now - lastTime
        lastTime = now

        local currentCash = getCash()
        wait(0.1)
        local newCash = getCash()
        local cost = math.abs(currentCash - newCash)

        local entry = { time = delta, cost = cost }

        if args[1] == "Troops" and args[2] == "Place" then
            entry.type = "place"
            entry.tower = args[4]
            entry.position = args[3].Position
            entry.rotation = args[3].Rotation
            print("🪖 Placed:", entry.tower, "- Cost:", cost)

        elseif args[1] == "Troops" and args[2] == "Upgrade" then
            local pos = args[4].Troop and args[4].Troop:FindFirstChild("HumanoidRootPart") and args[4].Troop.HumanoidRootPart.Position
            entry.type = "upgrade"
            entry.position = pos or Vector3.new()
            entry.path = args[4].Path
            print("🔼 Upgraded near:", tostring(entry.position), "- Cost:", cost)
        end

        if entry.type then
            table.insert(_G.recordedMacro, entry)
        end
    end

    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

print("✅ Macro recorder with cost tracking is now active!")
