-- Advanced Tower Defense Macro System
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local MACRO_FOLDER = "TD_Macros"
local DEFAULT_MAP = "Unknown"
local PLAYBACK_DELAY = 0.1 -- Base delay between actions
local RECORDING_FORMAT = {
    Map = DEFAULT_MAP,
    GameVersion = "1.0",
    Created = os.date("%Y-%m-%d %H:%M:%S"),
    Actions = {}
}

-- Create macro folder if it doesn't exist
if not isfolder(MACRO_FOLDER) then
    makefolder(MACRO_FOLDER)
end

-- Main GUI Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroSystemGUI"
ScreenGui.Parent = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

-- Draggable Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Tower Defense Macro System"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -10, 1, -40)
ContentFrame.Position = UDim2.new(0, 5, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Macro System Variables
local MacroSystem = {
    Recording = false,
    Playing = false,
    Paused = false,
    CurrentMacro = table.clone(RECORDING_FORMAT),
    SelectedMacro = nil,
    PlaybackSpeed = 1.0,
    RemoteEvents = {
        Place = ReplicatedStorage:WaitForChild("PlaceTowerRemote"),
        Upgrade = ReplicatedStorage:WaitForChild("UpgradeTowerRemote"),
        Sell = ReplicatedStorage:FindFirstChild("SellTowerRemote"),
        Skip = ReplicatedStorage:FindFirstChild("SkipWaveRemote")
    }
}

-- Utility Functions
local function parsePosition(posString)
    local parts = string.split(posString, ", ")
    return Vector3.new(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
end

local function formatPosition(pos)
    return string.format("%.6f, %.6f, %.6f", pos.X, pos.Y, pos.Z)
end

local function getCurrentTime()
    local total = os.clock()
    local minutes = math.floor(total / 60)
    local seconds = total % 60
    return string.format("%d %.9f", minutes, seconds)
end

local function safeFireRemote(remote, ...)
    local args = {...}
    return pcall(function()
        remote:FireServer(unpack(args))
    end)
end

-- GUI Creation Functions
local function createButton(parent, text, size, position)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = parent
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end)
    
    return btn
end

local function createLabel(parent, text, position)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 0, 20)
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createTextbox(parent, placeholder, position)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 150, 0, 25)
    box.Position = position
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderText = placeholder
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.Parent = parent
    
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
    end)
    
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
    end)
    
    return box
end

-- Create Macro Dropdown
local function createMacroDropdown(parent)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 150, 0, 25)
    dropdownFrame.Position = UDim2.new(0, 10, 0, 10)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdownFrame.Parent = parent
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(1, 0, 1, 0)
    dropdownButton.Text = "Select Macro"
    dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownButton.Font = Enum.Font.SourceSans
    dropdownButton.TextSize = 14
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Parent = dropdownFrame
    
    local dropdownArrow = Instance.new("TextLabel")
    dropdownArrow.Size = UDim2.new(0, 20, 1, 0)
    dropdownArrow.Position = UDim2.new(1, -20, 0, 0)
    dropdownArrow.Text = "▼"
    dropdownArrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    dropdownArrow.Font = Enum.Font.SourceSans
    dropdownArrow.TextSize = 14
    dropdownArrow.BackgroundTransparency = 1
    dropdownArrow.Parent = dropdownFrame
    
    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.Size = UDim2.new(1, 0, 0, 150)
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    optionsFrame.Visible = false
    optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    optionsFrame.ScrollBarThickness = 5
    optionsFrame.Parent = dropdownFrame
    
    local function listMacros()
        local files = {}
        if isfolder(MACRO_FOLDER) then
            for _, file in ipairs(listfiles(MACRO_FOLDER)) do
                table.insert(files, file:match("[^/\\]+$"):gsub("%.json$", ""))
            end
        end
        return files
    end
    
    local function updateOptions()
        optionsFrame:ClearAllChildren()
        optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local macros = listMacros()
        local yOffset = 0
        
        for _, macroName in ipairs(macros) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, -5, 0, 25)
            optionButton.Position = UDim2.new(0, 5, 0, yOffset)
            optionButton.Text = macroName
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.Font = Enum.Font.SourceSans
            optionButton.TextSize = 14
            optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            optionButton.Parent = optionsFrame
            
            optionButton.MouseButton1Click:Connect(function()
                MacroSystem.SelectedMacro = macroName
                dropdownButton.Text = macroName
                optionsFrame.Visible = false
                dropdownArrow.Text = "▼"
            end)
            
            yOffset = yOffset + 25
            optionsFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
        end
        
        if #macros == 0 then
            local noMacrosLabel = Instance.new("TextLabel")
            noMacrosLabel.Size = UDim2.new(1, -10, 0, 25)
            noMacrosLabel.Position = UDim2.new(0, 5, 0, 0)
            noMacrosLabel.Text = "No macros found"
            noMacrosLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            noMacrosLabel.Font = Enum.Font.SourceSans
            noMacrosLabel.TextSize = 14
            noMacrosLabel.BackgroundTransparency = 1
            noMacrosLabel.Parent = optionsFrame
        end
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        updateOptions()
        optionsFrame.Visible = not optionsFrame.Visible
        dropdownArrow.Text = optionsFrame.Visible and "▲" or "▼"
    end)
    
    return dropdownFrame
