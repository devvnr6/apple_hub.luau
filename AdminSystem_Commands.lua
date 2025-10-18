--[[
	AdminSystem_Commands Module
	All admin command implementations
	
	Responsibilities:
	- Command execution routing
	- Player moderation commands
	- Shooter-specific commands
	- Game control commands
	- Utility commands
]]

local Commands = {}

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Module References
local Config
local Permissions
local Logging
local AdminCore

-- Data Stores
local BanDataStore
local RankDataStore

-- Ban cache
local BannedPlayers = {}

--================================================================================
-- INITIALIZATION
--================================================================================

function Commands.Initialize(configModule, permissionsModule, loggingModule, coreModule)
	Config = configModule
	Permissions = permissionsModule
	Logging = loggingModule
	AdminCore = coreModule
	
	-- Initialize DataStores
	local success, err = pcall(function()
		BanDataStore = DataStoreService:GetDataStore(Config.GameSettings.BanDataStoreName)
		RankDataStore = DataStoreService:GetDataStore(Config.GameSettings.RankDataStoreName)
	end)
	
	if not success then
		warn("[Commands] Failed to initialize DataStores:", err)
	end
	
	-- Load ban list
	Commands.LoadBanList()
	
	-- Set up player join ban check
	Players.PlayerAdded:Connect(Commands.CheckPlayerBan)
	
	print("[Commands] Module initialized")
end

--================================================================================
-- COMMAND ROUTING
--================================================================================

function Commands.ExecuteCommand(executor, commandName, parameters)
	-- Security check
	local securityPassed, securityMsg = Permissions.SecurityCheck(executor, commandName, parameters)
	if not securityPassed then
		return false, securityMsg
	end
	
	-- Exploit check
	local exploitCheck, exploitMsg = Permissions.CheckForExploits(executor, parameters)
	if not exploitCheck then
		return false, exploitMsg
	end
	
	-- Route to appropriate command handler
	local commandFunction = Commands[commandName]
	
	if not commandFunction or type(commandFunction) ~= "function" then
		return false, string.format("Command not found: %s", commandName)
	end
	
	-- Execute command
	local success, result = pcall(commandFunction, executor, parameters)
	
	if not success then
		warn(string.format("[Commands] Error executing %s: %s", commandName, result))
		return false, "Command execution failed: " .. tostring(result)
	end
	
	return result.Success, result.Message
end

--================================================================================
-- PLAYER MODERATION COMMANDS
--================================================================================

-- Kick player
function Commands.Kick(executor, params)
	local targetName = params.Target
	local reason = params.Reason or "No reason provided"
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Permission check
	local canAffect, affectMsg = Permissions.CanAffectTarget(executor.UserId, target.UserId)
	if not canAffect then
		return {Success = false, Message = affectMsg}
	end
	
	-- Validate reason
	local valid, sanitizedReason = Permissions.ValidateReason(reason)
	if not valid then
		return {Success = false, Message = sanitizedReason}
	end
	
	-- Log action
	Logging.LogAction(executor, "KICK", target.Name, sanitizedReason)
	
	-- Execute kick
	target:Kick(string.format("You have been kicked.\nReason: %s\nModerator: %s", 
		sanitizedReason, executor.Name))
	
	return {Success = true, Message = string.format("Kicked %s", target.Name)}
end

