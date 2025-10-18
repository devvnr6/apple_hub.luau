--[[
	AdminSystem_Permissions Module
	Permission validation and security enforcement
	
	Responsibilities:
	- Rank hierarchy validation
	- Target permission checks
	- Security validation for all operations
	- Rank management operations
]]

local Permissions = {}

local Config
local Logging

--================================================================================
-- INITIALIZATION
--================================================================================

function Permissions.Initialize(configModule, loggingModule)
	Config = configModule
	Logging = loggingModule
	print("[Permissions] Module initialized")
end

--================================================================================
-- RANK VALIDATION
--================================================================================

-- Check if executor can affect target
function Permissions.CanAffectTarget(executorUserId, targetUserId)
	-- Can't affect yourself in most cases (except utility commands)
	if executorUserId == targetUserId then
		return false, "Cannot target yourself"
	end
	
	local executorRank = Config:GetUserRank(executorUserId)
	local targetRank = Config:GetUserRank(targetUserId)
	
	-- If rank hierarchy is enforced, check ranks
	if Config.Security.EnforceRankHierarchy then
		if targetRank > 0 and targetRank >= executorRank then
			return false, "Cannot affect admins of equal or higher rank"
		end
	end
	
	return true, "Permission granted"
end

-- Check if executor can use command on target
function Permissions.ValidateCommandExecution(executor, commandName, targetPlayer)
	local executorId = executor.UserId
	
	-- Check if executor has permission for command
	if not Config:CanUseCommand(executorId, commandName) then
		return false, "Insufficient permissions for this command"
	end
	
	-- If target is specified, check if executor can affect them
	if targetPlayer then
		local canAffect, reason = Permissions.CanAffectTarget(executorId, targetPlayer.UserId)
		if not canAffect then
			return false, reason
		end
	end
	
	return true, "Validation passed"
end

--================================================================================
-- RANK MANAGEMENT
--================================================================================

-- Promote a user
function Permissions.PromoteUser(executor, targetUserId)
	local executorId = executor.UserId
	local executorRank = Config:GetUserRank(executorId)
	
	-- Must be owner to promote
	if executorRank < 4 then
		return false, "Only owners can promote users"
	end
	
	-- Check current target rank
	local currentRank = Config:GetUserRank(targetUserId)
	
	if currentRank >= 4 then
		return false, "User is already at maximum rank"
	end
	
	-- Promote to next rank
	local newRank = currentRank + 1
	Config.AdminList[targetUserId] = newRank
	
	local rankData = Config:GetRankData(newRank)
	
	Logging.LogAction(executor, "PROMOTE", string.format("UserID: %d", targetUserId), 
		string.format("Promoted to %s (Rank %d)", rankData.RankName, newRank))
	
	return true, string.format("User promoted to %s", rankData.RankName)
end

-- Demote a user
function Permissions.DemoteUser(executor, targetUserId)
	local executorId = executor.UserId
	local executorRank = Config:GetUserRank(executorId)
	
	-- Must be owner to demote
	if executorRank < 4 then
		return false, "Only owners can demote users"
	end
	
	-- Can't demote yourself
	if executorId == targetUserId then
		return false, "Cannot demote yourself"
	end
	
	-- Check current target rank
	local currentRank = Config:GetUserRank(targetUserId)
	
	if currentRank <= 0 then
		return false, "User is not an admin"
	end
	
	-- Can't demote equal or higher rank (unless you're demoting to 0)
	if currentRank >= executorRank then
		return false, "Cannot demote admins of equal or higher rank"
	end
	
	-- Demote to previous rank
	local newRank = currentRank - 1
	
	if newRank <= 0 then
		Config.AdminList[targetUserId] = nil
		Logging.LogAction(executor, "DEMOTE", string.format("UserID: %d", targetUserId), 
			"Removed from admin list")
		return true, "User removed from admin list"
	else
		Config.AdminList[targetUserId] = newRank
		local rankData = Config:GetRankData(newRank)
		Logging.LogAction(executor, "DEMOTE", string.format("UserID: %d", targetUserId), 
			string.format("Demoted to %s (Rank %d)", rankData.RankName, newRank))
		return true, string.format("User demoted to %s", rankData.RankName)
	end
end

