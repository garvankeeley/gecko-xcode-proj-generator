This generates an Xcode project useful for editing Gecko (Firefox C/C++) source code.

The Firefox build system, `mach`, has an option to output the build commands per-file (`CompileDB`). This project imports the contents of that file into Xcode. 
Xcode can then compile the files, code complete/navigate, and show errors/warnings as-you-type.

It can compile individual source files, but does not link the executable.<br>
Use `mach build` for that.

You will need a very powerful Mac for this, as the project is huge (or just modify this to work with a subset of the project, likely there are plenty of modules you won't need code navigation for).

## Usage

1. Uses cocoapods project generator, install with:
`gem install xcodeproj`

2. `mach build-backend -b CompileDB` <br>
_This will output `compile_commands.json`_

3. `./gen.rb </path/to/firefox-obj-dir/compile_commands.json>` <br>
_pass in path+filename for the compilation commands_

Now open the xcode project, and use for code editing, completion, navigation, debugging.
