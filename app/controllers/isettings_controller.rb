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

class IsettingsController < ApplicationController


  def reset_config
    if User.current.admin?
      ISetting.active.each {|x| x.delete}
      redirect_to Redmine::Utils::relative_url_root + "/settings/plugin/access_tickets", :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def set_base_config
    if User.current.admin? && params[:parameters].present? && !ISetting.check_config()
      rawData = JSON.parse(params[:parameters])
      errors = {}
      inputData = []
      rawData.each do |object|
        if object["key"].in?(ISetting.values_map()) || object["key"].in?(ISetting.bs_values_map())
          inputData.push(object)
        end
      end
      if inputData.count == ISetting.bs_values_map().count
        ISetting.set_basic_settings(inputData)
      end
      redirect_to Redmine::Utils::relative_url_root + "/settings/plugin/access_tickets", :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end


  def show_group_details
    if ITicket.check_security_officer(User.current) && params[:group_id].present?
      users = [] 
      User.active.each do |obj|
        user = {}
        user[:id] = obj[:id]
        user[:name] = obj.name
        users.push(user)
      end
      group_liders = IGrouplider.where(:group_id => params[:group_id]).map(&:user_id)
      respond_to do |format|
        format.json { render :json => {:users => users, :group_liders => group_liders }}
      end
    else
      head :forbidden
    end
  end

  def set_group_liders
    if ( ITicket.check_security_officer(User.current) && params[:group_id].present? )

      IGrouplider.where(:group_id => params[:group_id]).destroy_all

      if params[:group_liders].length > 0
        params[:group_liders].each do |i|
          IGrouplider.create(:user_id => i, :group_id => params[:group_id])
        end
        render :inline => "{ status: ok }"
      else
        render :inline => "{ status: false }"
      end
    else
      head :forbidden
    end
  end

  def settings

    if ITicket.check_security_officer(User.current)

      at_simple_approvement = ISetting.active.where(:param => "at_simple_approvement")
      if at_simple_approvement.count == 0
        @at_simple_approvement = 1
        ISetting.create(:param => "at_simple_approvement", :value => @at_simple_approvement, :deleted => 0 )
      else
        @at_simple_approvement = at_simple_approvement.first.value.to_i
      end

      at_project_id = ISetting.active.where(:param => "at_project_id")
      if at_project_id.count == 0
        @at_project_id = 1
        ISetting.create(:param => "at_project_id", :value => @at_project_id, :deleted => 0 )
      else
        @at_project_id = at_project_id.first.value.to_i
      end

      tr_new_emp_id = ISetting.active.where(:param => "tr_new_emp_id")
      if tr_new_emp_id.count == 0
        @tr_new_emp_id = 1
        ISetting.create(:param => "tr_new_emp_id", :value => @tr_new_emp_id, :deleted => 0 )
      else
        @tr_new_emp_id = tr_new_emp_id.first.value.to_i
      end

      tr_grant_id = ISetting.active.where(:param => "tr_grant_id")
      if tr_grant_id.count == 0
        @tr_grant_id = 1
        ISetting.create(:param => "tr_grant_id", :value => @tr_grant_id, :deleted => 0 )
      else
        @tr_grant_id = tr_grant_id.first.value.to_i
      end

      tr_change_term_id = ISetting.active.where(:param => "tr_change_term_id")
      if tr_change_term_id.count == 0
        @tr_change_term_id = 1
        ISetting.create(:param => "tr_change_term_id", :value => @tr_change_term_id, :deleted => 0 )
      else
        @tr_change_term_id = tr_change_term_id.first.value.to_i
      end

      tr_revoke_id = ISetting.active.where(:param => "tr_revoke_id")
      if tr_revoke_id.count == 0
        @tr_revoke_id = 1
        ISetting.create(:param => "tr_revoke_id", :value => @tr_revoke_id, :deleted => 0 )
      else
        @tr_revoke_id = tr_revoke_id.first.value.to_i
      end

      tr_dismissal_id = ISetting.active.where(:param => "tr_dismissal_id")
      if tr_dismissal_id.count == 0
        @tr_dismissal_id = 1
        ISetting.create(:param => "tr_dismissal_id", :value => @tr_dismissal_id, :deleted => 0 )
      else
        @tr_dismissal_id = tr_dismissal_id.first.value.to_i
      end

      tr_template_agreement_id = ISetting.active.where(:param => "tr_template_agreement_id")
      if tr_template_agreement_id.count == 0
        @tr_template_agreement_id = 1
        ISetting.create(:param => "tr_template_agreement_id", :value => @tr_template_agreement_id, :deleted => 0 )
      else
        @tr_template_agreement_id = tr_template_agreement_id.first.value.to_i
      end

      cf_approved_id = ISetting.active.where(:param => "cf_approved_id")
      if cf_approved_id.count == 0
        @cf_approved_id = 0 
        ISetting.create(:param => "cf_approved_id", :value =>  @cf_approved_id, :deleted => 0 )
      else
        @cf_approved_id = cf_approved_id.first.value.to_i
      end

      cf_verified_id = ISetting.active.where(:param => "cf_verified_id")
      if cf_verified_id.count == 0
        @cf_verified_id = 0 #
        ISetting.create(:param => "cf_verified_id", :value =>  @cf_verified_id, :deleted => 0 )
      else
        @cf_verified_id = cf_verified_id.first.value.to_i
      end

      cf_granting_id = ISetting.active.where(:param => "cf_granting_id")
      if cf_granting_id.count == 0
        @cf_granting_id = 0 
        ISetting.create(:param => "cf_granting_id", :value =>  @cf_granting_id, :deleted => 0 )
      else
        @cf_granting_id = cf_granting_id.first.value.to_i
      end

      cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id")
      if cf_confirming_id.count == 0
        @cf_confirming_id = 0 
        ISetting.create(:param => "cf_confirming_id", :value =>  @cf_confirming_id, :deleted => 0 )
      else
        @cf_confirming_id = cf_confirming_id.first.value.to_i
      end

      cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id")
      if cf_revoked_id.count == 0
        @cf_revoked_id = 0 
        ISetting.create(:param => "cf_revoked_id", :value =>  @cf_revoked_id, :deleted => 0 )
      else
        @cf_revoked_id = cf_revoked_id.first.value.to_i
      end

      cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id")
      if cf_deactivated_id.count == 0
        @cf_deactivated_id = 0 
        ISetting.create(:param => "cf_deactivated_id", :value =>  @cf_deactivated_id, :deleted => 0 )
      else
        @cf_deactivated_id = cf_deactivated_id.first.value.to_i
      end

      working_issue_status_id = ISetting.active.where(:param => "working_issue_status_id")
      if working_issue_status_id.count == 0
        @working_issue_status_id = 1
        ISetting.create(:param => "working_issue_status_id", :value => @working_issue_status_id, :deleted => 0 )
      else
        @working_issue_status_id = working_issue_status_id.first.value.to_i
      end

      granted_issue_status_id = ISetting.active.where(:param => "granted_issue_status_id")
      if granted_issue_status_id.count == 0
        @granted_issue_status_id = 1
        ISetting.create(:param => "granted_issue_status_id", :value => @granted_issue_status_id, :deleted => 0 )
      else
        @granted_issue_status_id = granted_issue_status_id.first.value.to_i
      end

      blocked_issue_status_id = ISetting.active.where(:param => "blocked_issue_status_id")
      if blocked_issue_status_id.count == 0
        @blocked_issue_status_id = 1
        ISetting.create(:param => "blocked_issue_status_id", :value => @blocked_issue_status_id, :deleted => 0 )
      else
        @blocked_issue_status_id = blocked_issue_status_id.first.value.to_i
      end

      cf_new_emp_first_day_id = ISetting.active.where(:param => "cf_new_emp_first_day_id")
      if cf_new_emp_first_day_id.count == 0
        @cf_new_emp_first_day_id = 0
        ISetting.create(:param => "cf_new_emp_first_day_id", :value => @cf_new_emp_first_day_id, :deleted => 0 )
      else
        @cf_new_emp_first_day_id = cf_new_emp_first_day_id.first.value.to_i
      end

      sec_group_id = ISetting.active.where(:param => "sec_group_id")
      if sec_group_id.count == 0
        @sec_group_id = Group.all.first.id
        ISetting.create(:param => "sec_group_id", :value => @sec_group_id, :deleted => 0 )
      else
        @sec_group_id = sec_group_id.first.value.to_i
      end

      admin_group_id = ISetting.active.where(:param => "admin_group_id")
      if admin_group_id.count == 0
        @admin_group_id = Group.all.first.id
        ISetting.create(:param => "admin_group_id", :value => @admin_group_id, :deleted => 0 )
      else
        @admin_group_id = admin_group_id.first.value.to_i
      end

      hr_group_id = ISetting.active.where(:param => "hr_group_id")
      if hr_group_id.count == 0
        @hr_group_id = Group.all.first.id
        ISetting.create(:param => "hr_group_id", :value => @hr_group_id, :deleted => 0 )
      else
        @hr_group_id = hr_group_id.first.value.to_i
      end

      cw_group_id = ISetting.active.where(:param => "cw_group_id")
      if cw_group_id.count == 0
        @cw_group_id = Group.all.first.id
        ISetting.create(:param => "cw_group_id", :value => @cw_group_id, :deleted => 0 )
      else
        @cw_group_id = cw_group_id.first.value.to_i
      end

      respond_to do |format|
        format.html {
          render :template => 'isettings/at_settings'
        }
      end
    else
      redirect_to(:back)
    end
    
  end


  def set_settings_value
    if ITicket.check_security_officer(User.current)
      params.each do |key,value|
        if key.in?(ISetting.values_map()) 
          save_settings_value(key,value)
        end
      end
    else
      head :forbidden
    end
  end

  def save_settings_value(key,value)
    if ISetting.active.where(:param => key).nil?
      new_settings = ISetting.new
      new_settings[:key] = key
      new_settings[:value] = ""
      new_settings.save
    end
    settings = ISetting.active.where(:param => key).first
    settings[:value] = value
    if settings.save
      respond_to do |format|
        format.json { render :json => {:status => "ok"} }
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "false"} }
      end
    end
  end

end
