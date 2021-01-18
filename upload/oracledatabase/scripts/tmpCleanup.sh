echo 'ORACLE CLEANUP: Clearing Out Temporary Directories'

find /tmp  -maxdepth 1 -mindepth 1 -type d -amin +0 -exec rm -rv {} \;
find /tmp -type f -amin +0 -exec rm -rv {} \;