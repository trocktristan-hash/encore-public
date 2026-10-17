--[[
	Encore loader  (public)

	This file is safe to be public. It contains NO hub code - just a key check.
	It asks the backend for the real script; the backend only hands it over when
	the key is valid. An invalid/expired key gets a short "go get a key" message.

	Users run:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/encore/main/loader.lua"))()

	Advanced users can skip the popup by setting the key first:
		getgenv().EncoreKey = "XXXX-XXXX"
		loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/encore/main/loader.lua"))()
]]

----------------------------------------------------------------------------- CONFIG (fill these in)
local BACKEND = "https://encore-keys.affxter.workers.dev"  -- your deployed Worker URL, no trailing slash
local KEY_LINK = "https://your-key-link.example"                  -- where users get a key (Linkvertise, Pastebin, a Discord channel, ...)
local BRAND   = "Encore"
-------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local genv = (getgenv and getgenv()) or _G

-- data folder (match the hub's: "Encore", or an existing "PianoHub")
local function hasFolder(p)
	local ok, r = pcall(function() return isfolder and isfolder(p) end)
	return ok and r == true
end
local ROOT = (hasFolder("PianoHub") and not hasFolder("Encore")) and "PianoHub" or "Encore"
pcall(function() if makefolder and not hasFolder(ROOT) then makefolder(ROOT) end end)
local KEY_FILE = ROOT .. "/key.txt"

local function isfn(f) return type(f) == "function" end
local function readKeyFile()
	if isfn(readfile) and isfn(isfile) then
		local ok, exists = pcall(isfile, KEY_FILE)
		if ok and exists then
			local ok2, data = pcall(readfile, KEY_FILE)
			if ok2 and type(data) == "string" then return (data:gsub("%s+$", "")) end
		end
	end
	return nil
end
local function saveKeyFile(k)
	if isfn(writefile) then pcall(writefile, KEY_FILE, k) end
end

-- best-effort hardware id (used by premium keys; harmless if unavailable)
local function hwid()
	local candidates = { gethwid, get_hwid, (syn and syn.gethwid) }
	for _, fn in ipairs(candidates) do
		if isfn(fn) then
			local ok, id = pcall(fn)
			if ok and type(id) == "string" and #id > 0 then return id end
		end
	end
	local ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
	if ok and type(id) == "string" then return id end
	return "unknown"
end

-- http GET that works across executors (same strategy the hub uses)
local function httpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url, true) end)
	if ok and type(res) == "string" and #res > 0 then return res end
	local req = (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or http_request or request
	if req then
		local ok2, r = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(r) == "table" and r.Body then return r.Body, r.StatusCode end
	end
	return nil
end

local function notify(title, text, dur)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 6 })
	end)
	print(("[%s] %s - %s"):format(BRAND, title, text))
end

-- ask the backend for the script. Returns (body, status). Body is Lua to run (hub, or an error popup).
local function fetchScript(key)
	local url = ("%s/script?key=%s&hwid=%s&v=2"):format(
		BACKEND,
		HttpService:UrlEncode(key or ""),
		HttpService:UrlEncode(hwid())
	)
	return httpGet(url)
end

