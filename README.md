# 🎵 Encore

Play any song on any Roblox instrument. Autoplay, humanized performance, guitar & drums, band mode.

## Run it

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_GITHUB_USER/encore-public/main/loader.lua"))()
```

A box will ask for your **key**. Get this week's key here: **<your key link>** — then paste it in.
The key lasts the week; you won't need to re-enter it until it rotates.

Already have a key and want to skip the box:

```lua
getgenv().EncoreKey = "ENC-XXXXXXXX-XXXXXXXX"
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_GITHUB_USER/encore-public/main/loader.lua"))()
```

## Songs

The song library lives in [`library/`](library/) and updates automatically — new songs added in our
Discord show up the next time you load Encore (or press ⟳ in Settings). Every song keeps its license;
the bundled set is public-domain / Creative Commons (Mutopia Project).

Want a song added? Join the Discord and use `/submitsong` — a moderator approves it and it goes live for everyone.
