--[[
	Advanced Admin Panel Configuration
	Roblox Shooter Game - Admin System
	
	This module contains all configuration settings for the admin panel including:
	- Rank definitions and hierarchy
	- Admin user assignments
	- Command permissions mapping
	- Webhook URLs for logging
	- UI theme settings
]]

local AdminConfig = {}

--================================================================================
-- RANK HIERARCHY DEFINITION
--================================================================================

AdminConfig.Ranks = {
	[1] = {
		RankID = 1,
		RankName = "Staff",
		Description = "Basic utility commands (e.g., View Player Info, Speed/Jump changes on self)",
		Color = Color3.fromRGB(100, 200, 255),
	},
	[2] = {
		RankID = 2,
		RankName = "Moderator",
		Description = "Standard moderation (Kick, Temp Ban, Mute, Spectate)",
		Color = Color3.fromRGB(255, 200, 100),
	},
	[3] = {
		RankID = 3,
		RankName = "Head Admin",
		Description = "Access to all moderation commands, game control, and demote/promote staff",
		Color = Color3.fromRGB(255, 100, 100),
	},
	[4] = {
		RankID = 4,
		RankName = "Owner",
		Description = "Full access to all commands, including rank management",
		Color = Color3.fromRGB(255, 50, 255),
	},
}

--================================================================================
-- ADMIN USER ASSIGNMENTS
-- Map User IDs to Rank IDs
--================================================================================

AdminConfig.AdminList = {
	-- Example entries (Replace with actual User IDs):
	-- [123456789] = 4,  -- Owner
	-- [987654321] = 3,  -- Head Admin
	-- [555555555] = 2,  -- Moderator
	-- [111111111] = 1,  -- Staff
	
	-- ADD YOUR ADMIN USER IDS HERE:
	-- Format: [UserID] = RankID
}

--================================================================================
-- COMMAND PERMISSION MAPPING
-- Defines minimum rank required for each command
--================================================================================

AdminConfig.CommandPermissions = {
	-- Player Moderation Commands
	["Kick"] = 2,           -- Moderator+
	["Ban"] = 2,            -- Moderator+
	["Unban"] = 3,          -- Head Admin+
	["Mute"] = 2,           -- Moderator+
	["Unmute"] = 2,         -- Moderator+
	
	-- Info Commands
	["ViewInfo"] = 1,       -- Staff+
	
	-- Teleport Commands
	["Teleport"] = 2,       -- Moderator+
	["TeleportToMe"] = 2,   -- Moderator+
	["TeleportMeTo"] = 2,   -- Moderator+
	
	-- Player Manipulation
	["SetHealth"] = 3,      -- Head Admin+
	["SetSpeed"] = 3,       -- Head Admin+
	["SetJump"] = 3,        -- Head Admin+
	["ToggleGod"] = 3,      -- Head Admin+
	["ToggleFly"] = 3,      -- Head Admin+
	["GiveWeapon"] = 2,     -- Moderator+
	["StripWeapons"] = 2,   -- Moderator+
	
	-- Game Control
	["ForceRoundEnd"] = 3,  -- Head Admin+
	["SetMap"] = 3,         -- Head Admin+
	["ToggleSpectate"] = 2, -- Moderator+
	["ChangeTime"] = 3,     -- Head Admin+
	["SetGravity"] = 3,     -- Head Admin+
	
	-- Rank Management
	["Promote"] = 4,        -- Owner Only
	["Demote"] = 4,         -- Owner Only
	["SetRank"] = 4,        -- Owner Only
	
	-- System Commands
	["ViewLogs"] = 1,       -- Staff+
	["ClearLogs"] = 3,      -- Head Admin+
	["Shutdown"] = 4,       -- Owner Only
	["Announce"] = 2,       -- Moderator+
}

--================================================================================
-- LOGGING CONFIGURATION
--================================================================================

