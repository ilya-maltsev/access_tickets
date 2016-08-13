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


get '/issues/access_tickets', :to => 'itickets#show_at_project', :as => 'show_at_project'

get '/access_tickets/set_base_config', :to  => 'isettings#set_base_config', :as => 'set_base_config'
post '/access_tickets/available_users', :to => 'iaccesses#available_users', :as => 'available_users'
post '/access_tickets/show_resources_list', 'iresources#show_resources_list', :as => 'show_resources_list'

post '/access_tickets/save_resource', :to => 'iresources#save_resource', :as => 'save_resource'
post '/access_tickets/add_resource', :to => 'iresources#add_resource', :as => 'add_resource'

post '/access_tickets/show_resource/ientity_show_list', :to => 'ientities#ientity_show_list', :as => 'ientity_show_list'
get '/access_tickets/show_resource/export_entities', :to => 'ientities#export_entities', :as => 'export_entities'
post '/access_tickets/edit_resource/import_entities', :to => 'ientities#import_entities', :as => 'import_entities'

post '/access_tickets/show_role_description', :to => 'iroles#show_role_description', :as => 'show_role_description'
post '/access_tickets/show_role', :to => 'iroles#show_role', :as => 'show_role'

post '/access_tickets/edit_resource/add_entity', :to => 'ientities#add_entity', :as => 'add_entity'
post '/access_tickets/edit_resource/save_entity', :to => 'ientities#save_entity', :as => 'save_entity'
post '/access_tickets/edit_resource/remove_entity', :to => 'ientities#remove_entity', :as => 'remove_entity'


post '/access_tickets/edit_resource/set_granters', :to => 'iresources#set_granters', :as => 'set_granters'

post '/access_tickets/edit_resource/set_owners', :to => 'iresources#set_owners', :as => 'set_owners'

post '/access_tickets/edit_resource/set_has_entities', :to => 'iresources#set_has_entities', :as => 'set_has_entities'

post '/access_tickets/edit_resource/set_has_ip', :to => 'iresources#set_has_ip', :as => 'set_has_ip'

post '/access_tickets/edit_resource/set_groups_availability', :to => 'iresources#set_groups_availability', :as => 'set_groups_availability'

post '/access_tickets/show_resource/groups_availability', :to => 'iresources#groups_availability', :as => 'groups_availability'

post '/access_tickets/show_resource', :to => 'iresources#show_resource', :as => 'show_resource'

post '/access_tickets/edit_resource', :to => 'iresources#edit_resource', :as => 'edit_resource'

post '/access_tickets/remove_resource', :to => 'iresources#remove_resource', :as => 'remove_resource'


post '/settings/plugin/access_tickets_iresources/show', :to => 'iresources#ir_show', :as => 'ir_show'
post '/settings/plugin/access_tickets_iresources/add', :to => 'iresources#ir_add', :as => 'ir_add'
post '/settings/plugin/access_tickets_iresources/edit', :to => 'iresources#ir_edit', :as => 'ir_edit'
post '/settings/plugin/access_tickets_iresources/remove', :to => 'iresources#ir_remove', :as => 'ir_remove'
post '/settings/plugin/access_tickets_iresources/show_details', :to => 'iresources#show_details', :as => 'show_details'


get  '/access_tickets/resources_list', 'iresources#resources_list', :as => 'resources_list'

post '/settings/plugin/access_tickets_isettings/set_settings_value', :to => 'isettings#set_settings_value', :as => 'set_settings_value'

post '/settings/plugin/access_tickets_isettings/show_group_details', :to => 'isettings#show_group_details', :as => 'show_group_details'
post '/settings/plugin/access_tickets_isettings/set_group_liders', :to => 'isettings#set_group_liders', :as => 'set_group_liders'
post '/settings/plugin/access_tickets_isettings/set_group_templates', :to => 'isettings#set_group_templates', :as => 'set_group_templates'

post '/issues/access_tickets/edit_revoking_table', :to => 'iaccesses#edit_revoking_table', :as => 'edit_revoking_table'
post '/issues/access_tickets/edit_revoking_table/save', :to => 'iaccesses#save_revoking_table', :as => 'save_revoking_table'
post '/issues/access_tickets/show_last_users', :to => 'itickets#show_last_users', :as => 'show_last_users'
post '/issues/access_tickets/edit_ticket_table', :to => 'itickets#edit_ticket_table', :as => 'edit_ticket_table'
post '/issues/access_tickets/edit_ticket_table_ta', :to => 'itickets#edit_ticket_table_ta', :as => 'edit_ticket_table_ta'
post '/issues/access_tickets/edit_ticket_table/save_ta', :to => 'itickets#edit_ticket_table_save_ta', :as => 'edit_ticket_table_save_ta'

post '/issues/access_tickets/edit_retiming_table', :to => 'iretimeaccesses#edit_retiming_table', :as => 'edit_retiming_table'
post '/issues/access_tickets/edit_retiming_table/save', :to => 'iretimeaccesses#save_retiming_table', :as => 'save_retiming_table'


get '/issues/access_tickets/verify_retiming', :to => 'iretimeaccesses#verify_retiming', :as => 'verify_retiming'
get '/issues/access_tickets/reject_retiming', :to => 'iretimeaccesses#reject_retiming', :as => 'reject_retiming'

