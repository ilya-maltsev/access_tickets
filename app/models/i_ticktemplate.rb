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

class ITicktemplate < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  #belongs_to :ientity, :class_name => "IEntity", :foreign_key => "i_entity_id"
  #belongs_to :iticket, :class_name => "ITicket", :foreign_key => "i_ticket_id"
  has_many :itickets, :class_name => "ITicket"
  attr_accessible :name, :updated_by_id, :deleted, :app_issue_id
  validates :name, length: { in: 2..64 }
  #belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  before_create :default

  def default
    self.deleted = 0
  end

  def self.resowner_for_unapproval_issue(issue_id)
    unapproval_res_id = ITicket.active.where('i_tickets.verified_by_id IS NOT NULL and i_tickets.approved_by_id IS NULL').where(:issue_id => issue_id).first[:i_resource_id]
    IResowner.where(:i_resource_id => unapproval_res_id).map(&:user_id).uniq - [1]
  end

  def self.resowners_for_issue(issue_id)
    resources_ids = ITicket.active.where(:issue_id => issue_id).map(&:i_resource_id)
    IResowner.where(:i_resource_id => resources_ids).map(&:user_id).uniq - [1]
  end

  def self.template_versions(template_id, current_user_id)
    Time::DATE_FORMATS.merge!(:localdb=>"%d.%m.%Y %H:%M")
    if !current_user_id.nil?
      if User.find(current_user_id).time_zone != nil
        tz = User.current.time_zone
      else
        tz = "Minsk"
      end
    else
      tz = "Minsk"
    end
    version_list = []
    using_issue_id = ITicktemplate.find(template_id)[:using_issue_id]

    unusing_versions = ITicket.active.where('i_tickets.approved_by_id is NULL').where(:i_ticktemplate_id => template_id).order("created_at desc").map(&:t_uid).uniq
      unusing_versions.each do |hash|
      version = ITicket.where(:i_ticktemplate_id => template_id, :t_uid => hash).first
      version_option = []
      if !version[:approved_by_id].nil? && !version[:issue_id].nil?
        #has approved
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_approved)
        version_status = 2
        issue_id = version[:issue_id]
      elsif version[:approved_by_id].nil? && !version[:issue_id].nil?
        #in approving
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_on_approval)
        version_status = 1
        issue_id = version[:issue_id]
      elsif version[:issue_id].nil?
        #not approved
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_draft)
        version_status = 0
        issue_id = version[:issue_id]
      else

      end
      version_id = version.t_uid
      version_option.push(version_value)
      version_option.push(version_id)
      version_option.push(version_status)
      version_option.push(issue_id)
      version_list.push(version_option)
    end

    using_versions = ITicket.active.where('i_tickets.approved_by_id is NOT NULL').where(:issue_id => using_issue_id,:i_ticktemplate_id => template_id).map(&:t_uid).uniq
      using_versions.each do |hash|
      version = ITicket.where(:i_ticktemplate_id => template_id, :t_uid => hash).first
      version_option = []
      if !version[:approved_by_id].nil? && !version[:issue_id].nil?
        #has approved
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_approved)
        version_status = 2
        issue_id = version[:issue_id]
      elsif version[:approved_by_id].nil? && !version[:issue_id].nil?
        #in approving
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_on_approval)
        version_status = 1
        issue_id = version[:issue_id]
      elsif version[:issue_id].nil?
        #not approved
        version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb)# + l(:at_draft)
        version_status = 0
        issue_id = version[:issue_id]
      else

      end
      version_id = version.t_uid
      version_option.push(version_value)
      version_option.push(version_id)
      version_option.push(version_status)
      version_option.push(issue_id)
      version_list.push(version_option)
    end

    version_list
  end


  def self.previous_using_issue_id(template_id)
    old_template_ticket_template = ITicket.active.where("i_tickets.issue_id IS NOT NULL and i_tickets.verified_by_id IS NOT NULL and i_tickets.approved_by_id IS NOT NULL").where(:i_ticktemplate_id => template_id).order(:approved_by_id)
    #old_template_ticket_template = ITicket.active.where("i_tickets.issue_id IS NULL and i_tickets.verified_by_id IS NOT NULL and i_tickets.approved_by_id IS NOT NULL").where(:i_ticktemplate_id => template_id).order_by("approved_by_id DESC").limit(1)
    if old_template_ticket_template.count > 0
      old_template_ticket_template.last[:issue_id]
    else
      nil
    end
      
  end


  def self.unapproved_templates(group_id)
    unapproved_templates_ids = []
    template_ids = IGrouptemplate.joins(:iticktemplate).where('i_ticktemplates.app_issue_id IS NULL').where(:group_id => group_id).map(&:i_ticktemplate_id).uniq
    template_ids.each do |template_id|
      if ITicket.active.where(:i_ticktemplate_id => template_id).count > 0
        unapproved_templates_ids.push(template_id)
      end
    end
     ITicktemplate.active.select([:id,:name]).where('i_ticktemplates.app_issue_id IS NULL').where(:id => unapproved_templates_ids)
  end 


  def self.template_tickets_list(template_id, group_id = nil, issue_id = nil, current_user_id = nil)
    if template_id == 0 || group_id == 0
      tickets = []
    else
      Time::DATE_FORMATS.merge!(:atf=>"%H:%M %d.%m.%Y")
      if !current_user_id.nil?
        granted_resources = IResgranter.where(:user_id => current_user_id).map(&:i_resource_id)
        if User.find(current_user_id).time_zone != nil
          tz = User.current.time_zone
        else
          tz = "Minsk"
        end
      else
        tz = "Minsk"
      end
      tickets = []
      users = []
      using_issue_id = ITicktemplate.find(template_id)[:using_issue_id]
      if issue_id.nil? 
        if using_issue_id.nil?
          r_uids = ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => template_id).map(&:r_uid).uniq
        else
          r_uids = ITicket.active.where(:issue_id => using_issue_id, :i_ticktemplate_id => template_id).map(&:r_uid).uniq
        end
      else
        r_uids = ITicket.active.where(:issue_id => issue_id, :i_ticktemplate_id => template_id).map(&:r_uid).uniq
      end
      if !group_id.nil?
        group_users = User.in_group(group_id).select([:id, :firstname, :lastname])
        group_users.each do |group_user|
          user = {}
          user[:id] = group_user[:id]
          user[:name] = group_user[:firstname] + " " + group_user[:lastname]
          users.push(user)
        end
      end
      r_uids.each do |hash|
        if issue_id.nil?
          if using_issue_id.nil?
            main_tickets = ITicket.active.where("i_tickets.issue_id IS NULL").where(:i_ticktemplate_id => template_id, :r_uid => hash)
          else
            main_tickets = ITicket.active.where(:issue_id => using_issue_id, :i_ticktemplate_id => template_id, :r_uid => hash)
          end
        else
          main_tickets = ITicket.active.where(:issue_id => issue_id, :i_ticktemplate_id => template_id, :r_uid => hash)
        end
        ticket = main_tickets.select([:description]).first.attributes.symbolize_keys
        ticket[:uid] = hash
        main_ticket = main_tickets.first

        ticket[:i_resource_id] = main_tickets.map(&:i_resource_id).uniq
        if !main_ticket[:verified_by_id].nil?
          if main_ticket[:approved_by_id].nil?
            ticket[:status] = l(:at_need_to_approve)
            ticket[:status_id] = 1
          else
            ticket[:status] = l(:at_approved_by_owner)
            ticket[:status_id] = 2
            ticket[:user_id] = main_ticket[:approved_by_id]
            ticket[:user_name] = User.where(:id => main_ticket[:approved_by_id]).first.name
            #maybe grant by user for r_uid?
            if !current_user_id.nil?
              if ticket[:i_resource_id].in?(granted_resources)
                ticket[:may_be_granted] = 1
              else
                ticket[:may_be_granted] = 0
              end
            end
          end
        else
          ticket[:status] = l(:at_need_to_verified)
          ticket[:status_id] = 0
        end
        #ticket[:i_resource_id] = self.where(:i_ticktemplate_id => template_id, :r_uid => hash).select(:i_resource_id).map(&:i_resource_id).uniq

        ticket[:i_roles] = main_tickets.select(:i_role_id).map(&:i_role_id).uniq
        iresource = IResource.find(main_ticket[:i_resource_id])
        ticket[:i_resource] = iresource.name
        #ticket[:i_resource_roles] = self.where(:i_ticktemplate_id => template_id, :r_uid => hash).select(:i_resource_id).first.iresource.iroles.active.select([:id,:name])
        ticket[:i_resource_roles] = iresource.iroles.active.where(:id => ticket[:i_roles]).select([:id,:name])
        if iresource.has_entities
          ticket[:i_entities] = iresource.ientities.active.select(['i_entities.id',:name,:ipv4])
        else
          ticket[:i_entities] = []
        end
        ticket[:i_res_has_ip] = iresource.has_ip
        ticket[:i_res_has_entities] = iresource.has_entities
        ticket[:i_entity] = main_ticket.ientities.select(['i_entities.id'])
        ticket[:s_date] = "";
        ticket[:e_date] = "31.12.2025";
        ticket[:verified_by_id] = main_ticket[:verified_by_id]
        if !group_id.nil?
          ticket[:group_users] = users
        end
        tickets.push(ticket)
      end  
    end
    tickets
  end


  def self.template_version_list(template_id, t_uid, current_user_id)
    Time::DATE_FORMATS.merge!(:atf=>"%H:%M %d.%m.%Y")
    if !current_user_id.nil?
      if User.find(current_user_id).time_zone != nil
        tz = User.current.time_zone
      else
        tz = "Minsk"
      end
    else
      tz = "Minsk"
    end
    tickets = []
    r_uids = ITicket.active.where(:t_uid => t_uid, :i_ticktemplate_id => template_id).map(&:r_uid).uniq
    r_uids.each do |hash|
      main_tickets = ITicket.active.where(:t_uid => t_uid, :i_ticktemplate_id => template_id, :r_uid => hash)
      ticket = main_tickets.select([:description]).first.attributes.symbolize_keys
      ticket[:uid] = hash
      main_ticket = main_tickets.first
      ticket[:i_resource_id] = main_tickets.map(&:i_resource_id).uniq
      if !main_ticket[:verified_by_id].nil?
        if main_ticket[:approved_by_id].nil?
          ticket[:status] = l(:at_need_to_approve)
          ticket[:status_id] = 1
        else
          ticket[:status] = l(:at_approved_by_owner)
          ticket[:status_id] = 2
          ticket[:user_id] = main_ticket[:approved_by_id]
          ticket[:user_name] = User.where(:id => main_ticket[:approved_by_id]).first.name
          #maybe grant by user for r_uid?
        end
      else
        ticket[:status] = l(:at_need_to_verified)
        ticket[:status_id] = 0
      end
      ticket[:i_roles] = main_tickets.select(:i_role_id).map(&:i_role_id).uniq
      iresource = IResource.find(main_ticket[:i_resource_id])
      ticket[:i_resource] = iresource.name
      #ticket[:i_resource_roles] = iresource.iroles.active.where(:id => ticket[:i_roles]).select([:id,:name])
      ticket[:i_resource_roles] = iresource.iroles.active.select([:id,:name])
      if iresource.has_entities
        ticket[:i_entities] = iresource.ientities.active.select(['i_entities.id',:name,:ipv4])
      end
      ticket[:i_res_has_ip] = iresource.has_ip
      ticket[:i_res_has_entities] = iresource.has_entities
      ticket[:i_entity] = main_ticket.ientities.select(['i_entities.id'])
      ticket[:s_date] = "";
      ticket[:e_date] = "31.12.2025";
      ticket[:verified_by_id] = main_ticket[:verified_by_id]
      ticket[:issue_id] = main_ticket[:issue_id]
      tickets.push(ticket)
    end  
    tickets
  end


  def self.check_template_status(issue_id, current_user_id = nil)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value

    cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id)
    if cf_verified.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id, :value => 0)
      cf_verified = 0
    else
      cf_verified = cf_verified.first.value.to_i
    end

    cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id)
    if cf_approved.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id, :value => 0)
      cf_approved = 0
    else
      cf_approved = cf_approved.first.value.to_i
    end


    if cf_verified == 0
      Issue.find(issue_id).update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
    end

    #tickets_count = ITicket.active.where("i_tickets.issue_id IS NULL").where(:issue_id => issue_id).count

    template_id = ITicktemplate.template_id_by_issue(issue_id)
    if !template_id.nil?
      group_id = IGrouptemplate.group_id_by_template(template_id)
    else
      group_id = nil
    end
    if current_user_id.nil?
      return cf_verified, cf_approved, template_id, group_id
    else
      #security_officer = ITicket.check_security_officer( User.where(:id => current_user_id).first) ? 1 : 0
      if !template_id.nil? && !group_id.nil? 
        may_be_verify_template = ITicktemplate.may_be_verify_template(issue_id, current_user_id) ? 1 : 0
        may_be_reject_verification_template = ITicktemplate.may_be_reject_verification_template(issue_id, current_user_id) ? 1 : 0
        may_be_approve_template = ITicktemplate.may_be_approve_template(issue_id, current_user_id) ? 1 : 0
        may_be_refuse_approve_template = ITicktemplate.may_be_refuse_approve_template(issue_id, current_user_id) ? 1 : 0
      else
        template_id = 0 ##??
        group_id = 0 ##??
        may_be_verify_template = 0
        may_be_reject_verification_template = 0
        may_be_approve_template = 0
        may_be_refuse_approve_template = 0
      end


      #             0           1             2         3              4                    5                  6                        7   
      return cf_verified, cf_approved, group_id, template_id, may_be_verify_template, may_be_reject_verification_template, may_be_approve_template, may_be_refuse_approve_template
    end
  end



  def self.check_template_for_verified(issue_id, user_id) # Not used
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
      cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).first.value.to_i
      is_all_tickets_verified = ITicket.active.where(:issue_id => issue_id).count == ITicket.active.where("i_tickets.verified_by_id IS NOT NULL").where(:issue_id => issue_id).count
      issue = Issue.find(issue_id)
      if is_all_tickets_verified && cf_verified == 0
        assigned_to_id = ITicktemplate.resowner_for_unapproval_issue(issue_id).first
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => assigned_to_id)
        journal.details << details
        journal.save
        issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        issue.update_attributes(:assigned_to_id => assigned_to_id)
      elsif !is_all_tickets_verified && cf_verified == 1
        assigned_to_id = ISetting.active.where(:param => "sec_group_id").first.value
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "cf", :prop_key => cf_verified_id.to_s, :old_value => "1", :value => "0") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => Issue.find(issue_id).assigned_to_id, :value => assigned_to_id)
        journal.details << details
        journal.save
        issue.update_attributes(:assigned_to_id => assigned_to_id)
      else

      end
    end
  end


  def self.check_template_for_approved(issue_id, user_id)
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
      cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).first.value.to_i
      is_all_tickets_approved = ITicket.active.where(:issue_id => issue_id).count == ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id).count
      template_id = ITicktemplate.template_id_by_issue(issue_id)
      issue = Issue.find(issue_id)
      if is_all_tickets_approved && cf_approved == 0
        assigned_to_id = issue.author_id
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 1)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "cf", :prop_key => cf_approved_id.to_s, :old_value => "0", :value => "1") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => assigned_to_id)
        journal.details << details
        journal.save
        ITicktemplate.where(:id => template_id).update_all(:app_issue_id => issue_id, :using_issue_id => issue_id)
        issue.update_attributes(:status_id => ISetting.active.where(:param => "blocked_issue_status_id").first.value.to_i)
        issue.update_attributes(:assigned_to_id => assigned_to_id)
      elsif !is_all_tickets_approved && cf_approved == 1
        assigned_to_id = ITicktemplate.resowner_for_unapproval_issue(issue_id).first
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 0)
        journal = Journal.create(:journalized_id => issue_id, :journalized_type=> "Issue", :user_id=> user_id) ### set system user_id
        details = JournalDetail.new(:property => "cf", :prop_key => cf_approved_id.to_s, :old_value => "1", :value => "0") ### set current_user
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "status_id", :old_value => issue.status_id, :value => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        journal.details << details
        details = JournalDetail.new(:property => "attr", :prop_key => "assigned_to_id", :old_value => issue.assigned_to_id, :value => assigned_to_id)
        journal.details << details
        journal.save
        previous_using_issue_id = ITicktemplate.previous_using_issue_id(template_id)
        ITicktemplate.where(:id => template_id).update_all(:app_issue_id => nil, :using_issue_id => previous_using_issue_id)
        issue.update_attributes(:status_id => ISetting.active.where(:param => "working_issue_status_id").first.value.to_i)
        issue.update_attributes(:assigned_to_id => assigned_to_id)
      else
      end
    end
  end



  def self.verify_template_by_security(issue_id, user_id)
    ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => user_id, :verified_at => Time.now)
    ITicktemplate.check_template_for_verified(issue_id, user_id)
  end

  def self.reject_template_by_security(issue_id, user_id)
    ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => nil, :verified_at => nil)
    ITicktemplate.check_template_for_verified(issue_id, user_id)
  end

  def self.approve_template_by_owner(issue_id, owner_id)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).update_all(:approved_by_id => owner_id, :approved_at => Time.now)
    ITicktemplate.check_template_for_approved(issue_id, owner_id)
  end

  def self.refuse_approve_template_by_owner(issue_id, owner_id)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).update_all(:approved_by_id => nil, :approved_at => nil)
    ITicktemplate.check_template_for_approved(issue_id, owner_id)
  end

  def self.template_id_by_issue(issue_id)
    if ITicket.active.where("i_tickets.i_ticktemplate_id IS NOT NULL").where(:issue_id => issue_id).count > 0
      ITicket.active.where("i_tickets.i_ticktemplate_id IS NOT NULL").where(:issue_id => issue_id).map(&:i_ticktemplate_id).first
    end
  end

  def self.may_be_verify_template(issue_id, user_id)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).first.value.to_i
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).first.value.to_i
    ITicket.check_security_officer( User.where(:id => user_id).first) && cf_verified == 0 && cf_approved == 0
  end

  def self.may_be_reject_verification_template(issue_id, user_id)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).first.value.to_i
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).first.value.to_i
    ITicket.check_security_officer( User.where(:id => user_id).first) && cf_verified == 1 && cf_approved == 0
  end

  def self.may_be_approve_template(issue_id, owner_id)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).first.value.to_i
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).first.value.to_i
    ITicket.active.where(:issue_id => issue_id, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id),:approved_by_id => nil).count > 0 && cf_verified == 1 && cf_approved == 0
  end

  def self.may_be_refuse_approve_template(issue_id, owner_id)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).first.value.to_i
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).first.value.to_i
    ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0 && cf_verified == 1 && cf_approved = 1
  end


end