Pod::Spec.new do |s|
  s.name             = 'DBFileSynchronizer'
  s.version          = '1.0.5'
  s.summary          = 'Dropbox file sync utilities'
  s.description      = <<-DESC
Objective-C utilities classes for syncing objects or files on Dropbox
                       DESC
  s.homepage         = 'https://github.com/eddy-lau/DBFileSynchronizer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eddie Lau' => 'eddie@touchutility.com' }
  s.source           = { :git => 'https://github.com/eddy-lau/DBFileSynchronizer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.source_files = 'DBFileSynchronizer/Classes/**/*'
  s.private_header_files = [
    'DBFileSynchronizer/Classes/FileSync/{DBLocalMetadata,DBMetadata}.h',
    'DBFileSynchronizer/Classes/UI/DBAccountInfoCell.h'
  ]
  s.dependency 'ObjectiveDropboxOfficial', '~> 1.0'
end
