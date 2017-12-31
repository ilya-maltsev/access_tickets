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

class IticktemplatesController < ApplicationController

  def show_template_versions
    user_id = User.current.id
    if params[:group_id].present? && params[:template_id].present?
      is_lider_for_group = IGrouplider.is_lider_for_group(params[:group_id], user_id)
      if is_lider_for_group || params[:group_id].to_i.in?(User.current.groups.map(&:id).uniq) || ITicket.check_security_officer(User.current)
        versions = ITicktemplate.template_versions(params[:template_id], user_id)
        respond_to do |format|
          format.json { render :json => {:versions => versions, :is_lider_for_group => is_lider_for_group ? 1 : 0 } }
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end



  def show_group_templates
    if params[:group_id].present?
      is_lider_for_group = IGrouplider.is_lider_for_group(params[:group_id], User.current.id)
      if is_lider_for_group || params[:group_id].to_i.in?(User.current.groups.map(&:id).uniq) || ITicket.check_security_officer(User.current)
        if params[:issue_id].present?
          tracker_id = Issue.find(params[:issue_id]).tracker_id
          tr_template_agreement_id = ISetting.active.where(:param => "tr_template_agreement_id").first.value.to_i
          if tracker_id == tr_template_agreement_id
            group_templates = ITicktemplate.joins(:itickets).where("i_ticktemplates.deleted = 0 and i_ticktemplates.app_issue_id IS NULL and i_tickets.issue_id IS NULL and i_tickets.deleted = 0 and i_tickets.i_ticktemplate_id in (?)", IGrouptemplate.where(:group_id => params[:group_id]).map(&:i_ticktemplate_id).uniq).map(&:id).uniq
          else
            group_templates = ITicktemplate.joins(:itickets).where("i_ticktemplates.deleted = 0 and i_ticktemplates.using_issue_id IS NOT NULL and i_tickets.issue_id IS NOT NULL and i_tickets.deleted = 0 and i_tickets.i_ticktemplate_id in (?)", IGrouptemplate.where(:group_id => params[:group_id]).map(&:i_ticktemplate_id).uniq).map(&:id).uniq
          end
          templates = ITicktemplate.select([:id,:name]).where(:id => group_templates)
          respond_to do |format|
            format.json { render :json => {:templates => templates, :is_lider_for_group => is_lider_for_group ? 1 : 0 } }
          end
        else #params[:group_id].present?
          if params[:deleted].present?
            head :forbidden
          else
            group_templates = IGrouptemplate.where(:group_id => params[:group_id]).map(&:i_ticktemplate_id).uniq
            templates = ITicktemplate.active.select([:id,:name]).where(:id => group_templates)
            respond_to do |format|
              format.json { render :json => {:templates => templates, :is_lider_for_group => is_lider_for_group ? 1 : 0 } }
            end
          end
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def show_template
    if params[:group_id].present? && params[:template_id].present?
      if IGrouptemplate.where(:group_id => params[:group_id], :i_ticktemplate_id => params[:template_id]).count > 0
        if params[:t_uid].present?
          tickets = ITicktemplate.template_version_list(params[:template_id], params[:t_uid], User.current.id)
        else
          tickets = ITicktemplate.template_tickets_list(params[:template_id], params[:group_id], nil, User.current.id)
        end
        respond_to do |format|
          format.json { render :json =>  tickets }
        end
      else
        head :forbidden
      end
    #elsif params[:template_id].present?
    #  template_id = params[:template_id]
    #  tickets = ITicktemplate.template_tickets_list(template_id)
    #  respond_to do |format|
    #    format.json { render :json =>  tickets }
    #  end
    else
      head :forbidden
    end
  end


  def add_template
    if params[:group_id].present? && params[:name].present?
      user = User.current
      group_id = params[:group_id]
      if user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || IGrouplider.is_lider_for_group(group_id, user.id) 
          ticktemplate = ITicktemplate.create(:name => params[:name], :updated_by_id => user.id)
          IGrouptemplate.create(:i_ticktemplate_id => ticktemplate.id, :group_id => group_id)  
          templates_list = ITicktemplate.active.where(:id => IGrouptemplate.where(:group_id => group_id).map(&:i_ticktemplate_id).uniq).select([:id,:name])
          respond_to do |format|
            format.json { render :json => templates_list }
          end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def edit_template
    if params[:group_id].present? && params[:template_id].present? && params[:name].present? 
      user = User.current
      group_id = params[:group_id]
      i_ticktemplate_id = params[:template_id]
      if ( user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || IGrouplider.is_lider_for_group(group_id, user.id) ) && IGrouptemplate.where(:group_id => group_id, :i_ticktemplate_id => i_ticktemplate_id).count > 0
        ITicktemplate.find(params[:template_id]).update_attributes(:name => params[:name])
        templates_list = ITicktemplate.active.where(:id => IGrouptemplate.where(:group_id => group_id).map(&:i_ticktemplate_id).uniq).select([:id,:name])
        respond_to do |format|
          format.json { render :json => templates_list }
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def save_template
    if params[:group_id].present? && params[:template_id].present? && params[:i_tickets].present?
      group_id = params[:group_id]
      i_ticktemplate_id = params[:template_id]
      user = User.current
      if ( ITicket.check_security_officer(user) || IGrouplider.is_lider_for_group(group_id, user.id) ) && IGrouptemplate.where(:group_id => group_id, :i_ticktemplate_id => i_ticktemplate_id).count > 0
        inputData = JSON.parse(params[:i_tickets])
        old_tickets = ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => i_ticktemplate_id) # mark as deleted prev tickets for this issue
        if !old_tickets.empty?
          #old_tickets.update_all(:deleted => true)
          old_tickets.each do |old_ticket|
            old_ticket.itickentities.each { |itickentity| itickentity.delete }
          end
          old_tickets.each { |ticket| ticket.delete }
        end
        if !inputData.empty?
          t_uid = SecureRandom.hex(5)
          inputData.each do |objects|
            r_uid = SecureRandom.hex(5)
            objects["role_id"].each do |role|
              if objects["description"].nil?
                description = ""
              else
                description = objects["description"]
              end
              iticket = ITicket.new(:i_role_id => role, :i_ticktemplate_id => i_ticktemplate_id, :t_uid => t_uid, :i_resource_id => objects["resource_id"], :r_uid => r_uid,
                :description => description)
              iticket.save
              if objects["entity_id"] && IResource.find(objects["resource_id"]).has_entities
                objects["entity_id"].each do |entity|
                  itickentity = iticket.itickentities.new(:i_entity_id => entity)
                  itickentity.save
                end
              end
              
            end
          end
          ITicktemplate.where(:id => i_ticktemplate_id).update_all(:app_issue_id => nil)
        end
        #tickets = ITicktemplate.template_tickets_list(i_ticktemplate_id)
        tickets = ITicktemplate.template_version_list(i_ticktemplate_id, t_uid, user.id)
        versions = ITicktemplate.template_versions(i_ticktemplate_id, user.id)
        respond_to do |format|
          format.json { render :json =>  {:tickets => tickets, :versions => versions }}
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end

  def remove_template
    if params[:group_id].present? && params[:template_id].present?
      group_id = params[:group_id]
      i_ticktemplate_id = params[:template_id]
      user = User.current
      if ( ITicket.check_security_officer(user) || IGrouplider.is_lider_for_group(group_id, user.id) ) && IGrouptemplate.where(:group_id => group_id, :i_ticktemplate_id => i_ticktemplate_id).count > 0
        IGrouptemplate.where(:i_ticktemplate_id => i_ticktemplate_id).update_all(:deleted => true)#.delete_all
        ITicktemplate.where(:id => params[:template_id]).update_all(:deleted => true)#.delete
        old_tickets = ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => i_ticktemplate_id) # mark as deleted prev tickets for this issue
        if !old_tickets.empty?
          old_tickets.update_all(:deleted => true)
        end
        templates_list = ITicktemplate.active.where(:id => IGrouptemplate.where(:group_id => group_id).map(&:i_ticktemplate_id).uniq).select([:id,:name])
        respond_to do |format|
          format.json { render :json =>  templates_list }
        end
      else
        head :forbidden
      end
    else
      head :forbidden
    end
  end


  def set_issue_template
    if params[:issue_id].present? && params[:group_id].present? && params[:template_id].present?
      issue_id = params[:issue_id]
      group_id = params[:group_id]
      template_id = params[:template_id]
      if IGrouptemplate.where(:group_id => group_id, :i_ticktemplate_id => template_id).count > 0 && ITicktemplate.check_template_status(issue_id)[0..1] == [0,0]
        tickets = ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => template_id)
        if tickets.count > 0
        # delete old_tickets
          old_template_id = ITicktemplate.template_id_by_issue(issue_id)
          old_tickets = ITicket.active.where(:i_ticktemplate_id => old_template_id, :issue_id => issue_id)
          if old_tickets.count > 0
            ###check for old_template_draft###
            draft_template_tickets = ITicket.active.where(:i_ticktemplate_id => old_template_id, :issue_id => nil)
            if draft_template_tickets.count > 0
              draft_template_tickets.delete_all
            end
            old_tickets.update_all(:issue_id => nil, :verified_by_id => nil, :verified_at => nil, :approved_by_id => nil, :approved_at => nil)
            #
            #old_tickets.update_all(:issue_id => nil, :verified_by_id => nil, :verified_at => nil, :approved_by_id => nil, :approved_at => nil)
          end
          tickets.update_all(:issue_id => issue_id)
          issue = Issue.where(:id => issue_id).first
          issue.watcher_user_ids = issue.watcher_user_ids | ITicktemplate.resowners_for_issue(issue_id)
          #| User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "admin_group_id").first.value.to_i).map(&:id) | User.active.in_group(ISetting.active.where(:param => "cw_group_id").first.value.to_i).map(&:id) | Issue.where(:id => issue_id).map(&:author_id) 
          issue.save
          issue.update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
        end
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def verify_template
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      if ITicktemplate.may_be_verify_template(issue_id, user_id)
        issue_id = params[:issue_id]
        user_id = User.current.id
        ITicktemplate.verify_template_by_security(issue_id, user_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def reject_template
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      user_id = User.current.id
      if ITicktemplate.may_be_reject_verification_template(issue_id, user_id)
        issue_id = params[:issue_id]
        user_id = User.current.id
        ITicktemplate.reject_template_by_security(issue_id, user_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def approve_template
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      template_id = ITicktemplate.template_id_by_issue(issue_id)
      owner_id = User.current.id
      if ITicktemplate.may_be_approve_template(issue_id, owner_id)
        ITicktemplate.approve_template_by_owner(issue_id, owner_id)
        #issue_status = ITicktemplate.check_template_status(issue_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        head :forbidden
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def revoke_template
    if params[:issue_id].present?
      issue_id = params[:issue_id]
      template_id = ITicktemplate.template_id_by_issue(issue_id)
      owner_id = User.current.id
      if ITicktemplate.may_be_refuse_approve_template(issue_id, owner_id)
        ITicktemplate.refuse_approve_template_by_owner(issue_id, owner_id)
        #issue_status = ITicktemplate.check_template_status(issue_id)
        redirect_to Redmine::Utils::relative_url_root + "/issues/" + issue_id, :status => 302
      else
        #head :forbidden
        render_error({:message => :notice_file_not_found, :status => 404})
      end
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

end
