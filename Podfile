source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def sharedPods
  pod 'Alamofire'
  pod 'Kingfisher', '~> 3.13.1'
  pod 'RealmSwift'
  pod 'MMWormhole'
end

target 'Backlogger' do
    platform :ios, '10.3'
    sharedPods
    pod 'ImageViewer', '~> 4.1.0'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Zip', '~> 0.8.0'
    pod 'Zephyr', :git => 'https://github.com/ArtSabintsev/Zephyr.git', :branch => 'swift3.2'
end

target 'BackloggerWidget' do
    platform :ios, '10.3'
    sharedPods
    pod 'Fabric'
    pod 'Crashlytics'
end
=begin
target 'BackloggerWatch' do
    platform :watchos, '3.2'
    sharedPods
end

target 'BackloggerWatch Extension' do
    platform :watchos, '3.2'
    sharedPods
end
=end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
