Gem::Specification.new do |s|

  s.name     = 'gtk2todoapp'
  s.version  = '2.0.0'

  s.homepage = 'https://github.com/carlosjhr64/gtk2todoapp'

  s.author   = 'carlosjhr64'
  s.email    = 'carlosjhr64@gmail.com'

  s.date     = '2018-06-18'
  s.licenses = ['MIT']

  s.description = <<DESCRIPTION
A [todo.txt](http://todotxt.org/)
[gtk3app](https://https://rubygems.org/gems/gtk2app) gui
using [todo-txt](https://rubygems.org/gems/todo-txt).
DESCRIPTION

  s.summary = <<SUMMARY
A [todo.txt](http://todotxt.org/)
[gtk3app](https://https://rubygems.org/gems/gtk2app) gui
using [todo-txt](https://rubygems.org/gems/todo-txt).
SUMMARY

  s.require_paths = ['lib']
  s.files = %w(
LICENSE
README.md
bin/gtk2todoapp
cache/todo.txt
data/VERSION
data/logo.png
lib/gtk2todoapp.rb
lib/gtk2todoapp/config.rb
lib/gtk2todoapp/gui.rb
  )
  s.executables << 'gtk2todoapp'
  s.add_runtime_dependency 'gtk3app', '~> 2.1', '>= 2.1.0'

end
