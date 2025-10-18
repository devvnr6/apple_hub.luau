--[[
	AdminSystem_Core Module
	Core functionality and initialization for the admin panel system
	
	Responsibilities:
	- System initialization
	- Remote event/function setup
	- Player join/leave handling
	- Utility functions
	- Rate limiting
]]

local AdminCore = {}
AdminCore.__index = AdminCore

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Module References (to be loaded)
local Config
local Permissions
local Commands
local Logging

-- System state
local IsInitialized = false
local ActiveSessions = {}  -- Track admin sessions and rate limits
local RemoteFolder

--================================================================================
-- INITIALIZATION
--================================================================================

function AdminCore.Initialize(configModule, permissionsModule, commandsModule, loggingModule)
	if IsInitialized then
		warn("[AdminCore] System already initialized!")
		return false
	end
	
	-- Load module references
	Config = configModule
	Permissions = permissionsModule
	Commands = commandsModule
	Logging = loggingModule
	
	-- Create remote folder in ReplicatedStorage
	RemoteFolder = Instance.new("Folder")
	RemoteFolder.Name = "AdminSystem"
	RemoteFolder.Parent = ReplicatedStorage
	
	-- Create RemoteEvent for admin actions
	local AdminActionEvent = Instance.new("RemoteEvent")
	AdminActionEvent.Name = "AdminAction"
	AdminActionEvent.Parent = RemoteFolder
	
	-- Create RemoteFunction for data requests
	local AdminDataFunction = Instance.new("RemoteFunction")
	AdminDataFunction.Name = "AdminData"
	AdminDataFunction.Parent = RemoteFolder
	
	-- Create RemoteEvent for UI notifications
	local NotificationEvent = Instance.new("RemoteEvent")
	NotificationEvent.Name = "Notification"
	NotificationEvent.Parent = RemoteFolder
	
	-- Set up event handlers
	AdminActionEvent.OnServerEvent:Connect(AdminCore.HandleAdminAction)
	AdminDataFunction.OnServerInvoke = AdminCore.HandleDataRequest
	
	-- Set up player connections
	Players.PlayerAdded:Connect(AdminCore.OnPlayerAdded)
	Players.PlayerRemoving:Connect(AdminCore.OnPlayerRemoving)
	
	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		AdminCore.OnPlayerAdded(player)
	end
	
	IsInitialized = true
	print("[AdminCore] System initialized successfully!")
	Logging.LogSystem("SYSTEM", "Admin system initialized", "System startup complete")
	
	return true
end

--================================================================================
-- PLAYER MANAGEMENT
--================================================================================

function AdminCore.OnPlayerAdded(player)
	local userId = player.UserId
	
	-- Initialize session tracking
	ActiveSessions[userId] = {
		Player = player,
		RankId = Config:GetUserRank(userId),
		CommandCount = 0,
		LastCommandTime = 0,
		SessionStart = os.time(),
	}
	
	-- Check if player is admin
	if Config:IsAdmin(userId) then
		local rankData = Config:GetRankData(Config:GetUserRank(userId))
		print(string.format("[AdminCore] Admin joined: %s (%d) - Rank: %s", 
			player.Name, userId, rankData.RankName))
		
		Logging.LogSystem("ADMIN_JOIN", player.Name, string.format("Rank: %s", rankData.RankName))
		
		-- Wait a moment for client to load, then notify them to show UI
		task.wait(1)
		AdminCore.SendNotification(player, "Welcome", string.format("Admin panel loaded. Rank: %s", rankData.RankName), "Success")
	end
end

function AdminCore.OnPlayerRemoving(player)
	local userId = player.UserId
	
	if Config:IsAdmin(userId) then
		local rankData = Config:GetRankData(Config:GetUserRank(userId))
		Logging.LogSystem("ADMIN_LEAVE", player.Name, string.format("Rank: %s", rankData.RankName))
	end
	
	-- Clean up session
	ActiveSessions[userId] = nil
end

--================================================================================
-- REMOTE HANDLERS
--================================================================================

function AdminCore.HandleAdminAction(player, actionData)
	local userId = player.UserId
	
	-- Validate request structure
	if type(actionData) ~= "table" then
		AdminCore.SendNotification(player, "Error", "Invalid request format", "Error")
		return
	end
	
	local commandName = actionData.Command
	local parameters = actionData.Parameters or {}
	
	-- Security: Check if user is admin
	if not Config:IsAdmin(userId) then
		Logging.LogSystem("UNAUTHORIZED_ACCESS", player.Name, string.format("Attempted command: %s", tostring(commandName)))
		return
	end
	
	-- Rate limiting
	if not AdminCore.CheckRateLimit(userId) then
		AdminCore.SendNotification(player, "Rate Limited", "You are sending commands too quickly", "Warning")
		return
	end
	
	-- Permission check
	if not Config:CanUseCommand(userId, commandName) then
		AdminCore.SendNotification(player, "Permission Denied", 
			string.format("You don't have permission to use: %s", commandName), "Error")
		
		if Config.Security.LogFailedAttempts then
			Logging.LogSystem("PERMISSION_DENIED", player.Name, string.format("Command: %s", commandName))
		end
		return
	end
	
	-- Execute command
	local success, result = Commands.ExecuteCommand(player, commandName, parameters)
	
	if success then
		AdminCore.SendNotification(player, "Success", result or "Command executed successfully", "Success")
	else
		AdminCore.SendNotification(player, "Error", result or "Command failed", "Error")
	end
