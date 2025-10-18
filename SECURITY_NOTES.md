# 🔒 Security & Best Practices

## Critical Security Measures

### ⚠️ NEVER DO THIS

1. **❌ NEVER place admin modules in ReplicatedStorage**
   - Admin logic should NEVER be accessible to clients
   - Only place AdminSystem_UI in ReplicatedStorage
   - All other modules belong in ServerScriptService or ServerStorage

2. **❌ NEVER trust client input without validation**
   - Always validate on server-side
   - Never assume client data is safe
   - Use the built-in sanitization functions

3. **❌ NEVER expose your webhook URL**
   - Keep it in a private module
   - Don't share it in public code
   - Regenerate if compromised

4. **❌ NEVER make yourself owner in production**
   - Test in Studio first
   - Use proper rank assignments
   - Don't hardcode your User ID in multiple places

5. **❌ NEVER bypass rank hierarchy**
   - Always check permissions
   - Enforce rank-based access
   - Log failed permission attempts

---

## ✅ Security Best Practices

### Server-Side Validation

Every command goes through these checks:

```lua
1. Is sender actually an admin?
2. Does sender have permission for this command?
3. Can sender affect the target? (rank hierarchy)
4. Are parameters valid and sanitized?
5. Is this a potential exploit attempt?
6. Has rate limit been exceeded?
```

### Input Sanitization

All user inputs are sanitized:

```lua
✅ String length limits
✅ Character whitelist
✅ Number range validation
✅ Duration format validation
✅ Player name verification
```

### Rate Limiting

Protection against spam:

```lua
✅ 30 commands per minute per admin
✅ Automatic cooldown
✅ Warning notification
✅ Logged for review
```

### Anti-Exploit Monitoring

Built-in exploit detection:

```lua
✅ Health/MaxHealth monitoring
✅ WalkSpeed monitoring
✅ Suspicious parameter detection
✅ Command pattern analysis
✅ Nested table protection
```

---

## 🛡️ Rank Hierarchy Enforcement

### How It Works

```
Owner (4)
  ↓ Can affect everyone below
Head Admin (3)
  ↓ Can affect Moderators and below
Moderator (2)
  ↓ Can affect Staff and regular players
Staff (1)
  ↓ Can only view info
```

### Rules

1. **Cannot affect equal or higher ranks**
   - Moderators can't kick other Moderators
   - Head Admins can't ban other Head Admins
   - Only Owners can affect Owners

2. **Cannot modify your own rank**
   - Prevents self-promotion
   - Requires another admin

3. **Rank-specific commands**
   - Some commands locked to higher ranks
   - Configurable in Config module

---

## 🔐 Data Protection

### What's Secured

| Data Type | Location | Access |
|-----------|----------|--------|
| Admin List | ServerScriptService | Server Only |
| Ban Data | DataStore | Server Only |
| Rank Data | DataStore | Server Only |
| Command Logic | ServerScriptService | Server Only |
| Logs | Server Memory + Webhook | Server Only |

### What's NOT Secured

| Data Type | Location | Reason |
|-----------|----------|--------|
| UI Code | ReplicatedStorage | Client needs to display UI |
| Theme Config | Replicated | Client needs for UI styling |

**Note**: Even though UI is client-side, all actions are validated server-side.

---

## 🚨 Exploit Prevention

### Common Attack Vectors

#### 1. Remote Spam Attack
**Attack**: Spamming RemoteEvents to lag server  
**Defense**: Rate limiting + automatic blocking

#### 2. Parameter Injection
**Attack**: Sending malicious parameters  
**Defense**: Input sanitization + type checking

#### 3. Privilege Escalation
**Attack**: Trying to execute commands without permission  
**Defense**: Server-side rank verification

#### 4. DataStore Manipulation
**Attack**: Trying to modify ban data  
**Defense**: Server-side only access

#### 5. UI Manipulation
**Attack**: Modifying client UI to bypass checks  
**Defense**: All actions validated server-side regardless of UI

---

## 📊 Logging for Security

### What Gets Logged

