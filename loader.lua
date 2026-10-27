--[[
	Encore loader  (public)   -   safe to be public, contains NO hub code.

	Getting in (works on PC AND mobile):
	  1. Run this script - the Encore panel opens.
	  2. Tap "Get a key" - a link is copied to your clipboard.
	  3. Open it in your browser and finish it.
	  4. Come back to Roblox. On PC it loads on its own; on mobile just run the
	     script again - Encore remembers and loads your key automatically.
	  Your key lasts 24h and is bound to your device. No key to copy by hand.

	Premium/staff key? Paste it in the box and hit "Use key".
	Power users:  getgenv().EncoreKey = "ENC-...."  before running.

	loadstring(game:HttpGet("https://raw.githubusercontent.com/trocktristan-hash/encore-public/main/loader.lua"))()
]]

----------------------------------------------------------------------------- CONFIG
local BACKEND = "https://encore-keys.affxter.workers.dev"  -- your Worker URL, no trailing slash
local BRAND   = "Encore"
local DISCORD = "https://discord.gg/fSgSAd4URv"
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
local PEND_FILE = ROOT .. "/pending.txt"

local function readFile(p)
	if isfn(readfile) and isfn(isfile) then
		local ok, ex = pcall(isfile, p)
		if ok and ex then local ok2, d = pcall(readfile, p); if ok2 and type(d) == "string" then return (d:gsub("%s+$", "")) end end
	end
	return nil
end
local function writeF(p, v) if isfn(writefile) then pcall(writefile, p, v) end end
local function delF(p) if isfn(delfile) then pcall(delfile, p) end end

local function hwid()
	for _, fn in ipairs({ gethwid, get_hwid, (syn and syn.gethwid) }) do
		if isfn(fn) then local ok, id = pcall(fn); if ok and type(id) == "string" and #id > 0 then return id end end
	end
	local ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
	return (ok and type(id) == "string") and id or "unknown"
end

-- copy text with whichever clipboard function this executor has. returns true when it worked
local function copyText(s)
	local fns = {}
	if isfn(setclipboard) then fns[#fns + 1] = setclipboard end
	if isfn(toclipboard) then fns[#fns + 1] = toclipboard end
	if isfn(set_clipboard) then fns[#fns + 1] = set_clipboard end
	if syn and isfn(syn.write_clipboard) then fns[#fns + 1] = syn.write_clipboard end
	for _, fn in ipairs(fns) do
		if pcall(fn, s) then return true end
	end
	return false
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

-- fetch + run the hub for a key. returns true on success, or false,"rejected"
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

-- one /claim poll: returns "ready",key | "waiting" | "expired"
local function claimOnce(nonce)
	local body = httpGet(BACKEND .. "/claim?nonce=" .. esc(nonce))
	local d = body and decode(body)
	if not d then return "waiting" end
	if d.status == "ready" and d.key then return "ready", d.key end
	if d.status == "expired" then return "expired" end
	return "waiting"
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
	frame.Size = UDim2.fromOffset(360, 282); frame.Position = UDim2.new(0.5, -180, 0.5, -141)
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
	local status = label("Tap Get a key to start, or paste one below.", 72, 13, Color3.fromRGB(180, 180, 195), Enum.Font.Gotham)
	status.Size = UDim2.new(1, -44, 0, 44)
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
	return gui, frame, function(t) status.Text = t end, button, box
end

----------------------------------------------------------------------------- panel
local function startPanel(resumeNonce)
	local gui, frame, setStatus, button, box = buildGui()
	local busy = false

	local function finishWith(key, save)
		setStatus("Key accepted - loading Encore...")
		local ok, why = runWithKey(key)
		if ok then
			if save then writeF(KEY_FILE, key) end
			delF(PEND_FILE); gui:Destroy()
		elseif why == "rejected" then
			delF(KEY_FILE); setStatus("That key is invalid or expired. Get a new one.")
		else
			setStatus("Couldn't load. Try again.")
		end
	end

	-- poll /claim for a nonce until the key is minted
	local function poll(nonce)
		if busy then return end
		busy = true
		task.spawn(function()
			for _ = 1, 100 do -- ~5 min
				local st, key = claimOnce(nonce)
				if st == "ready" then busy = false; finishWith(key, true); return end
				if st == "expired" then busy = false; delF(PEND_FILE); setStatus("Session expired. Press Get a key again."); return end
				task.wait(3)
			end
			busy = false; setStatus("Still waiting. Finish the link, then press Get a key / reopen.")
		end)
	end

	button("Get a key", 112, Color3.fromRGB(124, 92, 255), function()
		if busy then return end
		setStatus("Starting...")
		local body = httpGet(BACKEND .. "/start?hwid=" .. esc(hwid()))
		local data = body and decode(body)
		if not data or not data.url then setStatus("Couldn't start. Try again in a moment."); return end
		writeF(PEND_FILE, data.nonce)
		if isfn(setclipboard) then pcall(setclipboard, data.url) end
		setStatus("Link copied! Open it in your browser & finish it.\nThen come back - PC loads automatically, on mobile\njust run the script again. (binds to this device)")
		poll(data.nonce)
	end)

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

	-- Discord: one tap copies the invite (to add songs, get help, see updates)
	local discordBtn
	discordBtn = button("Join Discord to add songs!", 218, Color3.fromRGB(88, 101, 242), function()
		if copyText(DISCORD) then
			setStatus("Discord invite copied! Paste it in your browser\nto join - that's where you add songs.")
			discordBtn.Text = "Invite copied!"
			task.delay(2.5, function()
				if discordBtn and discordBtn.Parent then discordBtn.Text = "Join Discord to add songs!" end
			end)
		else
			setStatus("Couldn't copy automatically. Join here:\n" .. DISCORD)
		end
	end)

	-- re-opened after starting a link? resume automatically
	if resumeNonce and resumeNonce ~= "" then
		setStatus("Welcome back - checking if your key is ready...")
		poll(resumeNonce)
	end
end

----------------------------------------------------------------------------- run
local saved = (type(genv.EncoreKey) == "string" and genv.EncoreKey) or readFile(KEY_FILE)
if saved and saved ~= "" then
	if runWithKey(saved) then return end
	delF(KEY_FILE)
end
startPanel(readFile(PEND_FILE))