AdminConfig.Logging = {
	-- Discord Webhook URL for persistent logging
	-- Replace with your actual webhook URL
	DiscordWebhookURL = "YOUR_DISCORD_WEBHOOK_URL_HERE",
	
	-- Enable/Disable different logging methods
	EnableLocalLogging = true,      -- Store logs in server memory
	EnableWebhookLogging = true,    -- Send logs to Discord webhook
	
	-- Maximum number of logs to store in memory
	MaxLocalLogs = 500,
	
	-- Webhook settings
	WebhookRetryAttempts = 3,
	WebhookTimeout = 10,
}

--================================================================================
-- UI THEME CONFIGURATION
--================================================================================

AdminConfig.UITheme = {
	-- Main Colors
	Primary = Color3.fromRGB(30, 30, 35),
	Secondary = Color3.fromRGB(40, 40, 45),
	Accent = Color3.fromRGB(80, 120, 255),
	Success = Color3.fromRGB(50, 200, 100),
	Warning = Color3.fromRGB(255, 180, 50),
	Error = Color3.fromRGB(255, 80, 80),
	
	-- Text Colors
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 180),
	TextDisabled = Color3.fromRGB(100, 100, 100),
	
	-- Border and Stroke
	Border = Color3.fromRGB(60, 60, 65),
	BorderThickness = 2,
	
	-- Transparency
	BackgroundTransparency = 0.05,
	ButtonTransparency = 0.1,
	
	-- Animations
	TweenSpeed = 0.3,
	
	-- Fonts
	HeaderFont = Enum.Font.GothamBold,
	BodyFont = Enum.Font.Gotham,
	MonospaceFont = Enum.Font.Code,
}

--================================================================================
-- GAME-SPECIFIC SETTINGS
--================================================================================

AdminConfig.GameSettings = {
	-- Default player stats
	DefaultHealth = 100,
	DefaultSpeed = 16,
	DefaultJumpPower = 50,
	
	-- Available weapons (for GiveWeapon command)
	-- Replace with your actual weapon names
	AvailableWeapons = {
		"Pistol",
		"Rifle",
		"Shotgun",
		"SMG",
		"Sniper",
		"Grenade",
	},
	
	-- Available maps (for SetMap command)
	-- Replace with your actual map names
	AvailableMaps = {
		"Desert",
		"Urban",
		"Factory",
		"Forest",
		"Warehouse",
	},
	
	-- Ban data store settings
	BanDataStoreName = "AdminBanList_v1",
	RankDataStoreName = "AdminRankList_v1",
}

--================================================================================
-- SECURITY SETTINGS
--================================================================================

AdminConfig.Security = {
	-- Maximum length for reason strings
	MaxReasonLength = 200,
	
	-- Rate limiting (commands per minute per admin)
	CommandRateLimit = 30,
	
	-- Validation patterns
	AllowedReasonCharacters = "[%w%s%p]",  -- Alphanumeric, whitespace, punctuation
	
	-- Prevent admins from affecting higher-ranked admins
	EnforceRankHierarchy = true,
	
	-- Log all failed permission checks
	LogFailedAttempts = true,
}

--================================================================================
-- HELPER FUNCTIONS
--================================================================================

-- Get rank information by User ID
function AdminConfig:GetUserRank(userId)
	return self.AdminList[userId] or 0
end

-- Get rank data by Rank ID
function AdminConfig:GetRankData(rankId)
	return self.Ranks[rankId]
end

-- Check if user is admin
function AdminConfig:IsAdmin(userId)
	return self.AdminList[userId] ~= nil
end

-- Get command permission requirement
function AdminConfig:GetCommandPermission(commandName)
	return self.CommandPermissions[commandName] or 999
end

-- Check if user can use command
function AdminConfig:CanUseCommand(userId, commandName)
	local userRank = self:GetUserRank(userId)
	local requiredRank = self:GetCommandPermission(commandName)
	return userRank >= requiredRank
end

-- Get all admins with rank >= specified rank
function AdminConfig:GetAdminsWithRank(minRank)
	local admins = {}
	for userId, rankId in pairs(self.AdminList) do
		if rankId >= minRank then
			table.insert(admins, {
				UserId = userId,
				RankId = rankId,
				RankName = self.Ranks[rankId].RankName
			})
		end
	end
	return admins
end

return AdminConfig
