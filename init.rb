# This file is a part of Access tickets plugin,
# access management plugin for Redmine
#
# Copyright (C) 2016 Ilya Maltsev
# email: i.y.maltsev@yandex.ru
#
# access_tickets is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# access_tickets is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with access_tickets.  If not, see <http://www.gnu.org/licenses/>.


require 'access_tickets/hooks'



ACCESS_TICKETS_VERSION_TYPE = "1.1.7"

Redmine::Plugin.register :access_tickets do
  name 'Access tickets' 
  author 'Maltsev Ilya' 
  description 'Access management plugin for Redmine'
  version ACCESS_TICKETS_VERSION_TYPE
  url 'https://github.com/iymaltsev/access_tickets/'
  author_url 'mailto:i.y.maltsev@yandex.ru'
  settings :partial => '/isettings/at_settings', :default => {} 

  Redmine::MenuManager.map :top_menu do |menu|

    menu.push(:access_tickets, 
    {:controller => 'itickets', :action => 'show_at_project'}, 
    {
      :html => {:class => 'icon icon-roles'},
      :caption => :at_access_tickets,
      :if => Proc.new{ISetting.plugin_settings_ermi != 0 && ISetting.check_config()}
    })


    menu.push(:at_my_access_parent, 
    {:controller => 'iaccesses', :action => 'accesses_list'}, 
    {
      :parent => :access_tickets,
      :caption => :at_access_list,
      :if => Proc.new{ISetting.plugin_settings_ermi != 0}
    })

    menu.push(:at_resources_list_parent, 
    {:controller => 'iresources', :action => 'resources_list'}, 
    {
      :parent => :access_tickets,
      :caption => :at_resources_list,
      :if => Proc.new{ISetting.plugin_settings_ermi != 0}
    })


    menu.push(:access_tickets_no_parent, 
    {:controller => 'itickets', :action => 'show_at_project'}, 
    {
      :html => {:class => 'icon icon-roles'},
      :caption => :at_access_tickets,
      :if => Proc.new{ISetting.plugin_settings_ermi != 1 && ISetting.check_config()}
    })


    menu.push(:at_my_access, 
    {:controller => 'iaccesses', :action => 'accesses_list'}, 
    {
      :caption => :at_access_list,
      :if => Proc.new{ISetting.plugin_settings_ermi != 1 && ISetting.check_config()}
    })

    menu.push(:at_resources_list, 
    {:controller => 'iresources', :action => 'resources_list'}, 
    {
      :caption => :at_resources_list,
      :if => Proc.new{ISetting.plugin_settings_ermi != 1 && ISetting.check_config()}
    })


end

end

