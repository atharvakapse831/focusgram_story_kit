Pod::Spec.new do |s|
  s.name             = 'focusgram_story_kit'
  s.version          = '0.1.0'
  s.summary          = 'FocusGram Story Kit native video composition and hardware export plugin.'
  s.description      = <<-DESC
Native iOS AVFoundation video composition, CoreAnimation overlay rendering, and hardware H.264/AAC export.
                       DESC
  s.homepage         = 'https://github.com/atharvakapse831/focusgram_story_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FocusGram Team' => 'dev@focusgram.app' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.frameworks = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'CoreAudio', 'Photos'
end
