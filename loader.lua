--[[
	Encore loader  (public)

	Safe to be public - contains NO hub code, just a key check.

	How a user gets in:
	  * Click "Get a key"  -> a LootLabs link is copied to the clipboard.
	    Open it in a browser, finish it, come back - Encore loads itself (the key
	    is bound to this device). Keys last a while, then you grab a new one.
	  * Already have a key (e.g. a premium key)? Paste it in the box and hit Use key.
	  * Power users:  getgenv().EncoreKey = "ENC-...."  before running this.

	Run:
	  loadstring(game:HttpGet("https://raw.githubusercontent.com/trocktristan-hash/encore-public/main/loader.lua"))()
]]

----------------------------------------------------------------------------- CONFIG
local BACKEND = "https://encore-keys.affxter.workers.dev"  -- your Worker URL, no trailing slash
local BRAND   = "Encore"
-------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local genv = (getgenv and getgenv()) or _G

local function isfn(f) return type(f) == "function" end
local function hasFolder(p)
	local ok, r = pcall(function() return isfolder and isfolder(p) end)
	return ok and r == true
end
local ROOT = (hasFolder("PianoHub") and not hasFolder("Encore")) and "PianoHub" or "Encore"
pcall(function() if makefolder and not hasFolder(ROOT) then makefolder(ROOT) end end)
local KEY_FILE = ROOT .. "/key.txt"

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
local function saveKeyFile(k) if isfn(writefile) then pcall(writefile, KEY_FILE, k) end end
local function clearKeyFile() if isfn(delfile) then pcall(delfile, KEY_FILE) end end

local function hwid()
	for _, fn in ipairs({ gethwid, get_hwid, (syn and syn.gethwid) }) do
		if isfn(fn) then local ok, id = pcall(fn); if ok and type(id) == "string" and #id > 0 then return id end end
	end
	local ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
	return (ok and type(id) == "string") and id or "unknown"
end

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
local function decode(s) local ok, v = pcall(function() return HttpService:JSONDecode(s) end); return ok and v or nil end
local function esc(s) return HttpService:UrlEncode(s or "") end

local function notify(title, text, dur)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 6 }) end)
	print(("[%s] %s - %s"):format(BRAND, title, text))
end

-- fetch + run the hub for a key. returns true on success.
local function runWithKey(key)
	local body, status = httpGet(("%s/script?key=%s&hwid=%s&v=2"):format(BACKEND, esc(key), esc(hwid())))
	if not body then notify("Connection failed", "Couldn't reach the key server.", 6); return false end
	if status == 403 or status == 401 then return false, "rejected" end
	local fn, err = loadstring(body)
	if not fn then notify("Load error", tostring(err):sub(1, 120), 8); return false end
	local ok, runErr = pcall(fn)
	if not ok then notify("Load error", tostring(runErr):sub(1, 120), 8); return false end
	return true
end

----------------------------------------------------------------------------- GUI
local function buildGui()
	local CoreGui = game:GetService("CoreGui")
	local parent = (gethui and gethui()) or CoreGui
	if parent:FindFirstChild("EncoreKeyPrompt") then parent.EncoreKeyPrompt:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "EncoreKeyPrompt"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(360, 250); frame.Position = UDim2.new(0.5, -180, 0.5, -125)
	frame.BackgroundColor3 = Color3.fromRGB(23, 23, 31); frame.BorderSizePixel = 0; frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

	local function label(txt, y, size, color, font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 22, 0, y); l.Size = UDim2.new(1, -44, 0, size + 8)
		l.Font = font or Enum.Font.GothamBold; l.TextSize = size; l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top; l.TextWrapped = true
		l.TextColor3 = color or Color3.fromRGB(240, 240, 245); l.Text = txt; l.Parent = frame
		return l
	end
	label(BRAND, 18, 20)
	label("Play anything. Play together.", 44, 12, Color3.fromRGB(150, 150, 165), Enum.Font.Gotham)

	local status = label("Get a key to start, or paste one below.", 74, 13, Color3.fromRGB(180, 180, 195), Enum.Font.Gotham)
	status.Size = UDim2.new(1, -44, 0, 40)

	local function button(txt, y, color, cb)
		local b = Instance.new("TextButton")
		b.Position = UDim2.new(0, 22, 0, y); b.Size = UDim2.new(1, -44, 0, 38)
		b.BackgroundColor3 = color; b.BorderSizePixel = 0; b.AutoButtonColor = true
		b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = txt; b.Parent = frame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
		b.MouseButton1Click:Connect(cb); return b
	end

	local box = Instance.new("TextBox")
	box.Position = UDim2.new(0, 22, 0, 165); box.Size = UDim2.new(1, -120, 0, 38)
	box.BackgroundColor3 = Color3.fromRGB(15, 15, 21); box.BorderSizePixel = 0
	box.Font = Enum.Font.Code; box.TextSize = 14; box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderText = "paste a key"; box.Text = ""; box.ClearTextOnFocus = false; box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

	local function setStatus(t) status.Text = t end
	return gui, frame, setStatus, button, box
