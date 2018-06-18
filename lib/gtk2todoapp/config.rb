module Gtk2ToDoApp
  using Rafini::String

  APPDIR = File.dirname File.dirname __dir__

  CONFIG = {
    # Files
    TodoTxt: "#{XDG['CACHE']}/gtk3app/gtk2todoapp/todo.txt",
    DoneTxt: "#{XDG['CACHE']}/gtk3app/gtk2todoapp/done.txt",
    # Strings
    Projects: 'Projects:',
    Contexts: 'Contexts:',
    Empty: '-',
    Done: 'Done',
    Hidden: 'Hidden',
    # Colors
    ColorA: '#FF8C00',
    ColorB: '#008000',
    ColorC: '#00008B',
    ColorZ: '#000000',
    Late: '#FF0000',
    # Integers
    ArchiveDays: 28,
    ArchiveLines: 1000,
    # GUI Config
    thing: {
      HelpFile: 'https://github.com/carlosjhr64/gtk2todoapp',
      Logo: "#{XDG['DATA']}/gtk3app/gtk2todoapp/logo.png",
      window: {
        set_title: 'Gtk2ToDoApp',
        set_default_size: [324,200],
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
      # Error Message Dialog
      error_dialog: Rafini::Empty::HASH,
      # VBOX
      VBOX: [:vertical],
      vbox: Rafini::Empty::HASH,
      vbox!: [:VBOX, :vbox],
      # HBOX
      HBOX: [:horizontal],
      hbox: Rafini::Empty::HASH,
      hbox!: [:HBOX, :hbox],
      # Scrolled Window
      scrolled_window: {
        into: [:pack_start, expand: true, fill: true, padding: 1],
      },
      # Add Task Menu Item
      ADD_TASK: [label: 'Add Task'],
      add_task!: [:ADD_TASK, 'activate'],
      # Add Task Dialog
      add_task_dialog: {set_title: 'Add Task!'},
      add_task_entry: {set_activates_default: true},
      # Delete Task Dialog
      delete_task_dialog: {set_title: 'Delete?'},
      delete_task_label: Rafini::Empty::HASH,
    }
  }
end
