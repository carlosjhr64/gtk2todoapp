Gem::Specification.new do |s|

  s.name     = 'gtk2todoapp'
  s.version  = '2.2.1'

  s.homepage = 'https://github.com/carlosjhr64/gtk2todoapp'

  s.author   = 'carlosjhr64'
  s.email    = 'carlosjhr64@gmail.com'

  s.date     = '2018-06-23'
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
cache/README.txt
data/VERSION
data/logo.png
lib/gtk2todoapp.rb
lib/gtk2todoapp/config.rb
lib/gtk2todoapp/gui.rb
  )
  s.executables << 'gtk2todoapp'
  s.add_runtime_dependency 'todo-txt', '= 0.12'
  s.add_runtime_dependency 'gtk3app', '~> 2.1', '>= 2.1.0'
  s.requirements << 'ruby: ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]'
  s.requirements << 'tail: tail (GNU coreutils) 8.29'
  s.requirements << 'mv: mv (GNU coreutils) 8.29'
  s.requirements << 'wc: wc (GNU coreutils) 8.29'

end