end

----------------------------------------------------------------------------- flows
local started = false
local function startPanel()
	if started then return end
	started = true
	local gui, frame, setStatus, button, box = buildGui()
	local polling = false

	local function finishWith(key, save)
		setStatus("Key accepted - loading Encore...")
		local ok, why = runWithKey(key)
		if ok then if save then saveKeyFile(key) end; gui:Destroy()
		else
			if why == "rejected" then setStatus("That key is invalid or expired. Get a new one.") ; clearKeyFile()
			else setStatus("Couldn't load. Try again.") end
		end
	end

	-- Get a key (ad flow)
	button("Get a key", 112, Color3.fromRGB(124, 92, 255), function()
		if polling then return end
		setStatus("Starting...")
		local body = httpGet(BACKEND .. "/start?hwid=" .. esc(hwid()))
		local data = body and decode(body)
		if not data or not data.url then setStatus("Couldn't start. Try again in a moment."); return end
		if isfn(setclipboard) then pcall(setclipboard, data.url) end
		setStatus("Link copied! Open it in your browser,\nfinish it, then wait here. (your key binds to this PC)")
		polling = true
		task.spawn(function()
			for _ = 1, 100 do -- ~5 min
				task.wait(3)
				local cb = httpGet(BACKEND .. "/claim?nonce=" .. esc(data.nonce))
				local cd = cb and decode(cb)
				if cd and cd.status == "ready" and cd.key then
					polling = false; finishWith(cd.key, true); return
				elseif cd and cd.status == "expired" then
					polling = false; setStatus("Session expired. Press Get a key again."); return
				end
			end
			polling = false; setStatus("Timed out. Press Get a key to retry.")
		end)
	end)

	-- Use key (manual / premium)
	local use = Instance.new("TextButton")
	use.Position = UDim2.new(1, -92, 0, 165); use.Size = UDim2.new(0, 70, 0, 38)
	use.BackgroundColor3 = Color3.fromRGB(60, 60, 78); use.BorderSizePixel = 0; use.AutoButtonColor = true
	use.Font = Enum.Font.GothamBold; use.TextSize = 13; use.TextColor3 = Color3.fromRGB(255, 255, 255)
	use.Text = "Use key"; use.Parent = frame
	Instance.new("UICorner", use).CornerRadius = UDim.new(0, 9)
	local function submitBox()
		local k = (box.Text or ""):gsub("%s+", "")
		if k == "" then setStatus("Paste a key first."); return end
		finishWith(k, true)
	end
	use.MouseButton1Click:Connect(submitBox)
	box.FocusLost:Connect(function(enter) if enter then submitBox() end end)
end

----------------------------------------------------------------------------- run
local saved = (type(genv.EncoreKey) == "string" and genv.EncoreKey) or readKeyFile()
if saved and saved ~= "" then
	local ok = runWithKey(saved)
	if not ok then clearKeyFile(); startPanel() end
else
	startPanel()
end
