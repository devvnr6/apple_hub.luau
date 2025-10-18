--[[
	AdminSystem_UI Module (Client-Side)
	Modern dark-themed admin panel interface
	
	Features:
	- Tabbed navigation
	- Player search and filtering
	- Command forms with validation
	- Log viewer
	- Toast notifications
	- Responsive design
]]

local UI = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remote references
local RemoteFolder = ReplicatedStorage:WaitForChild("AdminSystem")
local AdminActionEvent = RemoteFolder:WaitForChild("AdminAction")
local AdminDataFunction = RemoteFolder:WaitForChild("AdminData")
local NotificationEvent = RemoteFolder:WaitForChild("Notification")

-- UI State
local MainFrame
local IsVisible = false
local CurrentTab = "Players"
local SelectedPlayer = nil
local Theme
local UserRank
local UserRankData

--================================================================================
-- INITIALIZATION
--================================================================================

function UI.Initialize()
	-- Get user rank from server
	local rankInfo = AdminDataFunction:InvokeServer("GetRank")
	if not rankInfo then
		warn("[AdminUI] Failed to get rank information")
		return false
	end
	
	UserRank = rankInfo.RankId
	UserRankData = rankInfo.RankData
	
	-- Get config from server
	local config = AdminDataFunction:InvokeServer("GetConfig")
	if config then
		Theme = config.Theme
	else
		-- Fallback theme
		Theme = {
			Primary = Color3.fromRGB(30, 30, 35),
			Secondary = Color3.fromRGB(40, 40, 45),
			Accent = Color3.fromRGB(80, 120, 255),
			Success = Color3.fromRGB(50, 200, 100),
			Warning = Color3.fromRGB(255, 180, 50),
			Error = Color3.fromRGB(255, 80, 80),
			TextPrimary = Color3.fromRGB(255, 255, 255),
			TextSecondary = Color3.fromRGB(180, 180, 180),
			Border = Color3.fromRGB(60, 60, 65),
		}
	end
	
	-- Create UI
	UI.CreateMainUI()
	
	-- Set up keybind (Right Shift to toggle)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			UI.TogglePanel()
		end
	end)
	
	-- Set up notification listener
	NotificationEvent.OnClientEvent:Connect(UI.ShowNotification)
	
	print("[AdminUI] Initialized successfully")
	return true
end

--================================================================================
-- MAIN UI CREATION
--================================================================================

function UI.CreateMainUI()
	-- Create ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdminPanel"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui
	
	-- Main container
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainContainer"
	MainFrame.Size = UDim2.new(0, 900, 0, 600)
	MainFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
	MainFrame.BackgroundColor3 = Theme.Primary
	MainFrame.BorderSizePixel = 0
	MainFrame.Visible = false
	MainFrame.Parent = ScreenGui
	
	-- Add rounded corners
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = MainFrame
	
	-- Add border
	local Border = Instance.new("UIStroke")
	Border.Color = Theme.Border
	Border.Thickness = 2
	Border.Parent = MainFrame
	
	-- Header
	UI.CreateHeader(MainFrame)
	
	-- Tab bar
	UI.CreateTabBar(MainFrame)
	
	-- Content area
	UI.CreateContentArea(MainFrame)
	
	-- Make draggable
	UI.MakeDraggable(MainFrame)
end

--================================================================================
-- HEADER
--================================================================================

function UI.CreateHeader(parent)
	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 50)
	Header.BackgroundColor3 = Theme.Secondary
	Header.BorderSizePixel = 0
	Header.Parent = parent
	
	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 10)
	HeaderCorner.Parent = Header
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(0, 300, 1, 0)
	Title.Position = UDim2.new(0, 15, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "🛡️ Advanced Admin Panel"
	Title.TextColor3 = Theme.TextPrimary
	Title.TextSize = 20
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header
	
	-- Rank badge
	local RankBadge = Instance.new("TextLabel")
	RankBadge.Name = "RankBadge"
	RankBadge.Size = UDim2.new(0, 120, 0, 30)
	RankBadge.Position = UDim2.new(1, -135, 0.5, -15)
	RankBadge.BackgroundColor3 = UserRankData.Color
	RankBadge.Text = UserRankData.RankName
	RankBadge.TextColor3 = Theme.TextPrimary
	RankBadge.TextSize = 14
	RankBadge.Font = Enum.Font.GothamBold
	RankBadge.Parent = Header
	
	local BadgeCorner = Instance.new("UICorner")
	BadgeCorner.CornerRadius = UDim.new(0, 6)
	BadgeCorner.Parent = RankBadge
	
	-- Close button
	local CloseButton = UI.CreateButton({
		Name = "CloseButton",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0.5, -15),
		Text = "✕",
		TextSize = 20,
		BackgroundColor = Theme.Error,
		Parent = Header,
		Callback = function()
			UI.TogglePanel()
		end
	})
end

--================================================================================
-- TAB BAR
--================================================================================

