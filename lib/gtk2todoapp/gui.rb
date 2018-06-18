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

      def set_created_on
        @created_on = Date.today
      end
    end
  end

  class DeleteTaskDialog < Such::Dialog
    def initialize(parent, text)
      super([parent: parent], :delete_task_dialog)
      Such::Label.new(child, [text], :delete_task_label)
      add_button(Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL)
      add_button(Gtk::Stock::OK, Gtk::ResponseType::OK)
    end

    def runs
      self.show_all
      response = (run==Gtk::ResponseType::OK)
      destroy
      return response
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
      response = (run==Gtk::ResponseType::OK)? @entry.text : nil
      destroy
      return response
    end
  end

  class ErrorDialog < Such::MessageDialog
    def initialize(parent)
      super([parent: parent, flags: :modal, type: :error, buttons_type: :close], :error_dialog)
    end

    def runs
      set_secondary_text $!.message
      run
      destroy
    end
  end

  class GUI
    using Refinements

    PREVIOUS_WDAY = lambda{|t,d| t - ((t.wday - d) % 7)}
    PREVIOUS_MDAY = lambda{|t,d| p=t.prev_month; Date.new(p.year, p.month, d)}
    PREVIOUS_YDAY = lambda{|t,m,d| p=t.prev_year; Date.new(p.year, m, d)}

    def resets
      today = Date.today
      @tasks.each do |task|
        next unless task.done?
        tags = task.tags
        task.not_done! if tags.key?(:daily) and task.completed_on < today
        task.not_done! if tags.key?(:weekly) and task.completed_on < PREVIOUS_WDAY[today, tags[:weekly].to_i]
        task.not_done! if tags.key?(:monthly) and task.completed_on <= PREVIOUS_MDAY[today, tags[:monthly].to_i]
        task.not_done! if tags.key?(:yearly) and task.completed_on <= PREVIOUS_YDAY[today, *tags[:yearly].split('-').map{|_|_.to_i}]
      end
    end

    def initialize(program)
      @active = true
      ### Priority Colors ###
      @colorA = Gdk::RGBA.parse(CONFIG[:ColorA])
      @colorB = Gdk::RGBA.parse(CONFIG[:ColorB])
      @colorC = Gdk::RGBA.parse(CONFIG[:ColorC])
      @colorZ = Gdk::RGBA.parse(CONFIG[:ColorZ])
      ### Data ###
      @tasks = Todo::List.new CONFIG[:TodoTxt]
      resets
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
                                    [CONFIG[:Done]],
                                    :check,
                                    'clicked'){ do_tasks }

      # Hidden
      @hidden = Such::CheckButton.new(filters_box,
                                      [CONFIG[:Hidden]],
                                      :check,
                                      'clicked'){ do_tasks }

      # Scrolled Tasks Box
      scrolled = Such::ScrolledWindow.new(vbox, :scrolled_window)
      @tasks_box = Such::Box.new(scrolled, :vbox!)
      do_tasks

      # Show All
      @window.show_all
    end

    def do_tasks
      return unless @active
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
        text = task.text.dup
        if due_on = task.due_on
          text << ": #{due_on}"
        end
        cb = Such::CheckButton.new(task_box, [text], {set_active: task.done?}, 'clicked') do
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
        eb = Such::EventBox.new(task_box, 'button_press_event') do |w,e|
          delete_task!(task) if e.button==1
        end
        Such::Image.new(eb, [stock: Gtk::Stock::DELETE])
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
      if raw = AddTaskDialog.new(@window).runs
        @active = false
        begin
          task = Todo::Task.new raw
          # Some quick validations
          tags = task.tags
          if due = tags[:due]
            raise "due: date not yyyy-mm-dd!" unless due=~/^\d\d\d\d-\d\d-\d\d$/
            Date.parse due # just checks for valid date
          end
          if daily = tags[:daily]
            raise "daily: must be 1." unless daily==1
          end
          if weekly = tags[:weekly]
            raise "weekly: must be in (0..6)." unless weekly=~/^[0123456]$/
          end
          if monthly = tags[:monthly]
            raise "montly: must be in (1..28)." unless monthly=~/^\d\d?$/ and (1..28).include?(monthly.to_i)
          end
          if yearly = tags[:yearly]
            raise "yearly: must be mm-dd." unless monthly=~/^[01]\d-[0123]\d$/
            m,d = monthly.split('-').map{|_|_.to_i}
            raise "Bad month(1..12) number in mm-dd." unless (1..12).include?(m)
            raise "Bad day(1..28) number in mm-dd." unless (1..28).include?(d)
          end
          # Auto set some values
          task.set_created_on
          # Reset the filters
          @done.set_active task.done?
          @hidden.set_active tags.key?(:h)
          @tasks << task
          @tasks.sort!{|a,b|b<=>a}
          # Projects filter
          no_project = task.projects.empty? 
          @projects.remove_all unless no_project
          project = no_project ? CONFIG[:Empty] : task.projects.first[1..-1]
          project_index = 0
          get_projects.each_with_index do |p,i|
            project_index = i if project==p
            @projects.append_text(p) unless no_project
          end
          @projects.set_active project_index
          # Contexts filter
          no_context = task.contexts.empty? 
          @contexts.remove_all unless no_context
          context = no_context ? CONFIG[:Empty] : task.contexts.first[1..-1]
          context_index = 0
          get_contexts.each_with_index do |c,i|
            context_index = i if context==c
            @contexts.append_text(c) unless no_context
          end
          @contexts.set_active context_index
          # Redo tasks list
          @active = true
          do_tasks
        rescue
          ErrorDialog.new(@window).runs
        ensure
          @active = true
        end
      end
    end

    def delete_task!(task)
      if DeleteTaskDialog.new(@window, task.text).runs
        s = task.to_s
        @tasks.delete_if{|t| t.to_s==s}
        do_tasks
      end
    end

    def finalize
      @tasks.save!
    end
  end
end
