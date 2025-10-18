--[[
	AdminSystem_Logging Module
	Comprehensive logging and auditing system
	
	Responsibilities:
	- Local log storage (in-memory)
	- Webhook integration for persistent logging
	- Log retrieval and filtering
	- Audit trail maintenance
]]

local Logging = {}

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Module References
local Config

-- Log storage
local LogHistory = {}
local MaxLogs = 500

--================================================================================
-- INITIALIZATION
--================================================================================

function Logging.Initialize(configModule)
	Config = configModule
	MaxLogs = Config.Logging.MaxLocalLogs or 500
	print("[Logging] Module initialized")
end

--================================================================================
-- LOG CREATION
--================================================================================

-- Log an admin action
function Logging.LogAction(executor, action, target, details)
	local logEntry = {
		Type = "ACTION",
		Timestamp = os.time(),
		DateTime = os.date("%Y-%m-%d %H:%M:%S", os.time()),
		Executor = {
			Name = executor.Name,
			UserId = executor.UserId,
			Rank = Config:GetUserRank(executor.UserId),
			RankName = Config:GetRankData(Config:GetUserRank(executor.UserId)).RankName,
		},
		Action = action,
		Target = target,
		Details = details,
		ServerId = game.JobId,
	}
	
	-- Add to local log
	Logging.AddToLocalLog(logEntry)
	
	-- Send to webhook
	if Config.Logging.EnableWebhookLogging then
		Logging.SendToWebhook(logEntry)
	end
	
	return logEntry
end

-- Log a system event
function Logging.LogSystem(eventType, subject, details)
	local logEntry = {
		Type = "SYSTEM",
		Timestamp = os.time(),
		DateTime = os.date("%Y-%m-%d %H:%M:%S", os.time()),
		EventType = eventType,
		Subject = subject,
		Details = details,
		ServerId = game.JobId,
	}
	
	-- Add to local log
	Logging.AddToLocalLog(logEntry)
	
	-- Send to webhook for important events
	if Config.Logging.EnableWebhookLogging and Logging.IsImportantEvent(eventType) then
		Logging.SendToWebhook(logEntry)
	end
	
	return logEntry
end

-- Determine if system event is important enough for webhook
function Logging.IsImportantEvent(eventType)
	local importantEvents = {
		"SYSTEM",
		"UNAUTHORIZED_ACCESS",
		"PERMISSION_DENIED",
		"EXPLOIT_ATTEMPT",
		"ADMIN_JOIN",
	}
	
	for _, event in ipairs(importantEvents) do
		if eventType == event then
			return true
		end
	end
	
	return false
end

--================================================================================
-- LOCAL LOG MANAGEMENT
--================================================================================