function UI.CreateTabBar(parent)
	local TabBar = Instance.new("Frame")
	TabBar.Name = "TabBar"
	TabBar.Size = UDim2.new(1, 0, 0, 45)
	TabBar.Position = UDim2.new(0, 0, 0, 50)
	TabBar.BackgroundColor3 = Theme.Secondary
	TabBar.BorderSizePixel = 0
	TabBar.Parent = parent
	
	local TabList = Instance.new("UIListLayout")
	TabList.FillDirection = Enum.FillDirection.Horizontal
	TabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	TabList.Padding = UDim.new(0, 5)
	TabList.Parent = TabBar
	
	local TabPadding = Instance.new("UIPadding")
	TabPadding.PaddingLeft = UDim.new(0, 10)
	TabPadding.PaddingTop = UDim.new(0, 5)
	TabPadding.Parent = TabBar
	
	-- Create tabs
	local tabs = {"Players", "Moderation", "Game Control", "Logs"}
	
	for _, tabName in ipairs(tabs) do
		UI.CreateTab(TabBar, tabName)
	end
end

function UI.CreateTab(parent, tabName)
	local Tab = Instance.new("TextButton")
	Tab.Name = tabName .. "Tab"
	Tab.Size = UDim2.new(0, 150, 0, 35)
	Tab.BackgroundColor3 = CurrentTab == tabName and Theme.Accent or Theme.Primary
	Tab.Text = tabName
	Tab.TextColor3 = Theme.TextPrimary
	Tab.TextSize = 14
	Tab.Font = Enum.Font.GothamBold
	Tab.AutoButtonColor = false
	Tab.Parent = parent
	
	local TabCorner = Instance.new("UICorner")
	TabCorner.CornerRadius = UDim.new(0, 6)
	TabCorner.Parent = Tab
	
	Tab.MouseButton1Click:Connect(function()
		UI.SwitchTab(tabName)
	end)
	
	-- Hover effect
	Tab.MouseEnter:Connect(function()
		if CurrentTab ~= tabName then
			TweenService:Create(Tab, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Secondary}):Play()
		end
	end)
	
	Tab.MouseLeave:Connect(function()
		if CurrentTab ~= tabName then
			TweenService:Create(Tab, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Primary}):Play()
		end
	end)
end

--================================================================================
-- CONTENT AREA
--================================================================================

function UI.CreateContentArea(parent)
	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, -20, 1, -115)
	ContentArea.Position = UDim2.new(0, 10, 0, 105)
	ContentArea.BackgroundTransparency = 1
	ContentArea.Parent = parent
	
	-- Create content for each tab
	UI.CreatePlayersContent(ContentArea)
	UI.CreateModerationContent(ContentArea)
	UI.CreateGameControlContent(ContentArea)
	UI.CreateLogsContent(ContentArea)
end

--================================================================================
-- PLAYERS TAB
--================================================================================

function UI.CreatePlayersContent(parent)
	local PlayersContent = Instance.new("Frame")
	PlayersContent.Name = "PlayersContent"
	PlayersContent.Size = UDim2.new(1, 0, 1, 0)
	PlayersContent.BackgroundTransparency = 1
	PlayersContent.Visible = true
	PlayersContent.Parent = parent
	
	-- Search bar
	local SearchBar = UI.CreateTextBox({
		Name = "SearchBar",
		Size = UDim2.new(1, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, 0),
		PlaceholderText = "Search players...",
		Parent = PlayersContent
	})
	
	-- Player list container
	local PlayerListContainer = Instance.new("ScrollingFrame")
	PlayerListContainer.Name = "PlayerList"
	PlayerListContainer.Size = UDim2.new(1, 0, 1, -45)
	PlayerListContainer.Position = UDim2.new(0, 0, 0, 45)
	PlayerListContainer.BackgroundColor3 = Theme.Secondary
	PlayerListContainer.BorderSizePixel = 0
	PlayerListContainer.ScrollBarThickness = 8
	PlayerListContainer.ScrollBarImageColor3 = Theme.Accent
	PlayerListContainer.Parent = PlayersContent
	
	local ListCorner = Instance.new("UICorner")
	ListCorner.CornerRadius = UDim.new(0, 8)
	ListCorner.Parent = PlayerListContainer
	
	local PlayerListLayout = Instance.new("UIListLayout")
	PlayerListLayout.Padding = UDim.new(0, 5)
	PlayerListLayout.Parent = PlayerListContainer
	
	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingAll = UDim.new(0, 10)
	ListPadding.Parent = PlayerListContainer
	
	-- Populate player list
	UI.UpdatePlayerList(PlayerListContainer)
	
	-- Auto-refresh every 5 seconds
	task.spawn(function()
		while true do
			task.wait(5)
			if CurrentTab == "Players" and IsVisible then
				UI.UpdatePlayerList(PlayerListContainer)
			end
		end
	end)
end

function UI.UpdatePlayerList(container)
	-- Clear existing
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Get player list from server
	local playerList = AdminDataFunction:InvokeServer("GetPlayers")
	if not playerList then return end
	
	-- Create player entries
	for _, playerData in ipairs(playerList) do
		UI.CreatePlayerEntry(container, playerData)
	end
	
	-- Update canvas size
	container.CanvasSize = UDim2.new(0, 0, 0, container.UIListLayout.AbsoluteContentSize.Y + 20)
