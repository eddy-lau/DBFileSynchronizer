#
# Be sure to run `pod lib lint DBFileSynchronizer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DBFileSynchronizer'
  s.version          = '1.0.0'
  s.summary          = 'Dropbox file sync utilities'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Objective-C utilities classes for syncing objects or files on Dropbox
                       DESC

  s.homepage         = 'https://github.com/eddy-lau/DBFileSynchronizer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Eddie Lau' => 'eddie@touchutility.com' }
  s.source           = { :git => 'https://github.com/eddy-lau/DBFileSynchronizer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'
  s.requires_arc = false

  s.source_files = 'DBFileSynchronizer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DBFileSynchronizer' => ['DBFileSynchronizer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ObjectiveDropboxOfficial'
end
