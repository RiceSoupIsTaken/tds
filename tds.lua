-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- GUI PATHS
local cashLabel = LocalPlayer.PlayerGui:WaitForChild("ReactUniversalHotbar").Frame.values.cash
local waveLabel = LocalPlayer.PlayerGui:WaitForChild("ReactGameTopGameDisplay").Frame.wave

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "MacroUI"
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 130)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.BorderSizePixel = 0

local function createLabel(text, y)
	local label = Instance.new("TextLabel", Frame)
	label.Text = text
	label.Size = UDim2.new(1, -10, 0, 20)
	label.Position = UDim2.new(0, 5, 0, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.SourceSans
	label.TextSize = 16
	return label
end

local function createDropdown(options, y)
	local dropdown = Instance.new("TextButton", Frame)
	dropdown.Size = UDim2.new(1, -10, 0, 20)
	dropdown.Position = UDim2.new(0, 5, 0, y)
	dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	dropdown.TextColor3 = Color3.new(1, 1, 1)
	dropdown.Font = Enum.Font.SourceSans
	dropdown.TextSize = 16
	dropdown.Text = "Select Macro"

	local selected
	local function updateOptions()
		local dropdownMenu = Instance.new("Frame", Frame)
		dropdownMenu.Position = UDim2.new(0, 5, 0, y + 20)
		dropdownMenu.Size = UDim2.new(1, -10, 0, math.min(#options * 20, 100))
		dropdownMenu.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		dropdownMenu.ClipsDescendants = true

		for _, name in ipairs(options) do
			local btn = Instance.new("TextButton", dropdownMenu)
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.Position = UDim2.new(0, 0, 0, (#dropdownMenu:GetChildren() - 1) * 20)
			btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = name
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 16
			btn.MouseButton1Click:Connect(function()
				dropdown.Text = name
				selected = name
				dropdownMenu:Destroy()
			end)
		end
	end

	dropdown.MouseButton1Click:Connect(updateOptions)

	return dropdown, function() return selected end
end

local function createToggle(labelText, y)
	local toggle = Instance.new("TextButton", Frame)
	toggle.Size = UDim2.new(1, -10, 0, 20)
	toggle.Position = UDim2.new(0, 5, 0, y)
	toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Font = Enum.Font.SourceSans
	toggle.TextSize = 16
	toggle.Text = "[ ] " .. labelText

	local active = false
	toggle.MouseButton1Click:Connect(function()
		active = not active
		toggle.Text = active and "[✔] " .. labelText or "[ ] " .. labelText
	end)

	return toggle, function() return active end
end

local function getCash()
	local text = cashLabel.Text:gsub("[^%d]", "")
	return tonumber(text) or 0
end

-- FILE SYSTEM
local folder = "workspace/macros"
if not isfolder("workspace") then makefolder("workspace") end
if not isfolder(folder) then makefolder(folder) end

local function saveMacro(name, data)
	writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
end

local function loadMacro(name)
	local path = folder .. "/" .. name .. ".json"
	if isfile(path) then
		local content = readfile(path)
		return HttpService:JSONDecode(content)
	end
end

local function listMacros()
	local list = {}
	for _, file in ipairs(listfiles(folder)) do
		table.insert(list, file:match("([^/\\]+)%.json$"))
	end
	return list
end

-- GUI ELEMENTS
createLabel("Create New Macro:", 5)
local nameBox = Instance.new("TextBox", Frame)
nameBox.Size = UDim2.new(1, -10, 0, 20)
nameBox.Position = UDim2.new(0, 5, 0, 25)
nameBox.PlaceholderText = "Enter macro name"
nameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nameBox.TextColor3 = Color3.new(1, 1, 1)
nameBox.Font = Enum.Font.SourceSans
nameBox.TextSize = 16

nameBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local newName = nameBox.Text
		if newName ~= "" then
			saveMacro(newName, {})
			nameBox.Text = ""
			print("Macro created:", newName)
		end
	end
end)

createLabel("Record Macro:", 50)
local recordDropdown, getRecordName = createDropdown(listMacros(), 70)
local recordToggle, isRecording = createToggle("Recording", 90)

createLabel("Play Macro:", 115)
local playDropdown, getPlayName = createDropdown(listMacros(), 135)
local playToggle, isPlaying = createToggle("Auto Play", 155)

-- RECORDING
local currentRecording = {}

local originalInvokeServer = game:GetService("ReplicatedStorage").RemoteFunction.InvokeServer
game:GetService("ReplicatedStorage").RemoteFunction.InvokeServer = function(self, ...)
	local args = {...}
	if isRecording() then
		table.insert(currentRecording, args)
	end
	return originalInvokeServer(self, unpack(args))
end

-- WATCH FOR MATCH START
task.spawn(function()
	local lastWave = "Wave 0"
	while true do
		local waveText = waveLabel.Text
		if waveText ~= lastWave and waveText ~= "Wave 0" then
			lastWave = waveText
			if isRecording() then
				local macroName = getRecordName()
				if macroName then
					saveMacro(macroName, currentRecording)
					print("Macro saved:", macroName)
					currentRecording = {}
				end
			end
			if isPlaying() then
				local macroName = getPlayName()
				local data = loadMacro(macroName)
				if data then
					task.spawn(function()
						for _, args in ipairs(data) do
							repeat wait(0.2) until getCash() >= 100 -- replace 100 with smarter logic later
							pcall(function()
								ReplicatedStorage.RemoteFunction:InvokeServer(unpack(args))
							end)
							wait(1)
						end
					end)
				end
			end
		end
		wait(1)
	end
end)
