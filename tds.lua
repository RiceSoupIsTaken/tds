-- 🧠 MACRO SYSTEM GUI + RECORDER + PLAYER

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

-- 🗂 Folder Setup
if not isfolder("workspace/macro") then
    makefolder("workspace/macro")
end

-- 🌍 Globals
_G.selectedMacroName = nil
_G.recordedMacro = {}
_G.isRecording = false
_G.isPlaying = false

-- 🛠 Helpers
local function saveMacro(name, data)
    writefile("workspace/macro/" .. name .. ".json", HttpService:JSONEncode(data))
end

local function loadMacro(name)
    local path = "workspace/macro/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

local function getMacroList()
    local files = listfiles("workspace/macro")
    local macros = {}
    for _, f in pairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name then table.insert(macros, name) end
    end
    return macros
end

local function getCash()
    local cashBox = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ReactUniversalHotbar").Frame.values.cash
    return tonumber(cashBox.Text:gsub(",", "")) or 0
end

-- 🎨 GUI
local gui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "MacroGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Macro Manager"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local inputBox = Instance.new("TextBox", frame)
inputBox.PlaceholderText = "Enter Macro Name"
inputBox.Position = UDim2.new(0, 10, 0, 40)
inputBox.Size = UDim2.new(0, 200, 0, 25)

local createBtn = Instance.new("TextButton", frame)
createBtn.Text = "Create Macro"
createBtn.Position = UDim2.new(0, 215, 0, 40)
createBtn.Size = UDim2.new(0, 75, 0, 25)
createBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)

local dropdown = Instance.new("TextButton", frame)
dropdown.Text = "Select Macro"
dropdown.Position = UDim2.new(0, 10, 0, 75)
dropdown.Size = UDim2.new(1, -20, 0, 25)
dropdown.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

local recordBtn = Instance.new("TextButton", frame)
recordBtn.Position = UDim2.new(0, 10, 0, 110)
recordBtn.Size = UDim2.new(0, 130, 0, 30)
recordBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
recordBtn.Text = "Record"

local playBtn = Instance.new("TextButton", frame)
playBtn.Position = UDim2.new(0, 150, 0, 110)
playBtn.Size = UDim2.new(0, 140, 0, 30)
playBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
playBtn.Text = "Play"

-- 🧠 GUI Callbacks
createBtn.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    if name ~= "" then
        saveMacro(name, {})
        _G.selectedMacroName = name
        dropdown.Text = "Selected: " .. name
        print("Macro created: " .. name)
        inputBox.Text = ""
    end
end)

dropdown.MouseButton1Click:Connect(function()
    local macros = getMacroList()
    if #macros > 0 then
        _G.selectedMacroName = macros[1]
        dropdown.Text = "Selected: " .. _G.selectedMacroName
        print("Selected Macro:", _G.selectedMacroName)
    else
        dropdown.Text = "No macros"
    end
end)

recordBtn.MouseButton1Click:Connect(function()
    _G.isRecording = not _G.isRecording
    recordBtn.Text = _G.isRecording and "Recording..." or "Record"
    if not _G.isRecording and _G.selectedMacroName then
        saveMacro(_G.selectedMacroName, _G.recordedMacro)
        print("💾 Saved macro:", _G.selectedMacroName)
        _G.recordedMacro = {}
    end
end)

playBtn.MouseButton1Click:Connect(function()
    if not _G.selectedMacroName then
        warn("⚠️ Select a macro first!")
        return
    end
    _G.isPlaying = true
    playBtn.Text = "Playing..."
end)

-- 🔴 Recorder Hook
local lastTime = tick()
local originalInvoke = RemoteFunction.InvokeServer
RemoteFunction.InvokeServer = function(self, ...)
    local args = {...}
    if _G.isRecording and _G.selectedMacroName then
        local delta = tick() - lastTime
        lastTime = tick()

        local log = nil
        if args[1] == "Troops" and args[2] == "Place" then
            log = {
                action = "place",
                position = args[3].Position,
                rotation = args[3].Rotation,
                towerType = args[4],
                time = delta
            }
        elseif args[1] == "Troops" and args[2] == "Upgrade" then
            local pos = args[4].Troop and args[4].Troop:FindFirstChild("HumanoidRootPart") and args[4].Troop.HumanoidRootPart.Position
            log = {
                action = "upgrade",
                troopPos = pos or Vector3.new(),
                path = args[4].Path,
                time = delta
            }
        end

        if log then
            table.insert(_G.recordedMacro, log)
            print("🔴 Recorded:", log.action)
        end
    end
    return originalInvoke(self, unpack(args))
end

-- ▶️ Playback Runner
task.spawn(function()
    while true do
        task.wait(1)
        if _G.isPlaying then
            local path = "workspace/macro/" .. _G.selectedMacroName .. ".json"
            if not isfile(path) then warn("Macro file not found!"); return end

            local macro = HttpService:JSONDecode(readfile(path))
            for _, step in ipairs(macro) do
                if not _G.isPlaying then break end
                wait(step.time or 0.1)

                if step.action == "place" then
                    RemoteFunction:InvokeServer("Troops", "Place", {
                        Rotation = step.rotation,
                        Position = step.position
                    }, step.towerType)
                    print("✅ Placed:", step.towerType)
                elseif step.action == "upgrade" then
                    local closest = nil
                    local minDist = math.huge
                    for _, tower in ipairs(workspace.Towers:GetChildren()) do
                        if tower:FindFirstChild("HumanoidRootPart") then
                            local dist = (tower.HumanoidRootPart.Position - step.troopPos).magnitude
                            if dist < minDist then
                                closest = tower
                                minDist = dist
                            end
                        end
                    end
                    if closest then
                        RemoteFunction:InvokeServer("Troops", "Upgrade", "Set", {
                            Troop = closest,
                            Path = step.path
                        })
                        print("⬆️ Upgraded tower")
                    end
                end
            end
            _G.isPlaying = false
            playBtn.Text = "Play"
            print("⏹️ Playback finished.")
        end
    end
end)

print("✅ Macro System Loaded. Use GUI to record & play.")
