source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def sharedPods
  pod 'Alamofire'
  pod 'Kingfisher'
  pod 'RealmSwift'
  pod 'MMWormhole'
end

target 'Backlogger' do
    platform :ios, '13'
    sharedPods
    pod 'ImageViewer', :git => 'https://github.com/Krisiacik/ImageViewer.git', :commit => '519fbdb57b4ad83de50ecd09b7182ed9d190f3ee'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Zip'
    pod 'Zephyr'
    pod 'Firebase/Analytics'
end

target 'BackloggerWidget' do
    platform :ios, '13'
    sharedPods
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Firebase/Analytics'
end

target 'BackloggerWatch' do
    platform :watchos, '6.1'
    sharedPods
end

target 'BackloggerWatch Extension' do
    platform :watchos, '6.1'
    sharedPods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.1'
    end
  end
end
