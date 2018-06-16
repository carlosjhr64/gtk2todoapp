module Gtk2ToDoApp
  def self.run(program)
    GUI.new(program)
  end

  class GUI
    CMP = lambda do |a,b|
      (a || '~') <=> (b || '~')
    end

    COMPARE = lambda do |a,b|
      cmp = CMP[a.priority, b.priority]
      cmp = CMP[a.tags[:due], b.tags[:due]] unless cmp==0
      cmp = CMP[a.text, b.text]             unless cmp==0
      return cmp
    end

    def initialize(program)
      ### Data ###
      @tasks = Todo::List.new CONFIG[:TODOTXT]
      @tasks.sort!{|a,b| COMPARE[a,b]}

      ### Scaffolding ###
      window,minime,menu = program.window,program.mini_menu,program.app_menu
      vbox = Such::Box.new(window, :vbox!)

      ### Filters Box ###
      filters_box = Such::Box.new(vbox, :hbox!)

      # Projects
      projects = get_projects
      @projects =
        Such::ComboBoxText.new(filters_box,
                               :combo,
                               {append_text: projects, set_active: 0},
                               'changed'){ do_tasks }

      # Contexts
      contexts = get_contexts
      @contexts =
        Such::ComboBoxText.new(filters_box,
                               :combo,
                               {append_text: contexts, set_active: 0},
                               'changed'){ do_tasks }

      # Done
      @done = Such::CheckButton.new(filters_box,
                                    ['Done'],
                                    :check,
                                    'clicked'){ do_tasks }

      # Hidden
      @hidden = Such::CheckButton.new(filters_box,
                                      ['Hidden'],
                                      :check,
                                      'clicked'){ do_tasks }

      # Scrolled Tasks Box
      scrolled = Such::ScrolledWindow.new(vbox, :expansive)
      @tasks_box = Such::Box.new(scrolled, :vbox!)
      do_tasks

      # Show All
      window.show_all
    end

    def do_tasks
      @tasks_box.each{|_|_.destroy}
      @tasks.each do |task|
        next if task.done? and not @done.active?
        next if task.tags.key?(:h) and not @hidden.active?
        next unless @projects.active==0 or task.projects.include?("+#{@projects.active_text}")
        next unless @contexts.active==0 or task.contexts.include?("@#{@contexts.active_text}")
        task_box = Such::Box.new(@tasks_box, :hbox!)
        cb = Such::CheckButton.new(task_box, [task.text], {set_active: task.done?})
        cb.set_tooltip_text task.raw
      end
      @tasks_box.show_all
    end

    def get_projects
      projects = @tasks.map{|_|_.projects}.flatten.uniq.sort.map{|_|_[1..-1]}
      projects.unshift CONFIG[:PROJECTS]
      return projects
    end

    def get_contexts
      contexts = @tasks.map{|_|_.contexts}.flatten.uniq.sort.map{|_|_[1..-1]}
      contexts.unshift CONFIG[:CONTEXTS]
      return contexts
    end
  end
end
