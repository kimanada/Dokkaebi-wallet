#!/usr/bin/env ruby
# 도깨비 지갑 Xcode 프로젝트 생성 스크립트.
#
# 폴더 구조를 그대로 Xcode 그룹으로 만들고, 앱·단위 테스트·UI 테스트 타깃과 공유 스킴을 구성한다.
# 파일을 추가하거나 옮긴 뒤 다시 실행하면 프로젝트가 새로 만들어진다:
#     gem install xcodeproj && ruby scripts/generate_project.rb
require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'DokkaebiWallet.xcodeproj')
APP = 'DokkaebiWallet'
DEPLOYMENT_TARGET = '17.0'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH, false, 56)
project.root_object.development_region = 'ko'
project.root_object.known_regions = %w[ko en Base]
project.root_object.attributes['LastSwiftUpdateCheck'] = '1600'
project.root_object.attributes['LastUpgradeCheck'] = '1600'
project.root_object.attributes['ORGANIZATIONNAME'] = 'DOKKAEBI WALLET'

FILE_TYPES = {
  '.xcstrings' => 'text.json.xcstrings',
  '.xcprivacy' => 'text.xml',
  '.xcconfig' => 'text.xcconfig'
}.freeze

def add_file(group, path)
  ref = group.new_reference(File.basename(path))
  type = FILE_TYPES[File.extname(path)]
  ref.last_known_file_type = type if type
  ref
end

# 폴더를 재귀적으로 그룹으로 추가하고 [소스 참조, 리소스 참조]를 돌려준다.
def add_folder(project_group, disk_path)
  sources = []
  resources = []
  group = project_group.new_group(File.basename(disk_path), File.basename(disk_path))
  Dir.children(disk_path).sort.each do |name|
    next if name.start_with?('.')
    full = File.join(disk_path, name)
    if name.end_with?('.xcassets')
      resources << add_file(group, full)
    elsif File.directory?(full)
      s, r = add_folder(group, full)
      sources.concat(s)
      resources.concat(r)
    elsif name.end_with?('.swift')
      sources << add_file(group, full)
    elsif %w[.xcstrings .xcprivacy].include?(File.extname(name))
      resources << add_file(group, full)
    else
      add_file(group, full) # Info.plist 등: 빌드 단계에 넣지 않음
    end
  end
  [sources, resources]
end

main = project.main_group

# 빌드 설정 파일
config_group = main.new_group('Configurations', 'Configurations')
debug_xcconfig = add_file(config_group, 'Debug.xcconfig')
release_xcconfig = add_file(config_group, 'Release.xcconfig')
add_file(config_group, 'Shared.xcconfig')
project.build_configurations.each do |config|
  config.base_configuration_reference = config.name == 'Debug' ? debug_xcconfig : release_xcconfig
end

# ---------------------------------------------------------------- 앱 타깃
app_target = project.new_target(:application, APP, :ios, DEPLOYMENT_TARGET, nil, :swift)
app_sources, app_resources = add_folder(main, File.join(ROOT, APP))
app_target.add_file_references(app_sources)
app_target.add_resources(app_resources)

app_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = '$(PRODUCT_BUNDLE_IDENTIFIER_BASE)'
  s['INFOPLIST_FILE'] = "#{APP}/Resources/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['INFOPLIST_KEY_CFBundleDisplayName'] = '도깨비 지갑'
  s['INFOPLIST_KEY_LSApplicationCategoryType'] = 'public.app-category.finance'
  s['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  s['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
  s['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  s['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
  s['SUPPORTS_MACCATALYST'] = 'NO'
  s['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['SWIFT_STRICT_CONCURRENCY'] = 'complete'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s['LOCALIZATION_PREFERS_STRING_CATALOGS'] = 'YES'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS'] = 'NO'
  s['ENABLE_PREVIEWS'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
  s['ENABLE_USER_SCRIPT_SANDBOXING'] = 'YES'
end

# ---------------------------------------------------------------- 단위 테스트 타깃
unit_target = project.new_target(:unit_test_bundle, "#{APP}Tests", :ios, DEPLOYMENT_TARGET, nil, :swift)
unit_sources, = add_folder(main, File.join(ROOT, "#{APP}Tests"))
unit_target.add_file_references(unit_sources)
unit_target.add_dependency(app_target)
unit_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = '$(PRODUCT_BUNDLE_IDENTIFIER_BASE).tests'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['TEST_HOST'] = "$(BUILT_PRODUCTS_DIR)/#{APP}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/#{APP}"
  s['BUNDLE_LOADER'] = '$(TEST_HOST)'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['SWIFT_VERSION'] = '5.0'
  s['SWIFT_STRICT_CONCURRENCY'] = 'complete'
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

# ---------------------------------------------------------------- UI 테스트 타깃
ui_target = project.new_target(:ui_test_bundle, "#{APP}UITests", :ios, DEPLOYMENT_TARGET, nil, :swift)
ui_sources, = add_folder(main, File.join(ROOT, "#{APP}UITests"))
ui_target.add_file_references(ui_sources)
ui_target.add_dependency(app_target)
ui_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = '$(PRODUCT_BUNDLE_IDENTIFIER_BASE).uitests'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['TEST_TARGET_NAME'] = APP
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['SWIFT_VERSION'] = '5.0'
  s['CODE_SIGN_STYLE'] = 'Automatic'
end

# 스크립트·문서 폴더는 참고용으로만 표시
%w[scripts docs].each do |folder|
  next unless Dir.exist?(File.join(ROOT, folder))
  group = main.new_group(folder, folder)
  Dir.children(File.join(ROOT, folder)).sort.each { |name| add_file(group, name) unless name.start_with?('.') }
end

# Products 그룹을 맨 아래로
products = main.children.find { |c| c.display_name == 'Products' }
if products
  main.children.delete(products)
  main.children << products
end

project.save

# ---------------------------------------------------------------- 공유 스킴
scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, unit_target, launch_target: true)
scheme.add_test_target(ui_target)
scheme.test_action.code_coverage_enabled = true
scheme.save_as(PROJECT_PATH, APP, true)

puts "생성 완료: #{PROJECT_PATH}"
puts "  앱 소스 #{app_sources.size}개, 리소스 #{app_resources.size}개"
puts "  단위 테스트 #{unit_sources.size}개, UI 테스트 #{ui_sources.size}개"