end

function UI.CreatePlayerEntry(parent, playerData)
	local Entry = Instance.new("Frame")
	Entry.Name = playerData.Name
	Entry.Size = UDim2.new(1, -10, 0, 60)
	Entry.BackgroundColor3 = Theme.Primary
	Entry.BorderSizePixel = 0
	Entry.Parent = parent
	
	local EntryCorner = Instance.new("UICorner")
	EntryCorner.CornerRadius = UDim.new(0, 6)
	EntryCorner.Parent = Entry
	
	-- Player name
	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(0, 200, 0, 25)
	NameLabel.Position = UDim2.new(0, 10, 0, 5)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = playerData.DisplayName
	NameLabel.TextColor3 = Theme.TextPrimary
	NameLabel.TextSize = 16
	NameLabel.Font = Enum.Font.GothamBold
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.Parent = Entry
	
	-- Username (if different)
	if playerData.Name ~= playerData.DisplayName then
		local UsernameLabel = Instance.new("TextLabel")
		UsernameLabel.Size = UDim2.new(0, 200, 0, 20)
		UsernameLabel.Position = UDim2.new(0, 10, 0, 30)
		UsernameLabel.BackgroundTransparency = 1
		UsernameLabel.Text = "@" .. playerData.Name
		UsernameLabel.TextColor3 = Theme.TextSecondary
		UsernameLabel.TextSize = 12
		UsernameLabel.Font = Enum.Font.Gotham
		UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
		UsernameLabel.Parent = Entry
	end
	
	-- Team badge
	if playerData.Team ~= "None" then
		local TeamBadge = Instance.new("TextLabel")
		TeamBadge.Size = UDim2.new(0, 80, 0, 20)
		TeamBadge.Position = UDim2.new(0, 220, 0, 10)
		TeamBadge.BackgroundColor3 = Theme.Accent
		TeamBadge.Text = playerData.Team
		TeamBadge.TextColor3 = Theme.TextPrimary
		TeamBadge.TextSize = 11
		TeamBadge.Font = Enum.Font.Gotham
		TeamBadge.Parent = Entry
		
		local BadgeCorner = Instance.new("UICorner")
		BadgeCorner.CornerRadius = UDim.new(0, 4)
		BadgeCorner.Parent = TeamBadge
	end
	
	-- Admin badge
	if playerData.IsAdmin then
		local AdminBadge = Instance.new("TextLabel")
		AdminBadge.Size = UDim2.new(0, 60, 0, 20)
		AdminBadge.Position = UDim2.new(0, 310, 0, 10)
		AdminBadge.BackgroundColor3 = Theme.Warning
		AdminBadge.Text = "ADMIN"
		AdminBadge.TextColor3 = Theme.TextPrimary
		AdminBadge.TextSize = 11
		AdminBadge.Font = Enum.Font.GothamBold
		AdminBadge.Parent = Entry
		
		local BadgeCorner = Instance.new("UICorner")
		BadgeCorner.CornerRadius = UDim.new(0, 4)
		BadgeCorner.Parent = AdminBadge
	end
	
	-- Action buttons
	local buttonX = 1
	local buttonOffset = -10
	
	-- View Info button
	UI.CreateButton({
		Name = "InfoBtn",
		Size = UDim2.new(0, 70, 0, 25),
		Position = UDim2.new(buttonX, buttonOffset, 0.5, -12.5),
		Text = "Info",
		TextSize = 12,
		BackgroundColor = Theme.Accent,
		Parent = Entry,
		Callback = function()
			UI.SendCommand("ViewInfo", {Target = playerData.Name})
		end
	})
	buttonOffset = buttonOffset - 80
	
	-- Quick actions
	if UserRank >= 2 then
		-- Teleport button
		UI.CreateButton({
			Name = "TeleportBtn",
			Size = UDim2.new(0, 70, 0, 25),
			Position = UDim2.new(buttonX, buttonOffset, 0.5, -12.5),
			Text = "TP",
			TextSize = 12,
			BackgroundColor = Theme.Success,
			Parent = Entry,
			Callback = function()
				UI.SendCommand("TeleportToMe", {Target = playerData.Name})
			end
		})
		buttonOffset = buttonOffset - 80
		
		-- Kick button
		UI.CreateButton({
			Name = "KickBtn",
			Size = UDim2.new(0, 70, 0, 25),
			Position = UDim2.new(buttonX, buttonOffset, 0.5, -12.5),
			Text = "Kick",
			TextSize = 12,
			BackgroundColor = Theme.Error,
			Parent = Entry,
			Callback = function()
				UI.ShowCommandDialog("Kick", playerData.Name)
			end
		})
	end
end

--================================================================================
-- MODERATION TAB
--================================================================================

