Gem::Specification.new do |s|
  s.name        = "jruby-warck"
  s.version     = `git symbolic-ref HEAD 2> /dev/null | cut -b 12-`-`git log --pretty=format:\"%h\" -1` 
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nuno Correia"]
  s.email       = ["nbettencourt@gmail.com"]
  s.homepage    = "http://github.com/ngcazz/jruby-warck"
  s.summary     = "Kinda like warbler, except our way"
  s.description = "Kinda like warbler, except WAR-only and contained in a single Rakefile."
 
  s.add_development_dependency "rspec"
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)
  s.require_path = 'lib'
end