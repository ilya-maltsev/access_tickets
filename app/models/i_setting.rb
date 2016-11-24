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

class ISetting < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :param, :value, :updated_at, :updated_by_id, :deleted

  def self.check_config
    if ISetting.active.all.count == ISetting.values_map.count && Project.where(:id => ISetting.active.where(:param => "at_project_id").first.value).count > 0
      true
    else
      false
    end
  end

  def self.values_map()
    ["cf_deactivated_id","cf_revoked_id", "at_project_id", "cw_group_id", "tr_grant_id", "tr_revoke_id",  "cf_verified_id", "cf_approved_id", "cf_granting_id", "cf_confirming_id", "sec_group_id", "admin_group_id", "hr_group_id","working_issue_status_id", "granted_issue_status_id", "blocked_issue_status_id", "at_simple_approvement"]
  end


  def self.bs_values_map()
    ["cf_deactivated_name","cf_revoked_name","project_name","cw_group_name", "tr_grant_name", "tr_revoke_name", "cf_verified_name","cf_approved_name", "cf_granting_name", "cf_confirming_name", "sec_group_name", "admin_group_name", "hr_group_name", "wis_name","gis_name","bis_name"]
  end

  def self.plugin_settings_ermi
    if Setting[:plugin_access_tickets].length != 0

      plugin_at_settings = Setting.plugin_access_tickets

      if plugin_at_settings.length != 0
        at_erm_integration = plugin_at_settings[:at_erm_integration].to_i
      else
        at_erm_integration = 0
      end
    else
      at_erm_integration = 0
    end
    at_erm_integration
  end

  def self.save_settings_value(key,value, user_id = 1)
    if ISetting.active.where(:param => key).empty?
      settings = ISetting.create(:updated_by_id => user_id)
      settings[:deleted] = 0
      settings[:param] = key
      settings[:value] = value
    else
      settings = ISetting.active.where(:param => key).first
      settings[:deleted] = 0
      settings[:value] = value
      settings[:updated_by_id] = user_id
    end
    if settings.save
      if key == "at_project_id"
        ISetting.set_default_project_values()
      end
      true
    else
      false
    end
  end

