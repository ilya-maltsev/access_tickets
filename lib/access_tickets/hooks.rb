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


      def controller_issues_new_before_save(context)
        autoset_watchers(context)
      end

      def autoset_watchers(context)
        if context[:params][:issue] && ISetting.check_config()
          if context[:issue].project_id == ISetting.active.where(:param => "at_project_id").first.value.to_i
            settings = ISetting.get_plugin_config()
            group_ids = []
            if context[:issue].tracker_id.in?([settings["tr_grant_id"], settings["tr_revoke_id"]])
              group_ids = [settings["admin_group_id"],settings["sec_group_id"],settings["cw_group_id"]]
            end
            group_ids.each do |group_id|
              context[:issue].watcher_user_ids = context[:issue].watcher_user_ids | User.active.in_group(group_id).map(&:id)
            end
            context[:issue].watcher_user_ids = context[:issue].watcher_user_ids.push(context[:issue].author_id)
          end
        end
      end

      def view_issues_show_description_bottom(context={})
        if context[:issue].project_id == ISetting.active.where(:param => "at_project_id").first.value.to_i
          if context[:issue].tracker_id == ISetting.active.where(:param => "tr_grant_id").first.value.to_i
            at_granting_status =  ITicket.check_issue_status(context[:issue].id, User.current.id)
            context[:controller].send(:render_to_string, :partial => 'ticket_table/table_issue_grant', :locals => {:context => context, :at_granting_status => at_granting_status})
          else
            if context[:issue].tracker_id == ISetting.active.where(:param => "tr_revoke_id").first.value.to_i || context[:issue].tracker_id == ISetting.active.where(:param => "tr_dismissal_id").first.value.to_i
              at_revoking_status = IAccess.check_revoking_status(context[:issue].id, User.current.id)
              context[:controller].send(:render_to_string, :partial => 'ticket_table/table_issue_revoke', :locals => {:context => context, :at_revoking_status => at_revoking_status})
            end
          end
        end
      end

    end
end
