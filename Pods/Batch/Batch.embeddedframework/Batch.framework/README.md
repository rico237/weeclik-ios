# Bridging Headers for tests

This folder contains the bridging headers for tests written in swift

It's tedious to generate them by hand, so a generator has been written.

## Generating the headers

Run generate.sh from the "bridging headers" folder.
You can also run "make tests-bridging-headers" from the sdk root.
Commit the changes on git

NOTE: Symlinks are not supported at all. Symlinked directories will not be followed, and symlinked headers will be ignored

## Configuring the generator

mapping.json is pretty much self documented: it tells the generator what header files should be named and what they should look for