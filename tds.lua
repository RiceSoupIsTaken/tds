-- Macro System with GUI
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Remote setup
local towerService = game:GetService("ReplicatedStorage")
    :WaitForChild("ReplicatedStorage_Source")
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("TowerDefenceTowersService")
    :WaitForChild("RF")

local placeTower = towerService:WaitForChild("PlaceTower")
local upgradeTower = towerService:WaitForChild("UpgradeTower")

local placementPart = workspace:WaitForChild("TowerDefence")
    :WaitForChild("PlacementZones")
    :WaitForChild("Part")

-- Filepath setup
local macroFolder = "workspace/macros"
if not isfolder(macroFolder) then
    makefolder(macroFolder)
end

-- State
local currentMacroName = nil
local recording = false
local playing = false
local recordedActions = {}
local startTime = nil

-- Cash helper
local function getCash()
    local moneyLabel = Player.PlayerGui:WaitForChild("LocalCoreGui")
        .GameInformation.MoneyFrame.Frame.Money
    local text = moneyLabel.Text:gsub("[^%d]", "")
    return tonumber(text) or 0
end

local function waitForCashAndInvoke(minCash, callback)
    repeat
        while getCash() < minCash do wait(0.5) end
        local success = pcall(callback)
        if not success then wait(1) end
    until success
    wait(1)
end

-- Action Wrappers (override remotes for recording)
local origPlace = placeTower.InvokeServer
placeTower.InvokeServer = function(self, towerName, pos, part)
    if recording and currentMacroName then
        table.insert(recordedActions, {
            time = tick() - startTime,
            type = "place",
            tower = towerName,
            position = { X = pos.X, Y = pos.Y, Z = pos.Z }
        })
    end
    return origPlace(self, towerName, pos, part)
end

local origUpgrade = upgradeTower.InvokeServer
upgradeTower.InvokeServer = function(self, index)
    if recording and currentMacroName then
        table.insert(recordedActions, {
            time = tick() - startTime,
            type = "upgrade",
            index = index
        })
    end
    return origUpgrade(self, index)
end

-- Playback Logic
local function playMacro(data)
    playing = true
    local start = tick()
    for _, action in ipairs(data) do
        local waitTime = action.time - (tick() - start)
        if waitTime > 0 then wait(waitTime) end

        if action.type == "place" then
            local pos = Vector3.new(action.position.X, action.position.Y, action.position.Z)
            waitForCashAndInvoke(300, function()
                placeTower:InvokeServer("Cashier", pos, placementPart)
            end)
        elseif action.type == "upgrade" then
            waitForCashAndInvoke(400, function()
                upgradeTower:InvokeServer(action.index)
            end)
        end
    end
    playing = false
end

-- GUI
local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
gui.Name = "MacroUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "⚙️ Macro Manager"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true

-- Dropdown for macros
local macroDropdown = Instance.new("TextBox", frame)
macroDropdown.PlaceholderText = "Enter Macro Name"
macroDropdown.Position = UDim2.new(0, 10, 0, 40)
macroDropdown.Size = UDim2.new(0, 200, 0, 30)
macroDropdown.Text = ""

-- Create Button
local createButton = Instance.new("TextButton", frame)
createButton.Position = UDim2.new(0, 220, 0, 40)
createButton.Size = UDim2.new(0, 70, 0, 30)
createButton.Text = "Create"

-- Record Checkbox
local recordToggle = Instance.new("TextButton", frame)
recordToggle.Position = UDim2.new(0, 10, 0, 80)
recordToggle.Size = UDim2.new(0, 140, 0, 30)
recordToggle.Text = "☐ Record Macro"

-- Play Checkbox
local playToggle = Instance.new("TextButton", frame)
playToggle.Position = UDim2.new(0, 160, 0, 80)
playToggle.Size = UDim2.new(0, 130, 0, 30)
playToggle.Text = "☐ Play Macro"

-- UI Behavior
createButton.MouseButton1Click:Connect(function()
    local name = macroDropdown.Text
    if name and name ~= "" then
        local path = macroFolder.."/"..name..".json"
        writefile(path, "[]")
        print("✅ Created macro:", name)
    end
end)

recordToggle.MouseButton1Click:Connect(function()
    if not recording then
        local name = macroDropdown.Text
        if name and name ~= "" then
            currentMacroName = name
            recordedActions = {}
            startTime = tick()
            recording = true
            recordToggle.Text = "☑ Recording..."
            print("🎥 Recording started:", name)
        end
    else
        recording = false
        recordToggle.Text = "☐ Record Macro"
        local path = macroFolder.."/"..currentMacroName..".json"
        writefile(path, HttpService:JSONEncode(recordedActions))
        print("💾 Recording saved to", path)
    end
end)

playToggle.MouseButton1Click:Connect(function()
    if not playing then
        local name = macroDropdown.Text
        local path = macroFolder.."/"..name..".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            playToggle.Text = "☑ Playing..."
            task.spawn(function()
                playMacro(data)
                playToggle.Text = "☐ Play Macro"
            end)
        else
            warn("❌ Macro not found:", name)
        end
    else
        warn("Already playing a macro.")
    end
end)
