#!/usr/bin/env ruby
require 'xcodeproj'
require 'json'

$extensions = 'c|cc|cpp|m|mm|hpp'

if ARGV[0].nil?
  puts "USAGE: ruby gen.rb </path/to/fx obj dir/compile_commands.json> \n First do: mach build-backend -b CompileDB"
  exit(1)
end

if not ARGV[0].end_with?('.json')
  puts "You must specify the full json filename"
  exit(1)
end

`cp -f fx-xcode.xcodeproj/project.pbxproj.template fx-xcode.xcodeproj/project.pbxproj`

$src_dirname = `grep -o -E 'file.+nsBrowserApp.cpp' #{ARGV[0]} | sed 's/.*: \"//' | sed 's#/browser/app/nsBrowserApp.cpp##'`
$src_dirname = $src_dirname.sub(/\n/, '')
puts 'Detected source dir: ' + $src_dirname

file = File.read(ARGV[0])

project_file = 'fx-xcode.xcodeproj'
$project = Xcodeproj::Project.open(project_file)

$groups = {}

def add_headers(group, path)
  _files = `ls -1 #{path}/*.h 2>/dev/null`
  files = _files.split(/\n/)
  files.each do |file|
    group.new_file(file)
  end
end

def grouper(path, cmd=nil, objdir=nil)
  is_leaf = path.count('/') == 0 || (path.count('/') == 1 and path.start_with?('/'))

  if path =~ /^Unified.+\.(#{$extensions})$/
      if cmd.nil?
        return
      end
    fullpath = objdir + '/' + path
    file_ref = $project.new_file(fullpath)
    ref = $project.targets.first.add_file_references([file_ref])
    ref[0].settings = {'COMPILER_FLAGS' => cmd}

    _files = `grep -o -E "include.+" #{fullpath}`
    files = _files.gsub('include ', '').gsub('"', '').split(/\n/)
    files.each do |file|
      if file.include?('/')
        grouper(file)
      end
    end
    return
  end

  ext = File.extname(path)
  is_dir = ext.empty? || (ext.length == 2 and not ext =~ /[hcm]/i)

  if is_leaf
    if is_dir
      $groups[path] = $project.new_group(path, path)
      return $groups[path]
    end

    puts 'error?'
    return
  end

  dirname = File.dirname(path)
  parent_group = $groups[dirname]

  if parent_group.nil?
    parent_group = grouper(dirname)
  end

  if is_dir
    $groups[path] = parent_group.new_group(File.basename(path), File.basename(path))
    add_headers($groups[path], path)
    return $groups[path]
  end

  file_ref = parent_group.new_file(File.basename(path))
  if not cmd.nil?
##    ref = $project.targets.first.add_file_references([file_ref])
  ##  ref[0].settings = {'COMPILER_FLAGS' => cmd}
  end
end

file = File.read(ARGV[0])
data = JSON.parse(file)
$groups[$src_dirname] = $project.new_group($src_dirname, $src_dirname)

data.each do |item|
  replacer = File.basename($src_dirname)
  i = item['file'].sub(/.+#{replacer}/, $src_dirname)
  c = item['command'].sub(/.+ -c /, ' ')
  c = c.sub(/ [^\s]+\.(#{$extensions})$/, ' ')
  c = c.sub('-O3', '')

  if item['directory'] =~ /pvx|vpx/
    c = ' -mavx2 ' + c
  end

  grouper(i, c, item['directory'])
end

$project.save


