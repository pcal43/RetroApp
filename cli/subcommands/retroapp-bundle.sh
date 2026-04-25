#!/bin/sh

#
# Good source for images
# https://gamesdb.launchbox-app.com/
#

usage() {
  echo "Usage: retroapp bundle [-h] [options...]

Creates a standlone launcher bundle for a retro game that can be double-clicked 
in MacOS.

    -h                   Print this message.

    -n appName           The name of the launcher app to build.
                         Usually just the name of the game.
                         Required.

    -e emulatorId        The emulator to use, e.g., 'stella' or 'nestopia'.
                         Run 'retroapp list-emulators' for a full list.
                         Required.

    -r romPath           Path to rom file for the launcher to run.
                         Required.

    -i icnsPath          Path to a .icns file toto use as an app icon.  These
                         can be generated with 'retroapp make-icon'.
                         Optional.  If omitted, a default icon will be used.

This tool works as follows:
- It locates the bundle template in cli/bundles/[emulatorId].  It's an error if it doesn't exist.
- Copy the contents of the template's 'bundle' subdirectory into a staging directory.
- Copy the rom provided by -r into the staging directory at [stagingdir]/Contents/Resources/Roms.  Create the Roms directory if needed.  
- If -i is specified, copy that file into the stageing directory at [stagingdir]/Contents/Resources/AppIcon.icns.  Overwrite the existing file.
- Scan the staging dir for any files with names ending in .template.  These need to 
be rewritten as new files without the .template extension and performing the following
substitutions: RETROAPP_APP_NAME (the -n appName) and RETROAPP_ROM_NAME the name of the file that provided by -r (basename only)
- Delete the .template files from the staging directory
- Ensure the file [stagingdir]/Contents/MacOS/launch is executable (chmod +x)

Note that this is a rework of retroapp-build.sh.  You can refer to that at a template
but note that the process here is significantly different.  Also refer to templates/stella
for an example of the kind of template we will be processing.



" >&2
  exit 1
}


