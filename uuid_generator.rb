#!/usr/bin/env rubyw

def load_lib(lib_name, gem_name)
	begin
		require lib_name
  rescue LoadError
    error_message = "Gem '#{gem_name}' missing.\nInstall it via 'gem install #{gem_name}'"
    begin
      require 'win32api'
      messageBox = Win32API.new('user32', 'MessageBox', ['L', 'P', 'P', 'L'], 'I')
      messageBox.call(0, error_message, "Missing requirement", 0x00000010)
    rescue LoadError
      STDERR.puts error_message
    end
		exit 1
	end
end

load_lib 'gtk3', 'gtk3'
require 'securerandom'

@max_history = 5;

@uuids = []

def generate_uuid
  uuid = SecureRandom.uuid
  puts "test"
  Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD).set_text(uuid)
  puts "test2"
  @uuids.insert(0, uuid)  
  @uuids = @uuids.slice(0, @max_history)
end

def create_history_sub_menu()
  submenu = Gtk::Menu.new
  history = Gtk::MenuItem.new(:label => 'History')
  history.set_submenu(submenu)
  @uuids.each_index { |index|
    old_uuid = @uuids[index]
    uuid_entry = Gtk::ImageMenuItem.new(:label => "(#{index+1}) #{old_uuid}")
    uuid_entry.signal_connect('activate') {
      Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD).set_text(old_uuid) 
    }
    submenu.append(uuid_entry)
  }
  if (@uuids.empty?)
    empty_entry = Gtk::ImageMenuItem.new(:label => '<<EMPTY>>')
    empty_entry.sensitive = false
    submenu.append(empty_entry)
  else 
    submenu.append(Gtk::SeparatorMenuItem.new)
    clear_entry = Gtk::ImageMenuItem.new(:label => 'Clear history')
    clear_entry.signal_connect('activate') {
      @uuids.clear
    }
    submenu.append(clear_entry)
  end
  return history
end

def create_menu()
  menu = Gtk::Menu.new

  generate = Gtk::ImageMenuItem.new(:label => 'Generate UUID')
  generate.signal_connect('activate') {
    generate_uuid
  }
  menu.append(generate)

  history = create_history_sub_menu()
  menu.append(history)

  menu.append(Gtk::SeparatorMenuItem.new)

  quit = Gtk::ImageMenuItem.new(:label => 'Exit')
  quit.signal_connect('activate') {
    Gtk.main_quit
  }
  menu.append(quit)

  menu.show_all
  return menu
end

tray              = Gtk::StatusIcon.new
tray.stock        = Gtk::Stock::COLOR_PICKER
tray.pixbuf       = GdkPixbuf::Pixbuf.new(:file => 'uuid_generator.png')
tray.tooltip_text = 'UUID Generator'

tray.signal_connect('activate'){ |icon|
  generate_uuid
}
tray.signal_connect('popup-menu') { |icon, button, time|
  menu = create_menu
  menu.popup(nil, nil, button, time)
}

Gtk.main
