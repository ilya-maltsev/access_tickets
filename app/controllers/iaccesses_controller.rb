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

  def add_accesses
      respond_to do |format|
        format.js
      end
  end


  def export_all_accesses
    if ITicket.check_security_officer(User.current)
      current_user_id = User.current.id
      a_ies = []
      a_ies.push(['#issue','#resource','#role','#description','#start_date','#end_date','#deactivated_in','#deactivated_at'])
      grant_filter = false
      revoke_filter = false
      if params[:grant_filter].present?
        if params[:grant_filter] == "on"
          grant_filter = true
          s_date_g = params[:s_date_g]
          e_date_g = params[:e_date_g]
        end
      end
      if params[:revoke_filter].present?
        if params[:revoke_filter] == "on"
          revoke_filter = true
          s_date_r = params[:s_date_r]
          e_date_r = params[:e_date_r]
        end
      end
      resources_list = IResource.active.all.map(&:id)
      resources_list.each do |resource|
        accesses_list = IAccess.accesses_list_by_resource(resource, current_user_id)
        rev_accesses_list = IAccess.revoked_accesses_list_by_resource(resource, current_user_id)
        if !revoke_filter
          accesses_list.each do |access|
            if grant_filter
              if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
                a_ies.push(IAccess.create_export_row(access))
              end
            else
              a_ies.push(IAccess.create_export_row(access))
            end
          end
        end
        rev_accesses_list.each do |access|
          if grant_filter && !revoke_filter
            if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
              a_ies.push(IAccess.create_export_row(access))
            end
          elsif !grant_filter && revoke_filter
            if access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
              a_ies.push(IAccess.create_export_row(access))
            end
          elsif grant_filter && revoke_filter
            if access[:s_date].to_date > s_date_g.to_date && access[:s_date].to_date < e_date_g.to_date && access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
              a_ies.push(IAccess.create_export_row(access))
            end
          else
            a_ies.push(IAccess.create_export_row(access))
          end
        end
      end
      csv = IAccess.to_csv(a_ies)
      respond_to do |format|
        format.html
        format.csv { send_data csv, :filename => 'accesses'+'_at_'+ Time.now().strftime("%HH-%MM-%d-%m-%Y") +'.csv' }
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end

  end


  def export_accesses
    current_user_id = User.current.id
    a_ies = []
    a_ies.push(['#issue','#resource','#role','#description','#start_date','#end_date','#deactivated_in','#deactivated_at'])
    grant_filter = false
    revoke_filter = false
    if params[:grant_filter].present?
      if params[:grant_filter] == "on"
        grant_filter = true
        s_date_g = params[:s_date_g]
        e_date_g = params[:e_date_g]
      end
    end
    if params[:revoke_filter].present?
      if params[:revoke_filter] == "on"
        revoke_filter = true
        s_date_r = params[:s_date_r]
        e_date_r = params[:e_date_r]
      end
    end
    if ITicket.check_security_officer(User.current) && params[:user_id].present?
      accesses_list = IAccess.accesses_list(params[:user_id].to_i, nil, current_user_id)
      rev_accesses_list = IAccess.revoked_accesses_list(params[:user_id].to_i, current_user_id)

      if !revoke_filter
        accesses_list.each do |access|
          if grant_filter
            if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
              a_ies.push(IAccess.create_export_row(access))
            end
          else
            a_ies.push(IAccess.create_export_row(access))
          end
        end
      end

      rev_accesses_list.each do |access|
        if grant_filter && !revoke_filter
          if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        elsif !grant_filter && revoke_filter
          if access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        elsif grant_filter && revoke_filter
          if access[:s_date].to_date > s_date_g.to_date && access[:s_date].to_date < e_date_g.to_date && access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        else
          a_ies.push(IAccess.create_export_row(access))
        end
      end

      csv = IAccess.to_csv(a_ies)
      respond_to do |format|
        format.html
        format.csv { send_data csv, :filename => 'accesses'+'_at_'+ Time.now().strftime("%HH-%MM-%d-%m-%Y") +'.csv' }
      end
    elsif ITicket.check_security_officer(User.current) && params[:resource_id].present?
      current_user_id = User.current.id
      accesses_list = IAccess.accesses_list_by_resource(params[:resource_id], current_user_id)
      rev_accesses_list = IAccess.revoked_accesses_list_by_resource(params[:resource_id], current_user_id)

      if !revoke_filter
        accesses_list.each do |access|
          if grant_filter
            if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
              a_ies.push(IAccess.create_export_row(access))
            end
          else
            a_ies.push(IAccess.create_export_row(access))
          end
        end
      end

      rev_accesses_list.each do |access|
        if grant_filter && !revoke_filter
          if access[:s_date].to_date > s_date_g.to_date &&  access[:s_date].to_date < e_date_g.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        elsif !grant_filter && revoke_filter
          if access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        elsif grant_filter && revoke_filter
          if access[:s_date].to_date > s_date_g.to_date && access[:s_date].to_date < e_date_g.to_date && access[:deactivated_at].to_date > s_date_r.to_date && access[:deactivated_at].to_date < e_date_r.to_date
            a_ies.push(IAccess.create_export_row(access))
          end
        else
          a_ies.push(IAccess.create_export_row(access))
        end
      end

      csv = IAccess.to_csv(a_ies)
      respond_to do |format|
        format.html
        format.csv { send_data csv, :filename => 'accesses'+'_at_'+ Time.now().strftime("%HH-%MM-%d-%m-%Y") +'.csv' }
      end

    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def expand_by_user
    if ITicket.check_security_officer(User.current) && params[:user_id].present?
      user_id = params[:user_id]
      at_pr = ISetting.active.where(:param => "at_project_id").first.value
      tr_r = ISetting.active.where(:param => "tr_change_term_id").first.value
      sec_group_id = ISetting.active.where(:param => "sec_group_id").first.value
      eal = IAccess.expired_accesses_list(nil,user_id)
      if !eal.empty?
        counter = 0
        eal.each do |access|
          if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NULL or i_retimeaccesses.r_approved_by_id IS NULL").where(:r_uid => access[:r_uid]).empty?
            counter = counter + 1
          end
        end
        if counter > 0
          i = Issue.create(:tracker_id => tr_r, :project_id => at_pr, :author_id => User.current.id, :assigned_to_id => sec_group_id,:subject => l(:at_prolongation), :description => "", :priority_id => 1)
          if i.save
            IRetimeaccess.create_prolongated_accesses(i.id,eal,Date.today.next_year.strftime("%d.%m.%Y"))
            redirect_to Redmine::Utils::relative_url_root + "/issues/" + i.id.to_s, :status => 302 #root_url
          else
            render_error({:message => :notice_file_not_found, :status => 404})
          end
        else
          render_error({:message => :at_notice_can_not_create_issue, :status => 404})
        end
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end


  def expand_by_resource
    if ITicket.check_security_officer(User.current) && params[:resource_id].present?
      resource_id = params[:resource_id]
      at_pr = ISetting.active.where(:param => "at_project_id").first.value
      tr_r = ISetting.active.where(:param => "tr_change_term_id").first.value
      sec_group_id = ISetting.active.where(:param => "sec_group_id").first.value
      eal = IAccess.expired_accesses_list(resource_id)
      if !eal.empty?
        counter = 0
        eal.each do |access|
          if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NULL or i_retimeaccesses.r_approved_by_id IS NULL").where(:r_uid => access[:r_uid]).empty?
            counter = counter + 1
          end
        end
        if counter > 0
          i = Issue.create(:tracker_id => tr_r, :project_id => at_pr, :author_id => User.current.id, :assigned_to_id => sec_group_id,:subject => l(:at_prolongation, :resource_name => IResource.find(resource_id).name), :description => "", :priority_id => 1)
          if i.save
            IRetimeaccess.create_prolongated_accesses(i.id,eal,Date.today.next_year.strftime("%d.%m.%Y"))
            i.watcher_user_ids = i.watcher_user_ids | IRetimeaccess.resowners_for_issue(i.id)
            i.save
            redirect_to Redmine::Utils::relative_url_root + "/issues/" + i.id.to_s, :status => 302 #root_url
          else
            render_error({:message => :notice_file_not_found, :status => 404})
          end
        else
          render_error({:message => :at_notice_can_not_create_issue, :status => 404})
        end
      else
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end



  def set_dismissal_user
    if params[:r_user_id].present? && params[:issue_id].present?
      issue_id = params[:issue_id]
      r_user_id = params[:r_user_id].to_i
      user_id = User.current.id
      if IAccess.can_dismiss_user(r_user_id, user_id)
        old_r_accesses = IAccess.active.where(:rev_issue_id => issue_id)
        if !old_r_accesses.empty?
          old_r_accesses.update_all(:revoked_by_id => nil, :rev_issue_id => nil, :deactivated_by_id => nil, :deactivated_at => nil)
          IAccess.refuse_confirmation_revoking_for_accesses(issue_id, user_id)
        end
        accesses = IAccess.accesses_list(r_user_id)
        if !accesses.empty?
          rev_accesses = []
          accesses.each do |access|
            r_access = {}
            r_access[:r_uid] = access[:r_uid]
            r_access[:entities] = []
            access[:ientities].each do |ientity|
              r_access[:entities].push(ientity[:id].to_s)
            end
            rev_accesses.push(r_access)
          end
          rev_accesses.each do |rev_access|
            if rev_access[:entities].empty?
              IAccess.joins(:iticket).where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => rev_access[:r_uid]).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id)
            else
              IAccess.joins(:iticket).where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => rev_access[:r_uid], "i_accesses.i_entity_id" => rev_access[:entities]).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id)
            end
          end
          issue = Issue.find(issue_id)
          #issue.watcher_user_ids = issue.watcher_user_ids | User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "admin_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "cw_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | Issue.where(:id => issue_id).map(&:author_id)
          #issue.save
          revoking_status = IAccess.check_revoking_status(issue_id, user_id)
          if revoking_status[4] == 1
            IAccess.confirm_revoking_for_accesses(issue_id, user_id)
            journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
            details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => ISetting.active.where(:param => "admin_group_id").first.value)
            journal.details << details
            details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
            journal.details << details
            journal.save
            issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)
            issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
          end
        else
          IAccess.refuse_confirmation_revoking_for_accesses(issue_id, user_id)
        end
        accesses = IAccess.accesses_list(0, issue_id, user_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302 #root_url
        #respond_to do |format|
        #  format.json { render :json =>  [accesses, IAccess.last_revoking_version(issue_id, user_id), IAccess.check_revoking_status(issue_id, user_id)] }
        #end
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

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
        old_r_accesses.update_all(:revoked_by_id => nil, :revoked_at => nil, :rev_issue_id => nil, :r_created_by_id => nil)
      end

      if !inputData.empty?
        inputData.each do |ticket|
          if ticket["entities"].empty?
            if !IResource.find(ITicket.where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"]).first[:i_resource_id]).has_entities
              ids = IAccess.active.joins(:iticket).where("i_accesses.rev_issue_id is NULL").where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"]).select("i_accesses.id").map(&:id)
              IAccess.where(:id => ids).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id, :updated_at => Time.now)
            end
          else
            ids = IAccess.active.joins(:iticket).where("i_accesses.rev_issue_id is NULL").where("i_tickets.user_id" => r_user_id, "i_tickets.r_uid" => ticket["r_uid"], "i_accesses.i_entity_id" => ticket["entities"]).select("i_accesses.id").map(&:id)
            IAccess.where(:id => ids).update_all(:rev_issue_id => issue_id, :r_created_by_id => user_id, :updated_at => Time.now)
          end
        end
      end
      #issue = Issue.find(issue_id)
      #issue.watcher_user_ids = issue.watcher_user_ids | User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "admin_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "cw_group_id").first.value.to_i).map(&:id) | Issue.where(:id => issue_id).map(&:author_id)
      #issue.save
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


  def OLD_show_template
      template_id = params[:template_id]
      tickets = ITicktemplate.template_tickets_list(template_id)
      respond_to do |format|
        format.json { render :json =>  tickets }
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


  def access_templates
    user = User.current
    if user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || IGrouplider.is_group_lider(User.current.id)
      respond_to do |format|
        format.html {
          render :template => 'iaccesses/access_templates'
        }
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
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
        #tickets = ITicket.tickets_list(issue_id, user_id)
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
        #tickets = ITicket.tickets_list(issue_id, user_id)
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
      #tickets = ITicket.tickets_list(issue_id, user_id)
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
          journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id)
          cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
          details = JournalDetail.new(:property => "cf", :prop_key => cf_confirming_id.to_s, :old_value => "0", :value => "1") ### set current_user
          journal.details << details
          details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
          journal.details << details
          journal.save
          issue.update_attributes(:status_id => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)####
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





  def accesses_list_save
    if ITicket.check_security_officer(User.current)
      issue_name = params[:issue_name]
      description = params[:description]
      user_id = User.current.id
      itickets_ids = []
      at_pr = ISetting.active.where(:param => "at_project_id").first.value
      tr_r = ISetting.active.where(:param => "tr_grant_id").first.value
      bs_id = ISetting.active.where(:param => "blocked_issue_status_id").first.value
      #old_tickets = ITicket.active.where(:issue_id => issue_id) # mark as deleted prev tickets for this issue
      #if !old_tickets.empty?
      #  old_tickets.update_all(:deleted => true)
      #end
      exist_accesses = []
      #issue = Issue.where(:id => issue_id).first
      if params[:group_id].present? && params[:template_id].present? #&& ISetting.active.where(:param => "at_simple_approvement").first.value.to_i == 1
        #rawData = JSON.parse(params[:i_tickets])
        group_id = params[:group_id]
        i_ticktemplate_id = params[:template_id]
        #vData = ITicket.verify_tickets_for_simple_approvement(rawData, group_id, i_ticktemplate_id, issue_id)
        vData = JSON.parse(params[:i_tickets])
        inputData = ITicket.verify_tickets_for_duplicates(vData)
        exist_accesses = inputData[:exist_accesses]
        t_uid = SecureRandom.hex(5)
        if !inputData[:ticktets].empty?
          i = Issue.create(:tracker_id => tr_r, :project_id => at_pr, :author_id => user_id, :assigned_to_id => user_id,:subject => issue_name, :description => description, :priority_id => 1, :status_id => bs_id)
          i.save
          issue_id = i.id
          cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
          cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
          cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
          cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id).update_all(:value => 1)
          inputData[:ticktets].each do |object|
            r_uid = SecureRandom.hex(5)
            if object["user_id"] == nil
              object["user_id"] = []
              object["user_id"].push(0)
            end
            object["user_id"].each do |user|
              object["role_id"].each do |role|
                if object["description"].nil?
                  description = ""
                else
                  description = object["description"]
                end
                iticket = ITicket.new(:user_id => user, :i_role_id => role, :t_uid => t_uid, :i_resource_id => object["resource_id"], :r_uid => r_uid,
                  :description => description, :s_date => object["s_date"], :e_date => object["e_date"], :f_date => object["e_date"], :issue_id => issue_id,:verified_by_id => user_id, :verified_at => Time.now,:approved_by_id => user_id, :approved_at => Time.now)
                iticket.save
                itickets_ids.push(iticket.id)
                if object["entity_id"]
                  object["entity_id"].each do |entity|
                    itickentity = iticket.itickentities.new(:i_entity_id => entity)
                    itickentity.save
                  end
                end
              end
            end
          #ITicket.verify_tickets_by_security(issue_id, 1)
          #ITicket.active.where(:issue_id => issue_id).update_all(:approved_by_id => user_id, :approved_at => Time.now) ####?????
          #issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "admin_group_id").first.value)

          end
        end


      else
        vData = JSON.parse(params[:i_tickets])
        inputData = ITicket.verify_tickets_for_duplicates(vData)
        exist_accesses = inputData[:exist_accesses]
        t_uid = SecureRandom.hex(5)
        if !inputData[:ticktets].empty?
          i = Issue.create(:tracker_id => tr_r, :project_id => at_pr, :author_id => user_id, :assigned_to_id => user_id,:subject => issue_name, :description => description, :priority_id => 1, :status_id => bs_id)
          i.save
          issue_id = i.id
          cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
          cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
          cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
          cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id).update_all(:value => 1)
          CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id).update_all(:value => 1)
          inputData[:ticktets].each do |object|
            r_uid = SecureRandom.hex(5)
            object["user_id"].each do |user|
              object["role_id"].each do |role|
                if object["description"].nil?
                  description = ""
                else
                  description = object["description"]
                end
                iticket = ITicket.new(:user_id => user, :i_role_id => role, :t_uid => t_uid, :i_resource_id => object["resource_id"], :r_uid => r_uid, :description => description, :s_date => Date.parse(object["s_date"]), :e_date => Date.parse(object["e_date"]), :f_date => Date.parse(object["e_date"]), :issue_id => issue_id, :verified_by_id => user_id, :verified_at => Time.now,:approved_by_id => user_id, :approved_at => Time.now)
                iticket.save
                itickets_ids.push(iticket.id)
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

        #issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
      end

      if !itickets_ids.empty?
        itickets = ITicket.active.where(:id => itickets_ids)
        itickets.each do |iticket|
          if iticket.iaccesses.active.count > 0
            iticket.iaccesses.active.each  { |access| access.delete }
          end
        end
        itickets.each do |iticket|
          if iticket.ientities.empty?
              iaccess = IAccess.new(:i_ticket_id => iticket.id, :granted_by_id => user_id, :granted_at => Time.now, :confirmed_by_id => user_id, :confirmed_at => Time.now)
              iaccess.save
          else
            iticket.ientities.each {|entity|
              iaccess = IAccess.new(:i_ticket_id => iticket.id, :granted_by_id => user_id, :granted_at => Time.now, :confirmed_by_id => user_id, :confirmed_at => Time.now, :i_entity_id => entity.id)
              iaccess.save
            }
          end
        end
      end


      #issue = Issue.where(:id => issue_id).first
      #issue.watcher_user_ids = issue.watcher_user_ids | ITicket.resowners_for_issue(issue_id)

      #issue.save
      #ITicket.check_itickets_for_verified(issue_id)
      #ITicket.check_itickets_for_approved(issue_id)
      #ITicket.check_itickets_for_granted(issue_id)
      #ITicket.check_itickets_for_confirmed(issue_id)
      #check_issue_status = 0
      #show_last_ticket_version = 0
      tickets = itickets_ids.count
      respond_to do |format|
        format.json { render :json =>  [tickets, issue_id, exist_accesses] } # show_last_ticket_version, check_issue_status
      end
    else
      head :forbidden
    end
  end


end
