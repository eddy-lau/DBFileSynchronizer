Pod::Spec.new do |s|
  s.name             = 'DBFileSynchronizer'
  s.version          = '2.0.0'
  s.summary          = 'Dropbox file sync utilities'
  s.description      = <<-DESC
Objective-C utilities classes for syncing objects or files on Dropbox
                       DESC
  s.homepage         = 'https://github.com/eddy-lau/DBFileSynchronizer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eddie Lau' => 'eddie@touchutility.com' }
  s.source           = { :git => 'https://github.com/eddy-lau/DBFileSynchronizer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'DBFileSynchronizer/Classes/**/*'
  s.private_header_files = [
    'DBFileSynchronizer/Classes/FileSync/*.h',
    'DBFileSynchronizer/Classes/UI/DBAccountInfoCell.h'
  ]
  s.dependency 'ObjectiveDropboxOfficial', '~> 6.0'
end