function UI.CreateModerationContent(parent)
	local ModContent = Instance.new("Frame")
	ModContent.Name = "ModerationContent"
	ModContent.Size = UDim2.new(1, 0, 1, 0)
	ModContent.BackgroundTransparency = 1
	ModContent.Visible = false
	ModContent.Parent = parent
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 30)
	Title.BackgroundTransparency = 1
	Title.Text = "Moderation Commands"
	Title.TextColor3 = Theme.TextPrimary
	Title.TextSize = 18
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = ModContent
	
	-- Command grid
	local CommandGrid = Instance.new("ScrollingFrame")
	CommandGrid.Size = UDim2.new(1, 0, 1, -40)
	CommandGrid.Position = UDim2.new(0, 0, 0, 40)
	CommandGrid.BackgroundColor3 = Theme.Secondary
	CommandGrid.BorderSizePixel = 0
	CommandGrid.ScrollBarThickness = 8
	CommandGrid.Parent = ModContent
	
	local GridCorner = Instance.new("UICorner")
	GridCorner.CornerRadius = UDim.new(0, 8)
	GridCorner.Parent = CommandGrid
	
	local GridLayout = Instance.new("UIGridLayout")
	GridLayout.CellSize = UDim2.new(0, 200, 0, 80)
	GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	GridLayout.Parent = CommandGrid
	
	local GridPadding = Instance.new("UIPadding")
	GridPadding.PaddingAll = UDim.new(0, 10)
	GridPadding.Parent = CommandGrid
	
	-- Moderation commands
	local commands = {
		{Name = "Kick", MinRank = 2, Color = Theme.Warning},
		{Name = "Ban", MinRank = 2, Color = Theme.Error},
		{Name = "Unban", MinRank = 3, Color = Theme.Success},
		{Name = "Mute", MinRank = 2, Color = Theme.Warning},
		{Name = "Unmute", MinRank = 2, Color = Theme.Success},
		{Name = "SetHealth", MinRank = 3, Color = Theme.Accent},
		{Name = "SetSpeed", MinRank = 3, Color = Theme.Accent},
		{Name = "ToggleGod", MinRank = 3, Color = Theme.Warning},
		{Name = "ToggleFly", MinRank = 3, Color = Theme.Accent},
		{Name = "GiveWeapon", MinRank = 2, Color = Theme.Success},
	}
	
	for _, cmd in ipairs(commands) do
		if UserRank >= cmd.MinRank then
			UI.CreateCommandButton(CommandGrid, cmd)
		end
	end
end

function UI.CreateCommandButton(parent, commandData)
	local Button = Instance.new("TextButton")
	Button.Name = commandData.Name
	Button.BackgroundColor3 = commandData.Color
	Button.Text = commandData.Name
	Button.TextColor3 = Theme.TextPrimary
	Button.TextSize = 16
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = parent
	
	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 8)
	ButtonCorner.Parent = Button
	
	Button.MouseButton1Click:Connect(function()
		UI.ShowCommandDialog(commandData.Name, nil)
	end)
	
	-- Hover effect
	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.new(
				commandData.Color.R * 1.2,
				commandData.Color.G * 1.2,
				commandData.Color.B * 1.2
			)
		}):Play()
	end)
	
	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = commandData.Color}):Play()
	end)
end

--================================================================================
-- GAME CONTROL TAB
--================================================================================

function UI.CreateGameControlContent(parent)
	local GameContent = Instance.new("Frame")
	GameContent.Name = "GameControlContent"
	GameContent.Size = UDim2.new(1, 0, 1, 0)
	GameContent.BackgroundTransparency = 1
	GameContent.Visible = false
	GameContent.Parent = parent
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 30)
	Title.BackgroundTransparency = 1
	Title.Text = "Game Control"
	Title.TextColor3 = Theme.TextPrimary
	Title.TextSize = 18
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = GameContent
	
	-- Control panel
	local ControlPanel = Instance.new("Frame")
	ControlPanel.Size = UDim2.new(1, 0, 1, -40)
	ControlPanel.Position = UDim2.new(0, 0, 0, 40)
	ControlPanel.BackgroundColor3 = Theme.Secondary
	ControlPanel.BorderSizePixel = 0
	ControlPanel.Parent = GameContent
	
	local PanelCorner = Instance.new("UICorner")
	PanelCorner.CornerRadius = UDim.new(0, 8)
	PanelCorner.Parent = ControlPanel
	
	-- Game control commands (for Head Admin+)
	if UserRank >= 3 then
		local yPos = 20
		
		-- Time control
		UI.CreateControlSection(ControlPanel, "Time of Day", yPos, function(container)
			local timeSlider = UI.CreateSlider(container, 0, 24, 12)
			UI.CreateButton({
				Name = "SetTimeBtn",
				Size = UDim2.new(0, 100, 0, 30),
				Position = UDim2.new(1, -110, 1, -40),
				Text = "Set Time",
				BackgroundColor = Theme.Accent,
				Parent = container,
				Callback = function()
					UI.SendCommand("ChangeTime", {Time = timeSlider.Value})
				end
			})
		end)
		yPos = yPos + 120
		
		-- Round control
		UI.CreateButton({
			Name = "EndRoundBtn",
			Size = UDim2.new(0.45, 0, 0, 50),
			Position = UDim2.new(0.025, 0, 0, yPos),
			Text = "Force Round End",
			TextSize = 16,
			BackgroundColor = Theme.Error,
			Parent = ControlPanel,
			Callback = function()
				UI.SendCommand("ForceRoundEnd", {})
			end
		})
		
		-- Map selection
		UI.CreateButton({
			Name = "SetMapBtn",
			Size = UDim2.new(0.45, 0, 0, 50),
			Position = UDim2.new(0.525, 0, 0, yPos),
			Text = "Set Map",
			TextSize = 16,
			BackgroundColor = Theme.Accent,
			Parent = ControlPanel,
			Callback = function()
				UI.ShowCommandDialog("SetMap", nil)
			end
		})
	else
		local NoAccessLabel = Instance.new("TextLabel")
		NoAccessLabel.Size = UDim2.new(1, 0, 1, 0)
		NoAccessLabel.BackgroundTransparency = 1
		NoAccessLabel.Text = "Access Denied\n\nHead Admin+ required"
		NoAccessLabel.TextColor3 = Theme.TextSecondary
		NoAccessLabel.TextSize = 20
		NoAccessLabel.Font = Enum.Font.Gotham
		NoAccessLabel.Parent = ControlPanel
	end
