# Gtk2ToDoApp II: Double Done

* [github](https://www.github.com/carlosjhr64/gtk2todoapp)
* [rubygems](https://rubygems.org/gems/gtk2todoapp)

## DESCRIPTION:

A [todo.txt](http://todotxt.org/)
[gtk3app](https://https://rubygems.org/gems/gtk2app) gui
using [todo-txt](https://rubygems.org/gems/todo-txt).

## INSTALL:

    $ sudo gem install gtk2todoapp

## MORE:

See the ruby gem [todo-txt](https://github.com/todotxt/todo.txt) for the standard format rules.
Supports the following tags for reoccurring tasks:

* daily:1
* weekly:n where n is day of week(0..6).
* monthly:n where n is day month(0..28).
* yearly:mm-dd where mm is the month(01..12) and dd is the day of month(01..28).

By default, Gtk2ToDoApp archives done tasks after 28 days and keeps only the last 1000 lines:

    ~/.cache/gtk3app/gtk2todoapp/done.txt

The configuation file is found in:

    ~/.config/gtk3app/gtk2todoapp/config-?.?.yml

## HELP:

    Usage:
      gtk2todoap
    Uses todotxt.org's format for todo text files:
      ~/.cache/gtk3app/gtk2todoapp/todo.txt

