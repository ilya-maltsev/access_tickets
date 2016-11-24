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

class ITicket < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible  :may_be_granted, :may_be_revoked,:i_ticktemplate_id, :description, :t_uid, :r_uid, :f_date, :e_date, :s_date, :user_id, :i_resource_id, :i_role_id, :deleted, :issue_id, :created_at, :updated_at
  belongs_to :issue, :class_name => "Issue", :foreign_key => "issue_id"
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :iresource, :class_name => "IResource", :foreign_key => "i_resource_id"
  belongs_to :irole, :class_name => "IRole", :foreign_key => "i_role_id"

  belongs_to :approver, :class_name => "User", :foreign_key => "approved_by_id"
  belongs_to :verifier, :class_name => "User", :foreign_key => "verified_by_id"
  belongs_to :creater, :class_name => "User", :foreign_key => "created_by_id"
  has_many :iaccesses, :class_name => "IAccess"
  has_many :itickentities, :class_name => "ITickentity"
  has_many :ientities, through: :itickentities, :class_name => "IEntity"

  #before_create :default
  validates :description, length: { in: 0..128 }
  before_validation(on: :create) do
    self.created_by_id = User.current.id
    self.deleted = 0
    if self.description.nil?
      self.description = ""
    end
  end




  def self.resowner_for_unapproval_issue(issue_id)
    unapproval_res_id = ITicket.active.where('i_tickets.verified_by_id IS NOT NULL and i_tickets.approved_by_id IS NULL').where(:issue_id => issue_id).first[:i_resource_id]
    IResowner.where(:i_resource_id => unapproval_res_id).map(&:user_id).uniq - [1]
  end


  def self.resowners_for_issue(issue_id)
    resources_ids = ITicket.active.where(:issue_id => issue_id).map(&:i_resource_id)
    IResowner.where(:i_resource_id => resources_ids).map(&:user_id).uniq - [1]
  end


  def self.may_be_set_ticket_user(issue_id, user_id)
    if ITicket.check_issue_status(issue_id)[0..1] == [1,1] && ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => user_id).map(&:i_resource_id)).count > 0 && IAccess.joins(:iticket).where("i_tickets.deleted" => 0, "i_tickets.issue_id" => issue_id).count == 0 
      true
    else
      false
    end
  end


  def self.verify_tickets_for_duplicates(rawData)
    tickets = []
    exist_accesses = []
    time = Time.now()
    if !rawData.empty?
      rawData.each do |object|
        tickets.push(object)
      end
    end
    {:tickets => tickets, :exist_accesses => exist_accesses}
  end

  def self.tickets_user_id(issue_id)
    if ITicket.active.where(:issue_id => issue_id).count > 0
      ITicket.active.where(:issue_id => issue_id).first.user_id
    else
      0
    end
  end

  def self.check_security_officer(user)
    if user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id))
      true
    else
      false
    end
  end


  def set_timezone
    if self.created_at?
      self.created_at = self.created_at.in_time_zone("Minsk")
    end
  end

  def default
    self.created_by_id = User.where(:login => User.current.login).first.id
    self.deleted = 0
    if self.description.nil?
      self.description = ""
    end
  end

  def self.ticket_versions(issue_id,current_user_id)
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
    versions = ITicket.where(:issue_id => issue_id).map(&:t_uid).uniq
    versions.each do |hash|
      version = ITicket.joins(:creater).select([:firstname,:lastname,:t_uid,:created_at]).where(:issue_id => issue_id, :t_uid => hash).first
      version_option = []
      version_value = l(:at_from) + version.created_at.in_time_zone(tz).to_s(:localdb) + " ("+ l(:at_author) + version.firstname + " " + version.lastname + ")"
      version_id = version.t_uid
      version_option.push(version_value)
      version_option.push(version_id)
      version_list.push(version_option)
    end
    version_list
  end

  def self.ticket_last_version(issue_id)
    version = ITicket.joins(:creater).where(:issue_id => issue_id).select([:firstname,:lastname,:created_at,:t_uid]).sort_by(&:created_at).last
  end

  def self.tickets_list(issue_id, current_user_id = nil)
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
    r_uids = self.active.where(:issue_id => issue_id).map(&:r_uid).uniq
    r_uids.each do |hash|
      ticket = self.active.where(:issue_id => issue_id, :r_uid => hash).select([:i_resource_id,:s_date,:f_date,:description,:approved_by_id,:verified_by_id]).first
      s_date = ticket[:s_date].strftime("%d.%m.%Y")
      f_date = ticket[:f_date].strftime("%d.%m.%Y")
      ticket = ticket.attributes.symbolize_keys
      ticket[:s_date] = s_date
      ticket[:e_date] = f_date
      ticket[:users] = []
      ticket[:uid] = hash
      #ticket[:e_date] = IticketsController.check_itickets_for_period(ticket[:e_date])
      users = self.active.where(:issue_id => issue_id, :r_uid => hash).select(:user_id).map(&:user_id).uniq
      users.each {|id| 
        object = {}
        if id == 0 
          object[:id] = 0
          object[:name] = ""
        else 
          object[:id] = id
          object[:name] = User.where(:id => id).first.name
        end
        ticket[:users].push(object)
      }
      ticket[:i_resource] = IResource.where(:id => ticket[:i_resource_id]).first.name
      main_ticket = ITicket.active.where(:issue_id => issue_id, :r_uid => hash).first
      if main_ticket.iaccesses.active.empty?
        if !ticket[:verified_by_id].nil?
          if ticket[:approved_by_id].nil?
            ticket[:status] = l(:at_need_to_approve)
            ticket[:status_id] = 1
          else
            ticket[:status] = l(:at_approved_by_owner)
            ticket[:status_id] = 2
            ticket[:user_id] = ticket[:approved_by_id]
            ticket[:user_name] = User.where(:id => ticket[:approved_by_id]).first.name
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
      else
        if main_ticket.iaccesses.active.first.confirmed_by_id?
          ticket[:status] = l(:at_confirmed_at) + main_ticket.iaccesses.active.first.confirmed_at.in_time_zone(tz).to_s(:atf)
          ticket[:status_id] = 4
          ticket[:user_id] = main_ticket.iaccesses.active.first.confirmed_by_id
          ticket[:user_name] = User.where(:id => main_ticket.iaccesses.active.first.confirmed_by_id).first.name
        else
          if main_ticket.iaccesses.active.first.granted_by_id?
            ticket[:status] = l(:at_granted_at) + main_ticket.iaccesses.active.first.granted_at.in_time_zone(tz).to_s(:atf)
            ticket[:status_id] = 3
            ticket[:user_id] = main_ticket.iaccesses.active.first.granted_by_id
            ticket[:user_name] = User.where(:id => main_ticket.iaccesses.active.first.granted_by_id).first.name
            if !current_user_id.nil?
              if ticket[:i_resource_id].in?(granted_resources)
                ticket[:may_be_revoked] = 1
              else
                ticket[:may_be_revoked] = 0
              end
            end
          end
        end
      end
      ticket[:i_roles] = []
      self.active.where(:issue_id => issue_id, :r_uid => hash).select(:i_role_id).map(&:i_role_id).uniq.each {|id| 
        ticket[:i_roles].push(IRole.where(:id => id).first.name)
      }
      ticket[:ientities] = []
      main_ticket.ientities.select([:name,'i_entities.id',:ipv4]).each {|entity|
        if IResource.where(:id => ticket[:i_resource_id]).first.has_ip
          ticket[:ientities].push(entity.name + " [" + entity.ipv4 + "];")
        else
          ticket[:ientities].push(entity.name)
        end
      }
      tickets.push(ticket)
    end  
    tickets
  end

  def self.edit_tickets_list(issue_id)
    tickets = []
    r_uids = self.active.where(:issue_id => issue_id).map(&:r_uid).uniq
    r_uids.each do |hash|
      ticket = self.active.where(:issue_id => issue_id, :r_uid => hash).select([:s_date,:e_date,:description]).first
      s_date = ticket["s_date"].strftime("%d.%m.%Y")
      e_date = ticket["e_date"].strftime("%d.%m.%Y")
      ticket = ticket.attributes.symbolize_keys
      ticket[:uid] = hash
      ticket[:users] = self.active.where(:issue_id => issue_id, :r_uid => hash).select(:user_id).map(&:user_id).uniq
      ticket[:i_resource_id] = self.active.where(:issue_id => issue_id, :r_uid => hash).select(:i_resource_id).map(&:i_resource_id).uniq
      ticket[:i_resource_roles] = self.active.where(:issue_id => issue_id, :r_uid => hash).select(:i_resource_id).first.iresource.iroles.active.select([:id,:name])
      ticket[:i_roles] = self.active.where(:issue_id => issue_id, :r_uid => hash).select(:i_role_id).map(&:i_role_id).uniq
      ticket[:has_entities] = IResource.find(ticket[:i_resource_id][0]).has_entities
      ticket[:has_ip] = IResource.find(ticket[:i_resource_id][0]).has_ip
      ticket[:i_entities] = IResource.find(ticket[:i_resource_id][0]).ientities.active.select(['i_entities.id',:name, :description, :ipv4])
      ticket[:ie_count] = IResource.find(ticket[:i_resource_id][0]).ientities.active.count
      ticket[:i_entity] = ITicket.where(:issue_id => issue_id, :r_uid => hash).first.ientities.select(['i_entities.id',:name, :description, :ipv4])
      ticket[:s_date] = s_date
      ticket[:e_date] = e_date
      tickets.push(ticket)
    end  
    tickets
  end

  def self.show_tickets_list(issue_id,t_uid)
    tickets = []
    r_uids = self.where(:issue_id => issue_id, :t_uid => t_uid).map(&:r_uid).uniq
    users = []
    group_users = User.active.select([:id, :firstname, :lastname])
    group_users.each do |group_user|
      user = {}
      user[:id] = group_user[:id]
      user[:name] = group_user[:firstname] + " " + group_user[:lastname]
      users.push(user)
    end
    r_uids.each do |hash|
      ticket = self.where(:issue_id => issue_id, :r_uid => hash).select([:s_date,:f_date,:description]).first.attributes.symbolize_keys
      ticket[:uid] = hash
      ticket[:users] = self.where(:issue_id => issue_id, :r_uid => hash).select(:user_id).map(&:user_id).uniq
      ticket[:i_resource_id] = self.where(:issue_id => issue_id, :r_uid => hash).select(:i_resource_id).map(&:i_resource_id).uniq
      ticket[:i_resource_roles] = self.where(:issue_id => issue_id, :r_uid => hash).select(:i_resource_id).first.iresource.iroles.active.select([:id,:name])
      ticket[:i_roles] = self.where(:issue_id => issue_id, :r_uid => hash).select(:i_role_id).map(&:i_role_id).uniq
      ticket[:i_res_has_entities] = IResource.find(ticket[:i_resource_id][0]).has_entities
      ticket[:i_res_has_ip] = IResource.find(ticket[:i_resource_id][0]).has_ip
      ticket[:i_entities] = IResource.find(ticket[:i_resource_id][0]).ientities.active.select(['i_entities.id',:name, :description, :ipv4])
      ticket[:ie_count] = IResource.find(ticket[:i_resource_id][0]).ientities.active.count
      ticket[:i_entity] = ITicket.where(:issue_id => issue_id, :r_uid => hash).first.ientities.select(['i_entities.id',:name, :description, :ipv4])
      ticket[:s_date] = ticket[:s_date].strftime("%d.%m.%Y")
      ticket[:e_date] = ticket[:f_date].strftime("%d.%m.%Y")
      ticket[:group_users] = users
      tickets.push(ticket)
    end
    tickets

  end

  def self.set_user_for_tickets(issue_id, user_id)
    if ITicket.active.where(:issue_id => issue_id, :approved_by_id => nil).count == 0
      ITicket.active.where(:issue_id => issue_id).update_all(:user_id => user_id)
    end
  end

  def self.approve_issue_status_by_owner(issue_id)
    if ITicket.active.where(:issue_id => issue_id, :approved_by_id => nil).count == 0
      if CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i).count == 0
        custom_value = CustomValue.new(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i, :value => 1)
        custom_value.save
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i).update_all(:value => 1)
      end
    end
  end

  def self.revoke_issue_status_by_owner(issue_id)
    if ITicket.active.where(:issue_id => issue_id, :approved_by_id => nil).count > 0
      if CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i).count == 0
        custom_value = CustomValue.new(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i, :value => 0)
        custom_value.save
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => ISetting.active.where(:param => "cf_approved_id").first.value.to_i).update_all(:value => 0)
      end
    end
  end

  def self.check_itickets_for_access(issue_id)
    ITicket.check_issue_status(issue_id)[0..3] == [1,1,1,1]
  end

  def self.approve_tickets_by_owner(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).update_all(:approved_by_id => owner_id, :approved_at => Time.now)
    ITicket.check_itickets_for_approved(issue_id)
  end

  def self.revoke_tickets_by_owner(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).update_all(:approved_by_id => nil, :approved_at => nil)
    ITicket.check_itickets_for_approved(issue_id)
  end

  def self.verify_tickets_by_security(issue_id, user_id)
    ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => user_id, :verified_at => Time.now)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
  end

  def self.reject_tickets_by_security(issue_id, user_id)
    
    tracker_id = Issue.find(issue_id).tracker_id
    tr_new_emp_id = 0#ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
    if tracker_id == tr_new_emp_id 
      ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => nil, :verified_at => nil, :user_id => 0, :approved_by_id => nil, :approved_at => nil)
    else
      ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => nil, :verified_at => nil)
    end
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
  end

  def self.check_issue_status(issue_id, user_id = nil)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
    cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value

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

    cf_granting = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id)
    if cf_granting.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id, :value => 0)
      cf_granting = 0
    else
      cf_granting = cf_granting.first.value.to_i
    end

    cf_confirming = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id)
    if cf_confirming.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id, :value => 0)
      cf_confirming = 0
    else
      cf_confirming = cf_confirming.first.value.to_i
    end

    if cf_verified == 0
    end
    tickets_count = ITicket.active.where(:issue_id => issue_id).count
    if user_id.nil?
      return cf_verified, cf_approved, cf_granting, cf_confirming, tickets_count
    else
      security_officer = ITicket.check_security_officer( User.where(:id => user_id).first) ? 1 : 0
      may_be_approved = ITicket.may_be_approved_by_owner_status(issue_id, user_id) ? 1 : 0
      may_be_revoked = ITicket.may_be_revoked_by_owner_status(issue_id, user_id) ? 1 : 0
      may_be_grant_access = IAccess.may_be_grant_access_by_issue_status(issue_id, user_id) ? 1 : 0
      may_be_revoke_grant = IAccess.may_be_revoke_grant_by_issue_status(issue_id, user_id) ? 1 : 0
      access_confirmer = IAccess.check_access_confirmer(issue_id, User.where(:id => user_id).first) ? 1 : 0
      may_be_set_ticket_user = ITicket.may_be_set_ticket_user(issue_id, user_id) ? 1 : 0
      #            0           1              2           3              4                 5                6              7               8                       9 .                             
      return cf_verified, cf_approved, cf_granting, cf_confirming, tickets_count, security_officer, may_be_approved, may_be_revoked, may_be_grant_access, may_be_revoke_grant, access_confirmer, may_be_set_ticket_user
      #     10                     11
    end
  end

  def self.set_default_cf(issue_id)
    if !issue_id.nil?
      cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
      cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
      cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
      cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
      cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id)
      cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id)
      cf_granting = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id)
      cf_confirming = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id)
      if cf_verified.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id, :value => 0)
      else
        cf_verified = cf_verified.update_all(:value => 0)
      end
      if cf_approved.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id, :value => 0)
      else
        cf_approved = cf_approved.update_all(:value => 0)
      end


      if cf_granting.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id, :value => 0)
      else
        cf_granting = cf_granting.update_all(:value => 0)
      end

      if cf_confirming.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id, :value => 0)
      else
        cf_confirming = cf_confirming.update_all(:value => 0)
      end
    end
  end

  def self.check_itickets_for_verified(issue_id) # Not used
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
      if ITicket.active.where(:issue_id => issue_id).count == ITicket.active.where("i_tickets.verified_by_id IS NOT NULL").where(:issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
      end

    end
  end

  def self.check_itickets_for_approved(issue_id)
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
      if ITicket.active.where(:issue_id => issue_id).count == ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 0)
      end
    end
  end

  def self.check_itickets_for_granted(issue_id)
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      i = 0
      ITicket.active.where(:issue_id => issue_id).each do |iticket|
        if iticket.iaccesses.active.count > 0
          if iticket.iaccesses.active.first.granted_by_id?
            i += 1
          end
        end
      end
      cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
      if ITicket.active.where(:issue_id => issue_id).count == i
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id).update_all(:value => 0)
      end
    end
  end

  def self.check_itickets_for_confirmed(issue_id)
    if ITicket.active.where(:issue_id => issue_id).count > 0 
      i = 0
      ITicket.active.where(:issue_id => issue_id).each do |iticket|
        if iticket.iaccesses.active.count > 0
          if iticket.iaccesses.active.first.confirmed_by_id?
            i += 1
          end
        end
      end
      cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
      if ITicket.active.where(:issue_id => issue_id).count == i
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id).update_all(:value => 0)
      end

    end
  end


  def self.may_be_approved_by_owner_status(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id),:approved_by_id => nil).count > 0
  end



  def self.may_be_revoked_by_owner_status(issue_id, owner_id, r_uid = nil)
    if ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0 
        tracker_id = Issue.find(issue_id).tracker_id
        tr_new_emp_id = 0#ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
        tr_grant_id = ISetting.active.where(:param => "tr_grant_id").first.value.to_i
        if tracker_id == tr_new_emp_id
          IAccess.joins(:iticket).where("i_tickets.deleted" => 0, "i_tickets.issue_id" => issue_id).count == 0
        else
          ITicket.active.joins(:iaccesses).where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count == 0 && tracker_id == tr_grant_id
        end
      else
        false
      end
  end

  def self.need_to_approve_by_owner_status(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id), :approved_by_id => nil).count > 0
  end


end

