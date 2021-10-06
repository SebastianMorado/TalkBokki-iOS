platform :ios, '13.0'

target 'Chat iOS' do
  use_frameworks!

  # Pods for Flash Chat iOS13
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Core'
  pod 'Firebase/AdMob'
  pod 'Firebase/Database'
  pod 'Firebase/Messaging'
  pod 'PaddingLabel', '1.2'
  pod 'ChameleonFramework/Swift', :git => 'https://github.com/wowansm/Chameleon.git', :branch =>'swift5'
  pod 'GhostTypewriter'
  
  post_install do |installer|
   installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
     config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
   end
  end
  

end
