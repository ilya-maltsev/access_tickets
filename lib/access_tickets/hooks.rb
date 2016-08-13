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


module Access_Tickets
    class Hooks  < Redmine::Hook::ViewListener

      def view_issues_show_description_bottom(context={})
        if context[:issue].project_id == ISetting.active.where(:param => "at_project_id").first.value.to_i
          if context[:issue].tracker_id == ISetting.active.where(:param => "tr_grant_id").first.value.to_i
            context[:issue][:at_granting_status] =  ITicket.check_issue_status(context[:issue].id, User.current.id)
            context[:controller].send(:render_to_string, :partial => 'ticket_table/table_issue_grant', :locals => context)
          else
            if context[:issue].tracker_id == ISetting.active.where(:param => "tr_revoke_id").first.value.to_i || context[:issue].tracker_id == ISetting.active.where(:param => "tr_dismissal_id").first.value.to_i
              context[:issue][:at_revoking_status] = IAccess.check_revoking_status(context[:issue].id, User.current.id)
              context[:controller].send(:render_to_string, :partial => 'ticket_table/table_issue_revoke', :locals => context)
            end
          end
        end
      end

      #def view_issues_new_top(context={})
      #  context[:controller].send(:render_to_string, :partial => 'ticket_table/table_new_issue', :locals => context)
      #end

    end
end