end

function UI.CreateControlSection(parent, title, yPos, buildFunc)
	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, -40, 0, 100)
	Section.Position = UDim2.new(0, 20, 0, yPos)
	Section.BackgroundColor3 = Theme.Primary
	Section.BorderSizePixel = 0
	Section.Parent = parent
	
	local SectionCorner = Instance.new("UICorner")
	SectionCorner.CornerRadius = UDim.new(0, 6)
	SectionCorner.Parent = Section
	
	local SectionTitle = Instance.new("TextLabel")
	SectionTitle.Size = UDim2.new(1, -20, 0, 30)
	SectionTitle.Position = UDim2.new(0, 10, 0, 5)
	SectionTitle.BackgroundTransparency = 1
	SectionTitle.Text = title
	SectionTitle.TextColor3 = Theme.TextPrimary
	SectionTitle.TextSize = 14
	SectionTitle.Font = Enum.Font.GothamBold
	SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	SectionTitle.Parent = Section
	
	if buildFunc then
		buildFunc(Section)
	end
	
	return Section
end

--================================================================================
-- LOGS TAB
--================================================================================

function UI.CreateLogsContent(parent)
	local LogsContent = Instance.new("Frame")
	LogsContent.Name = "LogsContent"
	LogsContent.Size = UDim2.new(1, 0, 1, 0)
	LogsContent.BackgroundTransparency = 1
	LogsContent.Visible = false
	LogsContent.Parent = parent
	
	-- Title and refresh button
	local Header = Instance.new("Frame")
	Header.Size = UDim2.new(1, 0, 0, 35)
	Header.BackgroundTransparency = 1
	Header.Parent = LogsContent
	
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(0, 200, 1, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "Admin Action Logs"
	Title.TextColor3 = Theme.TextPrimary
	Title.TextSize = 18
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Header
	
	local RefreshBtn = UI.CreateButton({
		Name = "RefreshBtn",
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(1, -105, 0, 2.5),
		Text = "🔄 Refresh",
		TextSize = 12,
		BackgroundColor = Theme.Accent,
		Parent = Header,
		Callback = function()
			UI.UpdateLogs(LogsContent:FindFirstChild("LogList"))
		end
	})
	
	-- Log list
	local LogList = Instance.new("ScrollingFrame")
	LogList.Name = "LogList"
	LogList.Size = UDim2.new(1, 0, 1, -45)
	LogList.Position = UDim2.new(0, 0, 0, 45)
	LogList.BackgroundColor3 = Theme.Secondary
	LogList.BorderSizePixel = 0
	LogList.ScrollBarThickness = 8
	LogList.Parent = LogsContent
	
	local LogCorner = Instance.new("UICorner")
	LogCorner.CornerRadius = UDim.new(0, 8)
	LogCorner.Parent = LogList
	
	local LogLayout = Instance.new("UIListLayout")
	LogLayout.Padding = UDim.new(0, 5)
	LogLayout.Parent = LogList
	
	local LogPadding = Instance.new("UIPadding")
	LogPadding.PaddingAll = UDim.new(0, 10)
	LogPadding.Parent = LogList
	
	-- Load logs
	UI.UpdateLogs(LogList)
end

function UI.UpdateLogs(container)
	-- Clear existing
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Get logs from server
	local logs = AdminDataFunction:InvokeServer("GetLogs")
	if not logs then return end
	
	-- Create log entries
	for _, log in ipairs(logs) do
		UI.CreateLogEntry(container, log)
	end
	
	-- Update canvas size
	container.CanvasSize = UDim2.new(0, 0, 0, container.UIListLayout.AbsoluteContentSize.Y + 20)
end

function UI.CreateLogEntry(parent, logData)
	local Entry = Instance.new("Frame")
	Entry.Size = UDim2.new(1, -10, 0, 70)
	Entry.BackgroundColor3 = Theme.Primary
	Entry.BorderSizePixel = 0
	Entry.Parent = parent
	
	local EntryCorner = Instance.new("UICorner")
	EntryCorner.CornerRadius = UDim.new(0, 6)
	EntryCorner.Parent = Entry
	
	-- Time
	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Size = UDim2.new(0, 150, 0, 20)
	TimeLabel.Position = UDim2.new(0, 10, 0, 5)
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.Text = logData.DateTime or "N/A"
	TimeLabel.TextColor3 = Theme.TextSecondary
	TimeLabel.TextSize = 11
	TimeLabel.Font = Enum.Font.Code
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TimeLabel.Parent = Entry
	
	-- Action type
	local ActionLabel = Instance.new("TextLabel")
	ActionLabel.Size = UDim2.new(0, 200, 0, 25)
	ActionLabel.Position = UDim2.new(0, 10, 0, 25)
	ActionLabel.BackgroundTransparency = 1
	ActionLabel.Text = logData.Action or logData.EventType or "UNKNOWN"
	ActionLabel.TextColor3 = Theme.Accent
	ActionLabel.TextSize = 14
	ActionLabel.Font = Enum.Font.GothamBold
	ActionLabel.TextXAlignment = Enum.TextXAlignment.Left
	ActionLabel.Parent = Entry
	
	-- Executor/Subject
	local ExecutorText = logData.Executor and logData.Executor.Name or logData.Subject or "System"
	local ExecutorLabel = Instance.new("TextLabel")
	ExecutorLabel.Size = UDim2.new(0, 150, 0, 20)
	ExecutorLabel.Position = UDim2.new(0, 220, 0, 27)
	ExecutorLabel.BackgroundTransparency = 1
	ExecutorLabel.Text = "By: " .. ExecutorText
	ExecutorLabel.TextColor3 = Theme.TextSecondary
	ExecutorLabel.TextSize = 12
	ExecutorLabel.Font = Enum.Font.Gotham
	ExecutorLabel.TextXAlignment = Enum.TextXAlignment.Left
	ExecutorLabel.Parent = Entry
	
	-- Details
	local DetailsLabel = Instance.new("TextLabel")
	DetailsLabel.Size = UDim2.new(1, -20, 0, 20)
	DetailsLabel.Position = UDim2.new(0, 10, 1, -25)
	DetailsLabel.BackgroundTransparency = 1
	DetailsLabel.Text = logData.Details or ""
	DetailsLabel.TextColor3 = Theme.TextPrimary
	DetailsLabel.TextSize = 11
	DetailsLabel.Font = Enum.Font.Gotham
	DetailsLabel.TextXAlignment = Enum.TextXAlignment.Left
	DetailsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	DetailsLabel.Parent = Entry
end

--================================================================================
-- HELPER UI COMPONENTS
--================================================================================

function UI.CreateButton(config)
	local Button = Instance.new("TextButton")
	Button.Name = config.Name or "Button"
	Button.Size = config.Size
	Button.Position = config.Position or UDim2.new(0, 0, 0, 0)
	Button.BackgroundColor3 = config.BackgroundColor or Theme.Accent
	Button.Text = config.Text or "Button"
	Button.TextColor3 = config.TextColor or Theme.TextPrimary
	Button.TextSize = config.TextSize or 14
	Button.Font = config.Font or Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = config.Parent
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Button
	
	if config.Callback then
		Button.MouseButton1Click:Connect(config.Callback)
	end
	
	-- Hover effect
	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.new(
				math.min(Button.BackgroundColor3.R * 1.2, 1),
				math.min(Button.BackgroundColor3.G * 1.2, 1),
				math.min(Button.BackgroundColor3.B * 1.2, 1)
			)
		}):Play()
	end)
	
	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.15), {
			BackgroundColor3 = config.BackgroundColor or Theme.Accent
		}):Play()
	end)
	
	return Button
