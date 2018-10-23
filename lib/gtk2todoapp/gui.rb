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

      def cycle_up!
        if @priority.nil? or @priority>'C'
          @priority = 'C'
        elsif @priority<'B'
          @priority = nil
        else
          @priority = (priority.ord-1).chr
        end
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

  class EditTaskDialog < Such::Dialog
    def initialize(parent, text='')
      super([parent: parent], :edit_task_dialog)
      @entry = Such::Entry.new(child, {set_text: text}, :edit_task_entry)
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

    CMP = lambda do |a,b|
      cmp,x,y = 0,nil,nil
      [:completed_on, :priority, :due_on, :created_on, :text].each do |m|
        case m
        when :completed_on, :created_on
          x,y = (b.method(m).call || '~').to_s, (a.method(m).call || '~').to_s
        when :due_on
          x,y = (a.method(m).call || '~').to_s, (b.method(m).call || '~').to_s
        else
          x,y = (a.method(m).call || '~'), (b.method(m).call || '~')
        end
        cmp = x<=>y
        break unless cmp==0
      end
      cmp
    end

    TSK = lambda do |task|
      "#{task.done? ? 'x' : ' '} #{task.text}"
    end

    def resets
      today = Date.today
      @tasks.each do |task|
        next unless task.done?
        tags = task.tags
        task.not_done! if tags.key?(:restart)
        task.not_done! if tags.key?(:daily) and task.completed_on < today
        task.not_done! if tags.key?(:weekly) and task.completed_on < PREVIOUS_WDAY[today, tags[:weekly].to_i]
        task.not_done! if tags.key?(:monthly) and task.completed_on <= PREVIOUS_MDAY[today, tags[:monthly].to_i]
        task.not_done! if tags.key?(:yearly) and task.completed_on <= PREVIOUS_YDAY[today, *tags[:yearly].split('-').map{|_|_.to_i}]
        task.not_done! if tags.key?(:reset) and (task.completed_on + tags[:reset].to_i) <= today
      end
    end

    def escalate
      today = Date.today
      @tasks.each do |task|
        next if task.done?
        next unless task.priority.nil? or task.priority <= 'C'
        if due_on = task.due_on
          task.cycle_up! if (due_on - today).to_i < CONFIG[:EscalateDays]
        end
      end
    end

    def initialize(program)
      @active = true

      ### Priority Colors ###
      @colorA = Gdk::RGBA.parse(CONFIG[:ColorA])
      @colorB = Gdk::RGBA.parse(CONFIG[:ColorB])
      @colorC = Gdk::RGBA.parse(CONFIG[:ColorC])
      @colorZ = Gdk::RGBA.parse(CONFIG[:ColorZ])
      @late = Gdk::RGBA.parse(CONFIG[:Late])

      ### Data ###
      todo_txt=CONFIG[:TodoTxt]
      File.write(todo_txt, "(A) Gtk2TodoApp +Tasks @PC") unless File.exist?(todo_txt)
      @tasks = Todo::List.new todo_txt
      resets
      escalate
      @tasks.sort!{|a,b|CMP[a,b]}

      ### Scaffolding ###
      @window,@minime,menu = program.window,program.mini_menu,program.app_menu
      menu.each{|_|_.destroy if _.key==:fs!}
      menu.add_menu_item(:save!){ @tasks.save! }
      menu.add_menu_item(:add_task!){ add_task! }
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

      # Priority
      @important = Such::CheckButton.new(filters_box,
                                    [CONFIG[:Important]],
                                    :important_check_box,
                                    'clicked'){ do_tasks }

      # Done
      @hidden = Such::CheckButton.new(filters_box,
                                    [CONFIG[:Hidden]],
                                    :hidden_check_box,
                                    'clicked'){ do_tasks }

      # Scrolled Tasks Box
      scrolled = Such::ScrolledWindow.new(vbox, :scrolled_window)
      @tasks_box = Such::Box.new(scrolled, :vbox!)
      do_tasks

      # Show All
      @window.show_all
    end

    def get_color(task)
      if task.overdue?
        @late
      else
        case task.priority
        when 'A'
          @colorA
        when 'B'
          @colorB
        when 'C'
          @colorC
        else
          @colorZ
        end
      end
    end

    def do_tasks
      return unless @active

      # Clear displays
      @tasks_box.each{|_|_.destroy}
      @minime.each{|_|_.destroy}

      today = Date.today
      @tasks.each do |task|
        next if task.priority.nil? and @important.active?

        # Include done?
        due_on = task.due_on
        unless @hidden.active?
          next if task.done?
          next if due_on and (due_on - today).to_i > CONFIG[:HiddenDays]
        end

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
        item = nil # <= reserve this variable to be set later, but to used next...
        task_box = Such::Box.new(@tasks_box, :hbox!)

        # Check List Item
        text = task.text.dup
        text << ": #{due_on}" if due_on
        cb = Such::CheckButton.new(task_box,
                                   [text],
                                   :task_check_button,
                                   {set_active: task.done?},
                                   'clicked') do
          if cb.active?
            task.done!
          else
            task.not_done!
          end
          cb.set_tooltip_text task.to_s
          item.set_label TSK[task]
        end
        cb.set_tooltip_text task.to_s

        # Set Color
        color = get_color(task)
        cb.override_color :normal, color

        # Increment Priority Image Button
        ebu = Such::EventBox.new(task_box, 'button_press_event') do |w,e|
          task.cycle_up!  if e.button==1
          @tasks.sort!{|a,b|CMP[a,b]}
          do_tasks
        end
        Such::Image.new(ebu, [stock: Gtk::Stock::GO_UP], :stock_image)

        # Edit Task Image Button
        ebe = Such::EventBox.new(task_box, 'button_press_event') do |w,e|
          edit_task!(task) if e.button==1
        end
        Such::Image.new(ebe, [stock: Gtk::Stock::EDIT], :stock_image)

        # Delete Task Image Button
        ebd = Such::EventBox.new(task_box, 'button_press_event') do |w,e|
          delete_task!(task) if e.button==1
        end
        Such::Image.new(ebd, [stock: Gtk::Stock::DELETE], :stock_image)

        # Rebuild MiniMe Menu Items
        item = Such::MenuItem.new([label: TSK[task]], :minime_menu_item, 'activate') do
          if task.done?
            task.not_done!
            cb.set_active(false)
          else
            task.done!
            cb.set_active(true)
          end
          item.set_label TSK[task]
        end
        item.override_color :normal, color
        @minime.append(item)
      end

      # Show All
      @tasks_box.show_all
      @minime.show_all
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

    def new_task(raw)
      task = Todo::Task.new raw
      # Some quick validations
      tags = task.tags
      if due = tags[:due]
        raise "due: date not yyyy-mm-dd!" unless due=~/^\d\d\d\d-\d\d-\d\d$/
        Date.parse due # just checks for valid date
      end
      if restart = tags[:restart]
        raise "restart: must be 1." unless restart=='1'
      end
      if daily = tags[:daily]
        raise "daily: must be 1." unless daily=='1'
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
      if reset = tags[:reset]
        raise "reset: must be an integer greater than zero." unless reset=~/^[123456789]\d*$/
      end
      # Auto set some values
      task.set_created_on
      return task
    end

    def reset_filters(task)
      # Reset the filters
      @hidden.set_active true if task.done?
      @important.set_active false if task.priority.nil?

      # Projects filter
      project_index = (@projects.active==0) ? 0 : nil
      project = task.projects.empty?  ? CONFIG[:Empty] : task.projects.first[1..-1]
      @projects.remove_all
      get_projects.each_with_index do |p,i|
        project_index = i if project_index.nil? and project==p
        @projects.append_text(p)
      end
      @projects.set_active project_index

      # Contexts filter
      context_index = (@contexts.active==0) ? 0 : nil
      context = task.contexts.empty?  ? CONFIG[:Empty] : task.contexts.first[1..-1]
      @contexts.remove_all
      get_contexts.each_with_index do |c,i|
        context_index = i if context_index.nil? and context==c
        @contexts.append_text(c)
      end
      @contexts.set_active context_index
    end

    def _add_task(task)
      @tasks << task
      @tasks.sort!{|a,b|CMP[a,b]}
      reset_filters(task)
    end

    def add_task!
      if raw = EditTaskDialog.new(@window).runs
        @active = false
        begin
          task = new_task(raw)
          _add_task(task)
          @active = true
          do_tasks
        rescue
          ErrorDialog.new(@window).runs
        ensure
          @active = true
        end
      end
    end

    def edit_task!(task)
      s = task.to_s
      if raw = EditTaskDialog.new(@window, s).runs
        @active = false
        begin
          task = new_task(raw)
          @tasks.delete_if{|t| t.to_s==s}
          _add_task(task)
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

    def truncate_archive
      done_txt,lines = CONFIG[:DoneTxt],CONFIG[:ArchiveLines]
      if `wc -l #{done_txt}`.to_i > lines
        if system "tail -n #{lines} #{done_txt} > #{done_txt}.tail"
          system "mv #{done_txt}.tail #{done_txt}"
        end
      end
    end

    def archive(fh)
      today, archive_days, appended = Date.today, CONFIG[:ArchiveDays].to_i, false
      @tasks.delete_if do |task|
        deletes = false
        # If done and old...
        if task.done? and (today - task.completed_on).to_i > archive_days
          tags = task.tags
          # Unless re-accurring...
          unless [:daily, :weekly, :monthly, :yearly].any?{|_|tags.key?(_)}
            # Then archive done tasks!
            fh.puts task.to_s
            deletes = true
            appended ||= true
          end
        end
        deletes
      end
      truncate_archive if appended
    end

    def finalize
      File.open(CONFIG[:DoneTxt], 'a'){|fh| archive(fh)}
      @tasks.save!
    end
  end
end
