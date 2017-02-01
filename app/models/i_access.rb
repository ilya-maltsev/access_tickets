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


class IAccess < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :i_entity_id, :rev_issue_id,:i_ticket_id, :r_created_by_id, :granted_by_id, :granted_at, :confirmed_by_id, :confirmed_at, :revoked_by_id, :revoked_at, :deleted, :active, :deactivated_by_id, :deactivated_at, :created_at, :updated_at
  belongs_to :iticket, :class_name => "ITicket", :foreign_key => "i_ticket_id"
  belongs_to :granter, :class_name => "User", :foreign_key => "granted_by_id"
  belongs_to :confirmer, :class_name => "User", :foreign_key => "confirmed_by_id"
  belongs_to :revoker, :class_name => "User", :foreign_key => "revoked_by_id"
  belongs_to :deactivater, :class_name => "User", :foreign_key => "deactivated_by_id"
  belongs_to :ientity, :class_name => "IEntity", :foreign_key => "i_entity_id"
  belongs_to :revoker, :class_name => "User", :foreign_key => "revoked_by_id"
  belongs_to :r_creater, :class_name => "User", :foreign_key => "r_created_by_id"
  before_create :default


  def self.can_dismiss_user(dismiss_user_id, current_user_id)
    if IGrouplider.lider_for_user(dismiss_user_id, current_user_id) ||  current_user_id == 1 || current_user_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || current_user_id.in?(User.active.in_group(ISetting.active.where(:param => "hr_group_id").first.value.to_i).map(&:id))
      true
    else
      false
    end
  end


  def self.refuse_deactivating_grants(issue_id, deactivater_id, r_uid = nil)
    if r_uid.nil?
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), :rev_issue_id => issue_id).update_all(:deactivated_by_id => nil, :deactivated_at => nil)
    else
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), "i_tickets.r_uid" => r_uid, :rev_issue_id => issue_id).update_all(:deactivated_by_id => nil, :deactivated_at => nil)
    end
    IAccess.check_accesses_for_deactivated(issue_id)
  end

  def self.deactivate_grants(issue_id, deactivater_id, r_uid = nil)
    if r_uid.nil?
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), :rev_issue_id => issue_id).update_all(:deactivated_by_id => deactivater_id, :deactivated_at => Time.now)
    else
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), "i_tickets.r_uid" => r_uid, :rev_issue_id => issue_id).update_all(:deactivated_by_id => deactivater_id, :deactivated_at => Time.now)
    end
    IAccess.check_accesses_for_deactivated(issue_id)
  end


  def self.check_accesses_for_deactivated(issue_id)
    cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id").first.value
    if IAccess.where("i_accesses.revoked_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NOT NULL").where(:rev_issue_id => issue_id).count == IAccess.where(:rev_issue_id => issue_id).count
      CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id).update_all(:value => 1)
    else
      CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id).update_all(:value => 0)
    end
  end

  def self.refuse_confirmation_revoking_for_accesses(issue_id, revoker_id)
    IAccess.where(:rev_issue_id => issue_id).update_all(:revoked_by_id => nil, :revoked_at => nil)
    IAccess.check_revoking_for_confirmed(issue_id)
  end


  def self.confirm_revoking_for_accesses(issue_id, revoker_id)
    IAccess.where(:rev_issue_id => issue_id).update_all(:revoked_by_id => revoker_id, :revoked_at => Time.now)
    IAccess.check_revoking_for_confirmed(issue_id)
  end

  def self.check_revoking_for_confirmed(issue_id)
    cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
    if IAccess.active.where(:rev_issue_id => issue_id).count > 0 
      if IAccess.where(:rev_issue_id => issue_id).count == IAccess.where("i_accesses.revoked_by_id IS NOT NULL").where(:rev_issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 0)
      end
    else
      CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 0)
    end
  end


  def self.old_check_revoking_for_confirmed(issue_id)
    if IAccess.active.where(:rev_issue_id => issue_id).count > 0 
      cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
      if IAccess.where(:rev_issue_id => issue_id).count == IAccess.where("i_accesses.revoked_by_id IS NOT NULL").where(:rev_issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 0)
      end
    end
  end

  def self.rev_accesses_user_id(issue_id)
    if IAccess.active.where(:rev_issue_id => issue_id).count > 0
      IAccess.active.where(:rev_issue_id => issue_id).first.iticket.user_id
    else
      0
    end
  end

  def self.last_revoking_version(issue_id, user_id)
    if !IAccess.active.where(:rev_issue_id => issue_id).empty?
      Time::DATE_FORMATS.merge!(:localdb=>"%H:%M:%S %d.%m.%Y")
      user = User.find(user_id)
      if user.time_zone != nil
        tz = user.time_zone
      else
        tz = "Minsk"
      end
      version = IAccess.joins(:r_creater).where(:rev_issue_id => issue_id).select("firstname,lastname,updated_at").first
      version_value = "(" + l(:at_last_edited_by) + version.firstname + " " + version.lastname + l(:at_at) + version.updated_at.in_time_zone(tz).to_s(:localdb) + ")"
    else
      version_value = ""
    end
  end


  def self.show_revoking_users(revoker_id, issue_id = nil)
    users_nosort = []
    first_option = {}
    first_option[:id] = ""
    first_option[:name] = l(:at_select_employee)
    #users_nosort.push(first_option)
    users = []

    if issue_id.nil?
      if revoker_id == 1 || revoker_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || revoker_id.in?(User.active.in_group(ISetting.active.where(:param => "hr_group_id").first.value.to_i).map(&:id))
        users = User.active.select([:id,:firstname,:lastname])
        users.each do |user|
          option = {}
          option[:id]=user.id
          option[:name]=user.firstname + " " + user.lastname
          if users_nosort.detect{|w| w[:id] == option[:id]}.nil?
            users_nosort.push(option)
          end
        end
      else
        if IGrouplider.is_group_lider(revoker_id)
          groups = IGrouplider.where(:user_id => revoker_id).map(&:group_id)
          groups.each do |group|
            users = User.active.in_group(group).select([:id,:firstname,:lastname])
            users.each do |user|
              option = {}
              option[:id]=user.id
              option[:name]=user.firstname + " " + user.lastname
              if users_nosort.detect{|w| w[:id] == option[:id]}.nil?
                users_nosort.push(option)
              end
            end
          end
        end
      end
    else
      rev_user = {}
      rev_user[:id] = IAccess.rev_accesses_user_id(issue_id)
      if rev_user[:id] != 0
        rev_user[:name] = User.find(rev_user[:id]).name
        users_nosort.push(rev_user)
      end
    end
    users_list = users_nosort.to_a.sort_by! {|u| u[:id]}
    #users_list.insert(0, first_option)

  end


  def default
    self.deleted = 0
  end


  def self.check_revoking_status(issue_id, user_id = nil)

    cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
    cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id").first.value
    cf_revoked = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id)
    if cf_revoked.empty?
      CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id).update_all(:value => 0)
      cf_revoked_id = 0
    else
      cf_revoked = cf_revoked.first.value.to_i
    end
    cf_deactivated = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id)
    if cf_deactivated.empty?
      CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id).update_all(:value => 0)
      cf_deactivated = 0
    else
      cf_deactivated = cf_deactivated.first.value.to_i
    end
    accesses_count = IAccess.active.where(:rev_issue_id => issue_id).count
    if user_id.nil?
      return cf_revoked, cf_deactivated, accesses_count
    else
      security_officer = ITicket.check_security_officer( User.where(:id => user_id).first) ? 1 : 0
      may_be_confirm_revoking = IAccess.may_be_confirm_revoking(issue_id, user_id) ? 1 : 0
      may_be_refuse_confirmation_revoking = IAccess.may_be_refuse_confirmation_revoking(issue_id, user_id) ? 1 : 0
      may_be_deactivate_grant = IAccess.may_be_deactivate_grant(issue_id, User.where(:id => user_id).first ) ? 1 : 0
      may_be_refuse_deactivating_grants = IAccess.may_be_refuse_deactivating_grants(issue_id, User.where(:id => user_id).first ) ? 1 : 0
      rev_accesses_user_id = IAccess.rev_accesses_user_id(issue_id)
      #            0           1              2                  3                    4                           5      
      return cf_revoked, cf_deactivated, accesses_count, security_officer, may_be_confirm_revoking, may_be_refuse_confirmation_revoking, may_be_deactivate_grant, may_be_refuse_deactivating_grants, rev_accesses_user_id
      #           6                             7                             8         
    end
  end

    def self.accesses_list_by_resource(resource_id, current_user_id = nil)
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
    accesses = []
    #user_ids = User.all.map(&:id)
    user_ids = ITicket.active.joins(:iaccesses).where(:i_resource_id => resource_id).where("i_accesses.confirmed_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NULL").map(&:user_id).uniq
    user_ids.each do |user_id|
      r_uids = ITicket.active.joins(:iaccesses).where(:i_resource_id => resource_id).where("i_accesses.confirmed_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NULL").where(:user_id => user_id).map(&:r_uid).uniq
      r_uids.each do |r_uid|
        ientities = []
        access = {}
        access[:r_uid] = r_uid
        access[:users] = []
        access[:users_ids] = []
        access[:i_roles] = []
        access[:i_roles_id] = []
        access[:i_entities_id] = []
        itickets = ITicket.active.where(:r_uid => r_uid, :i_resource_id => resource_id, :user_id => user_id)
        if !User.where(:id => itickets.first[:user_id]).empty?
          user_name = User.find(itickets.first[:user_id]).name
          user_obj = {}
          user_obj[:id] = user_id
          user_obj[:name] = user_name
        else
          user_name = User.find(2).name
          user_obj = {}
          user_obj[:id] = 2
          user_obj[:name] = user_name
        end
        access[:users_ids].push(user_obj)
        access[:users].push(user_name)
        access[:i_resource_id] = itickets.first[:i_resource_id]
        access[:i_resource] = IResource.find(access[:i_resource_id]).name
        access[:description] = itickets.first[:description]
        access[:issue_id] =  itickets.first[:issue_id]
        itickets.each do |iticket|
          access[:i_roles].push(IRole.find(iticket[:i_role_id]).name)
          access[:i_roles_id].push(iticket[:i_role_id])
        end
        access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
        access[:e_date] = itickets.first[:e_date].strftime("%d.%m.%Y")
        iaccesses = itickets.first.iaccesses.active.where(:deactivated_by_id => nil)

        iaccesses.map(&:i_entity_id).uniq.each do |ientity_id|  
          IEntity.where(:id => ientity_id).each do |ientity| 
            entity = {}
            entity[:id] = ientity.id
            if ientity.iresource.has_ip
              entity[:caption] = ientity.name + " [" + ientity.ipv4 + "];"
            else
              entity[:caption] = ientity.name
            end
            ientities.push(entity)
            access[:i_entities_id].push(ientity.id)
          end
        end
        access[:ientities] = ientities
        accesses.push(access)
      end
    end
    accesses
  end

  def self.revoked_accesses_list_by_resource(resource_id, current_user_id = nil)
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
    accesses = []
    #user_ids = User.all.map(&:id)
    user_ids = ITicket.active.joins(:iaccesses).where(:i_resource_id => resource_id).where("i_accesses.deactivated_by_id IS NOT NULL").map(&:user_id).uniq
    user_ids.each do |user_id|
      r_uids = ITicket.active.joins(:iaccesses).where(:i_resource_id => resource_id).where("i_accesses.deactivated_by_id IS NOT NULL").where(:user_id => user_id).map(&:r_uid).uniq
      r_uids.each do |r_uid|
        ientities = []
        access = {}
        access[:r_uid] = r_uid
        access[:users] = []
        access[:users_ids] = []
        access[:i_roles] = []
        itickets = ITicket.active.where(:r_uid => r_uid, :i_resource_id => resource_id, :user_id => user_id)
        user_name = User.find(itickets.first[:user_id]).name
        user_obj = {}
        user_obj[:id] = user_id
        user_obj[:name] = user_name
        access[:users_ids].push(user_obj)
        access[:users].push(user_name)
        access[:i_resource_id] = itickets.first[:i_resource_id]
        access[:i_resource] = IResource.find(access[:i_resource_id]).name
        access[:description] = itickets.first[:description]
        access[:issue_id] =  itickets.first[:issue_id]
        itickets.each do |iticket|
          access[:i_roles].push(IRole.find(iticket[:i_role_id]).name)
        end
        access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
        access[:e_date] = itickets.first[:e_date].strftime("%d.%m.%Y")
        access[:revoked_by_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:revoked_by_id]
        access[:revoked_at] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:revoked_at]
        access[:deactivated_by_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:deactivated_by_id]
        access[:deactivated_at] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:deactivated_at]
        access[:rev_issue_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:rev_issue_id]
        if ! access[:deactivated_at].nil?
          access[:deactivated_at] = access[:deactivated_at].strftime("%d.%m.%Y")
        end
        if !access[:revoked_by_id].nil?
          if access[:deactivated_by_id].nil?
            access[:status] = l(:at_revoke_confirmed)
            access[:user_id] = access[:revoked_by_id]
            access[:user_name] = User.where(:id => access[:revoked_by_id]).first.name
            access[:status_id] = 1
          else
            access[:status] = l(:at_access_deactivated)
            access[:status_id] = 2
            access[:user_id] = access[:deactivated_by_id]
            access[:user_name] = User.where(:id => access[:deactivated_by_id]).first.name
          end
        else
          access[:status] = l(:at_need_to_confirm_revoking)
          access[:status_id] = 0
        end
        iaccesses = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL")
        iaccesses.map(&:i_entity_id).uniq.each do |ientity_id|  
          IEntity.where(:id => ientity_id).each do |ientity| 
            entity = {}
            entity[:id] = ientity.id
            if ientity.iresource.has_ip
              entity[:caption] = ientity.name + " [" + ientity.ipv4 + "];"
            else
              entity[:caption] = ientity.name
            end
            ientities.push(entity)
          end
        end
        access[:ientities] = ientities
        accesses.push(access)
      end
    end
    accesses
  end


  def self.accesses_list(user_id, rev_issue_id = nil, current_user_id = nil)
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
    accesses = []
    if rev_issue_id.nil?
      r_uids = ITicket.active.joins(:iaccesses).where("i_accesses.confirmed_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NULL").where(:user_id => user_id).map(&:r_uid).uniq
    else
      r_uids = ITicket.active.joins(:iaccesses).where("i_accesses.confirmed_by_id IS NOT NULL").where("i_accesses.rev_issue_id" => rev_issue_id).map(&:r_uid).uniq
    end
    r_uids.each do |r_uid|
      ientities = []
      access = {}
      access[:r_uid] = r_uid
      access[:users] = []
      access[:users_ids] = []
      access[:i_roles] = []
      access[:i_roles_id] = []
      access[:i_entities_id] = []
      if rev_issue_id.nil?
        itickets = ITicket.active.where(:r_uid => r_uid, :user_id => user_id)
        access[:revoked_by_id] = itickets.first.iaccesses.first[:revoked_by_id]
        access[:revoked_at] = itickets.first.iaccesses.first[:revoked_at]
        access[:deactivated_by_id] = itickets.first.iaccesses.first[:deactivated_by_id]
        access[:deactivated_at] = itickets.first.iaccesses.first[:deactivated_at]
      else
        itickets = ITicket.active.joins(:iaccesses).where(:r_uid => r_uid, "i_accesses.rev_issue_id" => rev_issue_id)
        access[:revoked_by_id] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:revoked_by_id]
        access[:revoked_at] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:revoked_at]
        access[:deactivated_by_id] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:deactivated_by_id]
        access[:deactivated_at] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:deactivated_at]
      end
      user_name = User.find(itickets.first[:user_id]).name
      user_obj = {}
      user_obj[:id] = user_id
      user_obj[:name] = user_name
      access[:users_ids].push(user_obj)
      access[:users].push(user_name)
      access[:i_resource_id] = itickets.first[:i_resource_id]
      access[:i_resource] = IResource.find(access[:i_resource_id]).name
      access[:description] = itickets.first[:description]
      access[:issue_id] =  itickets.first[:issue_id]
      itickets.each do |iticket|
        access[:i_roles].push(IRole.find(iticket[:i_role_id]).name)
        access[:i_roles_id].push(iticket[:i_role_id])
      end
      access[:i_roles] = access[:i_roles].uniq
      access[:i_roles_id] = access[:i_roles_id].uniq      
      access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
      access[:e_date] = itickets.first[:e_date].strftime("%d.%m.%Y")
      if !access[:revoked_by_id].nil?
        access[:revoked_at] = access[:revoked_at].in_time_zone(tz).to_s(:atf)
      end
      access[:deactivated_by_id] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:deactivated_by_id]
      access[:deactivated_at] = itickets.first.iaccesses.where(:rev_issue_id => rev_issue_id).first[:deactivated_at]
      if !access[:deactivated_by_id].nil?
        access[:deactivated_at] = access[:deactivated_at].in_time_zone(tz).to_s(:atf)#.strftime("%H:%M %d.%m.%Y")
      end
      if !access[:revoked_by_id].nil?
        if access[:deactivated_by_id].nil?
          access[:status] = l(:at_confirmed_revoke_at) + access[:revoked_at]
          access[:user_id] = access[:revoked_by_id]
          access[:user_name] = User.where(:id => access[:revoked_by_id]).first.name
          access[:status_id] = 1
          if !current_user_id.nil?
            if access[:i_resource_id].in?(granted_resources)
              access[:may_be_deactivated] = 1
            else
              access[:may_be_deactivated] = 0
            end
          end
        else
          access[:status] = l(:at_deactivated_access_at) + access[:deactivated_at]
          access[:status_id] = 2
          access[:user_id] = access[:deactivated_by_id]
          access[:user_name] = User.where(:id => access[:deactivated_by_id]).first.name
          if !current_user_id.nil?
            if access[:i_resource_id].in?(granted_resources)
              access[:may_be_activated] = 1
            else
              access[:may_be_activated] = 0
            end
          end
        end
      else
        access[:status] = l(:at_need_to_confirm_revoking)
        access[:status_id] = 0
      end
      if rev_issue_id.nil?
        iaccesses = itickets.first.iaccesses.active.where(:deactivated_by_id => nil)
      else
        iaccesses = itickets.first.iaccesses.active.where(:rev_issue_id => rev_issue_id)
      end
      iaccesses.map(&:i_entity_id).uniq.each do |ientity_id|  
        IEntity.where(:id => ientity_id).each do |ientity| 
          entity = {}
          entity[:id] = ientity.id
          if ientity.iresource.has_ip
            entity[:caption] = ientity.name + " [" + ientity.ipv4 + "];"
          else
            entity[:caption] = ientity.name
          end
          ientities.push(entity)
          access[:i_entities_id].push(ientity.id)
        end
      end
      access[:ientities] = ientities
      accesses.push(access)
    end
    accesses
  end

  def self.revoked_accesses_list(user_id, current_user_id = nil)
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
    accesses = []
    r_uids = ITicket.active.joins(:iaccesses).where("i_accesses.deactivated_by_id IS NOT NULL").where(:user_id => user_id).map(&:r_uid).uniq
    r_uids.each do |r_uid|
      ientities = []
      access = {}
      access[:r_uid] = r_uid
      access[:users] = []
      access[:users_ids] = []
      access[:i_roles] = []
      itickets = ITicket.active.where(:r_uid => r_uid, :user_id => user_id)
      user_name = User.find(itickets.first[:user_id]).name
      user_obj = {}
      user_obj[:id] = user_id
      user_obj[:name] = user_name
      access[:users_ids].push(user_obj)
      access[:users].push(user_name)
      access[:i_resource_id] = itickets.first[:i_resource_id]
      access[:i_resource] = IResource.find(access[:i_resource_id]).name
      access[:description] = itickets.first[:description]
      access[:issue_id] =  itickets.first[:issue_id]
      itickets.each do |iticket|
        access[:i_roles].push(IRole.find(iticket[:i_role_id]).name)
      end
      access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
      access[:e_date] = itickets.first[:e_date].strftime("%d.%m.%Y")
      access[:revoked_by_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:revoked_by_id]
      access[:revoked_at] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:revoked_at].in_time_zone(tz).to_s(:atf)
      access[:deactivated_by_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:deactivated_by_id]
      access[:deactivated_at] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:deactivated_at].in_time_zone(tz).to_s(:atf)
      access[:rev_issue_id] = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL").first[:rev_issue_id]
      if !access[:revoked_by_id].nil?
        if access[:deactivated_by_id].nil?
          access[:status] = l(:at_revoke_confirmed)
          access[:user_id] = access[:revoked_by_id]
          access[:user_name] = User.where(:id => access[:revoked_by_id]).first.name
          access[:status_id] = 1
        else
          access[:status] = l(:at_access_deactivated)
          access[:status_id] = 2
          access[:user_id] = access[:deactivated_by_id]
          access[:user_name] = User.where(:id => access[:deactivated_by_id]).first.name
        end
      else
        access[:status] = l(:at_need_to_confirm_revoking)
        access[:status_id] = 0
      end
      iaccesses = itickets.first.iaccesses.active.where("i_accesses.deactivated_by_id IS NOT NULL")
      iaccesses.map(&:i_entity_id).uniq.each do |ientity_id|  
        IEntity.where(:id => ientity_id).each do |ientity| 
          entity = {}
          entity[:id] = ientity.id
          if ientity.iresource.has_ip
            entity[:caption] = ientity.name + " [" + ientity.ipv4 + "];"
          else
            entity[:caption] = ientity.name
          end
          ientities.push(entity)
        end
      end
      access[:ientities] = ientities
      accesses.push(access)
    end
    accesses
  end


  def self.may_be_grant_access_by_issue_status(issue_id, granter_id, r_uid = nil) # maybe packed
    if ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id)).count > 0 && ITicket.check_issue_status(issue_id)[0..3] == [1,1,0,0]
      i = 0
      j = 0
      #if ITicket.check_issue_status(issue_id)[0..3] == [1,1,0,0] && r_uid.nil?
      if r_uid.nil? 
        itickets = ITicket.active.where("i_tickets.user_id != 0").where(:issue_id => issue_id)
        granted_resources = IResgranter.where(:user_id => granter_id).map(&:i_resource_id)
        itickets.each do |iticket|
          if iticket.iaccesses.active.empty? 
            i += 1
          end
          if !iticket[:i_resource_id].in?(granted_resources)
            j += 1
          end
        end
        if i > 0 && j == 0
          true
        else
          false
        end

      else
        itickets = ITicket.active.where("i_tickets.approved_by_id IS NOT NULL AND i_tickets.user_id != 0").where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id), :r_uid => r_uid)
        itickets.each do |iticket|
          if iticket.iaccesses.active.empty? 
            i += 1
          end
        end
        i > 0
      end
    else
      false
    end
  end


  def self.may_be_revoke_grant_by_issue_status(issue_id, granter_id, r_uid = nil) # maybe packed
    if ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id)).count > 0
      i = 0
      j = 0
      if r_uid.nil?
        IAccess.active.joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => granter_id).map(&:i_resource_id), "i_tickets.issue_id" => issue_id).count > 0
      else
        itickets = ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id), :r_uid => r_uid)
        itickets.each do |iticket|
          if iticket.iaccesses.active.count > 0
            i += 1
          end
        end
        i > 0
      end
    end
  end

  def self.may_be_confirm_revoking(issue_id, revoker_id) #admin || group_lider || by_self | security | hr

    rev_user_id = IAccess.rev_accesses_user_id(issue_id)
    if rev_user_id != 0
      rev_user_groups = User.find(rev_user_id).groups.map(&:id)
      rev_user_gls = IGrouplider.where(:group_id => rev_user_groups).map(&:user_id).uniq
      if revoker_id == 1 || revoker_id.in?(rev_user_gls) || revoker_id == IAccess.rev_accesses_user_id(issue_id) || revoker_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) || revoker_id.in?(User.active.in_group(ISetting.active.where(:param => "hr_group_id").first.value.to_i).map(&:id))
        true
      else
        false
      end
    else
      false
    end
  end


  def self.may_be_refuse_confirmation_revoking(issue_id, revoker_id) #admin || revoke_confirmer || security

    cf_revoked_id = ISetting.active.where(:param => "cf_revoked_id").first.value
    cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id").first.value


    cf_revoked = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id)
    if cf_revoked.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_revoked_id, :value => 0)
      cf_revoked = 0
    else
      cf_revoked = cf_revoked.first.value.to_i
    end

    cf_deactivated = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id)
    if cf_deactivated.empty?
      CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id, :value => 0)
      cf_deactivated = 0
    else
      cf_deactivated = cf_deactivated.first.value.to_i
    end

    if (cf_revoked == 1 && cf_deactivated == 0) && ( revoker_id == 1 || IAccess.active.where(:rev_issue_id => issue_id, :revoked_by_id => revoker_id).count > 0 || revoker_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) ) && IAccess.where("i_accesses.deactivated_by_id IS NOT NULL").joins(:iticket).where(:rev_issue_id => issue_id).count == 0
      true
    else
      false
    end
  end


  def self.may_be_deactivate_grant(issue_id, deactivater_id, r_uid = nil)
    if r_uid.nil?
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), :rev_issue_id => issue_id, :deactivated_by_id => nil).count > 0
    else
      IAccess.where("i_accesses.revoked_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => deactivater_id).map(&:i_resource_id), "i_tickets.r_uid" => r_uid, :rev_issue_id => issue_id, :deactivated_by_id => nil).count > 0 
    end
  end

  def self.may_be_refuse_deactivating_grants(issue_id, activater_id, r_uid = nil)
    cf_deactivated_id = ISetting.active.where(:param => "cf_deactivated_id").first.value
    cf_deactivated = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_deactivated_id).first.value.to_i

    if r_uid.nil?
      if IAccess.where("i_accesses.revoked_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => activater_id).map(&:i_resource_id), :rev_issue_id => issue_id).count > 0 
        if cf_deactivated == 0
          true
        else
          activater_id == 1
        end
      else
        false
      end
    else
      if IAccess.where("i_accesses.revoked_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NOT NULL").joins(:iticket).where("i_tickets.i_resource_id" => IResgranter.where(:user_id => activater_id).map(&:i_resource_id), "i_tickets.r_uid" => r_uid, :rev_issue_id => issue_id).count > 0 
        if cf_deactivated == 0
          true
        else
          activater_id == 1
        end
      else
        false
      end
    end

  end

  def self.check_access_granter(granter)
    if granter.id == 1 || IResgranter.where(:user_id => granter.id).count > 0 # refine the list by coincidence with the resource
      true
    else
      false
    end
  end

  def self.check_access_confirmer(issue_id, user)
    if user.id == 1 || user.id ==  Issue.where(:id => issue_id).first.author_id || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) 
      return true
    else
      return false
    end
  end

  def self.grant_access_for_tickets(issue_id, granter_id, r_uid = nil)
    if r_uid.nil?
      itickets = ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id))
    else
      itickets = ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id), :r_uid => r_uid)
    end

    itickets.each do |iticket|
      if iticket.iaccesses.active.count > 0
        iticket.iaccesses.active.each  { |access| access.delete }
      end
    end

    itickets.each do |iticket|
      if iticket.ientities.empty?
          iaccess = IAccess.new(:i_ticket_id => iticket.id, :granted_by_id => granter_id, :granted_at => Time.now)
          iaccess.save
      else
        iticket.ientities.each {|entity|
          iaccess = IAccess.new(:i_ticket_id => iticket.id, :granted_by_id => granter_id, :granted_at => Time.now, :i_entity_id => entity.id)
          iaccess.save
        }
      end
    end
    ITicket.check_itickets_for_granted(issue_id)
  end


  def self.revoke_grant_for_tickets(issue_id, granter_id, r_uid = nil)
    tr_new_employee = 0#ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
    if r_uid.nil? #|| tr_new_employee
      itickets = ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id))
    else
      itickets = ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => granter_id).map(&:i_resource_id), :r_uid => r_uid)
    end

    itickets.each do |ticket| 
      if ticket.iaccesses.active.count > 0
        ticket.iaccesses.active.each { |access| access.delete }
      end
    end

    ITicket.check_itickets_for_granted(issue_id)
  end


  def self.confirm_access_for_tickets(issue_id, user_id)
    ITicket.active.where(:issue_id => issue_id).each do |ticket|
      if ticket.iaccesses.active.first.granted_by_id?
        ticket.iaccesses.active.update_all(:confirmed_by_id => user_id, :confirmed_at => Time.now)
      end
    end
    cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id).update_all(:value => 1)
  end


  def self.revoke_confirmation_for_tickets(issue_id, user_id)
    ITicket.active.where(:issue_id => issue_id).each do |ticket|
      ticket.iaccesses.active.update_all(:confirmed_by_id => nil, :confirmed_at => nil)
    end
    ITicket.check_itickets_for_confirmed(issue_id)
  end

end
