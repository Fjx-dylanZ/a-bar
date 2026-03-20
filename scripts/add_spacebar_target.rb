#!/usr/bin/env ruby
# Adds the space-bar target to a-bar.xcodeproj

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../a-bar.xcodeproj', __dir__)
SPACEBAR_DIR = File.expand_path('../space-bar', __dir__)
BUNDLE_ID    = 'com.jeantinland.space-bar'
TARGET_NAME  = 'space-bar'
DEPLOYMENT   = '13.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if target already exists
if project.targets.any? { |t| t.name == TARGET_NAME }
  puts "Target '#{TARGET_NAME}' already exists. Skipping."
  exit 0
end

# Create the native target
target = project.new_target(:application, TARGET_NAME, :osx, DEPLOYMENT)
target.product_name = TARGET_NAME

# Create a group for space-bar source files
spacebar_group = project.main_group.new_group(TARGET_NAME, SPACEBAR_DIR)

# Subdirectory groups
sub_dirs = %w[Protocols Providers Store Views Commands]
sub_groups = {}
sub_dirs.each do |dir|
  sub_groups[dir] = spacebar_group.new_group(dir, File.join(SPACEBAR_DIR, dir))
end

# Collect all Swift files and map them to groups
file_map = {}

Dir.glob(File.join(SPACEBAR_DIR, '*.swift')).sort.each do |f|
  file_map[f] = spacebar_group
end

sub_dirs.each do |dir|
  Dir.glob(File.join(SPACEBAR_DIR, dir, '*.swift')).sort.each do |f|
    file_map[f] = sub_groups[dir]
  end
end

# Add Swift source files to group + target Sources build phase
source_files = []
file_map.each do |path, group|
  ref = group.new_file(path)
  source_files << ref
end

source_files.each { |ref| target.source_build_phase.add_file_reference(ref) }

# Add .sdef file as a resource
sdef_path = File.join(SPACEBAR_DIR, 'space-bar.sdef')
sdef_ref = spacebar_group.new_file(sdef_path)
target.resources_build_phase.add_file_reference(sdef_ref)

# Add entitlements file (not compiled, just referenced in build settings)
ent_path = File.join(SPACEBAR_DIR, 'space-bar.entitlements')
ent_ref = spacebar_group.new_file(ent_path)

# Configure build settings for both Debug and Release
{
  'Debug'   => target.build_configuration_list['Debug'],
  'Release' => target.build_configuration_list['Release'],
}.each do |config_name, config|
  next unless config

  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER'    => BUNDLE_ID,
    'PRODUCT_NAME'                 => TARGET_NAME,
    'MACOSX_DEPLOYMENT_TARGET'     => DEPLOYMENT,
    'SWIFT_VERSION'                => '5.0',
    'ENABLE_HARDENED_RUNTIME'      => 'YES',
    'CODE_SIGN_ENTITLEMENTS'       => "space-bar/space-bar.entitlements",
    'INFOPLIST_KEY_LSUIElement'    => 'YES',
    'INFOPLIST_KEY_NSAppleScriptEnabled' => 'YES',
    'INFOPLIST_KEY_OSAScriptingDefinition' => 'space-bar.sdef',
    'INFOPLIST_KEY_NSAppleEventsUsageDescription' =>
      'space-bar needs Apple Events to receive refresh signals from yabai.',
    'GENERATE_INFOPLIST_FILE'      => 'YES',
    'CURRENT_PROJECT_VERSION'      => '1',
    'MARKETING_VERSION'            => '1.0.0',
  })
end

project.save
puts "✅ Target '#{TARGET_NAME}' added to #{PROJECT_PATH}"
puts "   #{source_files.count} Swift files added to Sources build phase."
puts ""
puts "Next steps in Xcode:"
puts "  1. Open a-bar.xcodeproj"
puts "  2. Select the space-bar target → Signing & Capabilities → set your Team"
puts "  3. Build (Cmd+B) with the space-bar scheme selected"
