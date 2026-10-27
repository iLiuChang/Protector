Pod::Spec.new do |s|
  s.name         = "Protector"
  s.version      = "1.1.0"
  s.summary      = "A thread-safe wrapper around a value."
  s.homepage     = "https://github.com/iLiuChang/Protector"
  s.license      = "MIT"
  s.authors      = { "iLiuChang" => "iliuchang@foxmail.com" }
  s.ios.deployment_target      = "12.0"
  s.osx.deployment_target      = "10.13"
  s.tvos.deployment_target     = "12.0"
  s.watchos.deployment_target  = "4.0"
  s.visionos.deployment_target = "1.0"
  s.source       = { :git => "https://github.com/iLiuChang/Protector.git", :tag => s.version }
  s.requires_arc = true
  s.swift_versions = ["5.5", "6.0"]
  s.source_files = "Sources/*.{swift}"
end
