# ⚡ Quick Reference Guide

## File Structure at a Glance

```
📁 ServerScriptService/
├── 📄 AdminSystem_Server.lua          (Main server script)
├── 📦 AdminSystem_Config.lua          (Configuration)
├── 📦 AdminSystem_Core.lua            (Core system)
├── 📦 AdminSystem_Permissions.lua     (Security)
├── 📦 AdminSystem_Commands.lua        (Commands)
└── 📦 AdminSystem_Logging.lua         (Logging)

📁 ReplicatedStorage/
└── 📦 AdminSystem_UI.lua              (UI module)

📁 StarterPlayer/StarterPlayerScripts/
└── 📄 AdminSystem_Client.lua          (Client script)
```

---

## Quick Setup (Copy-Paste Ready)

### 1. Add Your Admin

```lua
-- In AdminSystem_Config.lua, line 42
AdminConfig.AdminList = {
    [YOUR_USER_ID] = 4,  -- Replace with your User ID
}
```

### 2. Add Discord Webhook

```lua
-- In AdminSystem_Config.lua, line 82
DiscordWebhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE",
```

### 3. Add Weapons

```lua
-- In AdminSystem_Config.lua, line 113
AvailableWeapons = {
    "YourWeapon1",
    "YourWeapon2",
    "YourWeapon3",
},
```

### 4. Add Maps

```lua
-- In AdminSystem_Config.lua, line 122
AvailableMaps = {
    "YourMap1",
    "YourMap2",
    "YourMap3",
},
```

---

## Command Quick List

### Essential Commands

| Command | Rank | Usage |
|---------|------|-------|
| Kick | Mod+ | Quick removal |
| Ban | Mod+ | Permanent/temporary ban |
| Teleport | Mod+ | Move players |
| SetHealth | Head+ | Adjust health |
| ViewInfo | Staff+ | Player details |

### Rank Requirements

```
Staff (1)      → ViewInfo only
Moderator (2)  → Kick, Ban, Mute, Teleport
Head Admin (3) → All above + Game control
Owner (4)      → Everything + Rank management
```

---

## Common Tasks

### View Player Info
1. Open panel (Right Shift)
2. Go to "Players" tab
3. Find player in list
4. Click "Info" button

### Kick a Player
1. Players tab → Find player
2. Click "Kick" button
3. Enter reason
4. Click "Execute Command"

### Ban a Player
1. Moderation tab → Click "Ban"
2. Enter player name
3. Enter reason
4. Enter duration (30m, 2h, 1d, perm)
5. Execute

### Unban a Player
1. Moderation tab → Click "Unban"
2. Enter User ID (from ban logs)
3. Execute

### View Logs
1. Logs tab
2. Click "Refresh" for latest
3. Scroll through recent actions

---

## Duration Formats

```
30m  = 30 minutes
2h   = 2 hours
1d   = 1 day
perm = Permanent
```

---

## Keybinds

| Key | Action |
|-----|--------|
| Right Shift | Toggle admin panel |
| ESC | Close dialogs |

**Mobile**: Tap 🛡️ button in top-right

---

## Color Codes (For UI Customization)

```lua
Primary:   Color3.fromRGB(30, 30, 35)    -- Dark background
Secondary: Color3.fromRGB(40, 40, 45)    -- Lighter background
Accent:    Color3.fromRGB(80, 120, 255)  -- Blue
Success:   Color3.fromRGB(50, 200, 100)  -- Green
Warning:   Color3.fromRGB(255, 180, 50)  -- Orange
Error:     Color3.fromRGB(255, 80, 80)   -- Red
```

---

## Permission Levels

```lua
0 = Not admin
1 = Staff      (View only)
2 = Moderator  (Basic moderation)
3 = Head Admin (Game control)
4 = Owner      (Everything)
```

---

## Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| UI won't open | Check AdminList for your User ID |
| Commands fail | Verify rank is high enough |
| No webhook | Enable HTTP in Game Settings |
| Bans don't save | Enable Studio API Access |

---

## Integration Templates

### Weapon System

```lua
-- In AdminSystem_Commands.lua, GiveWeapon function
local YourWeaponModule = require(game.ServerStorage.Weapons)
YourWeaponModule.GiveWeapon(target, weaponName)
```

### Round System

```lua
-- In AdminSystem_Commands.lua, ForceRoundEnd function
local YourRoundModule = require(game.ServerStorage.RoundManager)
YourRoundModule.EndRound(winningTeam)
```

---

## Important Locations in Code

### Add New Command
- **File**: AdminSystem_Commands.lua
- **Line**: ~500 (after existing commands)
- **Also update**: AdminSystem_Config.lua permissions

### Change Permissions
- **File**: AdminSystem_Config.lua
- **Line**: 59 (CommandPermissions table)

### Modify UI Theme
- **File**: AdminSystem_Config.lua
- **Line**: 93 (UITheme table)

### Add Admin
- **File**: AdminSystem_Config.lua
- **Line**: 42 (AdminList table)

---

## Testing Checklist

```
□ UI opens with Right Shift
□ Can view player list
□ Can execute ViewInfo command
□ Kick command works
□ Ban saves to DataStore
□ Webhook sends to Discord
□ Logs appear in Logs tab
□ Mobile button appears on mobile
□ Rate limiting triggers after spam
□ Can't affect higher rank admins
```

---

## Support URLs

- **Find User ID**: roblox.com/users/USERNAME/profile
- **Discord Webhooks**: discord.com/developers/docs/resources/webhook
- **Roblox DataStores**: create.roblox.com/docs/cloud-services/data-stores

---

## Console Messages

### Success Messages
```
✅ "Advanced Admin Panel - Ready!"
✅ "Admin detected: [Name] (Rank: [Rank])"
✅ "Admin UI initialized successfully!"
```

### Error Messages
```
❌ "Failed to initialize Admin Panel!"
❌ "Admin system not found in ReplicatedStorage!"
❌ "Player is not an admin. UI will not load."
```

---

## API Quick Reference

### Config Functions
```lua
Config:GetUserRank(userId)
Config:IsAdmin(userId)
Config:CanUseCommand(userId, commandName)
```

### Core Functions
```lua
AdminCore.FindPlayer(identifier)
AdminCore.SendNotification(player, title, msg, type)
AdminCore.BroadcastToAdmins(title, msg, type, minRank)
```

### Logging Functions
```lua
Logging.LogAction(executor, action, target, details)
Logging.LogSystem(eventType, subject, details)
Logging.GetRecentLogs(count)
```

---

## Common Patterns

### Execute Custom Command
```lua
function Commands.MyCommand(executor, params)
    -- Your logic here
    Logging.LogAction(executor, "MY_COMMAND", params.Target, "Details")
    return {Success = true, Message = "Done!"}
end
```

### Send Notification to Admin
```lua
AdminCore.SendNotification(player, "Title", "Message", "Success")
-- Types: Success, Warning, Error, Info
```

### Log Custom Event
```lua
Logging.LogSystem("CUSTOM_EVENT", "Subject", "Details")
```

---

## Security Reminder

```
✅ DO: Keep modules in ServerScriptService
✅ DO: Validate all inputs server-side
✅ DO: Use rank hierarchy
✅ DO: Log all actions

❌ DON'T: Put admin logic in ReplicatedStorage
❌ DON'T: Trust client input
❌ DON'T: Share webhook URL
❌ DON'T: Disable security features
```

---

## Version Info

```
Version: 1.0.0
Created: 2025-10-18
Platform: Roblox
Language: Lua
```

---

**Need more detail? See [README.md](README.md) for full documentation.**

**Ready to admin! 🛡️**