end

function UI.CreateTextBox(config)
	local TextBox = Instance.new("TextBox")
	TextBox.Name = config.Name or "TextBox"
	TextBox.Size = config.Size
	TextBox.Position = config.Position or UDim2.new(0, 0, 0, 0)
	TextBox.BackgroundColor3 = Theme.Secondary
	TextBox.Text = config.Text or ""
	TextBox.PlaceholderText = config.PlaceholderText or ""
	TextBox.TextColor3 = Theme.TextPrimary
	TextBox.PlaceholderColor3 = Theme.TextSecondary
	TextBox.TextSize = config.TextSize or 14
	TextBox.Font = Enum.Font.Gotham
	TextBox.ClearTextOnFocus = false
	TextBox.Parent = config.Parent
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = TextBox
	
	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.Parent = TextBox
	
	return TextBox
end

function UI.CreateSlider(parent, min, max, default)
	-- Implementation for slider control
	-- Returns a table with .Value property
	return {Value = default}
end

--================================================================================
-- COMMAND DIALOG
--================================================================================

function UI.ShowCommandDialog(commandName, targetName)
	-- Create dialog overlay
	local Overlay = Instance.new("Frame")
	Overlay.Name = "DialogOverlay"
	Overlay.Size = UDim2.new(1, 0, 1, 0)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BorderSizePixel = 0
	Overlay.ZIndex = 10
	Overlay.Parent = MainFrame
	
	-- Dialog box
	local Dialog = Instance.new("Frame")
	Dialog.Size = UDim2.new(0, 400, 0, 300)
	Dialog.Position = UDim2.new(0.5, -200, 0.5, -150)
	Dialog.BackgroundColor3 = Theme.Secondary
	Dialog.BorderSizePixel = 0
	Dialog.ZIndex = 11
	Dialog.Parent = Overlay
	
	local DialogCorner = Instance.new("UICorner")
	DialogCorner.CornerRadius = UDim.new(0, 10)
	DialogCorner.Parent = Dialog
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -40, 0, 40)
	Title.Position = UDim2.new(0, 20, 0, 10)
	Title.BackgroundTransparency = 1
	Title.Text = commandName
	Title.TextColor3 = Theme.TextPrimary
	Title.TextSize = 20
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.ZIndex = 12
	Title.Parent = Dialog
	
	-- Close button
	local CloseBtn = UI.CreateButton({
		Name = "CloseDialog",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -35, 0, 10),
		Text = "✕",
		TextSize = 18,
		BackgroundColor = Theme.Error,
		Parent = Dialog,
		Callback = function()
			Overlay:Destroy()
		end
	})
	CloseBtn.ZIndex = 12
	
	-- Build form based on command
	local formData = {}
	local yPos = 60
	
	-- Target field (if not provided)
	if not targetName then
		local TargetLabel = Instance.new("TextLabel")
		TargetLabel.Size = UDim2.new(1, -40, 0, 20)
		TargetLabel.Position = UDim2.new(0, 20, 0, yPos)
		TargetLabel.BackgroundTransparency = 1
		TargetLabel.Text = "Target Player:"
		TargetLabel.TextColor3 = Theme.TextSecondary
		TargetLabel.TextSize = 12
		TargetLabel.Font = Enum.Font.Gotham
		TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
		TargetLabel.ZIndex = 12
		TargetLabel.Parent = Dialog
		
		formData.TargetBox = UI.CreateTextBox({
			Name = "TargetInput",
			Size = UDim2.new(1, -40, 0, 35),
			Position = UDim2.new(0, 20, 0, yPos + 25),
			PlaceholderText = "Player name or ID",
			Parent = Dialog
		})
		formData.TargetBox.ZIndex = 12
		yPos = yPos + 70
	else
		formData.Target = targetName
	end
	
	-- Command-specific fields
	if commandName == "Kick" or commandName == "Ban" or commandName == "Mute" then
		local ReasonLabel = Instance.new("TextLabel")
		ReasonLabel.Size = UDim2.new(1, -40, 0, 20)
		ReasonLabel.Position = UDim2.new(0, 20, 0, yPos)
		ReasonLabel.BackgroundTransparency = 1
		ReasonLabel.Text = "Reason:"
		ReasonLabel.TextColor3 = Theme.TextSecondary
		ReasonLabel.TextSize = 12
		ReasonLabel.Font = Enum.Font.Gotham
		ReasonLabel.TextXAlignment = Enum.TextXAlignment.Left
		ReasonLabel.ZIndex = 12
		ReasonLabel.Parent = Dialog
		
		formData.ReasonBox = UI.CreateTextBox({
			Name = "ReasonInput",
			Size = UDim2.new(1, -40, 0, 35),
			Position = UDim2.new(0, 20, 0, yPos + 25),
			PlaceholderText = "Enter reason...",
			Parent = Dialog
		})
		formData.ReasonBox.ZIndex = 12
		yPos = yPos + 70
	end
	
	if commandName == "Ban" or commandName == "Mute" then
		local DurationLabel = Instance.new("TextLabel")
		DurationLabel.Size = UDim2.new(1, -40, 0, 20)
		DurationLabel.Position = UDim2.new(0, 20, 0, yPos)
		DurationLabel.BackgroundTransparency = 1
		DurationLabel.Text = "Duration (e.g., 30m, 2h, 1d, perm):"
		DurationLabel.TextColor3 = Theme.TextSecondary
		DurationLabel.TextSize = 12
		DurationLabel.Font = Enum.Font.Gotham
		DurationLabel.TextXAlignment = Enum.TextXAlignment.Left
		DurationLabel.ZIndex = 12
		DurationLabel.Parent = Dialog
		
		formData.DurationBox = UI.CreateTextBox({
			Name = "DurationInput",
			Size = UDim2.new(1, -40, 0, 35),
			Position = UDim2.new(0, 20, 0, yPos + 25),
			Text = commandName == "Mute" and "30m" or "perm",
			Parent = Dialog
		})
		formData.DurationBox.ZIndex = 12
		yPos = yPos + 70
	end
	
	-- Submit button
	local SubmitBtn = UI.CreateButton({
		Name = "SubmitCommand",
		Size = UDim2.new(1, -40, 0, 40),
		Position = UDim2.new(0, 20, 1, -50),
		Text = "Execute Command",
		TextSize = 14,
		BackgroundColor = Theme.Success,
		Parent = Dialog,
		Callback = function()
			local params = {}
			
			if formData.TargetBox then
				params.Target = formData.TargetBox.Text
			elseif formData.Target then
				params.Target = formData.Target
			end
			
			if formData.ReasonBox then
				params.Reason = formData.ReasonBox.Text
			end
			
			if formData.DurationBox then
				params.Duration = formData.DurationBox.Text
			end
			
			UI.SendCommand(commandName, params)
			Overlay:Destroy()
		end
	})
	SubmitBtn.ZIndex = 12
	
	-- Click overlay to close
	Overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mouse = UserInputService:GetMouseLocation()
			local dialogPos = Dialog.AbsolutePosition
			local dialogSize = Dialog.AbsoluteSize
			
			if mouse.X < dialogPos.X or mouse.X > dialogPos.X + dialogSize.X or
			   mouse.Y < dialogPos.Y or mouse.Y > dialogPos.Y + dialogSize.Y then
				Overlay:Destroy()
			end
		end
	end)