-- Ban player
function Commands.Ban(executor, params)
	local targetName = params.Target
	local reason = params.Reason or "No reason provided"
	local duration = params.Duration or "perm"
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Permission check
	local canAffect, affectMsg = Permissions.CanAffectTarget(executor.UserId, target.UserId)
	if not canAffect then
		return {Success = false, Message = affectMsg}
	end
	
	-- Validate reason
	local valid, sanitizedReason = Permissions.ValidateReason(reason)
	if not valid then
		return {Success = false, Message = sanitizedReason}
	end
	
	-- Validate duration
	local durationValid, hours, durationStr = Permissions.ValidateDuration(duration)
	if not durationValid then
		return {Success = false, Message = durationStr}
	end
	
	-- Create ban entry
	local banData = {
		UserId = target.UserId,
		Username = target.Name,
		Reason = sanitizedReason,
		BannedBy = executor.Name,
		BannedById = executor.UserId,
		Timestamp = os.time(),
		Duration = hours,
		ExpiresAt = hours == -1 and -1 or (os.time() + (hours * 3600)),
	}
	
	-- Save to DataStore
	local success = Commands.SaveBan(target.UserId, banData)
	if not success then
		return {Success = false, Message = "Failed to save ban data"}
	end
	
	-- Add to cache
	BannedPlayers[target.UserId] = banData
	
	-- Log action
	Logging.LogAction(executor, "BAN", target.Name, 
		string.format("%s | Duration: %s", sanitizedReason, durationStr))
	
	-- Execute ban (kick player)
	target:Kick(string.format("You have been banned.\nReason: %s\nDuration: %s\nModerator: %s", 
		sanitizedReason, durationStr, executor.Name))
	
	return {Success = true, Message = string.format("Banned %s for %s", target.Name, durationStr)}
end

-- Unban player
function Commands.Unban(executor, params)
	local targetId = tonumber(params.UserId)
	
	if not targetId then
		return {Success = false, Message = "Invalid User ID"}
	end
	
	-- Check if player is banned
	if not BannedPlayers[targetId] then
		return {Success = false, Message = "Player is not banned"}
	end
	
	-- Remove ban
	local success = Commands.RemoveBan(targetId)
	if not success then
		return {Success = false, Message = "Failed to remove ban"}
	end
	
	-- Remove from cache
	local username = BannedPlayers[targetId].Username
	BannedPlayers[targetId] = nil
	
	-- Log action
	Logging.LogAction(executor, "UNBAN", string.format("UserID: %d (%s)", targetId, username), "Ban removed")
	
	return {Success = true, Message = string.format("Unbanned player: %s", username)}
end

-- Mute player
function Commands.Mute(executor, params)
	local targetName = params.Target
	local duration = params.Duration or "30m"
	local reason = params.Reason or "No reason provided"
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Permission check
	local canAffect, affectMsg = Permissions.CanAffectTarget(executor.UserId, target.UserId)
	if not canAffect then
		return {Success = false, Message = affectMsg}
	end
	
	-- Validate duration
	local durationValid, hours, durationStr = Permissions.ValidateDuration(duration)
	if not durationValid then
		return {Success = false, Message = durationStr}
	end
	
	-- Apply mute (set TextChatService or Chat properties)
	local success, err = pcall(function()
		local TextChatService = game:GetService("TextChatService")
		if TextChatService then
			-- Modern TextChatService approach
			target.TextChatMessage:Destroy()  -- This would need proper implementation
		end
	end)
	
	-- Log action
	Logging.LogAction(executor, "MUTE", target.Name, 
		string.format("%s | Duration: %s", reason, durationStr))
	
	AdminCore.SendNotification(target, "Muted", 
		string.format("You have been muted for %s. Reason: %s", durationStr, reason), "Warning")
	
	return {Success = true, Message = string.format("Muted %s for %s", target.Name, durationStr)}
end

-- Unmute player
function Commands.Unmute(executor, params)
	local targetName = params.Target
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Remove mute
	-- Implementation depends on your mute system
	
	-- Log action
	Logging.LogAction(executor, "UNMUTE", target.Name, "Unmuted")
	
	AdminCore.SendNotification(target, "Unmuted", "You have been unmuted", "Success")
	
	return {Success = true, Message = string.format("Unmuted %s", target.Name)}
end

--================================================================================
-- INFORMATION COMMANDS
--================================================================================

