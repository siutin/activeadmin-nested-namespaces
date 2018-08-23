
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_admin/nested_namespace/version"

Gem::Specification.new do |spec|
  spec.name          = "activeadmin-nested-namespaces"
  spec.version       = ActiveAdmin::NestedNamespace::VERSION
  spec.authors       = ["osiutino"]
  spec.email         = ["osiutino@gmail.com"]

  spec.summary       = %q{ ActiveAdmin plugin to enable nested namespaces support }
  spec.description   = %q{ This plugin allows you to register resources/pages with nested namespaces in ActiveAdmin. }
  spec.homepage      = "https://github.com/siutin/activeadmin-nested-namespaces"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activeadmin", "= 1.3.1"
end
