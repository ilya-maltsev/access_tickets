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

class IretimeaccessesController < ApplicationController


  def save_retiming_table
    if params[:issue_id].present? && params[:i_tickets].present?
      issue_id = params[:issue_id]
      r_user_id = params[:r_user_id]
      user = User.current
      if IRetimeaccess.check_retiming_editable(issue_id,user)
        inputData = JSON.parse(params[:i_tickets])
        #inputData = params[:i_tickets]
        IRetimeaccess.create_retiming_accesses(issue_id, inputData)
        issue = Issue.where(:id => issue_id).first
        issue.watcher_user_ids = issue.watcher_user_ids | IRetimeaccess.resowners_for_issue(issue_id) 
        issue.save
        respond_to do |format|
          format.json { render :json => [] }
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def edit_retiming_table
    if params[:issue_id].present? 
      @issue_id = params[:issue_id]
      @users_list = IGrouplider.available_users(User.current)
      current_user = User.current

      #@r_user_id = params[:r_user_id]
      if IRetimeaccess.check_retiming_editable(@issue_id, current_user)
        #old_r_accesses = IRetimeaccess.active.where(:retime_issue_id => @issue_id)
        #if !old_r_accesses.empty?
        #  if old_r_accesses.first.iaccess.iticket[:user_id] != @r_user_id.to_i
        #    old_r_accesses.delete_all()
        #  end
        #end
        @accesses = IRetimeaccess.retiming_accesses_list(@issue_id, current_user.id).to_json
        respond_to do |format|
          format.js 
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def show_retiming_accesses
    if params[:user_id].present? && params[:issue_id].present?
      issue_id = params[:issue_id]
      current_user_id = User.current.id
      dependent_user_id = params[:user_id].to_i
      if IGrouplider.lider_for_user(dependent_user_id, current_user_id) || current_user_id == 1 || current_user_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || current_user_id == dependent_user_id
        accesses_list = IRetimeaccess.retiming_accesses_list(issue_id, current_user_id, dependent_user_id)
        respond_to do |format|
          format.json { render :json => [accesses_list] }
        end
      end
    else
      head :forbidden
    end
  end

  def verify_retiming
    issue_id = params[:issue_id]
    user = User.current
    if IRetimeaccess.may_be_verify_retiming(issue_id, user.id)
      IRetimeaccess.verify_tickets_by_security(issue_id, user.id)
      retiming_status = IRetimeaccess.check_retiming_status(issue_id)#, user.id)
      issue = Issue.find(issue_id)
      if retiming_status[0..1] == [1,0] && retiming_status[2] > 0
        assigned_to_id = IRetimeaccess.resowner_for_unapproval_issue(issue_id).first
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user.id) ### set system user_id
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => assigned_to_id)
        journal.details << details
        cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        journal.details << details
        journal.save
        issue.update_attributes(:assigned_to_id => assigned_to_id)
        issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def reject_retiming
    issue_id = params[:issue_id]
    user = User.current
    if IRetimeaccess.may_be_reject_verification_retiming(issue_id, user.id)
      IRetimeaccess.reject_tickets_by_security(issue_id, user.id)
      retiming_status = IRetimeaccess.check_retiming_status(issue_id)#, user.id)
      if retiming_status[0..1] == [0,0]
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user.id) ### set system user_id
        cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "1", :value => "0") ### set current_user
        journal.details << details
        journal.save
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
    else
      #head :forbidden
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def approve_retiming
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user = User.current
    
    if IRetimeaccess.may_be_approve_retiming(issue_id, user.id, r_uid)
      IRetimeaccess.approve_retiming_by_owner(issue_id, user.id, r_uid)
      retiming_status = IRetimeaccess.check_retiming_status(issue_id)
      issue = Issue.find(issue_id)
      if retiming_status[0..1] == [1,1]
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user.id) ### set system user_id
        cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_approved_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => Issue.where(:id => issue_id).first.author_id)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
        journal.details << details
        journal.save
        issue.update_attributes(:status_id => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
        issue.update_attributes(:assigned_to_id => issue.author_id)
      else 
        old_assigned_to_id = issue.assigned_to_id
        assigned_to_id = IRetimeaccess.resowner_for_unapproval_issue(issue_id).first
        if old_assigned_to_id != assigned_to_id
          issue.update_attributes(:assigned_to_id => assigned_to_id)
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user.id) ### set system user_id
          details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => Issue.where(:id => issue_id).first.author_id)
          journal.details << details
          journal.save
        end
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def revoke_retiming
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user = User.current
    if IRetimeaccess.may_be_refuse_approve_retiming(issue_id, user.id, r_uid)
      IRetimeaccess.refuse_approve_retiming_by_owner(issue_id, user.id, r_uid)
      retiming_status = IRetimeaccess.check_retiming_status(issue_id)
      if retiming_status[0..1] == [1,0]
        assigned_to_id = IRetimeaccess.resowner_for_unapproval_issue(issue_id).first
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user.id) ### set system user_id
        cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_approved_id.to_s, :old_value => "1", :value => "0") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => assigned_to_id)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => Issue.find(issue_id).status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        journal.details << details
        journal.save
        Issue.where(:id => issue_id).first.update_attributes(:assigned_to_id => assigned_to_id)
        Issue.where(:id => issue_id).first.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end


end