-- Add entry to local log storage
function Logging.AddToLocalLog(logEntry)
	if not Config.Logging.EnableLocalLogging then
		return
	end
	
	table.insert(LogHistory, 1, logEntry)
	
	-- Trim log history if it exceeds max
	if #LogHistory > MaxLogs then
		table.remove(LogHistory, #LogHistory)
	end
end

-- Get recent logs
function Logging.GetRecentLogs(count)
	count = math.min(count or 50, #LogHistory)
	local logs = {}
	
	for i = 1, count do
		if LogHistory[i] then
			table.insert(logs, LogHistory[i])
		end
	end
	
	return logs
end

-- Get logs filtered by criteria
function Logging.GetFilteredLogs(filters)
	local filtered = {}
	
	for _, log in ipairs(LogHistory) do
		local match = true
		
		-- Filter by executor
		if filters.Executor and log.Executor then
			if log.Executor.Name ~= filters.Executor then
				match = false
			end
		end
		
		-- Filter by action
		if filters.Action then
			if log.Action ~= filters.Action and log.EventType ~= filters.Action then
				match = false
			end
		end
		
		-- Filter by target
		if filters.Target then
			if log.Target ~= filters.Target and log.Subject ~= filters.Target then
				match = false
			end
		end
		
		-- Filter by time range
		if filters.StartTime then
			if log.Timestamp < filters.StartTime then
				match = false
			end
		end
		
		if filters.EndTime then
			if log.Timestamp > filters.EndTime then
				match = false
			end
		end
		
		if match then
			table.insert(filtered, log)
		end
	end
	
	return filtered
end

-- Clear all logs
function Logging.ClearLogs()
	LogHistory = {}
	print("[Logging] Log history cleared")
end

-- Get log statistics
function Logging.GetLogStats()
	local stats = {
		TotalLogs = #LogHistory,
		ActionLogs = 0,
		SystemLogs = 0,
		RecentActivity = {},
		TopExecutors = {},
	}
	
	-- Count by type
	for _, log in ipairs(LogHistory) do
		if log.Type == "ACTION" then
			stats.ActionLogs = stats.ActionLogs + 1
		elseif log.Type == "SYSTEM" then
			stats.SystemLogs = stats.SystemLogs + 1
		end
	end
	
	return stats
end

--================================================================================
-- WEBHOOK INTEGRATION
--================================================================================

-- Send log to Discord webhook
function Logging.SendToWebhook(logEntry)
	local webhookUrl = Config.Logging.DiscordWebhookURL
	
	if not webhookUrl or webhookUrl == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
		return
	end
	
	-- Format embed based on log type
	local embed
	if logEntry.Type == "ACTION" then
		embed = Logging.FormatActionEmbed(logEntry)
	elseif logEntry.Type == "SYSTEM" then
		embed = Logging.FormatSystemEmbed(logEntry)
	end
	
	if not embed then
		return
	end
	
	local payload = {
		embeds = {embed}
	}
	
	-- Send to webhook (with retry logic)
	Logging.SendWebhookRequest(webhookUrl, payload)
end

-- Format action log as Discord embed
function Logging.FormatActionEmbed(logEntry)
	local color = 3447003  -- Default blue
	
	-- Set color based on action severity
	local severeActions = {"BAN", "KICK", "SHUTDOWN"}
	local warningActions = {"MUTE", "TELEPORT", "SET_HEALTH"}
	
	for _, action in ipairs(severeActions) do
		if string.find(logEntry.Action, action) then
			color = 15158332  -- Red
			break
		end
	end
	
	for _, action in ipairs(warningActions) do
		if string.find(logEntry.Action, action) then
			color = 16776960  -- Yellow
			break
		end
	end
	
	return {
		title = "🛡️ Admin Action",
		color = color,
		fields = {
			{
				name = "Action",
				value = logEntry.Action,
				inline = true
			},
			{
				name = "Executor",
				value = string.format("%s (%s)", logEntry.Executor.Name, logEntry.Executor.RankName),
				inline = true
			},
			{
				name = "Target",
				value = logEntry.Target,
				inline = true
			},
			{
				name = "Details",
				value = logEntry.Details or "No details provided",
				inline = false
			},
			{
				name = "Server ID",
				value = logEntry.ServerId,
				inline = true
			},
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%S", logEntry.Timestamp),
		footer = {
			text = string.format("User ID: %d", logEntry.Executor.UserId)
		}
	}
end

-- Format system log as Discord embed
function Logging.FormatSystemEmbed(logEntry)
	local color = 10070709  -- Gray
	
	-- Set color based on event type
	if string.find(logEntry.EventType, "EXPLOIT") or string.find(logEntry.EventType, "UNAUTHORIZED") then
		color = 15158332  -- Red
	elseif string.find(logEntry.EventType, "ADMIN_JOIN") or string.find(logEntry.EventType, "ADMIN_LEAVE") then
		color = 5763719  -- Green
	end
	
	return {
		title = "⚙️ System Event",
		color = color,
		fields = {
			{
				name = "Event Type",
				value = logEntry.EventType,
				inline = true
			},
			{
				name = "Subject",
				value = logEntry.Subject,
				inline = true
			},
			{
				name = "Details",
				value = logEntry.Details or "No details provided",
				inline = false
			},
			{
				name = "Server ID",
				value = logEntry.ServerId,
				inline = true
			},
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%S", logEntry.Timestamp),
	}
end

-- Send HTTP request to webhook with retry logic
function Logging.SendWebhookRequest(url, payload)
	local attempts = 0
	local maxAttempts = Config.Logging.WebhookRetryAttempts or 3
	
	local function trySend()
		attempts = attempts + 1
		
		local success, err = pcall(function()
			HttpService:PostAsync(
				url,
				HttpService:JSONEncode(payload),
				Enum.HttpContentType.ApplicationJson,
				false
			)
		end)
		
		if not success then
			warn(string.format("[Logging] Webhook send failed (attempt %d/%d): %s", 
				attempts, maxAttempts, tostring(err)))
			
			if attempts < maxAttempts then
				task.wait(1)
				trySend()
			end
		end
	end
	
	-- Send asynchronously to avoid blocking
	task.spawn(trySend)
end

--================================================================================
-- LOG EXPORT
--================================================================================

-- Export logs as formatted string
function Logging.ExportLogsAsString(count)
	count = math.min(count or 100, #LogHistory)
	local exportString = string.format("=== Admin Panel Logs (Recent %d) ===\n\n", count)
	
	for i = 1, count do
		local log = LogHistory[i]
		if not log then break end
		
		if log.Type == "ACTION" then
			exportString = exportString .. string.format(
				"[%s] ACTION: %s | Executor: %s (%s) | Target: %s | Details: %s\n",
				log.DateTime,
				log.Action,
				log.Executor.Name,
				log.Executor.RankName,
				log.Target,
				log.Details
			)
		elseif log.Type == "SYSTEM" then
			exportString = exportString .. string.format(
				"[%s] SYSTEM: %s | Subject: %s | Details: %s\n",
				log.DateTime,
				log.EventType,
				log.Subject,
				log.Details
			)
		end
	end
	
	return exportString
end

-- Export logs as JSON
function Logging.ExportLogsAsJSON(count)
	count = math.min(count or 100, #LogHistory)
	local logs = {}
	
	for i = 1, count do
		if LogHistory[i] then
			table.insert(logs, LogHistory[i])
		end
	end
	
	return HttpService:JSONEncode(logs)
end

--================================================================================
-- SEARCH AND QUERY
--================================================================================

-- Search logs by keyword
function Logging.SearchLogs(keyword)
	local results = {}
	keyword = string.lower(keyword)
	
	for _, log in ipairs(LogHistory) do
		local searchText = ""
		
		if log.Type == "ACTION" then
			searchText = string.format("%s %s %s %s",
				log.Action,
				log.Executor.Name,
				log.Target,
				log.Details
			)
		elseif log.Type == "SYSTEM" then
			searchText = string.format("%s %s %s",
				log.EventType,
				log.Subject,
				log.Details
			)
		end
		
		if string.find(string.lower(searchText), keyword, 1, true) then
			table.insert(results, log)
		end
	end
	
	return results
end

-- Get actions by specific executor
function Logging.GetExecutorHistory(executorName)
	local history = {}
	
	for _, log in ipairs(LogHistory) do
		if log.Type == "ACTION" and log.Executor.Name == executorName then
			table.insert(history, log)
		end
	end
	
	return history
end

-- Get actions affecting specific target
function Logging.GetTargetHistory(targetName)
	local history = {}
	
	for _, log in ipairs(LogHistory) do
		if log.Type == "ACTION" and log.Target == targetName then
			table.insert(history, log)
		end
	end
	
	return history
end

--================================================================================
-- ANALYTICS
--================================================================================

-- Get most active admins
function Logging.GetMostActiveAdmins(limit)
	limit = limit or 5
	local adminActions = {}
	
	for _, log in ipairs(LogHistory) do
		if log.Type == "ACTION" then
			local name = log.Executor.Name
			adminActions[name] = (adminActions[name] or 0) + 1
		end
	end
	
	-- Convert to array and sort
	local sorted = {}
	for name, count in pairs(adminActions) do
		table.insert(sorted, {Name = name, Actions = count})
	end
	
	table.sort(sorted, function(a, b)
		return a.Actions > b.Actions
	end)
	
	-- Return top N
	local result = {}
	for i = 1, math.min(limit, #sorted) do
		table.insert(result, sorted[i])
	end
	
	return result
end

-- Get most common actions
function Logging.GetMostCommonActions(limit)
	limit = limit or 5
	local actionCounts = {}
	
	for _, log in ipairs(LogHistory) do
		if log.Type == "ACTION" then
			local action = log.Action
			actionCounts[action] = (actionCounts[action] or 0) + 1
		end
	end
	
	-- Convert to array and sort
	local sorted = {}
	for action, count in pairs(actionCounts) do
		table.insert(sorted, {Action = action, Count = count})
	end
	
	table.sort(sorted, function(a, b)
		return a.Count > b.Count
	end)
	
	-- Return top N
	local result = {}
	for i = 1, math.min(limit, #sorted) do
		table.insert(result, sorted[i])
	end
	
	return result
end

return Logging