end

-- Create GUI Elements
local macroDropdown = createMacroDropdown(ContentFrame)
local newMacroBox = createTextbox(ContentFrame, "New macro name", UDim2.new(0, 170, 0, 10))
local createButton = createButton(ContentFrame, "Create Macro", UDim2.new(0, 150, 0, 25), UDim2.new(0, 170, 0, 40))
local recordButton = createButton(ContentFrame, "Start Recording", UDim2.new(0, 150, 0, 25), UDim2.new(0, 10, 0, 80))
local playButton = createButton(ContentFrame, "Play Macro", UDim2.new(0, 150, 0, 25), UDim2.new(0, 170, 0, 80))
local pauseButton = createButton(ContentFrame, "Pause Playback", UDim2.new(0, 150, 0, 25), UDim2.new(0, 10, 0, 115))
local speedLabel = createLabel(ContentFrame, "Playback Speed: 1.0x", UDim2.new(0, 10, 0, 150))
local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(0, 310, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 170)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedSlider.Text = ""
speedSlider.Parent = ContentFrame

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.new(0.5, 0, 1, 0)
speedBar.Position = UDim2.new(0, 0, 0, 0)
speedBar.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
speedBar.Parent = speedSlider

local speedKnob = Instance.new("Frame")
speedKnob.Size = UDim2.new(0, 10, 1, 0)
speedKnob.Position = UDim2.new(0.5, -5, 0, 0)
speedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
speedKnob.Parent = speedSlider

-- Speed slider functionality
local function updateSpeed(positionX)
    local relativeX = math.clamp(positionX - speedSlider.AbsolutePosition.X, 0, speedSlider.AbsoluteSize.X)
    local ratio = relativeX / speedSlider.AbsoluteSize.X
    speedBar.Size = UDim2.new(ratio, 0, 1, 0)
    speedKnob.Position = UDim2.new(ratio, -5, 0, 0)
    
    -- Map ratio to speed (0.1x to 3x)
    MacroSystem.PlaybackSpeed = 0.1 + (ratio * 2.9)
    speedLabel.Text = string.format("Playback Speed: %.1fx", MacroSystem.PlaybackSpeed)
end

speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updateSpeed(input.Position.X)
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                connection:Disconnect()
            else
                updateSpeed(input.Position.X)
            end
        end)
    end
end)

