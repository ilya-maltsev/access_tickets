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


class IticketsController < ApplicationController

  def show_last_users
    users_nosort = []
    first_option = {}
    first_option[:id] = ""
    first_option[:name] = l(:at_select_employee)
    users = User.active.select([:id,:firstname,:lastname])
    users.each do |user|
      option = {}
      option[:id] = user.id
      option[:name] = user.firstname + " " + user.lastname
      if users_nosort.detect{|w| w[:id] == option[:id]}.nil?
        users_nosort.push(option)
      end
    end
    users_list = users_nosort.sort_by! {|u| -u[:id]}
    users_list.insert(0, first_option)
    respond_to do |format|
      format.json { render :json =>  users_list }
    end
  end

  def set_tickets_user
    if params[:user_id].present? && params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = params[:user_id]
      c_user_id = User.current.id
      if ITicket.may_be_set_ticket_user(issue_id, c_user_id) 
        ITicket.set_user_for_tickets(issue_id, user_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def show_at_project
    if !ISetting.active.where(:param => "at_project_id").first.nil?
      at_project = ISetting.active.where(:param => "at_project_id").first.value
    else
      at_project = 1
    end
    if !ISetting.active.where(:param => "blocked_issue_status_id").first.nil?
      value = "!" + ISetting.active.where(:param => "blocked_issue_status_id").first.value
    else
      value = "*"
    end
    redirect_to Redmine::Utils::relative_url_root + "/projects/" + at_project + "/issues?set_filter=1&status_id=" + value, :status => 302
  end

  def edit_ticket_table_add_row
    respond_to do |format|
      format.js
    end
  end


  def ticket_table_show_version
    issue_id = params[:issue_id]
    t_uid = params[:version]
    itickets = ITicket.show_tickets_list(issue_id,t_uid)
    respond_to do |format|
      format.json { render :json =>  [itickets, t_uid] }
    end
  end

  def edit_ticket_table
    @current_year = Time.now().strftime("%Y").to_i
    @last_year = @current_year + 10
    @issue_id = params[:issue_id]
    @tracker_id = Issue.find(@issue_id).tracker_id
    @itickets = []
    tr_new_emp_id = 0
    if ISetting.active.where(:param => "at_simple_approvement").first.value.to_i == 0 || (ITicket.check_security_officer(User.current) && @tracker_id != tr_new_emp_id )
      @itickets = ITicket.edit_tickets_list(@issue_id).to_json
    end

    issue_editable = IticketsController.check_issue_editable(@issue_id,User.current)
    if issue_editable
      if @tracker_id == tr_new_emp_id 
        if tr_new_emp_is_date
          respond_to do |format|
            format.js 
          end
        else
          respond_to do |format|
            format.js { render "tr_new_emp_missing_sdate.js" }
          end
        end
      else
        respond_to do |format|
          format.js 
        end
      end
    else
      head :forbidden
    end
  end

  def self.check_issue_editable(issue_id,user)
    if issue_id.nil?
      false
    else
      if ITicket.check_security_officer(user) 
        return true
      elsif CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i, :value => 1).count > 0 || CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_verified_id").first.value.to_i, :value => 1).count > 0 
        return false
      else
        return true
      end
    end
  end

  def edit_ticket_table_save
    if IticketsController.check_issue_editable(params[:issue_id], User.current) 
      issue_id = params[:issue_id]
      user_id = User.current.id
      old_tickets = ITicket.active.where(:issue_id => issue_id) # mark as deleted prev tickets for this issue
      if !old_tickets.empty?
        old_tickets.update_all(:deleted => true)
      end
      exist_accesses = []
      issue = Issue.where(:id => issue_id).first
      vData = JSON.parse(params[:i_tickets])
      inputData = ITicket.verify_tickets_for_duplicates(vData)
      exist_accesses = inputData[:exist_accesses]
      t_uid = SecureRandom.hex(5)
      if !inputData[:tickets].empty?
        inputData[:tickets].each do |object|
          r_uid = SecureRandom.hex(5)
          object["user_id"].each do |user|

            object["role_id"].each do |role|

              iticket = ITicket.new(:user_id => user, :i_role_id => role, :t_uid => t_uid, :i_resource_id => object["resource_id"], :r_uid => r_uid, :description => object["description"], :s_date => Date.parse(object["s_date"]), :e_date => Date.parse(object["e_date"]), :f_date => Date.parse(object["e_date"]), :issue_id => issue_id)
              iticket.save

              if object["entity_id"]
                object["entity_id"].each do |entity|
                  itickentity = iticket.itickentities.new(:i_entity_id => entity)
                  itickentity.save
                end
              end
            end        
          end  
        end
      end
      issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
      issue.watcher_user_ids = issue.watcher_user_ids | User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "admin_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "cw_group_id").first.value.to_i).map(&:id) | Issue.where(:id => issue_id).map(&:author_id) | ITicket.resowners_for_issue(issue_id)
      issue.save
      ITicket.check_itickets_for_verified(issue_id)
      ITicket.check_itickets_for_approved(issue_id)
      ITicket.check_itickets_for_granted(issue_id)
      ITicket.check_itickets_for_confirmed(issue_id)
      check_issue_status = 0 
      show_last_ticket_version = 0 
      tickets = 0 
      respond_to do |format|
        format.json { render :json =>  [tickets, show_last_ticket_version, check_issue_status, exist_accesses] }
      end
    else
      head :forbidden
    end
  end


  def self.show_last_ticket_version(issue_id)
    if !ITicket.active.where(:issue_id => issue_id).empty?
      Time::DATE_FORMATS.merge!(:localdb=>"%H:%M:%S %d.%m.%Y")
      if User.current.time_zone != nil
        tz = User.current.time_zone
      else
        tz = "Minsk"
      end
      version = ITicket.ticket_last_version(issue_id)
      version_value = "(" + l(:at_last_edited_by) + version.firstname + " " + version.lastname + l(:at_at) + version.created_at.in_time_zone(tz).to_s(:localdb) + ")"
    else
      version_value = ""
    end
  end

  def verify_tickets
    if ITicket.check_security_officer(User.current)
      user_id = User.current.id
      if params[:issue_id].present?
        issue_id = params[:issue_id]
        ITicket.verify_tickets_by_security(issue_id, user_id)
        assigned_to_id = ITicket.resowner_for_unapproval_issue(issue_id).first
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => assigned_to_id)
        journal.details << details
        cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        journal.save
        Issue.where(:id => issue_id).first.update_attributes(:assigned_to_id => assigned_to_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
      elsif params[:template_id].present?
        ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => params[:template_id]).update_all(:verified_by_id => user_id, :verified_at => Time.now)
        tickets = ITicktemplate.template_tickets_list(params[:template_id])
        respond_to do |format|
          format.json { render :json =>  tickets }
        end
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def reject_tickets
    if ITicket.check_security_officer(User.current)
      user_id = User.current.id
      if params[:issue_id].present?
        issue_id = params[:issue_id]
        ITicket.reject_tickets_by_security(issue_id, user_id)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "1", :value => "0") ### set current_user
        journal.details << details
        journal.save
        tickets = []
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
      elsif params[:template_id].present?
        ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => params[:template_id]).update_all(:verified_by_id => nil, :verified_at => nil)
        tickets = ITicktemplate.template_tickets_list(params[:template_id])
        respond_to do |format|
          format.json { render :json =>  tickets }
        end
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def approve_tickets
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user_id = User.current.id
    if ITicket.may_be_approved_by_owner_status(issue_id, user_id, r_uid)
      ITicket.approve_tickets_by_owner(issue_id, user_id, r_uid)
      issue_status = ITicket.check_issue_status(issue_id) #, user_id)
      if issue_status[0..3] == [1,1,0,0]
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
        journal.details << details
        cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
        details = JournalDetail.new(:property => "cf", :prop_key => cf_approved_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        journal.save
        Issue.where(:id => issue_id).first.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
      else
        assigned_to_id = ITicket.resowner_for_unapproval_issue(issue_id).first
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => assigned_to_id)
        journal.details << details
        journal.save
        Issue.where(:id => issue_id).first.update_attributes(:assigned_to_id => assigned_to_id)
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def revoke_tickets
    issue_id = params[:issue_id]
    if params[:uid].present?
      r_uid = params[:uid]
    else 
      r_uid = nil
    end
    user_id = User.current.id
    if ITicket.may_be_revoked_by_owner_status(issue_id, user_id, r_uid)
      tracker_id = Issue.find(issue_id).tracker_id
      tr_new_emp_id = 0#ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
      if tracker_id == tr_new_emp_id
        ITicket.reject_tickets_by_security(issue_id, user_id)
        ITicket.check_itickets_for_approved(issue_id)
      else
        ITicket.revoke_tickets_by_owner(issue_id, user_id, r_uid)
      end
      issue_status = ITicket.check_issue_status(issue_id)#, user_id)
      if issue_status[0..3] == [0,0,0,0]
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "sec_group_id").first.value)
        journal.details << details
        journal.save
        Issue.where(:id => issue_id).first.update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
      elsif issue_status[0..3] == [1,0,0,0] 

      else
      end
      redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

end
