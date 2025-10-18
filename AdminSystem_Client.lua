--[[
	AdminSystem_Client.lua
	Main client-side script for the Advanced Admin Panel
	
	Place this script in StarterPlayer > StarterPlayerScripts
	
	This script:
	- Initializes the admin UI for authorized users
	- Handles client-side input
	- Communicates with server for admin actions
	- Displays notifications
]]

--================================================================================
-- SERVICES AND VARIABLES
--================================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Wait for admin system to be ready
local AdminSystem = ReplicatedStorage:WaitForChild("AdminSystem", 10)

if not AdminSystem then
	warn("[AdminClient] Admin system not found in ReplicatedStorage!")
	return
end

local AdminDataFunction = AdminSystem:WaitForChild("AdminData")

--================================================================================
-- CHECK ADMIN STATUS
--================================================================================

print("[AdminClient] Checking admin status...")

-- Check if player is an admin
local isAdmin = false
local rankInfo = nil

local success, result = pcall(function()
	return AdminDataFunction:InvokeServer("GetRank")
end)

if success and result then
	rankInfo = result
	isAdmin = rankInfo.RankId > 0
end

if not isAdmin then
	print("[AdminClient] Player is not an admin. UI will not load.")
	return
end

print(string.format("[AdminClient] Admin detected: %s (Rank: %s)", 
	LocalPlayer.Name, rankInfo.RankData.RankName))

--================================================================================
-- LOAD UI MODULE
--================================================================================

-- Note: Place AdminSystem_UI in ReplicatedStorage or require from ServerStorage
-- For this example, we'll look for it in ReplicatedStorage
local AdminUI = require(ReplicatedStorage:WaitForChild("AdminSystem_UI"))

-- Wait for character to load
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Small delay to ensure everything is loaded
task.wait(1)

--================================================================================
-- INITIALIZE UI
--================================================================================

local uiSuccess = AdminUI.Initialize()

if uiSuccess then
	print("[AdminClient] Admin UI initialized successfully!")
	print("[AdminClient] Press Right Shift to toggle the admin panel")
	
	-- Notify player
	task.wait(2)
	StarterGui:SetCore("ChatMakeSystemMessage", {
		Text = "[Admin Panel] Press Right Shift to open the admin panel",
		Color = Color3.fromRGB(80, 120, 255),
		Font = Enum.Font.GothamBold,
		FontSize = Enum.FontSize.Size18
	})
else
	warn("[AdminClient] Failed to initialize admin UI!")
end

--================================================================================
-- CLIENT-SIDE ANTI-CHEAT BYPASS DETECTION
--================================================================================

-- Monitor for client-side script injection attempts
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Log client-side errors (potential exploit attempts)
local originalLogService = game:GetService("LogService")
originalLogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		-- Check for suspicious error patterns
		if string.find(message:lower(), "remote") or 
		   string.find(message:lower(), "invoke") or
		   string.find(message:lower(), "fire") then
			-- Could indicate exploit attempt, but could also be legitimate errors
			-- Log for review
			print("[AdminClient] Suspicious error detected:", message)
		end
	end
end)

--================================================================================
-- HEARTBEAT MONITORING
--================================================================================

-- Keep admin system responsive
RunService.Heartbeat:Connect(function()
	-- This runs every frame
	-- You can add client-side checks here if needed
end)

-- Periodic check (every 30 seconds)
task.spawn(function()
	while true do
		task.wait(30)
		
		-- Verify admin status hasn't been revoked
		local stillAdmin = pcall(function()
			local check = AdminDataFunction:InvokeServer("GetRank")
			return check and check.RankId > 0
		end)
		
		if not stillAdmin then
			warn("[AdminClient] Admin privileges revoked!")
			-- Could hide UI here
		end
	end
end)

--================================================================================
-- MOBILE SUPPORT
--================================================================================

local UserInputService = game:GetService("UserInputService")

-- Add mobile button if on mobile device
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	print("[AdminClient] Mobile device detected, creating touch button...")
	
	-- Create mobile button
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	local MobileButton = Instance.new("ScreenGui")
	MobileButton.Name = "AdminMobileButton"
	MobileButton.ResetOnSpawn = false
	MobileButton.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	MobileButton.Parent = PlayerGui
	
	local Button = Instance.new("ImageButton")
	Button.Size = UDim2.new(0, 60, 0, 60)
	Button.Position = UDim2.new(1, -70, 0, 10)
	Button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
	Button.BorderSizePixel = 0
	Button.Parent = MobileButton
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Button
	
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Text = "🛡️"
	Label.TextSize = 30
	Label.Parent = Button
	
	Button.MouseButton1Click:Connect(function()
		-- Toggle admin panel
		if AdminUI and AdminUI.TogglePanel then
			AdminUI.TogglePanel()
		end
	end)
	
	print("[AdminClient] Mobile button created")
end

--================================================================================
-- KEYBIND HINTS
--================================================================================

-- Show keybind hint on first join
if not LocalPlayer:GetAttribute("AdminPanelHintShown") then
	LocalPlayer:SetAttribute("AdminPanelHintShown", true)
	
	task.wait(3)
	
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Admin Panel",
			Text = "Press Right Shift to open",
			Duration = 5,
			Icon = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		})
	end)
end

--================================================================================
-- CLEANUP
--================================================================================

LocalPlayer.CharacterRemoving:Connect(function()
	print("[AdminClient] Character removing, preparing for respawn...")
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	print("[AdminClient] Character respawned")
	-- UI should persist through respawn due to ResetOnSpawn = false
end)

--================================================================================
-- DEBUG INFO
--================================================================================

if game:GetService("RunService"):IsStudio() then
	print("========================================")
	print("[DEBUG] Admin Client Loaded")
	print("Player:", LocalPlayer.Name)
	print("UserID:", LocalPlayer.UserId)
	print("Admin Rank:", rankInfo.RankId, "-", rankInfo.RankData.RankName)
	print("========================================")
end

print("[AdminClient] Initialization complete")
