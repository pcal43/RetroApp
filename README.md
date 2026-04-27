# RetroApp

**RetroApp** creates standalone MacOS desktop applications from 
retro game ROM files.  Drag-and-drop a ROM, out pops an app!

https://github.com/user-attachments/assets/49f888a9-b9ad-44bb-94b7-376bba11f4f3

## Features

* Create standalone retro game launchers for a variety of popular systems and emulators
* Automatically downloads box art for the game and creates a MacOS icon from it
* Fully sandboxes configuration files for each game (optional)
* Embeds the emulator for a truly standalone launcher (optional)

## Installation

* Download the [latest release](https://github.com/pcal43/RetroApp/releases)
* Open the `.dmg` and drag RetroApp into `/Applications`

## Usage

* Drag a ROM file onto RetroApp
* It creates standalone launcher app
* Click the launcher and play!

_NOTE: RetroApp currently assumes that you have the target emulator installed in your
/Applications directory and that you've configured it the way you want (bios, controllers, 
video settings).  Future versions will make this process more seamless._

## Legal

**RetroApp does not provide any game ROMs.  Please only use ROMs from games you own or are otherwise authorized to use.**


## Feedback

RetroApp is still an alpha. I'm trying to get a sense of how much community 
interest there is in something like this before investing more time in it.

If you think it's a useful idea, come to my [discord channel](https://discord.pcal.net) 
and let me know!

---

## FAQ

### What systems are supported?

Here's the current list.  I'll be adding more if there's community interest.

| System | Emulator |
|--------|-------------|
| Atari - 2600 | stella |
| Coleco - ColecoVision | ares |
| Nintendo - Family Computer Disk System | ares |
| Nintendo - Game Boy | ares |
| Nintendo - Game Boy Advance | ares |
| Nintendo - Game Boy Color | ares |
| Nintendo - GameCube | dolphin |
| Nintendo - Nintendo 64 | ares |
| Nintendo - Nintendo 64DD | ares |
| Nintendo - Nintendo Entertainment System | ares |
| Nintendo - Super Nintendo Entertainment System | ares |
| Nintendo - Wii | dolphin |
| Sony - PlayStation | duckstation |
| Sony - PlayStation 2 | pcsx2 |

### Why would anyone want to use this?

RetroApp might be a good choice if:

* **You really only care about playing a few games.**  If you just have a dozen or 
so retro games that you care about playing regularly on your mac, you may 
find a small set of regular desktop applications easier to manage than
a full-featured launcher.

* **You want to use Steam as your launcher for everything.**  Configuring
emulators as *Non-Steam Games* can be tedious; it's much easier to just point 
Steam at a desktop app.

* **You want to create easy-to-use launchers for kids** or other folks who 
aren't technically-savvy.

* **You want to separate config folders for each game.**  By default, RetroApps
are run in a sandboxed configuration directory - they have their own configuration
that is completely separate from other games using the same emulator.
This can be helpful if you want cleanly-separated settings and save files 
for each game. 

* You just think **having a bunch of PlayStation discs in your MacOS Dock looks cool.**

If none of these apply to you, there are lots of other launchers out there that
will probably work better for you, especially if you care about managing
a lot of ROMs.

### Won't embedding the emulator use up extra disk space?

Well, yes...but also a little bit no.  It's true that you end up with a 
copy of an emulator for each game.  But in many cases, it's not a huge 
amount of extra space, especially compared to the size of CD- and DVD- based ROMs.

Also, RetroApp uses 
[copy-on-write](https://bestreviews.net/the-magic-behind-apfs-copy-on-write/) 
when duplicating emulators and ROMs.  Which means that as long as they stay
on your computer, the extra 'copeis' don't actually use any extra disk space.


### Is there a command-line interface?

Yes, see `RetroApp.app/Contents/Resources/cli/retroapp`.  If 
there is interest, I'll add support for installing it on your PATH properly.


## Acknowledgments

RetroApp uses or depends on the following software:

* [Ares](https://ares-emu.net/)
* [Dolphin](https://dolphin-emu.org/)
* [Duckstation](https://github.com/stenzek/duckstation)
* [ImageMagick](https://imagemagick.org/)
* [PCSX2](https://pcsx2.net/)
* [Platypus](https://sveinbjorn.org/platypus)
* [Stella](https://stella-emu.github.io/)

Thanks very much to the authors of these programs for their hard work.