----------------------------------------------------------------------------- minimal key prompt GUI
-- shown only when no key is provided via getgenv().EncoreKey or the saved file
local function promptForKey(onSubmit)
	local ok = pcall(function()
		local CoreGui = game:GetService("CoreGui")
		local LP = Players.LocalPlayer
		local parent = (gethui and gethui()) or CoreGui
		if CoreGui:FindFirstChild("EncoreKeyPrompt") then CoreGui.EncoreKeyPrompt:Destroy() end

		local gui = Instance.new("ScreenGui")
		gui.Name = "EncoreKeyPrompt"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = parent

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(340, 190); frame.Position = UDim2.new(0.5, -170, 0.5, -95)
		frame.BackgroundColor3 = Color3.fromRGB(24, 24, 32); frame.BorderSizePixel = 0; frame.Parent = gui
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

		local function label(txt, y, size, color)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 20, 0, y); l.Size = UDim2.new(1, -40, 0, size + 6)
			l.Font = Enum.Font.GothamBold; l.TextSize = size; l.TextXAlignment = Enum.TextXAlignment.Left
			l.TextColor3 = color or Color3.fromRGB(240, 240, 245); l.Text = txt; l.Parent = frame
			return l
		end
		label(BRAND .. "  -  enter your key", 16, 18)
		label("This week's key. Keep it for the week.", 42, 12, Color3.fromRGB(150, 150, 165)).Font = Enum.Font.Gotham

		local box = Instance.new("TextBox")
		box.Position = UDim2.new(0, 20, 0, 74); box.Size = UDim2.new(1, -40, 0, 38)
		box.BackgroundColor3 = Color3.fromRGB(16, 16, 22); box.BorderSizePixel = 0
		box.Font = Enum.Font.Code; box.TextSize = 15; box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.PlaceholderText = "paste key here"; box.Text = ""; box.ClearTextOnFocus = false; box.Parent = frame
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

		local function button(txt, x, w, color, cb)
			local b = Instance.new("TextButton")
			b.Position = UDim2.new(0, x, 0, 126); b.Size = UDim2.new(0, w, 0, 40)
			b.BackgroundColor3 = color; b.BorderSizePixel = 0; b.AutoButtonColor = true
			b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.Text = txt; b.Parent = frame
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			b.MouseButton1Click:Connect(cb)
			return b
		end

		button("Get a key", 20, 150, Color3.fromRGB(60, 60, 78), function()
			if isfn(setclipboard) then pcall(setclipboard, KEY_LINK) end
			notify("Key link copied", "Paste it in your browser: " .. KEY_LINK, 10)
		end)
		button("Use key", 180, 140, Color3.fromRGB(124, 92, 255), function()
			local k = (box.Text or ""):gsub("%s+", "")
			if k == "" then notify("No key", "Paste your key first.", 4); return end
			gui:Destroy()
			onSubmit(k)
		end)
		box.FocusLost:Connect(function(enter)
			if enter then
				local k = (box.Text or ""):gsub("%s+", "")
				if k ~= "" then gui:Destroy(); onSubmit(k) end
			end
		end)
	end)
	if not ok then
		notify("Key needed", "Set getgenv().EncoreKey = \"...\" then run again. Get a key: " .. KEY_LINK, 12)
	end
end

----------------------------------------------------------------------------- run
local function tryKey(key, fromPrompt)
	if not key or key == "" then return end
	notify(BRAND, "Checking key...", 3)
	local body, status = fetchScript(key)
	if not body then
		notify("Connection failed", "Could not reach the key server. Try again.", 6)
		return
	end
	-- 200 from the backend always returns runnable Lua: either the hub, or a short popup telling the
	-- user the key is invalid/expired. We save the key only when the backend confirms it (HTTP 200).
	if status == nil or status == 200 then
		if fromPrompt then saveKeyFile(key) end
		local fn, err = loadstring(body)
		if fn then
			local ok, runErr = pcall(fn)
			if not ok then notify("Load error", tostring(runErr):sub(1, 120), 8) end
		else
			notify("Load error", tostring(err):sub(1, 120), 8)
		end
	elseif status == 403 or status == 401 then
		if isfn(delfile) then pcall(delfile, KEY_FILE) end  -- drop a stale saved key
		notify("Key rejected", "That key is invalid or expired. Grab this week's key.", 8)
		promptForKey(function(k) tryKey(k, true) end)
	else
		notify("Server error", "Key server returned " .. tostring(status) .. ". Try later.", 6)
	end
end

local savedOrGiven = (type(genv.EncoreKey) == "string" and genv.EncoreKey) or readKeyFile()
if savedOrGiven and savedOrGiven ~= "" then
	tryKey(savedOrGiven, false)
else
	promptForKey(function(k) tryKey(k, true) end)
end