✅ **All admin actions** - Who did what to whom  
✅ **Failed permission checks** - Who tried to do what  
✅ **Exploit attempts** - Suspicious patterns detected  
✅ **Admin joins/leaves** - Admin activity tracking  
✅ **System events** - Initialization, errors, etc.

### Why This Matters

- **Accountability**: Admins can be held responsible
- **Audit Trail**: Can review past actions
- **Exploit Detection**: Identify attack patterns
- **Training**: Learn from mistakes

---

## 🔍 Regular Security Audits

### Monthly Checklist

- [ ] Review admin list for inactive admins
- [ ] Check logs for suspicious patterns
- [ ] Verify webhook is still working
- [ ] Test ban system is functional
- [ ] Review and update permissions if needed
- [ ] Check for any security vulnerabilities
- [ ] Update admin ranks as needed

### Red Flags to Watch For

🚩 Admin using commands excessively  
🚩 Multiple failed permission attempts  
🚩 Unusual command patterns  
🚩 Commands executed at odd times  
🚩 Targeting specific players repeatedly  

---

## 💡 Security Tips for Admins

### DO:
✅ Use strong, clear reasons for all actions  
✅ Discuss major decisions with other admins  
✅ Report suspicious activity immediately  
✅ Keep webhook URL private  
✅ Review logs regularly  
✅ Follow rank hierarchy strictly  

### DON'T:
❌ Share your admin account  
❌ Use admin powers for personal gain  
❌ Abuse commands (god mode, fly, etc.)  
❌ Target players without reason  
❌ Ignore security warnings  
❌ Bypass permission checks  

---

## 🔒 Secure Configuration Example

```lua
-- Good: Proper security settings
AdminConfig.Security = {
    MaxReasonLength = 200,
    CommandRateLimit = 30,
    EnforceRankHierarchy = true,
    LogFailedAttempts = true,
}

-- Bad: Disabled security
AdminConfig.Security = {
    MaxReasonLength = 99999,
    CommandRateLimit = 999,
    EnforceRankHierarchy = false,  -- NEVER DO THIS
    LogFailedAttempts = false,     -- NEVER DO THIS
}
```

---

## 🚀 Advanced Security Measures

### Custom Security Hooks

Add custom security checks in `AdminSystem_Permissions.lua`:

```lua
function Permissions.CustomSecurityCheck(executor, command, target)
    -- Example: Prevent banning players with high playtime
    if command == "Ban" and target then
        local playtime = GetPlayerPlaytime(target)
        if playtime > 1000 then  -- 1000 hours
            return false, "Cannot ban veteran players"
        end
    end
    
    return true
end
```

### IP-Based Rate Limiting (Advanced)

```lua
-- Track by IP instead of just User ID
-- Prevents multi-account spam
-- Requires custom implementation
```

### Two-Factor Authentication (Advanced)

```lua
-- Require PIN code for sensitive commands
-- Like Shutdown, Unban, SetRank
-- Requires custom implementation
```

---

## 📝 Incident Response

If you detect unauthorized admin access:

1. **Immediately remove them from AdminList**
2. **Change webhook URL if compromised**
3. **Review all their actions in logs**
4. **Reverse any malicious actions**
5. **Document the incident**
6. **Update security measures**

---

## 🛠️ Security Testing

Before going live, test these scenarios:

### Exploit Tests
- [ ] Try to execute commands as non-admin
- [ ] Try to spam commands (should rate limit)
- [ ] Try to affect higher-rank admins
- [ ] Try to modify parameters in client
- [ ] Try to call RemoteEvents directly

### Permission Tests
- [ ] Verify each rank can only use allowed commands
- [ ] Verify rank hierarchy is enforced
- [ ] Verify self-targeting is prevented
- [ ] Verify Owner-only commands are locked

### Data Tests
- [ ] Verify bans persist after server restart
- [ ] Verify DataStore errors are handled
- [ ] Verify logs are saved correctly
- [ ] Verify webhook sends successfully

---

## 📞 Reporting Security Issues

If you find a security vulnerability:

1. **Do not exploit it**
2. **Document the issue clearly**
3. **Report to game owner immediately**
4. **Provide steps to reproduce**
5. **Suggest a fix if possible**

---

**Security is everyone's responsibility! 🛡️**

Stay vigilant, stay secure.
