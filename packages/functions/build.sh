#!/bin/sh

# Install dependencies
dart pub get

# build the binary
dart compile exe bin/main.dart -o dist/bootstrap

# Exit
exit

