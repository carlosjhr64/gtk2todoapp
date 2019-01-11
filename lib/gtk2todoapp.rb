module Gtk2ToDoApp
  VERSION = '2.5.1'
  if _ = ARGV.shift
    if ['-v','--version'].include?(_)
      puts VERSION
    else
      puts <<-HELP
Usage:
  gtk2todoap
Uses todotxt.org's format for todo text files:
  ~/.cache/gtk3app/gtk2todoapp/todo.txt
      HELP
    end
    exit
  end


  def self.requires
    require 'todo-txt'
    require 'gtk3app'

    require_relative 'gtk2todoapp/config.rb'
    require_relative 'gtk2todoapp/gui.rb'
  end
end

# Requires:
#`ruby`
#`tail`
#`mv`
#`wc`