-- View player info
function Commands.ViewInfo(executor, params)
	local targetName = params.Target
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	local character = target.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	local info = {
		Name = target.Name,
		DisplayName = target.DisplayName,
		UserId = target.UserId,
		AccountAge = target.AccountAge,
		Team = target.Team and target.Team.Name or "None",
		Health = humanoid and humanoid.Health or "N/A",
		MaxHealth = humanoid and humanoid.MaxHealth or "N/A",
		Speed = humanoid and humanoid.WalkSpeed or "N/A",
		JumpPower = humanoid and humanoid.JumpPower or "N/A",
		IsAdmin = Config:IsAdmin(target.UserId),
		AdminRank = Config:GetUserRank(target.UserId),
	}
	
	local infoString = string.format(
		"Name: %s\nDisplay: %s\nUserID: %d\nAge: %d days\nTeam: %s\nHealth: %s/%s\nSpeed: %s",
		info.Name, info.DisplayName, info.UserId, info.AccountAge, info.Team,
		tostring(info.Health), tostring(info.MaxHealth), tostring(info.Speed)
	)
	
	-- Log action
	Logging.LogAction(executor, "VIEW_INFO", target.Name, "Viewed player info")
	
	return {Success = true, Message = infoString}
end

--================================================================================
-- TELEPORT COMMANDS
--================================================================================

-- Teleport player to another player
function Commands.Teleport(executor, params)
	local targetName = params.Target
	local destinationName = params.Destination
	
	local target = AdminCore.FindPlayer(targetName)
	local destination = AdminCore.FindPlayer(destinationName)
	
	if not target then
		return {Success = false, Message = "Target player not found"}
	end
	
	if not destination then
		return {Success = false, Message = "Destination player not found"}
	end
	
	local targetChar = target.Character
	local destChar = destination.Character
	
	if not targetChar or not destChar then
		return {Success = false, Message = "Character not found"}
	end
	
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local destRoot = destChar:FindFirstChild("HumanoidRootPart")
	
	if not targetRoot or not destRoot then
		return {Success = false, Message = "HumanoidRootPart not found"}
	end
	
	-- Teleport
	targetRoot.CFrame = destRoot.CFrame + Vector3.new(3, 0, 0)
	
	-- Log action
	Logging.LogAction(executor, "TELEPORT", target.Name, 
		string.format("Teleported to %s", destination.Name))
	
	return {Success = true, Message = string.format("Teleported %s to %s", target.Name, destination.Name)}
end

-- Teleport player to executor
function Commands.TeleportToMe(executor, params)
	params.Destination = executor.Name
	return Commands.Teleport(executor, params)
end

-- Teleport executor to player
function Commands.TeleportMeTo(executor, params)
	local newParams = {
		Target = executor.Name,
		Destination = params.Target
	}
	return Commands.Teleport(executor, newParams)
end

--================================================================================
-- PLAYER MANIPULATION COMMANDS
--================================================================================

-- Set player health
function Commands.SetHealth(executor, params)
	local targetName = params.Target
	local value = params.Value
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Validate value
	local valid, validatedValue, msg = Permissions.ValidateNumber(value, 1, 100, 100)
	if not valid then
		return {Success = false, Message = msg}
	end
	
	local character = target.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	if not humanoid then
		return {Success = false, Message = "Humanoid not found"}
	end
	
	humanoid.Health = validatedValue
	
	-- Log action
	Logging.LogAction(executor, "SET_HEALTH", target.Name, string.format("Set to %d", validatedValue))
	
	return {Success = true, Message = string.format("Set %s health to %d", target.Name, validatedValue)}
end

-- Set player speed
function Commands.SetSpeed(executor, params)
	local targetName = params.Target
	local value = params.Value
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Validate value
	local valid, validatedValue, msg = Permissions.ValidateNumber(value, 0, 200, 16)
	if not valid then
		return {Success = false, Message = msg}
	end
	
	local character = target.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	if not humanoid then
		return {Success = false, Message = "Humanoid not found"}
	end
	
	humanoid.WalkSpeed = validatedValue
	
	-- Log action
	Logging.LogAction(executor, "SET_SPEED", target.Name, string.format("Set to %d", validatedValue))
	
	return {Success = true, Message = string.format("Set %s speed to %d", target.Name, validatedValue)}
