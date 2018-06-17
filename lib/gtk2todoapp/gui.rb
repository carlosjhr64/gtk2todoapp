module Gtk2ToDoApp
  def self.run(program)
    GUI.new(program)
  end

  module Refinements
    refine Todo::Task do
      def done!
        @completed_on = Date.today
        @is_completed = true
      end

      def not_done!
        @completed_on = nil
        @is_completed = false
      end
    end
  end

  class AddTaskDialog < Such::Dialog
    def initialize(parent)
      super([parent: parent], :add_task_dialog)
      @entry = Such::Entry.new(child, :add_task_entry)
      add_button(Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL)
      add_button(Gtk::Stock::OK, Gtk::ResponseType::OK)
    end

    def runs
      self.show_all
      yield @entry.text if run == Gtk::ResponseType::OK
      destroy
    end
  end

  class GUI
    using Refinements
    def initialize(program)
      ### Priority Colors ###
      @colorA = Gdk::RGBA.parse(CONFIG[:ColorA])
      @colorB = Gdk::RGBA.parse(CONFIG[:ColorB])
      @colorC = Gdk::RGBA.parse(CONFIG[:ColorC])
      @colorZ = Gdk::RGBA.parse(CONFIG[:ColorZ])
      ### Data ###
      @tasks = Todo::List.new CONFIG[:TodoTxt]
      @tasks.sort!{|a,b|b<=>a}

      ### Scaffolding ###
      @window,minime,menu = program.window,program.mini_menu,program.app_menu
      menu.each{|_|_.destroy if _.key==:fs!}
      menu.append_menu_item(:add_task!){ add_task! }
      minime.each{|_|_.destroy}
      vbox = Such::Box.new(@window, :vbox!)

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
      @window.show_all
    end

    def do_tasks
      @tasks_box.each{|_|_.destroy}
      @tasks.each do |task|
        # Include done?
        next if task.done? and not @done.active?
        # Include hidden?
        next if task.tags.key?(:h) and not @hidden.active?
        # Which projects to include?
        if @projects.active_text == CONFIG[:Empty]
          next unless task.projects.empty?
        else
          next unless @projects.active==0 or task.projects.include?("+#{@projects.active_text}")
        end
        # Which contexts to include?
        if @contexts.active_text == CONFIG[:Empty]
          next unless task.contexts.empty?
        else
          next unless @contexts.active==0 or task.contexts.include?("@#{@contexts.active_text}")
        end
        # Build the tasks box!
        task_box = Such::Box.new(@tasks_box, :hbox!)
        cb = Such::CheckButton.new(task_box, [task.text], {set_active: task.done?}, 'clicked') do
          cb.active? ? task.done! : task.not_done!
          cb.set_tooltip_text task.to_s
        end
        cb.set_tooltip_text task.to_s
        case task.priority
        when 'A'
          cb.override_color :normal, @colorA
        when 'B'
          cb.override_color :normal, @colorB
        when 'C'
          cb.override_color :normal, @colorC
        else
          cb.override_color :normal, @colorZ
        end
      end
      @tasks_box.show_all
    end

    def get_projects
      projects = @tasks.map{|_|_.projects}.flatten.uniq.sort.map{|_|_[1..-1]}
      projects.unshift CONFIG[:Projects]
      projects.push CONFIG[:Empty]
      return projects
    end

    def get_contexts
      contexts = @tasks.map{|_|_.contexts}.flatten.uniq.sort.map{|_|_[1..-1]}
      contexts.unshift CONFIG[:Contexts]
      contexts.push CONFIG[:Empty]
      return contexts
    end

    def add_task!
      AddTaskDialog.new(@window).runs do |raw|
        begin
          task = Todo::Task.new raw
          @tasks << task
          @tasks.sort!{|a,b|b<=>a}
          do_tasks
        rescue
          puts $!
        end
      end
    end

    def finalize
      @tasks.save!
    end
  end
end
