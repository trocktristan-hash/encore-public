# 🎵 Encore

**Play anything. Play together.** Encore is a Roblox autoplayer hub: play any MIDI file on piano, guitar, bass, ukulele, drums and more - with a human-feel engine, live controls, Band Sync and Jam.

💬 **Discord:** https://discord.gg/fSgSAd4URv - add songs, get help, see updates.

## Run it

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/trocktristan-hash/encore-public/main/loader.lua"))()
```

1. Run the script - the Encore panel opens.
2. Tap **Get a key** - a link is copied to your clipboard.
3. Open it in your browser and finish it.
4. Come back to Roblox. On PC it loads on its own; on mobile just run the script again.

Your key lasts **24 hours** and is tied to your device, so there is nothing to copy by hand. Premium/staff key? Paste it in the box and hit **Use key**.

Already have a key and want to skip the box:

```lua
getgenv().EncoreKey = "ENC-XXXXXXXX-XXXXXXXX"
loadstring(game:HttpGet("https://raw.githubusercontent.com/trocktristan-hash/encore-public/main/loader.lua"))()
```

## Features

- **Plays any MIDI file** - drop it in, Encore picks the right instrument and transposes it to fit.
- **13 instruments** - piano, guitar (acoustic/electric), bass, ukulele, drums, and more. Parts are labelled so you can see what each track is.
- **Play like a human** - presets (Natural, Expressive, Sloppy, Beginner) plus sliders for timing wobble, chord roll, tempo drift, pauses between phrases and missed notes.
- **LIVE panel** - change tempo, octave and hands mid-song; Hesitate, Slip-up, Redo phrase, Flourish, Warm up, Big ending, Next song and Stop at the tap of a button.
- **Band Sync** - run drums, guitar and piano on separate accounts, locked to the same beat, with pause/seek/speed in sync.
- **Jam** - play along with anyone, no setup.
- **Smart drums** - real grooves and fills instead of one repeating beat.
- **A-B loop / practice** - loop a section and slow it down.
- **Add songs easily** - from your PC, a link or a sheet, or submit in Discord for everyone.
- **Always up to date** - the library and the hub update automatically.

## Songs

The song library lives in [`library/`](library/) and updates automatically - new songs added in our Discord show up the next time you load Encore (or press ⟳ in Settings). Every song keeps its license; the bundled set is public-domain / Creative Commons (Mutopia Project).

Want a song added? **Join the Discord** (tap *Join Discord to add songs!* in Encore to copy the invite) and submit it - a moderator approves it and it goes live for everyone.