-- Set specific rank
function Permissions.SetRank(executor, targetUserId, rankId)
	local executorId = executor.UserId
	local executorRank = Config:GetUserRank(executorId)
	
	-- Must be owner to set ranks
	if executorRank < 4 then
		return false, "Only owners can set ranks"
	end
	
	-- Can't modify your own rank
	if executorId == targetUserId then
		return false, "Cannot modify your own rank"
	end
	
	-- Validate rank ID
	if rankId < 0 or rankId > 4 then
		return false, "Invalid rank ID (must be 0-4)"
	end
	
	-- Can't set someone to owner rank unless you want to (security consideration)
	if rankId == 4 then
		return false, "Cannot set users to Owner rank directly"
	end
	
	if rankId == 0 then
		Config.AdminList[targetUserId] = nil
		Logging.LogAction(executor, "SET_RANK", string.format("UserID: %d", targetUserId), 
			"Removed from admin list")
		return true, "User removed from admin list"
	else
		Config.AdminList[targetUserId] = rankId
		local rankData = Config:GetRankData(rankId)
		Logging.LogAction(executor, "SET_RANK", string.format("UserID: %d", targetUserId), 
			string.format("Set to %s (Rank %d)", rankData.RankName, rankId))
		return true, string.format("User rank set to %s", rankData.RankName)
	end
end

--================================================================================
-- INPUT VALIDATION
--================================================================================

-- Validate and sanitize reason string
function Permissions.ValidateReason(reason)
	if type(reason) ~= "string" then
		return false, "Invalid reason format"
	end
	
	if #reason == 0 then
		return false, "Reason cannot be empty"
	end
	
	if #reason > Config.Security.MaxReasonLength then
		reason = string.sub(reason, 1, Config.Security.MaxReasonLength)
	end
	
	-- Check for allowed characters
	local sanitized = string.gsub(reason, "[^%w%s%p]", "")
	
	return true, sanitized
end

-- Validate numeric input
function Permissions.ValidateNumber(value, min, max, default)
	local num = tonumber(value)
	
	if not num then
		return false, default or min, "Invalid number"
	end
	
	if num < min then
		return false, min, string.format("Value too low (minimum: %d)", min)
	end
	
	if num > max then
		return false, max, string.format("Value too high (maximum: %d)", max)
	end
	
	return true, num, "Valid"
end

-- Validate duration string (e.g., "30m", "2h", "perm")
function Permissions.ValidateDuration(durationStr)
	if type(durationStr) ~= "string" then
		return false, 0, "Invalid duration format"
	end
	
	-- Check for permanent ban
	if string.lower(durationStr) == "perm" or string.lower(durationStr) == "permanent" then
		return true, -1, "Permanent"
	end
	
	-- Parse duration (supports formats like "30m", "2h", "1d")
	local amount, unit = string.match(durationStr, "^(%d+)([mhd])$")
	
	if not amount or not unit then
		return false, 0, "Invalid duration format (use: 30m, 2h, 1d, or 'perm')"
	end
	
	amount = tonumber(amount)
	
	local hours = 0
	if unit == "m" then
		hours = amount / 60
	elseif unit == "h" then
		hours = amount
	elseif unit == "d" then
		hours = amount * 24
	end
	
	return true, hours, string.format("%d %s", amount, unit)
end

--================================================================================
-- SECURITY CHECKS
--================================================================================

-- Validate that the command execution is legitimate
function Permissions.SecurityCheck(executor, commandName, parameters)
	-- Check if executor still exists and is valid
	if not executor or not executor.Parent then
		return false, "Invalid executor"
	end
	
	-- Check if executor is still an admin (in case they were demoted mid-session)
	if not Config:IsAdmin(executor.UserId) then
		return false, "You are no longer an admin"
	end
	
	-- Re-validate permission
	if not Config:CanUseCommand(executor.UserId, commandName) then
		return false, "Permission revoked"
	end
	
	-- Additional security checks can be added here
	-- (e.g., checking for suspicious patterns, command chaining, etc.)
	
	return true, "Security check passed"
end

-- Check for potential exploit attempts
function Permissions.CheckForExploits(executor, parameters)
	-- Check for suspicious parameter patterns
	if type(parameters) == "table" then
		for key, value in pairs(parameters) do
			-- Check for extremely long strings
			if type(value) == "string" and #value > 1000 then
				Logging.LogSystem("EXPLOIT_ATTEMPT", executor.Name, 
					string.format("Suspicious parameter length: %d", #value))
				return false, "Suspicious parameter detected"
			end
			
			-- Check for nested tables (potential DoS attack)
			if type(value) == "table" then
				local depth = 0
				local function checkDepth(t, d)
					if d > 5 then return false end
					for _, v in pairs(t) do
						if type(v) == "table" then
							if not checkDepth(v, d + 1) then
								return false
							end
						end
					end
					return true
				end
				
				if not checkDepth(value, 0) then
					Logging.LogSystem("EXPLOIT_ATTEMPT", executor.Name, 
						"Suspicious nested table structure")
					return false, "Suspicious parameter structure detected"
				end
			end
		end
	end
	
	return true, "No exploits detected"
end

return Permissions
