--[[
	AdminSystem_Server.lua
	Main server-side script for the Advanced Admin Panel
	
	Place this script in ServerScriptService
	
	This script:
	- Initializes all admin system modules
	- Sets up anti-exploit measures
	- Monitors system health
	- Handles server-side logic
]]

--================================================================================
-- MODULE LOADING
--================================================================================

-- Get all modules (adjust paths as needed for your game structure)
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load admin modules
-- NOTE: Place these ModuleScripts in ServerStorage or ServerScriptService for security
local Config = require(script.Parent:WaitForChild("AdminSystem_Config"))
local Permissions = require(script.Parent:WaitForChild("AdminSystem_Permissions"))
local Commands = require(script.Parent:WaitForChild("AdminSystem_Commands"))
local Logging = require(script.Parent:WaitForChild("AdminSystem_Logging"))
local AdminCore = require(script.Parent:WaitForChild("AdminSystem_Core"))

--================================================================================
-- SYSTEM INITIALIZATION
--================================================================================

print("========================================")
print("Advanced Admin Panel - Initializing...")
print("========================================")

-- Initialize logging first
Logging.Initialize(Config)
print("[Server] Logging system initialized")

-- Initialize permissions
Permissions.Initialize(Config, Logging)
print("[Server] Permissions system initialized")

-- Initialize commands
Commands.Initialize(Config, Permissions, Logging, AdminCore)
print("[Server] Commands system initialized")

-- Initialize core (must be last)
local success = AdminCore.Initialize(Config, Permissions, Commands, Logging)

if success then
	print("========================================")
	print("Advanced Admin Panel - Ready!")
	print("Admin Count:", #Config:GetAdminsWithRank(1))
	print("========================================")
else
	warn("Failed to initialize Admin Panel!")
end

--================================================================================
-- ANTI-EXPLOIT MONITORING
--================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Monitor for suspicious activity
local function MonitorPlayer(player)
	-- Check for common exploits
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Monitor walkspeed changes
	local lastSpeed = humanoid.WalkSpeed
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if not Config:IsAdmin(player.UserId) then
			-- Check if speed was changed client-side (potential exploit)
			if humanoid.WalkSpeed ~= Config.GameSettings.DefaultSpeed and 
			   math.abs(humanoid.WalkSpeed - lastSpeed) > 50 then
				Logging.LogSystem("EXPLOIT_DETECTED", player.Name, 
					string.format("Suspicious speed change: %d -> %d", lastSpeed, humanoid.WalkSpeed))
				
				-- Reset to default
				humanoid.WalkSpeed = Config.GameSettings.DefaultSpeed
			end
		end
		lastSpeed = humanoid.WalkSpeed
	end)
	
	-- Monitor health changes (god mode detection)
	humanoid.HealthChanged:Connect(function(health)
		if not Config:IsAdmin(player.UserId) then
			if health > humanoid.MaxHealth then
				Logging.LogSystem("EXPLOIT_DETECTED", player.Name, 
					string.format("Health exceeded MaxHealth: %d/%d", health, humanoid.MaxHealth))
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end)
end

-- Apply monitoring to all players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		MonitorPlayer(player)
	end)
end)

-- Monitor existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		MonitorPlayer(player)
	end
	player.CharacterAdded:Connect(function()
		MonitorPlayer(player)
	end)
end

--================================================================================
-- PERIODIC TASKS
--================================================================================

-- Cleanup expired bans every 5 minutes
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutes
		
		-- This would iterate through ban cache and remove expired bans
		-- Implementation depends on your specific needs
		print("[Server] Periodic maintenance: Checking for expired bans...")
	end
end)

-- Log statistics every hour
task.spawn(function()
	while true do
		task.wait(3600) -- 1 hour
		
		local stats = Logging.GetLogStats()
		Logging.LogSystem("STATISTICS", "Server", 
			string.format("Total logs: %d | Actions: %d | System: %d", 
				stats.TotalLogs, stats.ActionLogs, stats.SystemLogs))
	end
end)

--================================================================================
-- ADMIN NOTIFICATIONS
--================================================================================

-- Notify admins of important events
local function NotifyAdmins(title, message, minRank)
	AdminCore.BroadcastToAdmins(title, message, "Info", minRank or 2)
end

-- Example: Notify when a player with prior bans joins
Players.PlayerAdded:Connect(function(player)
	-- You could check if player was previously banned and notify admins
	-- This is just an example
end)

--================================================================================
-- GRACEFUL SHUTDOWN
--================================================================================

game:BindToClose(function()
	print("[Server] Server shutting down...")
	
	-- Log shutdown
	Logging.LogSystem("SHUTDOWN", "Server", "Server is shutting down")
	
	-- Export final logs (optional)
	local exportedLogs = Logging.ExportLogsAsString(100)
	print("Final logs exported:", #exportedLogs, "characters")
	
	-- Give time for final webhook sends
	task.wait(2)
	
	print("[Server] Admin system shutdown complete")
end)

--================================================================================
-- DEVELOPMENT COMMANDS (Remove in production)
--================================================================================

-- Debug command to manually test logging
if game:GetService("RunService"):IsStudio() then
	print("[DEBUG] Studio mode detected")
	
	-- Add yourself as owner for testing
	local StudioUserId = game:GetService("StudioService"):GetUserId()
	if StudioUserId > 0 then
		Config.AdminList[StudioUserId] = 4
		print("[DEBUG] Studio user added as Owner:", StudioUserId)
	end
	
	-- Test log
	Logging.LogSystem("DEBUG", "Studio", "Admin system loaded in Studio mode")
end

--================================================================================
-- DOCUMENTATION
--================================================================================

--[[
	SETUP INSTRUCTIONS:
	
	1. Place this script in ServerScriptService
	
	2. Place all Admin module scripts in ServerScriptService or ServerStorage:
	   - AdminSystem_Config
	   - AdminSystem_Core
	   - AdminSystem_Permissions
	   - AdminSystem_Commands
	   - AdminSystem_Logging
	   
	3. Configure AdminSystem_Config:
	   - Add admin User IDs to AdminList
	   - Set your Discord webhook URL
	   - Adjust permissions as needed
	   - Configure game-specific settings (weapons, maps, etc.)
	   
	4. Place AdminSystem_Client in StarterPlayer > StarterPlayerScripts
	
	5. Place AdminSystem_UI in ReplicatedStorage (so client can access it)
	
	6. Test in Studio first:
	   - Press Right Shift to open panel
	   - Test commands with different rank levels
	   - Check Output for any errors
	   
	7. Test ban system in actual game servers (DataStores don't work in Studio properly)
	
	8. Configure webhook and test logging
	
	SECURITY NOTES:
	- NEVER put admin modules in ReplicatedStorage
	- Always validate on server-side
	- Keep Config.AdminList secure
	- Regularly check logs for suspicious activity
	- Use strong reasons for moderation actions
	
	CUSTOMIZATION:
	- Edit commands in AdminSystem_Commands
	- Modify UI theme in AdminSystem_Config
	- Add custom commands following existing patterns
	- Extend logging for custom events
]]

print("[Server] Documentation loaded. See script for setup instructions.")
