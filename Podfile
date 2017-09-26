source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.3'
use_frameworks!

target 'Backlogger' do
    pod 'Alamofire'
    pod 'RealmSwift'
    pod 'Kingfisher', '~> 3.13.1'
    pod 'ImageViewer'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Zip', '~> 0.8.0'
    pod 'Zephyr', :git => 'https://github.com/ArtSabintsev/Zephyr.git', :branch => 'swift3.2'
end

target 'BackloggerWidget' do
    pod 'Alamofire'
    pod 'RealmSwift'
    pod 'Kingfisher', '~> 3.13.1'
    pod 'Fabric'
    pod 'Crashlytics'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
