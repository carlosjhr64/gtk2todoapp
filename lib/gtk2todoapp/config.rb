module Gtk2ToDoApp
  using Rafini::String
  APPDIR = File.dirname File.dirname __dir__
  CONFIG = {
    TODOTXT: "#{XDG['CACHE']}/gtk3app/gtk2todoapp/todo.txt",
    PROJECTS: 'Projects:',
    CONTEXTS: 'Contexts:',
    thing: {
      HelpFile: 'https://github.com/carlosjhr64/gtk2todoapp',
      Logo: "#{XDG['DATA']}/gtk3app/gtk2todoapp/logo.png",
      window: {
        set_title: 'Gtk2ToDoApp',
        set_default_size: [100,60],
        set_window_position: :center,
      },
      about_dialog: {
        set_program_name: 'Gtk2ToDoApp',
        set_version: VERSION.semantic(0..1),
        set_copyright: '(c) 2018 CarlosJHR64',
        set_comments: 'Stuff to do!',
        set_website: 'https://github.com/carlosjhr64/gtk2todoapp',
        set_website_label: 'See it at GitHub!',
      },
      # ComboBox
      combo: Rafini::Empty::HASH,
      # CheckBox
      check: Rafini::Empty::HASH,
      # VBOX
      VBOX: [:vertical],
      vbox: Rafini::Empty::HASH,
      vbox!: [:VBOX, :vbox],
      # HBOX
      HBOX: [:horizontal],
      hbox: Rafini::Empty::HASH,
      hbox!: [:HBOX, :hbox],
      # Scrolled Window
      expansive: {
        into: [:pack_start, expand: true, fill: true, padding: 1],
      },
    }
  }
end
