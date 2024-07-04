Pod::Spec.new do |s|
  s.name             = "CustomAR"
  s.version          = "1.1.0"
  
  s.summary          = "AR detection utilities"
  s.author           = { "Fatima Syed" => "fatima.syed@inqbarna.com", "David Romacho" => "david.romacho@inqbarna.com" }
  s.source           = { :git => "https://github.com/InQBarna/CustomAR.git", :tag => s.version.to_s }

  s.platform     = :ios
  s.ios.deployment_target = '12.0'

  s.source_files = 'Sources/CustomAR/**/*.swift'
  #s.resources = 'Pod/Assets/*'

  s.frameworks = 'UIKit', 'AVFoundation', 'Vision', 'CoreML', 'CoreMotion', 'AVKit', 'SceneKit', 'ImageIO'
  s.module_name = 'CustomAR'

  s.dependency 'MediaPipeTasksVision', '0.10.14'
end