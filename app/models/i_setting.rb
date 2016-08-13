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
    if ISetting.all.count == 0
      false
    else
      true
    end
  end

  def self.values_map()
    ["cf_deactivated_id","cf_revoked_id","cf_new_emp_first_day_id", "at_project_id", "cw_group_id", "tr_dismissal_id", "tr_template_agreement_id", "tr_new_emp_id", "tr_change_term_id", "tr_grant_id", "tr_revoke_id", "cf_approved_id", "cf_verified_id", "cf_granting_id", "cf_confirming_id", "sec_group_id", "approving_issue_status_id","working_issue_status_id", "granted_issue_status_id", "blocked_issue_status_id", "at_simple_approvement", "admin_group_id", "hr_group_id", "at_erm_integration"]
  end




def self.basic_config
    config = {}


    at_erm_integration = ISetting.active.where(:param => "at_erm_integration")
    if at_erm_integration.count == 0
      @at_erm_integration = 0        
      ISetting.create(:param => "at_erm_integration", :value => @at_erm_integration, :deleted => 0 )
    else
      @at_erm_integration = at_erm_integration.first.value.to_i
    end
    config[:at_erm_integration] = @at_erm_integration


    at_simple_approvement = ISetting.active.where(:param => "at_simple_approvement")
    if at_simple_approvement.count == 0
      @at_simple_approvement = 0        
      ISetting.create(:param => "at_simple_approvement", :value => @at_simple_approvement, :deleted => 0 )
    else
      @at_simple_approvement = at_simple_approvement.first.value.to_i
    end
    config[:at_simple_approvement] = @at_simple_approvement

    at_project_id = ISetting.active.where(:param => "at_project_id")
    if at_project_id.count == 0
      @at_project_id = 1
      ISetting.create(:param => "at_project_id", :value => @at_project_id, :deleted => 0 )
    else
      @at_project_id = at_project_id.first.value.to_i
    end
    config[:at_project_id] = @at_project_id

    #tr_new_emp_id = ISetting.active.where(:param => "tr_new_emp_id")
    #if tr_new_emp_id.count == 0
    #  @tr_new_emp_id = 1
    #  ISetting.create(:param => "tr_new_emp_id", :value => @tr_new_emp_id, :deleted => 0 )
    #else
    #  @tr_new_emp_id = tr_new_emp_id.first.value.to_i
    #end
    #config[:tr_new_emp_id] = @tr_new_emp_id

    tr_grant_id = ISetting.active.where(:param => "tr_grant_id")
    if tr_grant_id.count == 0
      @tr_grant_id = 1
      ISetting.create(:param => "tr_grant_id", :value => @tr_grant_id, :deleted => 0 )
    else
      @tr_grant_id = tr_grant_id.first.value.to_i
    end
    config[:tr_grant_id] = @tr_grant_id

    #tr_change_term_id = ISetting.active.where(:param => "tr_change_term_id")
    #if tr_change_term_id.count == 0
    #  @tr_change_term_id = 1
    #  ISetting.create(:param => "tr_change_term_id", :value => @tr_change_term_id, :deleted => 0 )
    #else
    #  @tr_change_term_id = tr_change_term_id.first.value.to_i
    #end
    #config[:tr_change_term_id] = @tr_change_term_id

    tr_revoke_id = ISetting.active.where(:param => "tr_revoke_id")
    if tr_revoke_id.count == 0
      @tr_revoke_id = 1
      ISetting.create(:param => "tr_revoke_id", :value => @tr_revoke_id, :deleted => 0 )
    else
      @tr_revoke_id = tr_revoke_id.first.value.to_i
    end
    config[:tr_revoke_id] = @tr_revoke_id

    #tr_dismissal_id = ISetting.active.where(:param => "tr_dismissal_id")
    #if tr_dismissal_id.count == 0
    #  @tr_dismissal_id = 1
    #  ISetting.create(:param => "tr_dismissal_id", :value => @tr_dismissal_id, :deleted => 0 )
    #else
    #  @tr_dismissal_id = tr_dismissal_id.first.value.to_i
    #end
    #config[:tr_dismissal_id] = @tr_dismissal_id

    #tr_template_agreement_id = ISetting.active.where(:param => "tr_template_agreement_id")
    #if tr_template_agreement_id.count == 0
    #  @tr_template_agreement_id = 1
    #  ISetting.create(:param => "tr_template_agreement_id", :value => @tr_template_agreement_id, :deleted => 0 )
    #else
    #  @tr_template_agreement_id = tr_template_agreement_id.first.value.to_i
    #end
    #config[:tr_template_agreement_id] = @tr_template_agreement_id

    cf_approved_id = ISetting.active.where(:param => "cf_approved_id")
    if cf_approved_id.count == 0
      @cf_approved_id = 0 
      ISetting.create(:param => "cf_approved_id", :value =>  @cf_approved_id, :deleted => 0 )
    else
      @cf_approved_id = cf_approved_id.first.value.to_i
    end
    config[:cf_approved_id] = @cf_approved_id

    cf_verified_id = ISetting.active.where(:param => "cf_verified_id")
    if cf_verified_id.count == 0
      @cf_verified_id = 0 
      ISetting.create(:param => "cf_verified_id", :value =>  @cf_verified_id, :deleted => 0 )
    else
      @cf_verified_id = cf_verified_id.first.value.to_i
    end
    config[:cf_verified_id] = @cf_verified_id

    cf_granting_id = ISetting.active.where(:param => "cf_granting_id")
    if cf_granting_id.count == 0
      @cf_granting_id = 0 
      ISetting.create(:param => "cf_granting_id", :value =>  @cf_granting_id, :deleted => 0 )
    else
      @cf_granting_id = cf_granting_id.first.value.to_i
    end
    config[:cf_granting_id] = @cf_granting_id

    cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id")
    if cf_confirming_id.count == 0
      @cf_confirming_id = 0 
      ISetting.create(:param => "cf_confirming_id", :value =>  @cf_confirming_id, :deleted => 0 )
    else
      @cf_confirming_id = cf_confirming_id.first.value.to_i
    end
    config[:cf_confirming_id] = @cf_confirming_id

    cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id")
    if cf_revoked_id.count == 0
      @cf_revoked_id = 0 
      ISetting.create(:param => "cf_revoked_id", :value =>  @cf_revoked_id, :deleted => 0 )
    else
      @cf_revoked_id = cf_revoked_id.first.value.to_i
    end
    config[:cf_revoked_id] = @cf_revoked_id

    cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id")
    if cf_deactivated_id.count == 0
      @cf_deactivated_id = 0 
      ISetting.create(:param => "cf_deactivated_id", :value =>  @cf_deactivated_id, :deleted => 0 )
    else
      @cf_deactivated_id = cf_deactivated_id.first.value.to_i
    end
    config[:cf_deactivated_id] = @cf_deactivated_id

    working_issue_status_id = ISetting.active.where(:param => "working_issue_status_id")
    if working_issue_status_id.count == 0
      @working_issue_status_id = 1
      ISetting.create(:param => "working_issue_status_id", :value => @working_issue_status_id, :deleted => 0 )
    else
      @working_issue_status_id = working_issue_status_id.first.value.to_i
    end
    config[:working_issue_status_id] = @working_issue_status_id

    granted_issue_status_id = ISetting.active.where(:param => "granted_issue_status_id")
    if granted_issue_status_id.count == 0
      @granted_issue_status_id = 1
      ISetting.create(:param => "granted_issue_status_id", :value => @granted_issue_status_id, :deleted => 0 )
    else
      @granted_issue_status_id = granted_issue_status_id.first.value.to_i
    end
    config[:granted_issue_status_id] = @granted_issue_status_id

    blocked_issue_status_id = ISetting.active.where(:param => "blocked_issue_status_id")
    if blocked_issue_status_id.count == 0
      @blocked_issue_status_id = 1
      ISetting.create(:param => "blocked_issue_status_id", :value => @blocked_issue_status_id, :deleted => 0 )
    else
      @blocked_issue_status_id = blocked_issue_status_id.first.value.to_i
    end
    config[:blocked_issue_status_id] = @blocked_issue_status_id

    cf_new_emp_first_day_id = ISetting.active.where(:param => "cf_new_emp_first_day_id")
    if cf_new_emp_first_day_id.count == 0
      @cf_new_emp_first_day_id = 0
      ISetting.create(:param => "cf_new_emp_first_day_id", :value => @cf_new_emp_first_day_id, :deleted => 0 )
    else
      @cf_new_emp_first_day_id = cf_new_emp_first_day_id.first.value.to_i
    end
    config[:cf_new_emp_first_day_id] = @cf_new_emp_first_day_id

    sec_group_id = ISetting.active.where(:param => "sec_group_id")
    if sec_group_id.count == 0
      if Group.all.count == 0
        Group.new(:lastname => 'test').save
      else
        @sec_group_id = Group.all.first.id
      end
      ISetting.create(:param => "sec_group_id", :value => @sec_group_id, :deleted => 0 )
    else
      @sec_group_id = sec_group_id.first.value.to_i
    end
    config[:sec_group_id] = @sec_group_id

    admin_group_id = ISetting.active.where(:param => "admin_group_id")
    if admin_group_id.count == 0
      if Group.all.count == 0
        Group.new(:lastname => 'test').save
      else
        @admin_group_id = Group.all.first.id
      end
      ISetting.create(:param => "admin_group_id", :value => @admin_group_id, :deleted => 0 )
    else
      @admin_group_id = admin_group_id.first.value.to_i
    end
    config[:admin_group_id] = @admin_group_id

    hr_group_id = ISetting.active.where(:param => "hr_group_id")
    if hr_group_id.count == 0
      @hr_group_id = Group.all.first.id
      ISetting.create(:param => "hr_group_id", :value => @hr_group_id, :deleted => 0 )
    else
      @hr_group_id = hr_group_id.first.value.to_i
    end
    config[:hr_group_id] = @hr_group_id

    cw_group_id = ISetting.active.where(:param => "cw_group_id")
    if cw_group_id.count == 0
      @cw_group_id = Group.all.first.id
      ISetting.create(:param => "cw_group_id", :value => @cw_group_id, :deleted => 0 )
    else
      @cw_group_id = cw_group_id.first.value.to_i
    end
    config[:cw_group_id] = @cw_group_id

    config
  end


end

