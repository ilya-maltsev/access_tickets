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


class IaccessesController < ApplicationController

   def confirm_revoking
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      revoking_status = IAccess.check_revoking_status(issue_id, user_id)
      if revoking_status[0..1] == [0,0] && revoking_status[2] > 0 && revoking_status[4] == 1
        IAccess.confirm_revoking_for_accesses(issue_id, user_id)
        accesses = IAccess.accesses_list(0, issue_id, user_id)
        revoking_status = IAccess.check_revoking_status(issue_id)#, user_id)
        if revoking_status[0..1] == [1,0]
          issue = Issue.find(issue_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
          journal.details << details
          cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_revoked_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def refuse_confirmation_revoking
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      revoking_status = IAccess.check_revoking_status(issue_id, user_id)
      if revoking_status[0..1] == [1,0] && revoking_status[5] == 1
        IAccess.refuse_confirmation_revoking_for_accesses(issue_id, user_id)
        accesses = IAccess.accesses_list(0, issue_id, user_id)
        revoking_status = IAccess.check_revoking_status(issue_id)#, user_id)
        if revoking_status[0..1] == [0,0]
          issue = Issue.find(issue_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "sec_group_id").first.value)
          journal.details << details
          cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_revoked_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def deactivate_grants
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      if params[:uid].present?
        r_uid = params[:uid]
      else 
        r_uid = nil
      end
      user_id = User.current.id
      if IAccess.may_be_deactivate_grant(issue_id, user_id, r_uid)
        IAccess.deactivate_grants(issue_id, user_id, r_uid)
        accesses = IAccess.accesses_list(0, issue_id, user_id)
        revoking_status = IAccess.check_revoking_status(issue_id, user_id)
        if revoking_status[0..1] == [1,1]
          issue = Issue.find(issue_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => issue.author_id)
          journal.details << details
          cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_deactivated_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => Issue.find(issue_id).status_id, :value => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => issue.author_id)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
        end
        if r_uid.nil?
          redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
        else
          respond_to do |format|
            format.json { render :json =>  [accesses, IAccess.last_revoking_version(issue_id, user_id), revoking_status] }
          end
        end
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def refuse_deactivating_grants
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      if params[:uid].present?
        r_uid = params[:uid]
      else 
        r_uid = nil
      end
      user_id = User.current.id
      if IAccess.may_be_refuse_deactivating_grants(issue_id, user_id, r_uid)
        IAccess.refuse_deactivating_grants(issue_id, user_id, r_uid)
        accesses = IAccess.accesses_list(0, issue_id, user_id)
        revoking_status = IAccess.check_revoking_status(issue_id, user_id)
        if revoking_status[0..1] == [1,0]
          issue = Issue.find(issue_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        end
        if r_uid.nil?
          redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
        else
          respond_to do |format|
            format.json { render :json =>  [accesses, IAccess.last_revoking_version(issue_id, user_id), revoking_status] }
          end
        end
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def self.show_last_revoking_version(issue_id)
    if !IAccess.active.where(:rev_issue_id => issue_id).empty?
      Time::DATE_FORMATS.merge!(:localdb=>"%H:%M:%S %d.%m.%Y")
      if User.current.time_zone != nil
        tz = User.current.time_zone
      else
        tz = "Minsk"
      end
      version = IAccess.revoking_last_version(issue_id)
      if version
        version_value = "(" + l(:at_last_edited_by) + version.firstname + " " + version.lastname + l(:at_at) + version.revoked_at.in_time_zone(tz).to_s(:localdb) + ")"
      else
        version_value = ""
      end
    else
      version_value = ""
    end
  end


  def save_revoking_table
    issue_id = params[:issue_id]
    r_user_id = params[:r_user_id]
    user_id = User.current.id
    if IaccessesController.check_revoking_editable(issue_id,User.current)
      inputData = JSON.parse(params[:i_tickets])
      #inputData = params[:i_tickets]
      old_r_accesses = IAccess.active.where(:rev_issue_id => issue_id) 
      if !old_r_accesses.empty?
        old_r_accesses.update_all(:revoked_by_id => nil, :rev_issue_id => nil, :r_created_by_id => nil)
      end

      if !inputData.empty?
        inputData.each do |ticket|
          if ticket["entities"].empty?
            if !IResource.find(ITicket.where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"]).first[:i_resource_id]).has_entities
              ids = IAccess.joins(:iticket).where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"]).select("i_accesses.id").map(&:id)
              IAccess.where(:id => ids).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id, :updated_at => Time.now)
            end
          else
            ids = IAccess.joins(:iticket).where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"], "i_accesses.i_entity_id" => ticket["entities"]).select("i_accesses.id").map(&:id)
            IAccess.where(:id => ids).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id, :updated_at => Time.now)
          end
        end
      end
      issue = Issue.find(issue_id)
      issue.watcher_user_ids = issue.watcher_user_ids | User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "admin_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "cw_group_id").first.value.to_i).map(&:id) | Issue.where(:id => issue_id).map(&:author_id)
      issue.save      
      accesses = IAccess.accesses_list(r_user_id, issue_id)
      respond_to do |format|
        format.json { render :json =>  [accesses, IAccess.last_revoking_version(issue_id, user_id), IAccess.check_revoking_status(issue_id, user_id)] }
      end
    else
      head :forbidden
    end
  end

  def edit_revoking_table
    @issue_id = params[:issue_id]
    @r_user_id = params[:r_user_id]
    @accesses = IAccess.accesses_list(@r_user_id).to_json
    if IaccessesController.check_revoking_editable(@issue_id,User.current)
      respond_to do |format|
        format.js 
      end
    else
      head :forbidden
    end
  end

  def self.check_revoking_editable(issue_id, user)
    if user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) 
      return true
    elsif CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_revoked_id").first.value.to_i, :value => 1).count > 0 || CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_deactivated_id").first.value.to_i, :value => 1).count > 0 
      return false
    else
      return true
    end

  end


  def available_users
    respond_to do |format|
      format.json { render :json => [IGrouplider.available_users(User.current)] }
    end
  end

  def accesses_list
    @user_id = User.current.id
    users_nosort = []
    @is_resowner = IResowner.is_resowner(@user_id)
    @is_resgranter = IResgranter.is_resgranter(@user_id)
    @is_group_lider = IGrouplider.is_group_lider(@user_id)
    @is_security = ITicket.check_security_officer(User.current)
    if @is_security
      @is_group_lider = true
    end
    @users_list = IGrouplider.available_users(User.current)
    respond_to do |format|
      format.html {
        render :template => 'iaccesses/access_list'
      }
    end
  end


  def show_accesses
    current_user_id = User.current.id
    if params[:user_id].present?
      dependent_user_id = params[:user_id].to_i
      if IGrouplider.lider_for_user(dependent_user_id, current_user_id) || current_user_id == 1 || current_user_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || current_user_id == dependent_user_id
        accesses_list = IAccess.accesses_list(dependent_user_id, nil, current_user_id)
        rev_accesses_list = IAccess.revoked_accesses_list(dependent_user_id, current_user_id)
        respond_to do |format|
          format.json { render :json => [accesses_list, rev_accesses_list] }
        end
      else
        head :forbidden
      end
    elsif params[:resource_id].present?
      resource_id = params[:resource_id]
      if current_user_id == 1 || current_user_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || IResgranter.is_granter_for_resource(current_user_id, resource_id) || IResowner.is_owner_for_resource(current_user_id, resource_id)
        accesses_list = IAccess.accesses_list_by_resource(resource_id, current_user_id)
        rev_accesses_list = IAccess.revoked_accesses_list_by_resource(resource_id, current_user_id)
        respond_to do |format|
          format.json { render :json => [accesses_list, rev_accesses_list] }
        end
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end


  def grant_access
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      if params[:uid].present?
        r_uid = params[:uid]
      else 
        r_uid = nil
      end
      user_id = User.current.id
      if IAccess.may_be_grant_access_by_issue_status(issue_id, user_id, r_uid)
        IAccess.grant_access_for_tickets(issue_id, user_id, r_uid)
        issue_status = ITicket.check_issue_status(issue_id)#, user_id)
        if issue_status[0..3] == [1,1,1,0]
          issue = Issue.find(issue_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
          cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_granting_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => issue.author_id)
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => issue.author_id)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def revoke_grant
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      if params[:uid].present?
        r_uid = params[:uid]
      else 
        r_uid = nil
      end
      user_id = User.current.id
      if IAccess.may_be_revoke_grant_by_issue_status(issue_id, user_id, r_uid)
        old_issue_status = ITicket.check_issue_status(issue_id)#, user_id)
        IAccess.revoke_grant_for_tickets(issue_id, user_id, r_uid)
        issue_status = ITicket.check_issue_status(issue_id)#, user_id)
        if issue_status[0..3] == [1,1,0,0] && old_issue_status[0..3] == [1,1,1,0]
          issue = Issue.find(issue_id)
          cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id   
          details = JournalDetail.new(:property => "cf", :prop_key => cf_granting_id.to_s, :old_value => "1", :value => "0") 
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def grant_single_access
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user_id = User.current.id
    if IAccess.may_be_grant_access_by_issue_status(issue_id, user_id, r_uid)
      IAccess.grant_access_for_tickets(issue_id, user_id, r_uid)
      issue_status = ITicket.check_issue_status(issue_id, user_id)
      if issue_status[0..3] == [1,1,1,0]
        issue = Issue.find(issue_id)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_granting_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => issue.author_id)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
        journal.details << details
        journal.save
        issue.update_attributes(:assigned_to_id => issue.author_id)
        issue.update_attributes(:status_id => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
      end
      tickets = ITicket.tickets_list(issue_id, user_id)
      respond_to do |format|
        format.json { render :json =>  [tickets, IticketsController.show_last_ticket_version(issue_id), issue_status, ITicket.tickets_user_id(issue_id) ] }
      end
    else
      head :forbidden
    end
  end

  def revoke_single_grant
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user_id = User.current.id
    if IAccess.may_be_revoke_grant_by_issue_status(issue_id, user_id, r_uid)
      old_issue_status = ITicket.check_issue_status(issue_id, user_id)
      IAccess.revoke_grant_for_tickets(issue_id, user_id, r_uid)
      issue_status = ITicket.check_issue_status(issue_id, user_id)
      if issue_status[0..3] == [1,1,0,0] && old_issue_status[0..3] == [1,1,1,0]
        issue = Issue.find(issue_id)
        cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id   
        details = JournalDetail.new(:property => "cf", :prop_key => cf_granting_id.to_s, :old_value => "1", :value => "0") 
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        journal.details << details
        journal.save
        issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
        issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
      end
      tickets = ITicket.tickets_list(issue_id, user_id)
      respond_to do |format|
        format.json { render :json =>  [tickets, IticketsController.show_last_ticket_version(issue_id), issue_status, ITicket.tickets_user_id(issue_id) ] }
      end
    else
      head :forbidden
    end
  end

  def confirm_access
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      issue_status = ITicket.check_issue_status(issue_id)
      if IAccess.check_access_confirmer(issue_id, User.current) && issue_status[0..3] == [1,1,1,0]
        IAccess.confirm_access_for_tickets(issue_id, user_id)
        issue_status = ITicket.check_issue_status(issue_id)
        if issue_status[0..3] == [1,1,1,1]
          issue = Issue.find(issue_id)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id)
          cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_confirming_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def revoke_confirmation
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      issue_status = ITicket.check_issue_status(issue_id)
      if IAccess.check_access_confirmer(issue_id, User.current) && issue_status[0..3] == [1,1,1,1]
        IAccess.revoke_confirmation_for_tickets(issue_id, user_id)
        issue_status = ITicket.check_issue_status(issue_id)
        if issue_status[0..3] == [1,1,1,0]
          issue = Issue.find(issue_id)
          issue.update_attributes(:status_id => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id)
          cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_confirming_id.to_s, :old_value => "1", :value => "0") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "granted_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      head :forbidden
    end
  end


end