end

-- Set player jump power
function Commands.SetJump(executor, params)
	local targetName = params.Target
	local value = params.Value
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Validate value
	local valid, validatedValue, msg = Permissions.ValidateNumber(value, 0, 200, 50)
	if not valid then
		return {Success = false, Message = msg}
	end
	
	local character = target.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	if not humanoid then
		return {Success = false, Message = "Humanoid not found"}
	end
	
	humanoid.JumpPower = validatedValue
	
	-- Log action
	Logging.LogAction(executor, "SET_JUMP", target.Name, string.format("Set to %d", validatedValue))
	
	return {Success = true, Message = string.format("Set %s jump power to %d", target.Name, validatedValue)}
end

-- Toggle god mode
function Commands.ToggleGod(executor, params)
	local targetName = params.Target
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	local character = target.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	if not humanoid then
		return {Success = false, Message = "Humanoid not found"}
	end
	
	-- Toggle god mode (using MaxHealth as indicator)
	local isGod = humanoid.MaxHealth > 999999
	
	if isGod then
		humanoid.MaxHealth = Config.GameSettings.DefaultHealth
		humanoid.Health = Config.GameSettings.DefaultHealth
		Logging.LogAction(executor, "TOGGLE_GOD", target.Name, "Disabled")
		return {Success = true, Message = string.format("Disabled god mode for %s", target.Name)}
	else
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge
		Logging.LogAction(executor, "TOGGLE_GOD", target.Name, "Enabled")
		return {Success = true, Message = string.format("Enabled god mode for %s", target.Name)}
	end
end

-- Toggle fly mode
function Commands.ToggleFly(executor, params)
	local targetName = params.Target
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Implementation note: This requires a client-side fly script
	-- For now, we'll just log and notify
	
	Logging.LogAction(executor, "TOGGLE_FLY", target.Name, "Toggled")
	
	AdminCore.SendNotification(target, "Fly Mode", "Fly mode toggled by admin", "Info")
	
	return {Success = true, Message = string.format("Toggled fly mode for %s", target.Name)}
end

-- Give weapon to player
function Commands.GiveWeapon(executor, params)
	local targetName = params.Target
	local weaponName = params.Weapon
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Validate weapon name
	local validWeapon = false
	for _, weapon in ipairs(Config.GameSettings.AvailableWeapons) do
		if string.lower(weapon) == string.lower(weaponName) then
			validWeapon = true
			weaponName = weapon
			break
		end
	end
	
	if not validWeapon then
		return {Success = false, Message = "Invalid weapon name"}
	end
	
	-- Implementation note: This requires your game's weapon system
	-- For now, we'll just log
	
	Logging.LogAction(executor, "GIVE_WEAPON", target.Name, string.format("Weapon: %s", weaponName))
	
	return {Success = true, Message = string.format("Gave %s to %s", weaponName, target.Name)}
end

-- Strip all weapons
function Commands.StripWeapons(executor, params)
	local targetName = params.Target
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Implementation note: This requires your game's weapon system
	
	Logging.LogAction(executor, "STRIP_WEAPONS", target.Name, "Removed all weapons")
	
	return {Success = true, Message = string.format("Stripped weapons from %s", target.Name)}
end

--================================================================================
-- GAME CONTROL COMMANDS
--================================================================================

-- Force round end
function Commands.ForceRoundEnd(executor, params)
	local winningTeam = params.Team or "None"
	
	-- Implementation note: This requires your game's round system
	
	Logging.LogAction(executor, "FORCE_ROUND_END", "Server", string.format("Winning Team: %s", winningTeam))
	
	AdminCore.BroadcastToAdmins("Round Control", string.format("Round ended by %s", executor.Name), "Info", 1)
	
	return {Success = true, Message = "Round ended successfully"}