def self.set_basic_settings(params)

  ISetting.active.update_all(:deleted =>  1)

    if ISetting.active.where(:param => "at_simple_approvement").count == 0
      ISetting.create(:param => "at_simple_approvement", :value => 0, :deleted => 0 )
    end

    cf_verified = params.detect {|param| param["key"] == "cf_verified_id"}
    cf_verified_name = params.detect {|param| param["key"] == "cf_verified_name"}
    if !cf_verified.nil?
      cf_verified_id = cf_verified["value"]
      ISetting.active.where(:param => "cf_verified_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_verified_id", :value =>  cf_verified_id, :deleted => 0 )
    elsif !cf_verified_name.nil?
      cf = CustomField.new(:name => cf_verified_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_verified_id = cf[:id]
      ISetting.active.where(:param => "cf_verified_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_verified_id", :value =>  cf_verified_id, :deleted => 0 )
    else
    end

    cf_approved = params.detect {|param| param["key"] == "cf_approved_id"}
    cf_approved_name =  params.detect {|param| param["key"] == "cf_approved_name"}
    if !cf_approved.nil?
      cf_approved_id = cf_approved["value"]
      ISetting.active.where(:param => "cf_approved_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_approved_id", :value =>  cf_approved_id, :deleted => 0 )
    elsif !cf_approved_name.nil?
      cf = CustomField.new(:name => cf_approved_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_approved_id = cf[:id]
      ISetting.active.where(:param => "cf_approved_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_approved_id", :value =>  cf_approved_id, :deleted => 0 )
    else
    end

    cf_granting = params.detect {|param| param["key"] == "cf_granting_id"}
    cf_granting_name = params.detect {|param| param["key"] == "cf_granting_name"}
    if !cf_granting.nil?
      cf_granting_id = cf_granting["value"]
      ISetting.active.where(:param => "cf_granting_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_granting_id", :value =>  cf_granting_id, :deleted => 0 )
    elsif !cf_granting_name.nil?
      cf = CustomField.new(:name => cf_granting_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_granting_id = cf[:id]
      ISetting.active.where(:param => "cf_granting_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_granting_id", :value =>  cf_granting_id, :deleted => 0 )
    else
    end

    cf_confirming = params.detect {|param| param["key"] == "cf_confirming_id"}
    cf_confirming_name =  params.detect {|param| param["key"] == "cf_confirming_name"}
    if !cf_confirming.nil?
      cf_confirming_id = cf_confirming["value"]
      ISetting.active.where(:param => "cf_confirming_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_confirming_id", :value =>  cf_confirming_id, :deleted => 0 )
    elsif !cf_confirming_name.nil?
      cf = CustomField.new(:name => cf_confirming_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_confirming_id = cf[:id]
      ISetting.active.where(:param => "cf_confirming_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_confirming_id", :value =>  cf_confirming_id, :deleted => 0 )
    else
    end

    cf_revoked = params.detect {|param| param["key"] == "cf_revoked_id"}
    cf_revoked_name =  params.detect {|param| param["key"] == "cf_revoked_name"}
    if !cf_revoked.nil?
      cf_revoked_id = cf_revoked["value"]
      ISetting.active.where(:param => "cf_revoked_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_revoked_id", :value =>  cf_revoked_id, :deleted => 0 )
    elsif !cf_revoked_name.nil?
      cf = CustomField.new(:name => cf_revoked_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_revoked_id = cf[:id]
      ISetting.active.where(:param => "cf_revoked_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_revoked_id", :value =>  cf_revoked_id, :deleted => 0 )
    else
    end

    cf_deactivated = params.detect {|param| param["key"] == "cf_deactivated_id"}
    cf_deactivated_name =  params.detect {|param| param["key"] == "cf_deactivated_name"}
    if !cf_deactivated.nil?
      cf_deactivated_id = cf_deactivated["value"]
      ISetting.active.where(:param => "cf_deactivated_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_deactivated_id", :value =>  cf_deactivated_id, :deleted => 0 )
    elsif !cf_deactivated_name.nil?
      cf = CustomField.new(:name => cf_deactivated_name["value"], :field_format => 'bool', :default_value => 0, :is_required => false, :visible => true)
      cf[:type] = "IssueCustomField"
      cf.save
      cf_deactivated_id = cf[:id]
      ISetting.active.where(:param => "cf_deactivated_id").update_all(:deleted =>  1)
      ISetting.create(:param => "cf_deactivated_id", :value =>  cf_deactivated_id, :deleted => 0 )
    else
    end


    [["working_issue_status_id","wis_name"],["granted_issue_status_id","gis_name"],["blocked_issue_status_id","bis_name"]].each do |status|
      exist_status = params.detect {|param| param["key"] == status[0]}
      new_status_name =  params.detect {|param| param["key"] == status[1]}
      if !exist_status.nil?
        exist_status_id = exist_status["value"]
        ISetting.active.where(:param => status[0]).update_all(:deleted =>  1)
        ISetting.create(:param => status[0], :value =>  exist_status_id, :deleted => 0 )
      elsif !new_status_name.nil?
        is = IssueStatus.new(:name => new_status_name["value"])
        is.save
        new_status_id = is[:id]
        ISetting.active.where(:param => status[0]).update_all(:deleted =>  1)
        ISetting.create(:param => status[0], :value =>  new_status_id, :deleted => 0 )
      else
      end
    end

    tr_grant = params.detect {|param| param["key"] == "tr_grant_id"}
    tr_grant_name =  params.detect {|param| param["key"] == "tr_grant_name"}
    if !tr_grant.nil?
      tr_grant_id = tr_grant["value"]
      tracker_grant = Tracker.find(tr_grant_id)
      [cf_verified_id,cf_approved_id,cf_granting_id,cf_confirming_id].each do |cf_id|
        if cf_id.in?(tracker_grant.custom_field_ids)
          tracker_grant.custom_field_ids << cf_id
        end
      end
      ISetting.active.where(:param => "tr_grant_id").update_all(:deleted =>  1)
      ISetting.create(:param => "tr_grant_id", :value =>  tr_grant_id, :deleted => 0 )
    elsif !tr_grant_name.nil?
      tracker_grant = Tracker.new(:name => tr_grant_name["value"])
      tracker_grant[:position] = 1
      if ActiveRecord::Base.connection.column_exists?(:trackers, :default_status_id)
        tracker_grant[:default_status_id] = IssueStatus.first.id
      end
      tracker_grant.save
      #tracker_grant.update_attributes(:name => tr_grant_name["value"])
      tr_grant_id = tracker_grant[:id]
      tracker_grant.custom_field_ids = [cf_verified_id,cf_approved_id,cf_granting_id,cf_confirming_id]
      ISetting.active.where(:param => "tr_grant_id").update_all(:deleted =>  1)
      ISetting.create(:param => "tr_grant_id", :value =>  tr_grant_id, :deleted => 0 )
    else
    end

    tr_revoke = params.detect {|param| param["key"] == "tr_revoke_id"}
    tr_revoke_name =  params.detect {|param| param["key"] == "tr_revoke_name"}
    if !tr_revoke.nil?
      tr_revoke_id = tr_revoke["value"]
      tracker_revoke = Tracker.find(tr_revoke_id)
      [cf_revoked_id,cf_deactivated_id].each do |cf_id|
        if cf_id.in?(tracker_revoke.custom_field_ids)
          tracker_revoke.custom_field_ids << cf_id
        end
      end
      ISetting.active.where(:param => "tr_revoke_id").update_all(:deleted =>  1)
      ISetting.create(:param => "tr_revoke_id", :value =>  tr_revoke_id, :deleted => 0 )
    elsif !tr_revoke_name.nil?
      tracker_revoke = Tracker.new(:name => tr_revoke_name["value"])
      tracker_revoke[:position] = 1
      if ActiveRecord::Base.connection.column_exists?(:trackers, :default_status_id)
        tracker_revoke[:default_status_id] = IssueStatus.first.id
      end
      tracker_revoke.save
      #tracker_revoke.update_attributes(:name => tr_revoke_name["value"])
      tr_revoke_id = tracker_revoke[:id]
      tracker_revoke.custom_field_ids = [cf_revoked_id,cf_deactivated_id]
      ISetting.active.where(:param => "tr_revoke_id").update_all(:deleted =>  1)
      ISetting.create(:param => "tr_revoke_id", :value => tr_revoke_id, :deleted => 0 )
    else
    end


    [["cw_group_id","cw_group_name"],["sec_group_id","sec_group_name"],["admin_group_id","admin_group_name"],["hr_group_id","hr_group_name"]].each do |bm_group|
      exist_group = params.detect {|param| param["key"] == bm_group[0]}
      new_group_name = params.detect {|param| param["key"] == bm_group[1]}
      if !exist_group.nil?
        exist_group_id = exist_group["value"]
        ISetting.active.where(:param => bm_group[0]).update_all(:deleted =>  1)
        ISetting.create(:param => bm_group[0], :value =>  exist_group_id, :deleted => 0 )
      elsif !new_group_name.nil?
        group = Group.new(:lastname => new_group_name["value"])
        group.save
        new_group_id = group[:id]
        ISetting.active.where(:param => bm_group[0]).update_all(:deleted =>  1)
        ISetting.create(:param => bm_group[0], :value =>  new_group_id, :deleted => 0 )
      else
      end
    end
    at_project = params.detect { |param| param["key"] == "at_project_id" }
    project_name = params.detect { |param| param["key"] == "project_name" }
    if !at_project.nil?
      at_project_id = at_project["value"]
      project = Project.find(at_project_id)
      [tracker_grant,tracker_revoke].each do |tracker|
        if !tracker.in?(project.trackers)
          project.trackers << tracker
        end
      end
      [cf_verified_id,cf_approved_id,cf_granting_id, cf_confirming_id,cf_deactivated_id,cf_revoked_id].each do |cf_id|
        if !CustomField.find(cf_id).in?(project.issue_custom_fields)
          project.issue_custom_fields << CustomField.find(cf_id)
        end
      end
      if !project.enabled_modules.where(:name => "issue_tracking").empty?
        project.enabled_modules.create(:name => "issue_tracking")
      end
      ISetting.active.where(:param => "at_project_id").update_all(:deleted =>  at_project_id)
      ISetting.create(:param => "at_project_id", :value =>  at_project_id, :deleted => 0 )
    elsif !project_name.nil?
      project = Project.new(:name => project_name["value"], :identifier => SecureRandom.hex(5), :is_public => 1, :enabled_module_names => [""], :trackers => Tracker.where(:id => [tr_grant_id,tr_revoke_id]))
      project.save
      project.enabled_modules.create(:name => "issue_tracking")
      project.issue_custom_fields = CustomField.where(:id => [cf_verified_id,cf_approved_id,cf_granting_id, cf_confirming_id,cf_deactivated_id,cf_revoked_id])
      at_project_id = project[:id]
      ISetting.active.where(:param => "at_project_id").update_all(:deleted =>  at_project_id)
      ISetting.create(:param => "at_project_id", :value =>  at_project_id, :deleted => 0 )
    else
    end


  end



  def self.set_default_project_values
    ["tr_grant_id", "tr_revoke_id","cf_approved_id", "cf_verified_id", "cf_granting_id", "cf_confirming_id", "cf_deactivated_id","cf_revoked_id"].each do |key|
      if ISetting.active.where(:param => key).empty?
        settings = ISetting.create(:updated_by_id => 1)
        settings[:deleted] = 0
        settings[:param] = key
        settings[:value] = "0"
      else
        settings = ISetting.active.where(:param => key).first
        settings[:deleted] = 0
        settings[:value] = "0"
        settings[:updated_by_id] = 1
      end
      settings.save
    end
  end



  def self.get_plugin_config

      config = {}

      config["at_erm_integration"] = ISetting.plugin_settings_ermi

      ISetting.values_map.each do |key|
        values = ISetting.active.where(:param => key)
        if values.count == 0
          config[key] = 0
        else
          config[key] = values.first.value.to_i
        end
      end
      config
    end



end