-- Macro System Functions
function MacroSystem.startRecording()
    if MacroSystem.Playing then return false end
    
    MacroSystem.Recording = true
    MacroSystem.CurrentMacro = table.clone(RECORDING_FORMAT)
    MacroSystem.CurrentMacro.Created = os.date("%Y-%m-%d %H:%M:%S")
    MacroSystem.CurrentMacro.Map = DEFAULT_MAP -- Can be updated when game starts
    
    recordButton.Text = "Stop Recording"
    print("[Macro] Recording started")
    return true
end

function MacroSystem.stopRecording()
    if not MacroSystem.Recording then return false end
    
    MacroSystem.Recording = false
    recordButton.Text = "Start Recording"
    print("[Macro] Recording stopped. Total actions:", #MacroSystem.CurrentMacro.Actions)
    return true
end

function MacroSystem.saveMacro(name)
    if not name or name == "" then
        warn("[Macro] No name provided for saving")
        return false
    end
    
    if #MacroSystem.CurrentMacro.Actions == 0 then
        warn("[Macro] No actions to save")
        return false
    end
    
    local filename = MACRO_FOLDER.."/"..name..".json"
    local json = HttpService:JSONEncode(MacroSystem.CurrentMacro)
    
    writefile(filename, json)
    print("[Macro] Saved to:", filename)
    return true
end

function MacroSystem.loadMacro(name)
    if not name then return false end
    
    local filename = MACRO_FOLDER.."/"..name..".json"
    if not isfile(filename) then
        warn("[Macro] File not found:", filename)
        return false
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(filename))
    end)
    
    if not success then
        warn("[Macro] Failed to load macro:", data)
        return false
    end
    
    MacroSystem.CurrentMacro = data
    MacroSystem.SelectedMacro = name
    print("[Macro] Loaded macro:", name, "Actions:", #data.Actions)
    return true
end

function MacroSystem.playMacro()
    if MacroSystem.Recording or MacroSystem.Playing or #MacroSystem.CurrentMacro.Actions == 0 then
        return false
    end
    
    MacroSystem.Playing = true
    MacroSystem.Paused = false
    playButton.Text = "Stop Playback"
    
    print("[Macro] Playing macro:", MacroSystem.SelectedMacro or "Unsaved", "Speed:", MacroSystem.PlaybackSpeed.."x")
    
    -- Process actions with timing
    local startTime = os.clock()
    local lastActionTime = 0
    
    for i, action in ipairs(MacroSystem.CurrentMacro.Actions) do
        while MacroSystem.Paused do
            task.wait(0.1)
        end
        
        if not MacroSystem.Playing then
            break
        end
        
        -- Parse action time (format: "minutes seconds.decimal")
        local timeParts = string.split(action.Time, " ")
        local actionTime = (tonumber(timeParts[1]) or 0) * 60 + (tonumber(timeParts[2]) or 0)
        
        -- Calculate delay with speed adjustment
        local delay = (actionTime - lastActionTime) / MacroSystem.PlaybackSpeed
        if delay > 0 then
            task.wait(delay)
        end
        
        lastActionTime = actionTime
        
        -- Execute action
        if action.Type == "Place" then
            local pos = parsePosition(action.Pos)
            safeFireRemote(MacroSystem.RemoteEvents.Place, pos, action.Troop)
        elseif action.Type == "Upgrade" then
            local pos = parsePosition(action.Pos)
            safeFireRemote(MacroSystem.RemoteEvents.Upgrade, pos)
        elseif action.Type == "Skip" and MacroSystem.RemoteEvents.Skip then
            safeFireRemote(MacroSystem.RemoteEvents.Skip)
        end
    end
    
    MacroSystem.Playing = false
    playButton.Text = "Play Macro"
    print("[Macro] Playback complete")
    return true
end

function MacroSystem.stopPlayback()
    MacroSystem.Playing = false
    MacroSystem.Paused = false
    playButton.Text = "Play Macro"
    print("[Macro] Playback stopped")
end

function MacroSystem.togglePause()
    if not MacroSystem.Playing then return end
    
    MacroSystem.Paused = not MacroSystem.Paused
    pauseButton.Text = MacroSystem.Paused and "Resume Playback" or "Pause Playback"
    print("[Macro] Playback", MacroSystem.Paused and "paused" or "resumed")
end

-- Hook remote events for recording
for name, remote in pairs(MacroSystem.RemoteEvents) do
    if remote then
        remote.OnClientEvent:Connect(function(...)
            if not MacroSystem.Recording then return end
            
            local args = {...}
            local action = {
                Type = name,
                Time = getCurrentTime()
            }
            
            if name == "Place" then
                action.Troop = args[2] -- Tower type
                action.Pos = formatPosition(args[1]) -- Position
            elseif name == "Upgrade" or name == "Sell" then
                action.Pos = formatPosition(args[1]) -- Position
            end
            
            table.insert(MacroSystem.CurrentMacro.Actions, action)
        end)
    end
end

-- Button Connections
createButton.MouseButton1Click:Connect(function()
    local name = newMacroBox.Text
    if name and name ~= "" then
        MacroSystem.CurrentMacro = table.clone(RECORDING_FORMAT)
        MacroSystem.CurrentMacro.Created = os.date("%Y-%m-%d %H:%M:%S")
        MacroSystem.saveMacro(name)
        MacroSystem.SelectedMacro = name
        macroDropdown:FindFirstChildOfClass("TextButton").Text = name
    else
        warn("Please enter a macro name")
    end
end)

recordButton.MouseButton1Click:Connect(function()
    if MacroSystem.Recording then
        MacroSystem.stopRecording()
        if MacroSystem.SelectedMacro then
            MacroSystem.saveMacro(MacroSystem.SelectedMacro)
        end
    else
        MacroSystem.startRecording()
    end
end)

playButton.MouseButton1Click:Connect(function()
    if MacroSystem.Playing then
        MacroSystem.stopPlayback()
    else
        if MacroSystem.SelectedMacro then
            MacroSystem.loadMacro(MacroSystem.SelectedMacro)
        end
        MacroSystem.playMacro()
    end
end)

pauseButton.MouseButton1Click:Connect(function()
    MacroSystem.togglePause()
end)

-- Auto-detect map start (improved version)
task.spawn(function()
    while true do
        -- Wait for game to load
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local waveDisplay = playerGui:FindFirstChild("ReactGameTopGameDisplay", true)
        
        if waveDisplay then
            waveDisplay = waveDisplay:FindFirstChild("Frame", true)
            if waveDisplay then
                waveDisplay = waveDisplay:FindFirstChild("wave")
            end
        end
        
        if waveDisplay then
            local lastWave = "Wave 0"
            
            while true do
                local waveText = waveDisplay.Text
                if waveText ~= lastWave then
                    lastWave = waveText
                    
                    -- Detect wave 1 start
                    if waveText:match("Wave 1") then
                        print("[Macro] Detected match start - Wave 1")
                        
                        -- Try to get current map name
                        local mapName = DEFAULT_MAP
                        local mapDisplay = playerGui:FindFirstChild("MapNameDisplay", true)
                        if mapDisplay and mapDisplay:FindFirstChildWhichIsA("TextLabel") then
                            mapName = mapDisplay:FindFirstChildWhichIsA("TextLabel").Text
                        end
                        
                        MacroSystem.CurrentMacro.Map = mapName
                        
                        -- Auto-play if macro is loaded and matches current map
                        if MacroSystem.SelectedMacro and 
                           MacroSystem.CurrentMacro.Map == mapName and
                           not MacroSystem.Recording then
                            MacroSystem.playMacro()
                        end
                    end
                end
                task.wait(1)
            end
        end
        task.wait(5)
    end
end)

-- Initialize
print("Tower Defense Macro System loaded")
