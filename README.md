# 🛡️ Advanced Admin Panel for Roblox Shooter Game

A comprehensive, secure, and feature-rich admin panel system designed specifically for competitive Roblox shooter games. This system prioritizes **server-side validation**, **security**, and **user experience**.

---

## 📋 Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Command Reference](#command-reference)
6. [Security Features](#security-features)
7. [Logging & Auditing](#logging--auditing)
8. [Customization](#customization)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

## ✨ Features

### Core Features
- ✅ **Tiered Permission System** (Staff, Moderator, Head Admin, Owner)
- ✅ **Server-Side Validation** for all commands
- ✅ **Modern Dark-Themed UI** with responsive design
- ✅ **Real-Time Player Management**
- ✅ **Comprehensive Logging System** (local + webhook)
- ✅ **Ban System** with DataStore persistence
- ✅ **Mobile Support** with touch controls
- ✅ **Rate Limiting** to prevent abuse
- ✅ **Anti-Exploit Monitoring**

### Moderation Commands
- Kick, Ban, Unban, Mute, Unmute
- Teleport players
- View player information
- Spectate mode

### Shooter-Specific Commands
- Set player health, speed, jump power
- Toggle god mode and fly mode
- Give/remove weapons
- Game control (round end, map selection)
- Lighting and gravity control

### Logging & Auditing
- All actions logged with timestamp
- Discord webhook integration
- Searchable log viewer in UI
- Export logs as text or JSON
- Activity analytics

---

## 🏗️ Architecture

### Module Structure

```
AdminSystem/
├── AdminSystem_Config.lua          # Configuration (ranks, permissions, admins)
├── AdminSystem_Core.lua            # Core system (initialization, remotes)
├── AdminSystem_Permissions.lua     # Permission validation & security
├── AdminSystem_Commands.lua        # Command implementations
├── AdminSystem_Logging.lua         # Logging and audit system
├── AdminSystem_UI.lua             # Client-side UI (ReplicatedStorage)
├── AdminSystem_Server.lua         # Main server script
└── AdminSystem_Client.lua         # Main client script
```

### Technology Stack

- **Platform**: Roblox Studio (Lua)
- **Networking**: RemoteEvents & RemoteFunctions
- **Data Persistence**: DataStoreService
- **UI Framework**: Custom dark-themed responsive UI
- **Logging**: Local + Discord Webhooks

---

## 📦 Installation

### Step 1: File Placement

1. **Place in ServerScriptService:**
   - `AdminSystem_Server.lua` (Script)
   - `AdminSystem_Config.lua` (ModuleScript)
   - `AdminSystem_Core.lua` (ModuleScript)
   - `AdminSystem_Permissions.lua` (ModuleScript)
   - `AdminSystem_Commands.lua` (ModuleScript)
   - `AdminSystem_Logging.lua` (ModuleScript)

2. **Place in ReplicatedStorage:**
   - `AdminSystem_UI.lua` (ModuleScript)

3. **Place in StarterPlayer > StarterPlayerScripts:**
   - `AdminSystem_Client.lua` (LocalScript)

### Step 2: Verify Structure

Your explorer should look like this:

```
ServerScriptService/
├── AdminSystem_Server (Script)
├── AdminSystem_Config (ModuleScript)
├── AdminSystem_Core (ModuleScript)
├── AdminSystem_Permissions (ModuleScript)
├── AdminSystem_Commands (ModuleScript)
└── AdminSystem_Logging (ModuleScript)

ReplicatedStorage/
└── AdminSystem_UI (ModuleScript)

StarterPlayer/
└── StarterPlayerScripts/
    └── AdminSystem_Client (LocalScript)
```

### Step 3: Enable Required Services

Ensure these services are enabled:
- ✅ Allow HTTP Requests (for webhook logging)
- ✅ Enable Studio Access to API Services (for DataStores)

---

## ⚙️ Configuration

### Adding Admins

Edit `AdminSystem_Config.lua`:

```lua
AdminConfig.AdminList = {
    [123456789] = 4,  -- Owner (Your User ID)
    [987654321] = 3,  -- Head Admin
    [555555555] = 2,  -- Moderator
    [111111111] = 1,  -- Staff
}
```

**Finding User IDs:**
1. Go to roblox.com/users/[username]/profile
2. Copy the number from the URL

### Discord Webhook Setup

1. Create a Discord webhook in your server
2. Copy the webhook URL
3. Add to `AdminSystem_Config.lua`:

```lua
AdminConfig.Logging = {
    DiscordWebhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE",
    EnableWebhookLogging = true,
}
```

### Rank Permissions

Customize command permissions in `AdminSystem_Config.lua`:

```lua
AdminConfig.CommandPermissions = {
    ["Kick"] = 2,           -- Moderator+
    ["Ban"] = 2,            -- Moderator+
    ["Unban"] = 3,          -- Head Admin+
    ["SetHealth"] = 3,      -- Head Admin+
    ["Shutdown"] = 4,       -- Owner Only
}
```

### Game-Specific Settings

Configure your weapons and maps:

```lua
AdminConfig.GameSettings = {
    AvailableWeapons = {
        "Pistol",
        "Rifle",
        "Shotgun",
        -- Add your weapon names here
    },
    
    AvailableMaps = {
        "Desert",
        "Urban",
        "Factory",
        -- Add your map names here
    },
}
```

---

## 🎮 Command Reference

### Player Moderation

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **Kick** | Moderator+ | Target, Reason | Kicks a player from the server |
| **Ban** | Moderator+ | Target, Reason, Duration | Permanently or temporarily bans a player |
| **Unban** | Head Admin+ | UserID | Removes a ban from a player |
| **Mute** | Moderator+ | Target, Duration, Reason | Mutes a player's chat |
| **Unmute** | Moderator+ | Target | Unmutes a player |

### Player Information

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **ViewInfo** | Staff+ | Target | Displays detailed player information |

### Teleportation

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **Teleport** | Moderator+ | Target, Destination | Teleports one player to another |
| **TeleportToMe** | Moderator+ | Target | Teleports target player to you |
| **TeleportMeTo** | Moderator+ | Target | Teleports you to target player |

### Player Manipulation

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **SetHealth** | Head Admin+ | Target, Value (1-100) | Sets player's health |
| **SetSpeed** | Head Admin+ | Target, Value (0-200) | Sets player's walk speed |
| **SetJump** | Head Admin+ | Target, Value (0-200) | Sets player's jump power |
| **ToggleGod** | Head Admin+ | Target | Toggles invincibility |
| **ToggleFly** | Head Admin+ | Target | Toggles flight ability |
| **GiveWeapon** | Moderator+ | Target, Weapon | Gives a weapon to player |
| **StripWeapons** | Moderator+ | Target | Removes all weapons from player |

### Game Control

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **ForceRoundEnd** | Head Admin+ | Team (optional) | Immediately ends current round |
| **SetMap** | Head Admin+ | MapName | Sets the next map |
| **ToggleSpectate** | Moderator+ | Target (optional) | Enters spectator mode |
| **ChangeTime** | Head Admin+ | Time (0-24) | Changes time of day |
| **SetGravity** | Head Admin+ | Gravity (0-500) | Changes workspace gravity |

### System Commands

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **Announce** | Moderator+ | Message | Sends server-wide announcement |
| **ViewLogs** | Staff+ | - | Views recent admin actions |
| **ClearLogs** | Head Admin+ | - | Clears log history |
| **Shutdown** | Owner Only | Reason | Shuts down the server |

### Rank Management

| Command | Rank Required | Parameters | Description |
|---------|---------------|------------|-------------|
| **Promote** | Owner Only | UserID | Promotes user to next rank |
| **Demote** | Owner Only | UserID | Demotes user to previous rank |
| **SetRank** | Owner Only | UserID, RankID | Sets specific rank |

---

## 🔒 Security Features

### Server-Side Validation

Every command goes through multiple security checks:

1. **Authentication Check**: Verify sender is an admin
2. **Permission Check**: Verify sender has required rank
3. **Hierarchy Check**: Verify sender can affect target
4. **Input Sanitization**: Validate and clean all parameters
5. **Exploit Detection**: Check for suspicious patterns
6. **Rate Limiting**: Prevent command spam

### Anti-Exploit Measures

```lua
✅ Server-side command execution
✅ Client-side input validation
✅ Rate limiting (30 commands/minute)
✅ Parameter sanitization
✅ Rank hierarchy enforcement
✅ Suspicious activity logging
✅ Health/Speed monitoring
```

### Protected Data

- ❌ Admin list never exposed to client
- ❌ Ban list only accessible server-side
- ❌ Command logic hidden from client
- ✅ All remotes validate sender
- ✅ DataStore used for persistence
- ✅ Webhook for external logging

---

## 📊 Logging & Auditing

### What Gets Logged

All admin actions are logged with:
- ✅ Timestamp (date & time)
- ✅ Executor (name, ID, rank)
- ✅ Action performed
- ✅ Target affected
- ✅ Parameters/details
- ✅ Server ID

### Local Logging

- Stored in server memory
- Maximum 500 logs (configurable)
- Searchable in admin UI
- Survives until server shutdown

### Webhook Logging

Logs are sent to Discord with:
- Color-coded embeds
- Detailed information
- Retry logic (3 attempts)
- Severity-based filtering

### Log Viewer Features

- 📋 View recent 50 logs
- 🔍 Search by keyword
- 🗂️ Filter by action/executor
- 📊 View statistics
- 💾 Export as text/JSON

---

## 🎨 Customization

### UI Theme

Edit colors in `AdminSystem_Config.lua`:

```lua
AdminConfig.UITheme = {
    Primary = Color3.fromRGB(30, 30, 35),
    Secondary = Color3.fromRGB(40, 40, 45),
    Accent = Color3.fromRGB(80, 120, 255),
    Success = Color3.fromRGB(50, 200, 100),
    Warning = Color3.fromRGB(255, 180, 50),
    Error = Color3.fromRGB(255, 80, 80),
}
```

### Adding Custom Commands

1. Add command to `AdminSystem_Commands.lua`:

```lua
function Commands.MyCommand(executor, params)
    -- Your command logic here
    
    Logging.LogAction(executor, "MY_COMMAND", params.Target, "Details")
    
    return {Success = true, Message = "Command executed!"}
end
```

2. Add permission requirement to `AdminSystem_Config.lua`:

```lua
AdminConfig.CommandPermissions = {
    -- ... existing commands
    ["MyCommand"] = 2,  -- Moderator+
}
```

3. Add UI button in `AdminSystem_UI.lua` (optional)

### Integrating with Game Systems

#### Weapon System Integration

Edit `Commands.GiveWeapon` in `AdminSystem_Commands.lua`:

```lua
function Commands.GiveWeapon(executor, params)
    local target = AdminCore.FindPlayer(params.Target)
    local weaponName = params.Weapon
    
    -- YOUR WEAPON SYSTEM INTEGRATION
    local WeaponSystem = require(game.ServerStorage.WeaponSystem)
    WeaponSystem.GiveWeapon(target, weaponName)
    
    Logging.LogAction(executor, "GIVE_WEAPON", target.Name, weaponName)
    return {Success = true, Message = "Weapon given"}
end
```

#### Round System Integration

Edit `Commands.ForceRoundEnd`:

```lua
function Commands.ForceRoundEnd(executor, params)
    -- YOUR ROUND SYSTEM INTEGRATION
    local RoundSystem = require(game.ServerStorage.RoundSystem)
    RoundSystem.EndRound(params.Team)
    
    Logging.LogAction(executor, "FORCE_ROUND_END", "Server", params.Team)
    return {Success = true, Message = "Round ended"}
end
```

---

## 🐛 Troubleshooting

### UI Not Showing

**Problem**: Admin UI doesn't appear when pressing Right Shift

**Solutions**:
1. Check Output for errors
2. Verify you're in the AdminList with UserID
3. Ensure AdminSystem_UI is in ReplicatedStorage
4. Check if RemoteFolder exists in ReplicatedStorage
5. Try rejoining the game

### Commands Not Working

**Problem**: Commands fail or don't execute

**Solutions**:
1. Check your rank has permission for the command
2. Verify target player name is correct
3. Check Output for error messages
4. Ensure server-side modules are properly loaded
5. Check rate limiting (wait 1 minute and try again)

### Bans Not Persisting

**Problem**: Banned players can rejoin

**Solutions**:
1. Enable Studio API Access in Game Settings
2. Check DataStore name is correct
3. Verify HTTP requests are enabled
4. Test in actual game (not Studio - DataStores are limited in Studio)
5. Check Output for DataStore errors

### Webhook Not Working

**Problem**: Logs not appearing in Discord

**Solutions**:
1. Verify webhook URL is correct
2. Enable HTTP requests in game settings
3. Check webhook hasn't been deleted
4. Verify Discord server has webhook enabled
5. Check Output for HTTP errors

### Performance Issues

**Problem**: Game lagging with admin system

**Solutions**:
1. Increase rate limit cooldown
2. Reduce MaxLocalLogs in config
3. Disable webhook logging if too frequent
4. Optimize custom command implementations
5. Check for command loops or exploits

---

## 📚 API Reference

### AdminCore Functions

```lua
AdminCore.Initialize(config, permissions, commands, logging)
AdminCore.FindPlayer(identifier)
AdminCore.SanitizeInput(input, maxLength)
AdminCore.SendNotification(player, title, message, type)
AdminCore.BroadcastToAdmins(title, message, type, minRank)
```

### Permissions Functions

```lua
Permissions.CanAffectTarget(executorId, targetId)
Permissions.ValidateCommandExecution(executor, command, target)
Permissions.ValidateReason(reason)
Permissions.ValidateNumber(value, min, max, default)
Permissions.ValidateDuration(durationStr)
```

### Logging Functions

```lua
Logging.LogAction(executor, action, target, details)
Logging.LogSystem(eventType, subject, details)
Logging.GetRecentLogs(count)
Logging.GetFilteredLogs(filters)
Logging.SearchLogs(keyword)
Logging.ExportLogsAsString(count)
Logging.ExportLogsAsJSON(count)
```

### Config Functions

```lua
Config:GetUserRank(userId)
Config:GetRankData(rankId)
Config:IsAdmin(userId)
Config:CanUseCommand(userId, commandName)
Config:GetAdminsWithRank(minRank)
```

---

## 📝 Best Practices

### For Admins

1. **Always provide clear reasons** for moderation actions
2. **Use appropriate ban durations** (don't perma-ban for minor offenses)
3. **Document repeated offenders** in reasons
4. **Communicate with other admins** before major actions
5. **Never abuse powers** (god mode, fly, etc.)
6. **Review logs regularly** for suspicious activity

### For Developers

1. **Keep modules in ServerScriptService** for security
2. **Never expose admin list to client**
3. **Always validate on server-side**
4. **Test commands thoroughly** before production
5. **Regular backup of ban DataStore**
6. **Monitor webhook logs** for abuse patterns
7. **Update security measures** regularly

### For Security

1. **Use strong rank hierarchy**
2. **Enable all security checks**
3. **Regular audit of admin list**
4. **Monitor for exploit attempts**
5. **Keep webhook URL private**
6. **Use rate limiting appropriately**

---

## 🚀 Advanced Usage

### Custom Logging Filters

```lua
local logs = Logging.GetFilteredLogs({
    Executor = "PlayerName",
    Action = "BAN",
    StartTime = os.time() - 3600,  -- Last hour
})
```

### Programmatic Command Execution

```lua
-- From another script (server-side)
local Commands = require(script.Parent.AdminSystem_Commands)
local result = Commands.Kick(adminPlayer, {
    Target = "BadPlayer",
    Reason = "Automated ban for exploiting"
})
```

### Extending the UI

Add custom tabs by modifying `AdminSystem_UI.lua`:

```lua
-- In CreateTabBar function
local tabs = {"Players", "Moderation", "Game Control", "Logs", "MyCustomTab"}

-- Then create content function
function UI.CreateMyCustomTabContent(parent)
    -- Your custom tab content
end
```

---

## 📄 License & Credits

**Developer**: Advanced Admin Panel System  
**Version**: 1.0.0  
**For**: Roblox Shooter Games  
**License**: MIT (Customize as needed)

---

## 🆘 Support

For issues, questions, or contributions:

1. Check the troubleshooting section
2. Review your Output console for errors
3. Verify all setup steps were followed
4. Test in Studio first, then in-game
5. Check Discord webhook is working

---

## 🔄 Update Log

### Version 1.0.0 (Initial Release)
- ✅ Complete admin system
- ✅ Tiered permission system
- ✅ Modern UI with dark theme
- ✅ Comprehensive logging
- ✅ Ban system with DataStore
- ✅ Mobile support
- ✅ Anti-exploit measures
- ✅ Discord webhook integration
- ✅ Full documentation

---

**Made with ❤️ for Roblox Developers**

*Happy moderating! 🛡️*
