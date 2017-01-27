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

match 'access_tickets', :controller => 'itickets', :action => 'show_at_project', :via => :get

match '/access_tickets/access_templates', :controller => 'iaccesses', :action => 'access_templates', :via => :get

match '/access_tickets/accesses_list', :controller => 'iaccesses', :action => 'accesses_list', :via => :get

match '/access_tickets/show_accesses', :controller => 'iaccesses', :action => 'show_accesses', :via => :post

match '/access_tickets/show_resources_list', :controller => 'iresources', :action => 'show_resources_list', :via => :post

match '/access_tickets/resources_list', :controller => 'iresources', :action => 'resources_list', :via => :get

match '/access_tickets/edit_resource/add_role', :controller => 'iroles', :action => 'add_role', :via => :post

match '/access_tickets/edit_resource/edit_role', :controller => 'iroles', :action => 'edit_role', :via => :post

match '/access_tickets/edit_resource/remove_role', :controller => 'iroles', :action => 'remove_role', :via => :post

match '/issues/access_tickets', :controller => 'itickets', :action => 'show_at_project', :via => :get

match '/access_tickets/set_base_config', :controller => 'isettings', :action => 'set_base_config', :via => :get

match '/access_tickets/reset_config', :controller => 'isettings', :action => 'reset_config', :via => :get

match '/access_tickets/available_users', :controller => 'iaccesses', :action => 'available_users', :via => :post

match '/access_tickets/show_resources_list', :controller => 'iresources', :action => 'show_resources_list', :via => :post

match '/access_tickets/save_resource', :controller => 'iresources', :action => 'save_resource', :via => :post

match '/access_tickets/add_resource', :controller => 'iresources', :action => 'add_resource', :via => :post

match '/access_tickets/show_resource/ientity_show_list', :controller => 'ientities', :action => 'ientity_show_list', :via => :post

match '/access_tickets/show_resource/export_entities', :controller => 'ientities', :action => 'export_entities', :via => :get

match '/access_tickets/edit_resource/import_entities', :controller => 'ientities', :action => 'import_entities', :via => :post

match '/access_tickets/show_role_description', :controller => 'iroles', :action => 'show_role_description', :via => :post

match '/access_tickets/show_role', :controller => 'iroles', :action => 'show_role', :via => :post

match '/access_tickets/edit_resource/add_entity', :controller => 'ientities', :action => 'add_entity', :via => :post

match '/access_tickets/edit_resource/save_entity', :controller => 'ientities', :action => 'save_entity', :via => :post

match '/access_tickets/edit_resource/remove_entity', :controller => 'ientities', :action => 'remove_entity', :via => :post

match '/access_tickets/edit_resource/set_granters', :controller => 'iresources', :action => 'set_granters', :via => :post

match '/access_tickets/edit_resource/set_owners', :controller => 'iresources', :action => 'set_owners', :via => :post

match '/access_tickets/edit_resource/set_has_entities', :controller => 'iresources', :action => 'set_has_entities', :via => :post

match '/access_tickets/edit_resource/set_has_ip', :controller => 'iresources', :action => 'set_has_ip', :via => :post

match '/access_tickets/edit_resource/set_groups_availability', :controller => 'iresources', :action => 'set_groups_availability', :via => :post

match '/access_tickets/show_resource/groups_availability', :controller => 'iresources', :action => 'groups_availability', :via => :post

match '/access_tickets/show_resource', :controller => 'iresources', :action => 'show_resource', :via => :post

match '/access_tickets/edit_resource', :controller => 'iresources', :action => 'edit_resource', :via => :post

match '/access_tickets/remove_resource', :controller => 'iresources', :action => 'remove_resource', :via => :post

match '/settings/plugin/access_tickets_iresources/show', :controller => 'iresources', :action => 'ir_show', :via => :post

match '/settings/plugin/access_tickets_iresources/add', :controller => 'iresources', :action => 'ir_add', :via => :post

match '/settings/plugin/access_tickets_iresources/edit', :controller => 'iresources', :action => 'ir_edit', :via => :post

match '/settings/plugin/access_tickets_iresources/remove', :controller => 'iresources', :action => 'ir_remove', :via => :post

match '/settings/plugin/access_tickets_iresources/show_details', :controller => 'iresources', :action => 'show_details', :via => :post

match '/access_tickets/resources_list', :controller => 'iresources', :action => 'resources_list', :via => :get

match '/settings/plugin/access_tickets_isettings/set_settings_value', :controller => 'isettings', :action => 'set_settings_value', :via => :post

match '/settings/plugin/access_tickets_isettings/show_group_details', :controller => 'isettings', :action => 'show_group_details', :via => :post

match '/settings/plugin/access_tickets_isettings/set_group_liders', :controller => 'isettings', :action => 'set_group_liders', :via => :post

match '/settings/plugin/access_tickets_isettings/set_group_templates', :controller => 'isettings', :action => 'set_group_templates', :via => :post

match '/issues/access_tickets/edit_revoking_table', :controller => 'iaccesses', :action => 'edit_revoking_table', :via => :post

match '/issues/access_tickets/edit_revoking_table/save', :controller => 'iaccesses', :action => 'save_revoking_table', :via => :post

match '/issues/access_tickets/show_last_users', :controller => 'itickets', :action => 'show_last_users', :via => :post

match '/issues/access_tickets/edit_ticket_table', :controller => 'itickets', :action => 'edit_ticket_table', :via => :post

match '/issues/access_tickets/edit_ticket_table_ta', :controller => 'itickets', :action => 'edit_ticket_table_ta', :via => :post

match '/issues/access_tickets/edit_ticket_table/save_ta', :controller => 'itickets', :action => 'edit_ticket_table_save_ta', :via => :post