end

--================================================================================
-- NOTIFICATIONS
--================================================================================

function UI.ShowNotification(notificationData)
	local NotifContainer = PlayerGui:FindFirstChild("AdminPanel"):FindFirstChild("NotificationContainer")
	
	if not NotifContainer then
		NotifContainer = Instance.new("Frame")
		NotifContainer.Name = "NotificationContainer"
		NotifContainer.Size = UDim2.new(0, 300, 1, 0)
		NotifContainer.Position = UDim2.new(1, -310, 0, 10)
		NotifContainer.BackgroundTransparency = 1
		NotifContainer.Parent = PlayerGui:FindFirstChild("AdminPanel")
		
		local NotifLayout = Instance.new("UIListLayout")
		NotifLayout.Padding = UDim.new(0, 10)
		NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		NotifLayout.Parent = NotifContainer
	end
	
	local notifColor = Theme.Accent
	if notificationData.Type == "Success" then
		notifColor = Theme.Success
	elseif notificationData.Type == "Warning" then
		notifColor = Theme.Warning
	elseif notificationData.Type == "Error" then
		notifColor = Theme.Error
	end
	
	local Notif = Instance.new("Frame")
	Notif.Size = UDim2.new(1, 0, 0, 70)
	Notif.BackgroundColor3 = Theme.Secondary
	Notif.BorderSizePixel = 0
	Notif.Parent = NotifContainer
	
	local NotifCorner = Instance.new("UICorner")
	NotifCorner.CornerRadius = UDim.new(0, 8)
	NotifCorner.Parent = Notif
	
	local NotifBorder = Instance.new("UIStroke")
	NotifBorder.Color = notifColor
	NotifBorder.Thickness = 2
	NotifBorder.Parent = Notif
	
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 0, 25)
	TitleLabel.Position = UDim2.new(0, 10, 0, 5)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = notificationData.Title or "Notification"
	TitleLabel.TextColor3 = notifColor
	TitleLabel.TextSize = 14
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = Notif
	
	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Size = UDim2.new(1, -20, 0, 35)
	MessageLabel.Position = UDim2.new(0, 10, 0, 30)
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Text = notificationData.Message or ""
	MessageLabel.TextColor3 = Theme.TextPrimary
	MessageLabel.TextSize = 12
	MessageLabel.Font = Enum.Font.Gotham
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
	MessageLabel.TextWrapped = true
	MessageLabel.Parent = Notif
	
	-- Fade in
	Notif.BackgroundTransparency = 1
	TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	
	-- Auto-dismiss after 5 seconds
	task.delay(5, function()
		TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		task.wait(0.3)
		Notif:Destroy()
	end)
