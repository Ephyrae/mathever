#!/usr/bin/env scons
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# Include your source files from the src directory
src_files = Glob("src/*.cpp")

# Configure the output binary path inside res://bin/
env.Append(CPPPATH=["src"])
library = env.SharedLibrary(
    "bin/libmathmanager{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
    source=src_files
)

Default(library)