end

function AdminCore.HandleDataRequest(player, requestType)
	local userId = player.UserId
	
	-- Security: Check if user is admin
	if not Config:IsAdmin(userId) then
		return nil
	end
	
	if requestType == "GetRank" then
		local rankId = Config:GetUserRank(userId)
		return {
			RankId = rankId,
			RankData = Config:GetRankData(rankId)
		}
		
	elseif requestType == "GetPlayers" then
		return AdminCore.GetPlayerList()
		
	elseif requestType == "GetLogs" then
		if Config:CanUseCommand(userId, "ViewLogs") then
			return Logging.GetRecentLogs(50)
		end
		return nil
		
	elseif requestType == "GetCommands" then
		return AdminCore.GetAvailableCommands(userId)
		
	elseif requestType == "GetConfig" then
		return {
			Theme = Config.UITheme,
			Weapons = Config.GameSettings.AvailableWeapons,
			Maps = Config.GameSettings.AvailableMaps,
		}
	end
	
	return nil
end

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

-- Rate limiting check
function AdminCore.CheckRateLimit(userId)
	local session = ActiveSessions[userId]
	if not session then return false end
	
	local currentTime = os.time()
	local timeDiff = currentTime - session.LastCommandTime
	
	-- Reset counter if more than 1 minute has passed
	if timeDiff >= 60 then
		session.CommandCount = 0
	end
	
	session.CommandCount = session.CommandCount + 1
	session.LastCommandTime = currentTime
	
	return session.CommandCount <= Config.Security.CommandRateLimit
end

-- Get formatted player list
function AdminCore.GetPlayerList()
	local playerList = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(playerList, {
			Name = player.Name,
			DisplayName = player.DisplayName,
			UserId = player.UserId,
			Team = player.Team and player.Team.Name or "None",
			IsAdmin = Config:IsAdmin(player.UserId),
			AdminRank = Config:GetUserRank(player.UserId),
		})
	end
	return playerList
end

-- Get commands available to user
function AdminCore.GetAvailableCommands(userId)
	local userRank = Config:GetUserRank(userId)
	local availableCommands = {}
	
	for commandName, requiredRank in pairs(Config.CommandPermissions) do
		if userRank >= requiredRank then
			table.insert(availableCommands, {
				Name = commandName,
				RequiredRank = requiredRank,
				RankName = Config:GetRankData(requiredRank).RankName
			})
		end
	end
	
	return availableCommands
end

-- Find player by partial name or UserId
function AdminCore.FindPlayer(identifier)
	-- Try to find by exact name
	local player = Players:FindFirstChild(identifier)
	if player then return player end
	
	-- Try to parse as UserId
	local userId = tonumber(identifier)
	if userId then
		player = Players:GetPlayerByUserId(userId)
		if player then return player end
	end
	
	-- Try partial name match (case insensitive)
	local lowerIdentifier = string.lower(identifier)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(player.Name), lowerIdentifier, 1, true) then
			return player
		end
		if string.find(string.lower(player.DisplayName), lowerIdentifier, 1, true) then
			return player
		end
	end
	
	return nil
end

-- Sanitize string input
function AdminCore.SanitizeInput(input, maxLength)
	if type(input) ~= "string" then
		return ""
	end
	
	maxLength = maxLength or Config.Security.MaxReasonLength
	input = string.sub(input, 1, maxLength)
	
	-- Remove any characters that don't match allowed pattern
	input = string.gsub(input, "[^%w%s%p]", "")
	
	return input
end

-- Send notification to player
function AdminCore.SendNotification(player, title, message, notificationType)
	local NotificationEvent = RemoteFolder:FindFirstChild("Notification")
	if NotificationEvent then
		NotificationEvent:FireClient(player, {
			Title = title,
			Message = message,
			Type = notificationType or "Info",
			Timestamp = os.time()
		})
	end
end

-- Broadcast notification to all admins
function AdminCore.BroadcastToAdmins(title, message, notificationType, minRank)
	minRank = minRank or 1
	for _, player in ipairs(Players:GetPlayers()) do
		if Config:GetUserRank(player.UserId) >= minRank then
			AdminCore.SendNotification(player, title, message, notificationType)
		end
	end
end

--================================================================================
-- GETTERS
--================================================================================

function AdminCore.GetRemoteFolder()
	return RemoteFolder
end

function AdminCore.IsSystemInitialized()
	return IsInitialized
end

return AdminCore
