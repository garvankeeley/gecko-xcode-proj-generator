Uses cocoapods project generator, install with:
`gem install xcodeproj`

`mach build-backend -b CompileDB` # this will output `compile_commands.json`
`./gen.rb </path/to/firefox obj dir/compile_commands.json>`

Now open the xcode project, and work away
