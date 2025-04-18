-- 📦 Auto Macro Recorder with Cash Tracking
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local CASH_PATH = game.Players.LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values.cash.amount

-- Get current cash (cleans formatting)
local function getCash()
    local rawText = CASH_PATH.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "") -- remove $ and commas
    return tonumber(cleaned) or 0
end

-- Macro data + timing
_G.recordedMacro = {}
local lastTime = tick()

-- Hook RemoteFunction.InvokeServer
local originalInvokeServer = RemoteFunction.InvokeServer
RemoteFunction.InvokeServer = function(self, ...)
    local args = { ... }
    local now = tick()
    local delta = now - lastTime
    lastTime = now

    local currentCash = getCash()
    wait(0.1) -- give the server time to process the cash change
    local newCash = getCash()
    local cost = math.abs(currentCash - newCash)

    local entry = { time = delta, cost = cost }

    if args[1] == "Troops" and args[2] == "Place" then
        entry.type = "place"
        entry.tower = args[4]
        entry.position = args[3].Position
        entry.rotation = args[3].Rotation
        print("🪖 Recorded tower placement:", entry.tower, "- Cost:", cost)

    elseif args[1] == "Troops" and args[2] == "Upgrade" then
        local pos = args[4].Troop and args[4].Troop:FindFirstChild("HumanoidRootPart") and args[4].Troop.HumanoidRootPart.Position
        entry.type = "upgrade"
        entry.position = pos or Vector3.new()
        entry.path = args[4].Path
        print("🔼 Recorded tower upgrade - Cost:", cost)
    end

    if entry.type then
        table.insert(_G.recordedMacro, entry)
    end

    return originalInvokeServer(self, unpack(args))
end

print("🎥 Macro recorder with auto-cost tracking started!")
