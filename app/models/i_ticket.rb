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

  before_create :default

  validates :description, length: { in: 0..128 }

  def self.resowner_for_unapproval_issue(issue_id)
    unapproval_res_id = ITicket.active.where('i_tickets.verified_by_id IS NOT NULL and i_tickets.approved_by_id IS NULL').where(:issue_id => issue_id).first[:i_resource_id]
    IResowner.where(:i_resource_id => unapproval_res_id).map(&:user_id).uniq - [1]
  end


  def self.resowners_for_issue(issue_id)
    resources_ids = ITicket.active.where(:issue_id => issue_id).map(&:i_resource_id)
    IResowner.where(:i_resource_id => resources_ids).map(&:user_id).uniq - [1]
  end


  def self.may_be_set_ticket_user(issue_id, user_id)
    if ITicket.check_issue_status(issue_id)[0..1] == [1,1] && ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResgranter.where(:user_id => user_id).map(&:i_resource_id)).count > 0 && Issue.find(issue_id).tracker_id == ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i  && IAccess.joins(:iticket).where("i_tickets.deleted" => 0, "i_tickets.issue_id" => issue_id).count == 0 #&& ITicket.active.where("i_tickets.user_id != 0").where(:issue_id => issue_id).count == 0
      true
    else
      false
    end
  end


  def self.verify_tickets_for_duplicates(rawData)
    tickets = []
    exist_accesses = []
    tmp = []
    time = Time.now()
    if !rawData.empty?
      rawData.each do |object|
        object_entities = object["entity_id"]
        bad_users = []
        if !object["user_id"].empty?
          object["user_id"].each do |user|
            user_accesses = IAccess.accesses_list_by_resource_for_user(user,object["resource_id"])#IAccess.accesses_list(user)
            if !user_accesses.empty? && !object["resource_id"].nil? && !object["role_id"].nil?
              duplicated_entities = [] 
              not_duplicated_entities = []
              user_accesses.each do |access|
                exist_access = {}
                if object["resource_id"].to_i == access[:i_resource_id]
                  if IResource.find(object["resource_id"])["has_entities"] == false
                    if !(object["role_id"].map(&:to_i) & access[:i_roles_id]).empty?
                      exist_access["r_uid"] = object["r_uid"]
                      exist_access["users"] = []
                      exist_access["users"].push(User.where(:id => user).first.name)
                      exist_access["users_ids"] = []
                      exist_access["users_ids"].push(user)
                      exist_access["i_resource"] = IResource.where(:id => object["resource_id"]).first.name
                      exist_access["role_id"] = object["role_id"].map(&:to_i) & access[:i_roles_id]
                      exist_access["i_roles"] = []
                      IRole.where(:id => exist_access["role_id"]).each do |role|
                        exist_access["i_roles"].push(role.name)
                      end
                      exist_access["description"] = access[:description]
                      exist_access["ientities"] = []
                      exist_accesses.push(exist_access)
                      bad_users.push(user)
                    end
                  else
                    if object["entity_id"].empty?
                      bad_users.push(user)
                    else
                      if (!(duplicated_entities & access[:i_entities_id]).empty? || !(object["entity_id"].map(&:to_i) & access[:i_entities_id]).empty?) && !(object["role_id"].map(&:to_i) & access[:i_roles_id]).empty?
                        exist_access["r_uid"] = object["r_uid"]
                        exist_access["users"] = []
                        exist_access["users"].push(User.where(:id => user).first.name)
                        exist_access["users_ids"] = []
                        exist_access["users_ids"].push(user)
                        exist_access["i_resource"] = IResource.where(:id => object["resource_id"]).first.name
                        exist_access["role_id"] = object["role_id"].map(&:to_i) & access[:i_roles_id]
                        exist_access["i_roles"] = []
                        IRole.where(:id => exist_access["role_id"]).each do |role|
                          exist_access["i_roles"].push(role.name)
                        end
                        exist_access["entity_id"] = object["entity_id"].map(&:to_i) & access[:i_entities_id] 
                        exist_access["ientities"] = []
                        IEntity.where(:id => exist_access["entity_id"]).select([:id,:name,:ipv4]).each do |entity|
                          if entity.iresource.has_ip
                            exist_access["ientities"].push(entity.name + " [" + entity.ipv4 + "];")
                          else
                            exist_access["ientities"].push(entity.name)
                          end
                        end
                        exist_accesses.push(exist_access)
                        bad_users.push(user)
                        duplicated_entities = duplicated_entities + (object["entity_id"].map(&:to_i) & access[:i_entities_id])
                      else

                      end
                    end
                  end
                end
              end
            end
          end
          #end each users
        end
      end
      #end object
      exist_r_iuds = []
      exist_accesses.each do |ea|
        exist_r_iuds.push(ea["r_uid"])
      end
      exist_r_iuds = exist_r_iuds.uniq
      rawData.each do |object|
        object_entities = object["entity_id"]
        if object["r_uid"].in?(exist_r_iuds)
          exist_accesses_by_r_uid = []
          exist_accesses_users = []
          exist_accesses.each do |ea_r_uid|
            if ea_r_uid["r_uid"] == object["r_uid"] 
              exist_accesses_users = exist_accesses_users + ea_r_uid["users_ids"]
              exist_accesses_by_r_uid.push(ea_r_uid)
            end
          end
          if !(object["user_id"] - exist_accesses_users).empty? #any nonproblem users there in ticket?
            #exist_accesses_by_r_uid.each do |ea_by_r_uid|
              #if !(object["role_id"] - ea_by_r_uid["role_id"]).empty?
            non_exist_accesses = {}
            non_exist_accesses["r_uid"] = object["r_uid"]
            non_exist_accesses["resource_id"] = object["resource_id"]
            non_exist_accesses["role_id"] = object["role_id"]
            non_exist_accesses["user_id"] = object["user_id"] - exist_accesses_users
            non_exist_accesses["entity_id"] = object["entity_id"]
            non_exist_accesses["s_date"] = object["s_date"]
            non_exist_accesses["e_date"] = object["e_date"]
            tickets.push(non_exist_accesses)
              #end
            #end
          else
            #do nothing
          end

          #act with problem users
          exist_accesses_users.each do |ea_user|
            exist_accesses_by_user = []
            exist_accesses_by_user_roles = []
            exist_accesses_by_r_uid.each do |ea_by_r_uid_by_user|
              if ea_user.in?(ea_by_r_uid_by_user["users_ids"])
                exist_accesses_by_user_roles = exist_accesses_by_user_roles + ea_by_r_uid_by_user["role_id"]
              end
            end
            #any roles for this user in object??
            non_existing_roles = object["role_id"].map(&:to_i) - exist_accesses_by_user_roles
            if !non_existing_roles.empty?
              if IResource.find(object["resource_id"])["has_entities"] == false
                non_exist_accesses = {}
                non_exist_accesses["r_uid"] = object["r_uid"]
                non_exist_accesses["resource_id"] = object["resource_id"]
                non_exist_accesses["user_id"] = []
                non_exist_accesses["user_id"].push(ea_user)
                non_exist_accesses["role_id"] = non_existing_roles
                non_exist_accesses["s_date"] = object["s_date"]
                non_exist_accesses["e_date"] = object["e_date"]
                tickets.push(non_exist_accesses)
              else
                non_existing_roles.each do |non_e_role|
                  exist_accesses_by_user_roles_entities = []
                  exist_accesses_by_r_uid.each do |ea_by_r_uid_by_user|
                    if ea_by_r_uid_by_user["users_ids"] == ea_user && !(ea_by_r_uid_by_user["role_id"] & non_e_role).empty?
                      exist_accesses_by_user_roles_entities = exist_accesses_by_user_roles_entities + exist_accesses_by_r_uid["entity_id"]
                    end
                  end
                  non_existing_entities = object_entities.map(&:to_i) - exist_accesses_by_user_roles_entities
                  if !non_existing_entities.empty?
                    non_exist_accesses = {}
                    non_exist_accesses["r_uid"] = object["r_uid"]
                    non_exist_accesses["resource_id"] = object["resource_id"]
                    non_exist_accesses["user_id"] = []
                    non_exist_accesses["user_id"].push(ea_user)
                    non_exist_accesses["role_id"] = []
                    non_exist_accesses["role_id"].push(non_e_role)
                    non_exist_accesses["entity_id"] = non_existing_entities
                    non_exist_accesses["s_date"] = object["s_date"]
                    non_exist_accesses["e_date"] = object["e_date"]
                    tickets.push(non_exist_accesses)
                  end
                end
              end
            end
            #checkin for non existing entities for existing roles
            if !exist_accesses_by_user_roles.empty? ######################### not working if exits non problem roles in object
              if IResource.find(object["resource_id"])["has_entities"] == true
                exist_accesses_by_user_roles.each do |existing_role|
                  non_exist_accesses = {}
                  exist_accesses_by_user_ex_roles_entities = []
                  exist_accesses_by_r_uid.each do |ea_by_r_uid_by_user|
                    if ea_user.in?(ea_by_r_uid_by_user["users_ids"]) && existing_role.in?(ea_by_r_uid_by_user["role_id"])
                      exist_accesses_by_user_ex_roles_entities = exist_accesses_by_user_ex_roles_entities + ea_by_r_uid_by_user["entity_id"]
                    end
                  end
                  non_existing_entities = object_entities.map(&:to_i) - exist_accesses_by_user_ex_roles_entities
                  if !non_existing_entities.empty?
                    non_exist_accesses = {}
                    non_exist_accesses["r_uid"] = object["r_uid"]
                    non_exist_accesses["resource_id"] = object["resource_id"]
                    non_exist_accesses["user_id"] = []
                    non_exist_accesses["user_id"].push(ea_user)
                    non_exist_accesses["role_id"] = []
                    non_exist_accesses["role_id"].push(existing_role)
                    non_exist_accesses["entity_id"] = non_existing_entities
                    non_exist_accesses["s_date"] = object["s_date"]
                    non_exist_accesses["e_date"] = object["e_date"]
                    tickets.push(non_exist_accesses)
                  end
                end
              end
            end
          end
        else
          tickets.push(object)
        end
      end



    end
    {:tmp => tmp, :ticktets => tickets, :exist_accesses => exist_accesses}
  end



  def self.verify_tickets_for_simple_approvement(rawData, group_id, i_ticktemplate_id, issue_id)
    tickets = []
    if IGrouptemplate.where(:group_id => group_id, :i_ticktemplate_id => i_ticktemplate_id).count > 0
      tracker_id = Issue.find(issue_id).tracker_id
      tr_new_emp_id = ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i 
      templ_using_issue_id = ITicktemplate.where(:id => i_ticktemplate_id).first[:using_issue_id]
      template_uids =  ITicket.active.where(:issue_id => templ_using_issue_id,:i_ticktemplate_id => i_ticktemplate_id).map(&:r_uid).uniq
      group_users_ids = User.in_group(group_id).map(&:id).uniq
      if !rawData.empty?
        rawData.each do |object|  
          if object["r_uid"].in?(template_uids)
            user_ids = []
            if tracker_id != tr_new_emp_id
              object["user_id"].each do |user_id|
                if user_id.to_i.in?(group_users_ids)
                  user_ids.push(user_id)
                end
              end
            else
              user_ids.push(0)
            end
            if !user_ids.empty?
              template_tickets = ITicket.active.where(:issue_id => templ_using_issue_id,:i_ticktemplate_id => i_ticktemplate_id, :r_uid => object["r_uid"])
              ticket = template_tickets.select([:description]).first.attributes.symbolize_keys
              ticket["r_uid"] = object["r_uid"]
              ticket["user_id"] = user_ids
              ticket["resource_id"] = template_tickets.select(:i_resource_id).map(&:i_resource_id).first
              main_ticket = template_tickets.first
              ticket["role_id"] = template_tickets.select(:i_role_id).map(&:i_role_id).uniq
              if IResource.find(object["resource_id"])["has_entities"] == true
                template_entities = main_ticket.ientities.select(['i_entities.id']).map(&:id).uniq
                object_entities = object["entity_id"].map(&:to_i)
                if object_entities.empty?
                  ticket["entity_id"] = template_entities
                elsif !(template_entities & object_entities).empty?
                  ticket["entity_id"] = template_entities & object_entities
                else
                  ticket["entity_id"] = template_entities 
                end
              end
              if object["s_date"].nil?
                ticket["s_date"] = Time.now().strftime("%d.%m.%Y")
              else
                ticket["s_date"] = object["s_date"]
              end
              if object["e_date"].nil?
                ticket["e_date"] = "31.12.2025"
              else
                ticket["e_date"] = object["e_date"]
              end
              tickets.push(ticket)
            end
          end
        end
      end
    end
    tickets
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
      else
        if main_ticket.iaccesses.active.first.confirmed_by_id?
          #ticket[:status] = l(:at_confirmed_by)
          ticket[:status] = l(:at_confirmed_at) + main_ticket.iaccesses.active.first.confirmed_at.in_time_zone(tz).to_s(:atf)#.strftime("%H:%M %d.%m.%Y")
          ticket[:status_id] = 4
          ticket[:user_id] = main_ticket.iaccesses.active.first.confirmed_by_id
          ticket[:user_name] = User.where(:id => main_ticket.iaccesses.active.first.confirmed_by_id).first.name
        else
          if main_ticket.iaccesses.active.first.granted_by_id?
            #ticket[:status] = l(:at_granted_by)
            ticket[:status] = l(:at_granted_at) + main_ticket.iaccesses.active.first.granted_at.in_time_zone(tz).to_s(:atf)#.strftime("%H:%M %d.%m.%Y")
            ticket[:status_id] = 3
            ticket[:user_id] = main_ticket.iaccesses.active.first.granted_by_id
            ticket[:user_name] = User.where(:id => main_ticket.iaccesses.active.first.granted_by_id).first.name
            #maybe revoke by user for r_uid?
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

  def self.show_tickets_list(issue_id,t_uid)######
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
    #if ITicket.check_issue_status(issue_id)[0..3] == [1,1,1,1]
    #  true
    #else
    #  false
    #end
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
    #ITicket.check_itickets_for_verified(issue_id)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
  end

  def self.reject_tickets_by_security(issue_id, user_id)
    
    tracker_id = Issue.find(issue_id).tracker_id
    tr_new_emp_id = ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
    if tracker_id == tr_new_emp_id 
      ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => nil, :verified_at => nil, :user_id => 0, :approved_by_id => nil, :approved_at => nil)
    else
      ITicket.active.where(:issue_id => issue_id).update_all(:verified_by_id => nil, :verified_at => nil)
    end
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
  end

  def self.check_issue_status(issue_id, user_id = nil)
    #cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    #cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
    #cf_granting_id = ISetting.active.where(:param => "cf_granting_id").first.value
    #cf_confirming_id = ISetting.active.where(:param => "cf_confirming_id").first.value

    #cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id)
    #if cf_verified.empty?
    #  CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id, :value => 0)
      #cf_verified = 0
    #else
    #  cf_verified = cf_verified.first.value.to_i
    #end
    #cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id)

    #if cf_approved.empty?
    #  CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id, :value => 0)
      #cf_approved = 0
    #else
      #cf_approved = cf_approved.first.value.to_i
    #end

    #cf_granting = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id)
    #if cf_granting.empty?
    #  CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id, :value => 0)
    #  cf_granting = 0
    #else
    #  cf_granting = cf_granting.first.value.to_i
    #end

    #cf_confirming = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id)
    #if cf_confirming.empty?
    #  CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id, :value => 0)
    #  cf_confirming = 0
    #else
    #  cf_confirming = cf_confirming.first.value.to_i
    #end

    #if cf_verified == 0
      #Issue.find(issue_id).update_attributes(:assigned_to_id => ISetting.active.where(:param => "sec_group_id").first.value)
    #end
    cf_v = ITicket.check_granting_cf(issue_id)

    cf_verified = cf_v[0]
    cf_approved = cf_v[1]
    cf_granting = cf_v[2]
    cf_confirming = cf_v[3]

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

  def self.check_granting_cf(issue_id)
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
        cf_verified_v = 0
      else
        cf_verified_v = cf_verified.first.value
      end
      if cf_approved.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id, :value => 0)
        cf_approved_v = 0
      else
        cf_approved_v = cf_approved.first.value
      end
      if cf_granting.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id, :value => 0)
        cf_granting_v = 0
      else
        cf_granting_v = cf_granting.first.value
      end
      if cf_confirming.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id, :value => 0)
        cf_confirming_v = 0
      else
        cf_confirming_v = cf_confirming.first.value
      end
      all_tickets_count = ITicket.active.where(:issue_id => issue_id).count
      if all_tickets_count > 0 
        verified_tickets_count = ITicket.active.where("i_tickets.verified_by_id IS NOT NULL").where(:issue_id => issue_id).count
        if all_tickets_count != verified_tickets_count
          cf_verified.update_all(:value => 0)
          cf_approved.update_all(:value => 0)
          cf_granting.update_all(:value => 0)
          cf_confirming.update_all(:value => 0)
          cf_verified_v = 0
          cf_approved_v = 0
          cf_granting_v = 0
          cf_confirming_v = 0
        else
          approved_tickets_count = ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id).count
          if all_tickets_count != approved_tickets_count
            cf_approved.update_all(:value => 0)
            cf_granting.update_all(:value => 0)
            cf_confirming.update_all(:value => 0)
            cf_approved_v = 0
            cf_granting_v = 0
            cf_confirming_v = 0
          else
            granted_accesses_count = ITicket.active.joins(:iaccesses).where("i_accesses.granted_by_id IS NOT NULL").where(:issue_id => issue_id).map(&:id).uniq.count
            if granted_accesses_count == 0
              cf_granting.update_all(:value => 0)
              cf_confirming.update_all(:value => 0)
              cf_granting_v = 0
              cf_confirming_v = 0
            else
              if all_tickets_count != granted_accesses_count
                cf_granting.update_all(:value => 0)
                cf_confirming.update_all(:value => 0)
                cf_granting_v = 0
                cf_confirming_v = 0
              else
                confirmed_accesses_count = ITicket.active.joins(:iaccesses).where("i_accesses.confirmed_by_id IS NOT NULL").where(:issue_id => issue_id).map(&:id).uniq.count
                if all_tickets_count != confirmed_accesses_count
                  cf_confirming.update_all(:value => 0)
                  cf_confirming_v = 0
                end
              end
            end
          end
        end
      else
        if cf_verified_v != 0
          cf_verified.update_all(:value => 0)
          cf_verified_v = 0
        end
        if cf_approved_v != 0
          cf_approved.update_all(:value => 0)
          cf_approved_v = 0
        end
        if cf_granting_v != 0
          cf_granting.update_all(:value => 0)
          cf_granting_v = 0
        end
        if cf_confirming_v != 0
          cf_confirming.update_all(:value => 0)
          cf_confirming_v = 0
        end
      end
      return cf_verified_v.to_i,cf_approved_v.to_i,cf_granting_v.to_i,cf_confirming_v.to_i
    else
      return 0,0,0,0
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

      #cf_granting = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id)
      if cf_granting.empty?
        CustomValue.create(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_granting_id, :value => 0)
      else
        cf_granting = cf_granting.update_all(:value => 0)
      end
      #cf_confirming = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_confirming_id)
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
    #else
    #  ITicket.set_default_cf(issue_id)
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
    #else
    #  ITicket.set_default_cf(issue_id)
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
    #else
    #  ITicket.set_default_cf(issue_id)
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
    #else
    #  ITicket.set_default_cf(issue_id)
    end
  end


  def self.may_be_approved_by_owner_status(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id),:approved_by_id => nil).count > 0
    #if ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id),:approved_by_id => nil).count > 0
      #true
    #else
      #false
    #end
  end



  def self.may_be_revoked_by_owner_status(issue_id, owner_id, r_uid = nil)
    #if ITicket.check_issue_status(issue_id)[0..1] == [1,0] &&
    if ITicket.active.where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0 
        tracker_id = Issue.find(issue_id).tracker_id
        tr_new_emp_id = ISetting.active.where(:param => "tr_new_emp_id").first.value.to_i
        tr_grant_id = ISetting.active.where(:param => "tr_grant_id").first.value.to_i
        if tracker_id == tr_new_emp_id
          IAccess.joins(:iticket).where("i_tickets.deleted" => 0, "i_tickets.issue_id" => issue_id).count == 0
          #if IAccess.joins(:iticket).where("i_tickets.deleted" => 0, "i_tickets.issue_id" => issue_id).count == 0
          #  true
          #else
          #  false
          #end
        else
          ITicket.active.joins(:iaccesses).where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count == 0 && tracker_id == tr_grant_id
          #if ITicket.active.joins(:iaccesses).where("i_tickets.approved_by_id IS NOT NULL").where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count == 0 && tracker_id == tr_grant_id
          #  true
          #else
          #  false
          #end
        end
      else
        false
      end
  end

  def self.need_to_approve_by_owner_status(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id), :approved_by_id => nil).count > 0
    #if ITicket.active.where(:issue_id => issue_id,:i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id), :approved_by_id => nil).count > 0
      #true
    #else
      #false
    #end
  end


end