end

--================================================================================
-- UTILITY FUNCTIONS
--================================================================================

function UI.TogglePanel()
	IsVisible = not IsVisible
	MainFrame.Visible = IsVisible
	
	if IsVisible then
		-- Fade in
		MainFrame.BackgroundTransparency = 1
		TweenService:Create(MainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.05}):Play()
	end
end

function UI.SwitchTab(tabName)
	CurrentTab = tabName
	
	-- Update tab buttons
	local TabBar = MainFrame:FindFirstChild("TabBar")
	for _, tab in ipairs(TabBar:GetChildren()) do
		if tab:IsA("TextButton") then
			local isActive = string.find(tab.Name, tabName)
			tab.BackgroundColor3 = isActive and Theme.Accent or Theme.Primary
		end
	end
	
	-- Update content visibility
	local ContentArea = MainFrame:FindFirstChild("ContentArea")
	for _, content in ipairs(ContentArea:GetChildren()) do
		if content:IsA("Frame") then
			content.Visible = string.find(content.Name, tabName)
		end
	end
end

function UI.SendCommand(commandName, parameters)
	AdminActionEvent:FireServer({
		Command = commandName,
		Parameters = parameters
	})
end

function UI.MakeDraggable(frame)
	local dragging = false
	local dragInput, mousePos, framePos
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end)
end

return UI
