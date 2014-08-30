Pod::Spec.new do |s|
  s.name = 'Haneke+AFNetworking'
  s.version = '0.1.0'
  s.license = 'Apache 2.0'
  s.summary = 'Haneke extension to use AFNetworking to download images.'
  s.homepage = 'https://github.com/Haneke/Haneke-AFNetworking'
  s.author = 'Hermes Pique'
  s.social_media_url = 'https://twitter.com/hpique'
  s.source = { :git => 'https://github.com/Haneke/Haneke-AFNetworking', :tag => "v#{s.version}" }
  s.platform = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Haneke+AFNetworking/*.{h,m}'
  s.dependency 'Haneke', :git => 'https://github.com/hpique/Haneke.git', :branch=>'v1.0'
  s.dependency 'AFNetworking', '~> 2.3'
end