end

-- Set map
function Commands.SetMap(executor, params)
	local mapName = params.Map
	
	-- Validate map name
	local validMap = false
	for _, map in ipairs(Config.GameSettings.AvailableMaps) do
		if string.lower(map) == string.lower(mapName) then
			validMap = true
			mapName = map
			break
		end
	end
	
	if not validMap then
		return {Success = false, Message = "Invalid map name"}
	end
	
	-- Implementation note: This requires your game's map system
	
	Logging.LogAction(executor, "SET_MAP", "Server", string.format("Map: %s", mapName))
	
	AdminCore.BroadcastToAdmins("Map Control", string.format("Next map set to %s by %s", mapName, executor.Name), "Info", 1)
	
	return {Success = true, Message = string.format("Set next map to %s", mapName)}
end

-- Toggle spectate mode
function Commands.ToggleSpectate(executor, params)
	local targetName = params.Target or executor.Name
	
	local target = AdminCore.FindPlayer(targetName)
	if not target then
		return {Success = false, Message = "Player not found"}
	end
	
	-- Implementation note: This requires your game's spectator system
	
	Logging.LogAction(executor, "TOGGLE_SPECTATE", target.Name, "Toggled")
	
	return {Success = true, Message = string.format("Toggled spectate mode for %s", target.Name)}
end

-- Change time of day
function Commands.ChangeTime(executor, params)
	local timeValue = params.Time
	
	-- Validate time
	local valid, validatedTime, msg = Permissions.ValidateNumber(timeValue, 0, 24, 12)
	if not valid then
		return {Success = false, Message = msg}
	end
	
	Lighting.ClockTime = validatedTime
	
	Logging.LogAction(executor, "CHANGE_TIME", "Server", string.format("Time: %d:00", validatedTime))
	
	return {Success = true, Message = string.format("Set time to %d:00", validatedTime)}
end

-- Set gravity
function Commands.SetGravity(executor, params)
	local gravityValue = params.Gravity
	
	-- Validate gravity
	local valid, validatedGravity, msg = Permissions.ValidateNumber(gravityValue, 0, 500, 196.2)
	if not valid then
		return {Success = false, Message = msg}
	end
	
	Workspace.Gravity = validatedGravity
	
	Logging.LogAction(executor, "SET_GRAVITY", "Server", string.format("Gravity: %d", validatedGravity))
	
	return {Success = true, Message = string.format("Set gravity to %d", validatedGravity)}
end

--================================================================================
-- RANK MANAGEMENT COMMANDS
--================================================================================

function Commands.Promote(executor, params)
	local targetId = tonumber(params.UserId)
	if not targetId then
		return {Success = false, Message = "Invalid User ID"}
	end
	
	local success, message = Permissions.PromoteUser(executor, targetId)
	return {Success = success, Message = message}
end

function Commands.Demote(executor, params)
	local targetId = tonumber(params.UserId)
	if not targetId then
		return {Success = false, Message = "Invalid User ID"}
	end
	
	local success, message = Permissions.DemoteUser(executor, targetId)
	return {Success = success, Message = message}
end

function Commands.SetRank(executor, params)
	local targetId = tonumber(params.UserId)
	local rankId = tonumber(params.Rank)
	
	if not targetId or not rankId then
		return {Success = false, Message = "Invalid parameters"}
	end
	
	local success, message = Permissions.SetRank(executor, targetId, rankId)
	return {Success = success, Message = message}
end

--================================================================================
-- SYSTEM COMMANDS
--================================================================================

function Commands.ViewLogs(executor, params)
	-- Logs are retrieved via RemoteFunction in AdminCore
	return {Success = true, Message = "Logs retrieved"}
end

