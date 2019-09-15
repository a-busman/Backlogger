source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def sharedPods
  pod 'Alamofire'
  pod 'Kingfisher'
  pod 'RealmSwift'
  pod 'MMWormhole'
end

target 'Backlogger' do
    platform :ios, '12'
    sharedPods
    pod 'ImageViewer', :git => 'https://github.com/Krisiacik/ImageViewer.git', :commit => '9afa043ffcaf3fd5114a13d5fabcd9bcf5013265'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Zip'
    pod 'Zephyr', :git => 'https://github.com/ArtSabintsev/Zephyr.git', :branch => 'swift4.2'
end

target 'BackloggerWidget' do
    platform :ios, '12'
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
      config.build_settings['SWIFT_VERSION'] = '4.2'
    end
  end
end
