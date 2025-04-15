--// Macro System for New Tower Defense Game
--// Features: Create, Record, Playback macros with GUI + Auto-detection

--// Config
local macroFolder = "macros"
if not isfolder(macroFolder) then makefolder(macroFolder) end

--// GUI Setup
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "MacroSystem"

local function createButton(text, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 150, 0, 30)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = ScreenGui
    return btn
end

local function createTextbox(position, placeholder)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 150, 0, 30)
    box.Position = position
    box.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.Font = Enum.Font.SourceSans
    box.TextSize = 16
    box.Parent = ScreenGui
    return box
end

local function createDropdown(position)
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0, 150, 0, 30)
    dropdown.Position = position
    dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdown.TextColor3 = Color3.fromRGB(200, 200, 200)
    dropdown.Text = "Select Macro"
    dropdown.Font = Enum.Font.SourceSans
    dropdown.TextSize = 14
    dropdown.Parent = ScreenGui

    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(0, 150, 0, 100)
    optionsFrame.Position = UDim2.new(0, position.X.Offset, 0, position.Y.Offset + 30)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    optionsFrame.Visible = false
    optionsFrame.Parent = ScreenGui

    local selectedMacro = nil

    local function listMacros()
        return listfiles(macroFolder)
    end

    local function updateOptions()
        optionsFrame:ClearAllChildren()
        local y = 0
        for _, file in ipairs(listMacros()) do
            local name = file:match("[^/\\]+$") or file
            local opt = Instance.new("TextButton")
            opt.Size = UDim2.new(1, 0, 0, 20)
            opt.Position = UDim2.new(0, 0, 0, y)
            opt.Text = name
            opt.TextSize = 14
            opt.TextColor3 = Color3.fromRGB(255,255,255)
            opt.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            opt.Parent = optionsFrame
            y = y + 20

            opt.MouseButton1Click:Connect(function()
                selectedMacro = name
                dropdown.Text = name
                optionsFrame.Visible = false
            end)
        end
    end

    dropdown.MouseButton1Click:Connect(function()
        updateOptions()
        optionsFrame.Visible = not optionsFrame.Visible
    end)

    return function()
        return selectedMacro
    end
end

-- GUI Elements
local createBox = createTextbox(UDim2.new(0, 10, 0, 10), "Enter macro name")
local createBtn = createButton("Create Macro", UDim2.new(0, 170, 0, 10))
local getSelected = createDropdown(UDim2.new(0, 10, 0, 50))
local recordBtn = createButton("Record", UDim2.new(0, 170, 0, 50))
local playBtn = createButton("Play", UDim2.new(0, 330, 0, 50))

-- Macro System Vars
local recording = false
local currentRecording = {}

-- Hooking RemoteFunction Calls
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if method == "InvokeServer" and tostring(self) == "RemoteFunction" and recording then
        table.insert(currentRecording, args)
    end

    return oldNamecall(self, ...)
end)

-- Buttons
createBtn.MouseButton1Click:Connect(function()
    local name = createBox.Text
    if name ~= "" then
        writefile(macroFolder.."/"..name..".txt", "[]")
        print("-- Macro created:", name)
    end
end)

recordBtn.MouseButton1Click:Connect(function()
    local macro = getSelected()
    if macro then
        recording = not recording
        recordBtn.Text = recording and "Stop" or "Record"
        if not recording then
            writefile(macroFolder.."/"..macro, game:GetService("HttpService"):JSONEncode(currentRecording))
            print("-- Saved macro:", macro)
        else
            currentRecording = {}
            print("-- Recording started for:", macro)
        end
    else
        warn("No macro selected!")
    end
end)

playBtn.MouseButton1Click:Connect(function()
    local macro = getSelected()
    if macro and isfile(macroFolder.."/"..macro) then
        local data = readfile(macroFolder.."/"..macro)
        local steps = game:GetService("HttpService"):JSONDecode(data)
        for _, args in ipairs(steps) do
            pcall(function()
                game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
                wait(1)
            end)
        end
    end
end)

-- Auto playback on match start
-- Add this section to your playback logic
local function loadMacro(name)
    local path = "workspace/macros/" .. name .. ".txt"
    if not isfile(path) then
        warn("[Macro Playback] Macro file not found: " .. name)
        return nil
    end
    local contents = readfile(path)
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(contents)
    end)
    if not success then
        warn("[Macro Playback] Failed to decode macro file:", data)
        return nil
    end
    print("[Macro Playback] Loaded macro:", name, "(" .. #data .. " actions)")
    return data
end

local function playbackMacro(macroData)
    for index, action in ipairs(macroData) do
        print("[Macro Playback] Action", index, ":", action.type, action.unit or "", action.position or "", action.rotation or "")

        local args
        if action.type == "place" then
            args = {
                "Troops",
                "Pl\208\176ce",
                {
                    Position = loadstring("return " .. action.position)(),
                    Rotation = loadstring("return " .. action.rotation)()
                },
                action.unit
            }
        elseif action.type == "upgrade" then
            args = {
                "Troops",
                "Upgrade",
                "Set",
                {
                    Troop = workspace:FindFirstChild("Towers") and workspace.Towers:FindFirstChild(action.name),
                    Path = 1
                }
            }
        else
            warn("[Macro Playback] Unknown action type:", action.type)
            continue
        end

        print("[Macro Playback] Calling RemoteFunction with args:", unpack(args))
        local success, result = pcall(function()
            return game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
        end)

        if success then
            print("[Macro Playback] Action", index, "success ✅")
        else
            warn("[Macro Playback] Action", index, "failed ❌", result)
        end

        wait(0.5) -- slight delay between actions
    end
end