get '/issues/access_tickets/approve_retiming', :to => 'iretimeaccesses#approve_retiming', :as => 'approve_retiming'
get '/issues/access_tickets/revoke_retiming', :to => 'iretimeaccesses#revoke_retiming', :as => 'revoke_retiming'


get '/issues/access_tickets/verify_template', :to => 'iticktemplates#verify_template', :as => 'verify_template'
get '/issues/access_tickets/reject_template', :to => 'iticktemplates#reject_template', :as => 'reject_template'

get '/issues/access_tickets/approve_template', :to => 'iticktemplates#approve_template', :as => 'approve_template'
get '/issues/access_tickets/revoke_template', :to => 'iticktemplates#revoke_template', :as => 'revoke_template'

get '/access_tickets/set_issue_template',:to => 'iticktemplates#set_issue_template', :as => 'set_issue_template'

post '/access_tickets/show_template',:to => 'iticktemplates#show_template', :as => 'show_template'
post '/access_tickets/remove_template',:to => 'iticktemplates#remove_template', :as => 'remove_template'
post '/access_tickets/add_template',:to => 'iticktemplates#add_template', :as => 'add_template'
post '/access_tickets/edit_template',:to => 'iticktemplates#edit_template', :as => 'edit_template'
post '/access_tickets/save_template',:to => 'iticktemplates#save_template', :as => 'save_template'



post '/issues/access_tickets/edit_ticket_table/add_row', :to => 'itickets#edit_ticket_table_add_row', :as => 'edit_ticket_table_add_row'
post '/issues/access_tickets/edit_ticket_table/save', :to => 'itickets#edit_ticket_table_save', :as => 'edit_ticket_table_save'
post '/issues/access_tickets/edit_ticket_table/show', :to => 'itickets#ticket_table_show', :as => 'ticket_table_show'
post '/issues/access_tickets/edit_ticket_table/show_version', :to => 'itickets#ticket_table_show_version', :as => 'ticket_table_show_version'
get '/issues/access_tickets/edit_ticket_table/set_tickets_user', :to => 'itickets#set_tickets_user', :as => 'set_tickets_user'

get '/issues/access_tickets/approve_tickets', :to => 'itickets#approve_tickets', :as => 'approve_tickets'
get '/issues/access_tickets/revoke_tickets', :to => 'itickets#revoke_tickets', :as => 'revoke_tickets'

get '/issues/access_tickets/verify_tickets', :to => 'itickets#verify_tickets', :as => 'verify_tickets'
get '/issues/access_tickets/reject_tickets', :to => 'itickets#reject_tickets', :as => 'reject_tickets'

post '/issues/access_tickets/verify_tickets', :to => 'itickets#verify_tickets', :as => 'verify_tickets'
post '/issues/access_tickets/reject_tickets', :to => 'itickets#reject_tickets', :as => 'reject_tickets'

get  '/access_tickets/access_templates', 'iaccesses#access_templates', :as => 'access_templates'

get  '/access_tickets/accesses_list', 'iaccesses#accesses_list', :as => 'accesses_list'

post '/access_tickets/show_accesses', 'iaccesses#show_accesses', :as => 'show_accesses'


post '/issues/access_tickets/show_group_templates', :to => 'iticktemplates#show_group_templates', :as => 'show_group_templates'

post '/issues/access_tickets/show_template_versions', :to => 'iticktemplates#show_template_versions', :as => 'show_template_versions'



get '/issues/access_tickets/set_dismissal_user', :to => 'iaccesses#set_dismissal_user', :as => 'set_dismissal_user'

get '/issues/access_tickets/grant_access', :to => 'iaccesses#grant_access', :as => 'grant_access'
get '/issues/access_tickets/revoke_grant', :to => 'iaccesses#revoke_grant', :as => 'revoke_grant'

post '/issues/access_tickets/grant_single_access', :to => 'iaccesses#grant_single_access', :as => 'grant_single_access'
post '/issues/access_tickets/revoke_single_grant', :to => 'iaccesses#revoke_single_grant', :as => 'revoke_single_grant'

get '/issues/access_tickets/confirm_access', :to => 'iaccesses#confirm_access', :as => 'confirm_access'
get '/issues/access_tickets/revoke_confirmation', :to => 'iaccesses#revoke_confirmation', :as => 'revoke_confirmation'

get '/issues/access_tickets/confirm_revoking', :to => 'iaccesses#confirm_revoking', :as => 'confirm_revoking'
get '/issues/access_tickets/refuse_confirmation_revoking', :to => 'iaccesses#refuse_confirmation_revoking', :as => 'refuse_confirmation_revoking'
get '/issues/access_tickets/deactivate_grants', :to => 'iaccesses#deactivate_grants', :as => 'deactivate_grants'
get '/issues/access_tickets/refuse_deactivating_grants', :to => 'iaccesses#refuse_deactivating_grants', :as => 'refuse_deactivating_grants'
post '/issues/access_tickets/deactivate_single_grant', :to => 'iaccesses#deactivate_grants', :as => 'deactivate_grants'
post '/issues/access_tickets/activate_single_grant', :to => 'iaccesses#refuse_deactivating_grants', :as => 'refuse_deactivating_grants'

