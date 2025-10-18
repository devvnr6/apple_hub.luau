# 🚀 Quick Installation Guide

## Step-by-Step Setup (5 Minutes)

### 1️⃣ Download & Place Files

**ServerScriptService** (Place these as Scripts/ModuleScripts):
```
📁 ServerScriptService
  📄 AdminSystem_Server (Script)
  📦 AdminSystem_Config (ModuleScript)
  📦 AdminSystem_Core (ModuleScript)
  📦 AdminSystem_Permissions (ModuleScript)
  📦 AdminSystem_Commands (ModuleScript)
  📦 AdminSystem_Logging (ModuleScript)
```

**ReplicatedStorage**:
```
📁 ReplicatedStorage
  📦 AdminSystem_UI (ModuleScript)
```

**StarterPlayer > StarterPlayerScripts**:
```
📁 StarterPlayer
  📁 StarterPlayerScripts
    📄 AdminSystem_Client (LocalScript)
```

---

### 2️⃣ Configure Your Admins

Open `AdminSystem_Config` and add your User ID:

```lua
-- Line 42: AdminConfig.AdminList
AdminConfig.AdminList = {
    [YOUR_USER_ID_HERE] = 4,  -- Replace with your actual User ID
}
```

**How to find your User ID:**
1. Go to: https://www.roblox.com/users/YOUR_USERNAME/profile
2. Look at the URL - the number after `/users/` is your User ID
3. Example: `https://www.roblox.com/users/123456789/profile` → User ID is `123456789`

---

### 3️⃣ Set Up Discord Webhook (Optional)

1. Go to your Discord server
2. Create a text channel for logs (e.g., `#admin-logs`)
3. Click ⚙️ Edit Channel → Integrations → Webhooks → New Webhook
4. Copy the Webhook URL
5. In `AdminSystem_Config`, paste your webhook URL:

```lua
-- Line 82: AdminConfig.Logging
DiscordWebhookURL = "YOUR_WEBHOOK_URL_HERE",
```

---

### 4️⃣ Enable Required Services

In Roblox Studio:

1. **Home** → **Game Settings** → **Security**
   - ✅ Enable "Allow HTTP Requests"

2. **Home** → **Game Settings** → **Options**
   - ✅ Enable "Enable Studio Access to API Services"

---

### 5️⃣ Test in Studio

1. Press **F5** to start a test server
2. Wait for console message: `Advanced Admin Panel - Ready!`
3. Press **Right Shift** to open the admin panel
4. Test a command (e.g., ViewInfo on yourself)

---

## ✅ Verification Checklist

Before publishing, verify:

- [ ] All files are in correct locations
- [ ] Your User ID is in AdminList
- [ ] Console shows "Admin Panel - Ready!"
- [ ] UI opens with Right Shift
- [ ] Commands execute successfully
- [ ] Webhook sends to Discord (if configured)
- [ ] No errors in Output console

---

## 🎮 Basic Usage

### Opening the Panel
- **PC**: Press `Right Shift`
- **Mobile**: Tap the 🛡️ button in top-right

### Using Commands

1. **Quick Actions** (from Players tab):
   - Click on a player in the list
   - Use quick action buttons (Info, TP, Kick)

2. **Full Commands** (from Moderation tab):
   - Click command button
   - Fill in the dialog form
   - Click "Execute Command"

3. **View Logs** (from Logs tab):
   - See all recent admin actions
   - Use Refresh button to update

---

## 🔧 Common First-Time Issues

### Issue: UI doesn't appear
**Fix**: Make sure your User ID is in the AdminList in Config

### Issue: "Admin system not found"
**Fix**: Ensure AdminSystem_UI is in ReplicatedStorage

### Issue: Commands don't work
**Fix**: Check that modules are in ServerScriptService, not ReplicatedStorage

### Issue: Webhook not working
**Fix**: 
1. Enable HTTP Requests in Game Settings
2. Verify webhook URL is correct
3. Test webhook manually in Discord

---

## 🎯 Next Steps

After basic setup:

1. **Add More Admins**: Edit AdminList in Config
2. **Customize Commands**: Adjust permissions in Config
3. **Integrate with Your Game**: 
   - Add your weapon names to AvailableWeapons
   - Add your map names to AvailableMaps
   - Integrate weapon/round systems (see README)
4. **Test Ban System**: Test in published game (DataStores don't work fully in Studio)

---

## 📞 Need Help?

1. Check the main **README.md** for detailed documentation
2. Review the **Troubleshooting** section
3. Check Output console for specific error messages
4. Verify all steps were followed correctly

---

**Ready to moderate! 🛡️**

Return to [README.md](README.md) for full documentation.