function Commands.ClearLogs(executor, params)
	Logging.ClearLogs()
	Logging.LogAction(executor, "CLEAR_LOGS", "System", "Logs cleared")
	return {Success = true, Message = "Logs cleared successfully"}
end

function Commands.Shutdown(executor, params)
	local reason = params.Reason or "Server shutdown by admin"
	
	Logging.LogAction(executor, "SHUTDOWN", "Server", reason)
	
	-- Notify all players
	for _, player in ipairs(Players:GetPlayers()) do
		player:Kick(string.format("Server shutdown.\nReason: %s\nAdmin: %s", reason, executor.Name))
	end
	
	task.wait(2)
	
	-- Close all servers
	game:Shutdown()
	
	return {Success = true, Message = "Server shutting down"}
end

function Commands.Announce(executor, params)
	local message = params.Message
	
	if not message or #message == 0 then
		return {Success = false, Message = "Message cannot be empty"}
	end
	
	-- Sanitize message
	local valid, sanitizedMessage = Permissions.ValidateReason(message)
	if not valid then
		return {Success = false, Message = sanitizedMessage}
	end
	
	-- Broadcast to all players
	for _, player in ipairs(Players:GetPlayers()) do
		AdminCore.SendNotification(player, "Admin Announcement", sanitizedMessage, "Info")
	end
	
	Logging.LogAction(executor, "ANNOUNCE", "All Players", sanitizedMessage)
	
	return {Success = true, Message = "Announcement sent"}
end

--================================================================================
-- BAN MANAGEMENT
--================================================================================

function Commands.SaveBan(userId, banData)
	if not BanDataStore then
		return false
	end
	
	local success, err = pcall(function()
		BanDataStore:SetAsync(tostring(userId), banData)
	end)
	
	return success
end

function Commands.RemoveBan(userId)
	if not BanDataStore then
		return false
	end
	
	local success, err = pcall(function()
		BanDataStore:RemoveAsync(tostring(userId))
	end)
	
	return success
end

function Commands.LoadBanList()
	if not BanDataStore then
		return
	end
	
	-- Note: In production, you'd want to use OrderedDataStore or Pages
	-- For now, bans are loaded as players join
	print("[Commands] Ban system initialized")
end

function Commands.CheckPlayerBan(player)
	local userId = player.UserId
	
	-- Check cache first
	if BannedPlayers[userId] then
		local banData = BannedPlayers[userId]
		
		-- Check if ban has expired
		if banData.ExpiresAt ~= -1 and os.time() >= banData.ExpiresAt then
			Commands.RemoveBan(userId)
			BannedPlayers[userId] = nil
			return
		end
		
		-- Player is still banned
		local timeLeft = banData.ExpiresAt == -1 and "Permanent" or 
			string.format("%d hours", math.ceil((banData.ExpiresAt - os.time()) / 3600))
		
		player:Kick(string.format("You are banned from this game.\nReason: %s\nTime Remaining: %s\nBanned by: %s",
			banData.Reason, timeLeft, banData.BannedBy))
		return
	end
	
	-- Load from DataStore
	if BanDataStore then
		local success, banData = pcall(function()
			return BanDataStore:GetAsync(tostring(userId))
		end)
		
		if success and banData then
			-- Check if ban has expired
			if banData.ExpiresAt ~= -1 and os.time() >= banData.ExpiresAt then
				Commands.RemoveBan(userId)
				return
			end
			
			-- Cache ban
			BannedPlayers[userId] = banData
			
			-- Kick player
			local timeLeft = banData.ExpiresAt == -1 and "Permanent" or 
				string.format("%d hours", math.ceil((banData.ExpiresAt - os.time()) / 3600))
			
			player:Kick(string.format("You are banned from this game.\nReason: %s\nTime Remaining: %s\nBanned by: %s",
				banData.Reason, timeLeft, banData.BannedBy))
		end
	end
end

return Commands
