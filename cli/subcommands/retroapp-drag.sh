#!/bin/sh

usage() {
  cat >&2 <<'EOF'
Usage: retroapp drag [-h] FILE1 [FILE2] [FILE3] [...]

This is the main entry point to the bundling app - it receives an arbitrary list
of files from the user, probably via Finder drag-and-drop, tries to figure out
what they are and assembles a launcher app from them.

The script should work as follows:

Iterate through all of the arguments, each of which must be a path to file.  For each path:
If the file doesn't exist, output a warning message.
Otherwise, run 'retroarch-identify' on it.  
If the file identifies as unknown, output a warning message.
If the file identifies as a png, note it as the icon path
If the file identifies as a rom, note it as the rom file path.  In this case we must
also preseve the second and third lines of output (the system name and the game name).

In the case where more than one file of a type is passed, the first one should win.  Output
a warning message that the extra arguments are being ignored.

Once we have all of the arguments, we need to begin to build the bundle.  If we were not
able to identify a rom file, output an error message and exit 1.

We first need to determine which emulator to use.  We can get an emulator id by
checking the files in cli/emulators - this contains a file for each 'system name' 
that we support.  The contents of each file is the emulator id.  Check for the
file that corresponds to the 'system name' line we got from identifying the rom.
If the file exists, cat it and make note of the emulator id.  If it does not exist, 
output an error message saying 'emulator not supported' and exit 1.

If the icon path was not specified, get one by running retroapp-icon-png.sh.  This
will attempt to download one or use a default if that fails.  Take the path
that is output and use it as the icon png.

Once we have an icon png, we need to create a .icns file using retroapp-make-icon.sh.
Output it (second argument) to a tempoary file and save that path as the icns path.

Now we should have all of the following information:
- game name
- path to rom file
- emulator id
- icns file

which is exactly what we need to run retroapp-bundle.  Go ahead and run it.




EOF
  exit 1
}