match '/issues/access_tickets/edit_retiming_table', :controller => 'iretimeaccesses', :action => 'edit_retiming_table', :via => :post

match '/issues/access_tickets/edit_retiming_table/save', :controller => 'iretimeaccesses', :action => 'save_retiming_table', :via => :post

match '/issues/access_tickets/verify_retiming', :controller => 'iretimeaccesses', :action => 'verify_retiming', :via => :get

match '/issues/access_tickets/reject_retiming', :controller => 'iretimeaccesses', :action => 'reject_retiming', :via => :get

match '/issues/access_tickets/approve_retiming', :controller => 'iretimeaccesses', :action => 'approve_retiming', :via => :get

match '/issues/access_tickets/revoke_retiming', :controller => 'iretimeaccesses', :action => 'revoke_retiming', :via => :get

match '/issues/access_tickets/verify_template', :controller => 'iticktemplates', :action => 'verify_template', :via => :get

match '/issues/access_tickets/reject_template', :controller => 'iticktemplates', :action => 'reject_template', :via => :get

match '/issues/access_tickets/approve_template', :controller => 'iticktemplates', :action => 'approve_template', :via => :get

match '/issues/access_tickets/revoke_template', :controller => 'iticktemplates', :action => 'revoke_template', :via => :get

match '/access_tickets/set_issue_template', :controller => 'iticktemplates', :action => 'set_issue_template', :via => :get

match '/access_tickets/show_template', :controller => 'iticktemplates', :action => 'show_template', :via => :post

match '/access_tickets/remove_template', :controller => 'iticktemplates', :action => 'remove_template', :via => :post

match '/access_tickets/add_template', :controller => 'iticktemplates', :action => 'add_template', :via => :post

match '/access_tickets/edit_template', :controller => 'iticktemplates', :action => 'edit_template', :via => :post

match '/access_tickets/save_template', :controller => 'iticktemplates', :action => 'save_template', :via => :post

match '/issues/access_tickets/edit_ticket_table/add_row', :controller => 'itickets', :action => 'edit_ticket_table_add_row', :via => :post

match '/issues/access_tickets/edit_ticket_table/save', :controller => 'itickets', :action => 'edit_ticket_table_save', :via => :post

match '/issues/access_tickets/edit_ticket_table/show', :controller => 'itickets', :action => 'ticket_table_show', :via => :post

match '/issues/access_tickets/edit_ticket_table/show_version', :controller => 'itickets', :action => 'ticket_table_show_version', :via => :post

match '/issues/access_tickets/edit_ticket_table/set_tickets_user', :controller => 'itickets', :action => 'set_tickets_user', :via => :get

match '/issues/access_tickets/approve_tickets', :controller => 'itickets', :action => 'approve_tickets', :via => :get

match '/issues/access_tickets/revoke_tickets', :controller => 'itickets', :action => 'revoke_tickets', :via => :get

match '/issues/access_tickets/verify_tickets', :controller => 'itickets', :action => 'verify_tickets', :via => :get

match '/issues/access_tickets/reject_tickets', :controller => 'itickets', :action => 'reject_tickets', :via => :get

match '/issues/access_tickets/verify_tickets', :controller => 'itickets', :action => 'verify_tickets', :via => :post

match '/issues/access_tickets/reject_tickets', :controller => 'itickets', :action => 'reject_tickets', :via => :post

match '/access_tickets/access_templates', :controller => 'iaccesses', :action => 'access_templates', :via => :get

match '/access_tickets/accesses_list', :controller => 'iaccesses', :action => 'accesses_list', :via => :get

match '/access_tickets/show_accesses', :controller => 'iaccesses', :action => 'show_accesses', :via => :post

match '/issues/access_tickets/show_group_templates', :controller => 'iticktemplates', :action => 'show_group_templates', :via => :post

match '/issues/access_tickets/show_template_versions', :controller => 'iticktemplates', :action => 'show_template_versions', :via => :post

match '/issues/access_tickets/set_dismissal_user', :controller => 'iaccesses', :action => 'set_dismissal_user', :via => :get

match '/issues/access_tickets/grant_access', :controller => 'iaccesses', :action => 'grant_access', :via => :get

match '/issues/access_tickets/revoke_grant', :controller => 'iaccesses', :action => 'revoke_grant', :via => :get

match '/issues/access_tickets/grant_single_access', :controller => 'iaccesses', :action => 'grant_single_access', :via => :post

match '/issues/access_tickets/revoke_single_grant', :controller => 'iaccesses', :action => 'revoke_single_grant', :via => :post

match '/issues/access_tickets/confirm_access', :controller => 'iaccesses', :action => 'confirm_access', :via => :get

match '/issues/access_tickets/revoke_confirmation', :controller => 'iaccesses', :action => 'revoke_confirmation', :via => :get

match '/issues/access_tickets/confirm_revoking', :controller => 'iaccesses', :action => 'confirm_revoking', :via => :get

match '/issues/access_tickets/refuse_confirmation_revoking', :controller => 'iaccesses', :action => 'refuse_confirmation_revoking', :via => :get

match '/issues/access_tickets/deactivate_grants', :controller => 'iaccesses', :action => 'deactivate_grants', :via => :get

match '/issues/access_tickets/refuse_deactivating_grants', :controller => 'iaccesses', :action => 'refuse_deactivating_grants', :via => :get

match '/issues/access_tickets/deactivate_single_grant', :controller => 'iaccesses', :action => 'deactivate_grants', :via => :post

match '/issues/access_tickets/activate_single_grant', :controller => 'iaccesses', :action => 'refuse_deactivating_grants', :via => :post
