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

class IRetimeaccess < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :i_access_id, :r_uid, :old_e_date, :r_date, :retime_issue_id, :retimed_to, :deleted, :active, :r_verifier_by_id, :r_verifier_at, :r_approver_by_id, :r_approver_at, :created_by_id, :created_at, :updated_at
  belongs_to :iaccess, :class_name => "IAccess", :foreign_key => "i_access_id"
  #belongs_to :iticket, :class_name => "ITicket", :foreign_key => "i_ticket_id"
  belongs_to :r_verifier, :class_name => "User", :foreign_key => "verified_by_id"
  belongs_to :r_approver, :class_name => "User", :foreign_key => "approved_by_id"
  belongs_to :creater, :class_name => "User", :foreign_key => "created_by_id"
  before_create :default

  def default
    self.deleted = 0
  end


  def self.create_prolongated_accesses(issue_id, inputData, new_r_date = nil)
    old_r_accesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    if !old_r_accesses.empty?
      old_r_accesses.delete_all()
    end
    if !inputData.empty?
      inputData.each do |ticket|
        r_date = new_r_date
        r_uid = ticket[:r_uid]
        users = ticket[:users]#[0][:id]
        users.each do |user|
          iaccesses = IAccess.joins(:iticket).where("i_accesses.confirmed_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NULL").where("i_tickets.user_id" => user[:id],"i_tickets.r_uid" => r_uid) 
          iaccesses.each do |iaccess|
            e_date = ITicket.where(:r_uid => r_uid, :user_id => user[:id]).first[:e_date]
            r_date = e_date.to_date.next_year.strftime("%d.%m.%Y")
            if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NULL or i_retimeaccesses.r_approved_by_id IS NULL").where(:i_access_id => iaccess.id, :r_uid => r_uid).empty?
              iretimeaccess = IRetimeaccess.new(:i_access_id => iaccess.id, :r_uid => r_uid, :old_e_date => e_date, :r_date => Date.parse(r_date), :retime_issue_id => issue_id, :created_by_id => User.current.id)
              iretimeaccess.save
            end
          end
        end
      end
    end
  end


  def self.create_retiming_accesses(issue_id, inputData, new_r_date = nil)
    old_r_accesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    if !old_r_accesses.empty?
      old_r_accesses.delete_all()
    end
    if !inputData.empty?
      inputData.each do |ticket|
        r_date = ticket["r_date"]
        r_uid = ticket["r_uid"]
        users = ticket["users"]#[0]["id"]
        users.each do |user|
          iaccesses = IAccess.joins(:iticket).where("i_accesses.confirmed_by_id IS NOT NULL AND i_accesses.deactivated_by_id IS NULL AND i_tickets.e_date != ?", Date.parse(r_date)).where("i_tickets.user_id" => user["id"],"i_tickets.r_uid" => r_uid) 
          iaccesses.each do |iaccess|
            e_date = ITicket.where(:r_uid => r_uid, :user_id => user["id"]).first[:e_date]
            if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NULL or i_retimeaccesses.r_approved_by_id IS NULL").where(:i_access_id => iaccess.id, :r_uid => r_uid).empty?
              iretimeaccess = IRetimeaccess.new(:i_access_id => iaccess.id, :r_uid => r_uid, :old_e_date => e_date, :r_date => Date.parse(r_date), :retime_issue_id => issue_id, :created_by_id => User.current.id)
              iretimeaccess.save
            end
          end
        end
      end
    end
  end


  def self.check_retiming_editable(issue_id, user, r_user_id = nil)
    if user.id == 1 || user.id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) 
      true
    else
      false
    end
  end


  def self.resowner_for_unapproval_issue(issue_id)
    unapproval_res_id = IRetimeaccess.active.where('i_retimeaccesses.r_verified_by_id IS NOT NULL and i_retimeaccesses.r_approved_by_id IS NULL').where(:retime_issue_id => issue_id).first.iaccess.iticket[:i_resource_id]
    IResowner.where(:i_resource_id => unapproval_res_id).map(&:user_id).uniq - [1]
  end

  def self.resowners_for_issue(issue_id)
    accesses_ids = IRetimeaccess.active.where(:retime_issue_id => issue_id).map(&:i_access_id)
    itickets = ITicket.joins(:iaccesses).where("i_accesses.id IN (?)",accesses_ids)
    resources_ids = itickets.map(&:i_resource_id).uniq
    IResowner.where(:i_resource_id => resources_ids).map(&:user_id).uniq - [1]
  end

  def self.last_retiming_version(issue_id, user)
    if !IRetimeaccess.active.where(:retime_issue_id => issue_id).empty?
      Time::DATE_FORMATS.merge!(:localdb=>"%H:%M:%S %d.%m.%Y")
      if user.time_zone != nil
        tz = user.time_zone
      else
        tz = "Minsk"
      end
      version = IRetimeaccess.joins(:creater).where(:retime_issue_id => issue_id).select("firstname,lastname,created_at").first
      version_value = "(" + l(:at_last_edited_by) + version.firstname + " " + version.lastname + l(:at_at) + version.created_at.in_time_zone(tz).to_s(:localdb) + ")"
    else
      version_value = ""
    end
  end


  def self.show_retiming_users(retimer_id, issue_id = nil)
    users_nosort = []
    first_option = {}
    first_option[:id] = ""
    first_option[:name] = l(:at_select_employee)
    users = []

    if issue_id.nil?
      if retimer_id == 1 || retimer_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id)) #|| retimer_id.in?(User.active.in_group(ISetting.active.where(:param => "hr_group_id").first.value.to_i).map(&:id))
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
        if IGrouplider.is_group_lider(retimer_id)
          groups = IGrouplider.where(:user_id => retimer_id).map(&:group_id)
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
      #rev_user = {}
      rev_users_ids = IRetimeaccess.retiming_accesses_user_id(issue_id)
      if !rev_users_ids.empty?
        rev_users_ids.each do |rev_user_id|
          rev_user = {}
          rev_user[:id]=rev_user_id
          rev_user[:name] = User.find(rev_user[:id]).name
          users_nosort.push(rev_user)
        end
      end
    end
    users_list = users_nosort.to_a.sort_by! {|u| u[:id]}
    #users_list.insert(0, first_option)

  end

  def self.retiming_accesses_user_id(issue_id)
    if IRetimeaccess.active.where(:retime_issue_id => issue_id).count > 0
      user_ids = []
      IRetimeaccess.active.where(:retime_issue_id => issue_id).each do |iretimeaccess| 
        user_ids.push(iretimeaccess.iaccess.iticket.user_id)
      end
      user_ids.uniq
    else
      []
    end
  end


def self.retiming_accesses_list(issue_id, current_user_id, r_user_id = nil)
    Time::DATE_FORMATS.merge!(:atf=>"%H:%M %d.%m.%Y")
    if User.find(current_user_id).time_zone != nil
      tz = User.current.time_zone
    else
      tz = "Minsk"
    end
    owned_resources = IResowner.where(:user_id => current_user_id).map(&:i_resource_id)
    iretimeaccesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)   
    issue_r_uids = iretimeaccesses.map(&:r_uid).uniq
    if !iretimeaccesses.empty?
      retimed_accesses_ids = iretimeaccesses.map(&:i_access_id)
      user_ids = ITicket.active.joins(:iaccesses).where("i_accesses.id IN (?)", retimed_accesses_ids).map(&:user_id).uniq
      accesses = []
      user_ids.each do |user_id|
        user_accesses_ids = IAccess.joins(:iticket).where("i_accesses.id IN (?) AND i_tickets.user_id = ?", retimed_accesses_ids, user_id).map(&:id).uniq 
        r_uids = ITicket.active.joins(:iaccesses).where("i_accesses.id IN (?)", user_accesses_ids).map(&:r_uid).uniq
        r_uids.each do |r_uid|
          access = {}
          access[:i_roles] = []
          access[:users] = []
          access[:users_ids] = []
          users = []
          users_ids= []
          ientities = []
          #accesses_ids = iretimeaccesses.where(:r_uid => r_uid).map(&:i_access_id)
          #accesses_ids = user_accesses_ids
          #accesses_ids.each do |access_id|
          #  user = {}
          #  user_id = IAccess.where(:id => access_id).first.iticket[:user_id]
          #  user[:id] = user_id
          #  user[:name] = User.find(user_id).name
          #  users_ids.push(user)
          #  users.push(User.find(user_id).name)
          #end
          user = {}
          user[:id] = user_id
          user[:name] = User.find(user_id).name
          users_ids.push(user)
          users.push(User.find(user_id).name)

          access[:users_ids] = users_ids.uniq
          access[:users] = users.uniq
          itickets = ITicket.joins(:iaccesses).where("i_accesses.id IN (?)",user_accesses_ids).where(:r_uid => r_uid)
          roles_ids = itickets.map(&:i_role_id).uniq
          access[:i_resource_id] = itickets.first.i_resource_id
          access[:i_resource] = IResource.find(access[:i_resource_id]).name
          access[:description] = itickets.first[:description]
          roles_ids.each do |role_id|
            access[:i_roles].push(IRole.find(role_id).name)
          end
          entities_ids = IAccess.joins(:iticket).where("i_tickets.r_uid = ?", r_uid).where(:id => user_accesses_ids).map(&:i_entity_id).uniq
          entities_ids.each do |ientity_id|
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
          access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
          e_date = iretimeaccesses.where(:r_uid => r_uid).first[:old_e_date]
          access[:e_date] = e_date.strftime("%d.%m.%Y")
          #r_date = iretimeaccesses.where(:r_uid => r_uid).first[:r_date]
          r_date = iretimeaccesses.where(:i_access_id => user_accesses_ids).first[:r_date]
          access[:r_date] = r_date.strftime("%d.%m.%Y")
          if r_date > e_date
            access[:prolongation] = 1
          else
            access[:prolongation] = 0
          end
          #access[:r_verified_by_id] = iretimeaccesses.where(:r_uid => r_uid).first[:r_verified_by_id]
          access[:r_verified_by_id] = iretimeaccesses.where(:i_access_id => user_accesses_ids).first[:r_verified_by_id]

          access[:r_uid] = r_uid
          if !access[:r_verified_by_id].nil?
            #access[:r_verified_at] = iretimeaccesses.where(:r_uid => r_uid).first[:r_verified_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
            access[:r_verified_at] = iretimeaccesses.where(:i_access_id => user_accesses_ids).first[:r_verified_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
          end
          #access[:r_approved_by_id] = iretimeaccesses.where(:r_uid => r_uid).first[:r_approved_by_id]
          access[:r_approved_by_id] = iretimeaccesses.where(:i_access_id => user_accesses_ids).first[:r_approved_by_id]
          if !access[:r_approved_by_id].nil?
            #access[:r_approved_at] = iretimeaccesses.where(:r_uid => r_uid).first[:r_approved_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
            access[:r_approved_at] = iretimeaccesses.where(:i_access_id => user_accesses_ids).first[:r_approved_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
          end
          if !access[:r_verified_by_id].nil?
            if access[:r_approved_by_id].nil?
              access[:status] = l(:at_need_to_approve)
              access[:user_id] = access[:r_verified_by_id]
              access[:user_name] = User.where(:id => access[:r_verified_by_id]).first.name
              access[:status_id] = 1
              if access[:i_resource_id].in?(owned_resources)
                access[:may_be_retimed] = 1
              else
                access[:may_be_retimed] = 0
              end
            else
              issue_approved_at = IRetimeaccess.active.where(:retime_issue_id => issue_id).first.r_approved_at.in_time_zone(tz)
              #if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:r_uid => r_uid).empty?
              if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:i_access_id => user_accesses_ids).empty?
                access[:status] = l(:at_approved_retiming_at) + access[:r_approved_at]
                access[:user_id] = access[:r_approved_by_id]
                access[:user_name] = User.where(:id => access[:r_approved_by_id]).first.name
                access[:status_id] = 2
                if access[:i_resource_id].in?(owned_resources)
                  access[:may_be_retimed] = 1
                else
                  access[:may_be_retimed] = 0
                end
              else
                #access[:new_retime_issue_id] = IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:r_uid => r_uid).last.retime_issue_id
                access[:new_retime_issue_id] = IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:i_access_id => user_accesses_ids).last.retime_issue_id
                access[:status_id] = 3
                access[:status] = l(:at_ext_retimed)
              end
            end
          else
            access[:status] = l(:at_need_to_verified)
            access[:status_id] = 0
          end   
          accesses.push(access)
        end
      end


      if !r_user_id.nil?
        IAccess.accesses_list(r_user_id).each do |access|
          if !access[:r_uid].in?(issue_r_uids)
            accesses.push(access)
          end
        end
      end
      accesses
    else
      IAccess.accesses_list(r_user_id)
    end
  end


##############
  def self.old_retiming_accesses_list(issue_id, current_user_id, r_user_id = nil)
    Time::DATE_FORMATS.merge!(:atf=>"%H:%M %d.%m.%Y")
    if User.find(current_user_id).time_zone != nil
      tz = User.current.time_zone
    else
      tz = "Minsk"
    end
    owned_resources = IResowner.where(:user_id => current_user_id).map(&:i_resource_id)
    iretimeaccesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    if !iretimeaccesses.empty?
      r_uids = iretimeaccesses.map(&:r_uid).uniq
      accesses = []
      problem_r_uids = []
      r_uids.each do |r_uid|
        access = {}
        access[:i_roles] = []
        access[:users] = []
        access[:users_ids] = []
        users = []
        users_ids= []
        ientities = []
        verified_accesses_ids = []
        problem_accesses_ids = []
        accesses_ids = iretimeaccesses.where(:r_uid => r_uid).map(&:i_access_id)
        accesses_ids.each do |access_id|
          user = {}
          user_id = IAccess.where(:id => access_id).first.iticket[:user_id]
          user[:id] = user_id
          user[:name] = User.find(user_id).name
          if IAccess.has_deactived_accesses(r_uid,user_id)
            problem_r_uid = {}
            problem_r_uid[:r_uid] = r_uid
            problem_r_uid[:user_id] = user_id
            problem_r_uid[:access_id] = access_id
            problem_accesses_ids.push(problem_r_uid)
          else
            users_ids.push(user)
            users.push(User.find(user_id).name)
            verified_access = {}
            verified_access[:access_id] = access_id
            verified_accesses_ids.push(access_id)
          end
        end
        access[:problem_accesses_ids] = problem_accesses_ids
        access[:users_ids] = users_ids.uniq
        access[:users] = users.uniq
        itickets = ITicket.joins(:iaccesses).where("i_accesses.id IN (?)",accesses_ids)
        roles_ids = itickets.map(&:i_role_id).uniq
        access[:i_resource_id] = itickets.first.i_resource_id
        access[:i_resource] = IResource.find(access[:i_resource_id]).name
        access[:description] = itickets.first[:description]
        roles_ids.each do |role_id|
          access[:i_roles].push(IRole.find(role_id).name)
        end
        entities_ids = IAccess.where(:id => IRetimeaccess.active.where(:r_uid => r_uid).map(&:i_access_id).uniq).map(&:i_entity_id).uniq
        entities_ids.each do |ientity_id|
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
        access[:s_date] = itickets.first[:s_date].strftime("%d.%m.%Y")
        e_date = iretimeaccesses.where(:r_uid => r_uid).first[:old_e_date]
        access[:e_date] = e_date.strftime("%d.%m.%Y")
        r_date = iretimeaccesses.where(:r_uid => r_uid).first[:r_date]
        access[:r_date] = r_date.strftime("%d.%m.%Y")
        if r_date > e_date
          access[:prolongation] = 1
        else
          access[:prolongation] = 0
        end
        access[:r_verified_by_id] = iretimeaccesses.where(:r_uid => r_uid).first[:r_verified_by_id]
        access[:r_uid] = r_uid
        if !access[:r_verified_by_id].nil?
          access[:r_verified_at] = iretimeaccesses.where(:r_uid => r_uid).first[:r_verified_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
        end
        access[:r_approved_by_id] = iretimeaccesses.where(:r_uid => r_uid).first[:r_approved_by_id]
        if !access[:r_approved_by_id].nil?
          access[:r_approved_at] = iretimeaccesses.where(:r_uid => r_uid).first[:r_approved_at].in_time_zone(tz).to_s(:atf)  #.strftime("%H:%M %d.%m.%Y")
        end
        if !access[:r_verified_by_id].nil?
          if access[:r_approved_by_id].nil?
            access[:status] = l(:at_need_to_approve)
            access[:user_id] = access[:r_verified_by_id]
            access[:user_name] = User.where(:id => access[:r_verified_by_id]).first.name
            access[:status_id] = 1
            if access[:i_resource_id].in?(owned_resources)
              access[:may_be_retimed] = 1
            else
              access[:may_be_retimed] = 0
            end
          else
            issue_approved_at = IRetimeaccess.active.where(:retime_issue_id => issue_id).first.r_approved_at.in_time_zone(tz)
            if IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:r_uid => r_uid).empty?
              access[:status] = l(:at_approved_retiming_at) + access[:r_approved_at]
              access[:user_id] = access[:r_approved_by_id]
              access[:user_name] = User.where(:id => access[:r_approved_by_id]).first.name
              access[:status_id] = 2
              if access[:i_resource_id].in?(owned_resources)
                access[:may_be_retimed] = 1
              else
                access[:may_be_retimed] = 0
              end
            else
              access[:new_retime_issue_id] = IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.r_approved_at > '%s'", issue_id, issue_approved_at).where(:r_uid => r_uid).last.retime_issue_id
              access[:status_id] = 3
              access[:status] = l(:at_ext_retimed)
            end

          end
        else
          access[:status] = l(:at_need_to_verified)
          access[:status_id] = 0
        end
        accesses.push(access)
      end
      if !r_user_id.nil?
        IAccess.accesses_list(r_user_id).each do |access|
          if !access[:r_uid].in?(r_uids)
            accesses.push(access)
          end
        end
      end
      accesses
    else
      IAccess.accesses_list(r_user_id)
    end
  end
######



  def self.check_retiming_status(issue_id, current_user_id = nil)
    cf_v = IRetimeaccess.check_retiming_cf(issue_id)

    cf_verified = cf_v[0]
    cf_approved = cf_v[1]
    ret_accesses_user_id = IRetimeaccess.retiming_accesses_user_id(issue_id)
    accesses_count = IRetimeaccess.active.where(:retime_issue_id => issue_id).count
    if current_user_id.nil?
      return cf_verified, cf_approved, accesses_count, ret_accesses_user_id
    else
      may_be_verify_retiming = IRetimeaccess.may_be_verify_retiming(issue_id, current_user_id) ? 1 : 0
      may_be_reject_verification_retiming = IRetimeaccess.may_be_reject_verification_retiming(issue_id, current_user_id) ? 1 : 0
      may_be_approve_retiming = IRetimeaccess.may_be_approve_retiming(issue_id, current_user_id ) ? 1 : 0
      may_be_refuse_approve_retiming = IRetimeaccess.may_be_refuse_approve_retiming(issue_id, current_user_id ) ? 1 : 0
      #             0           1             2                3                       4                         5                                6                             7                   
      return cf_verified, cf_approved, accesses_count, ret_accesses_user_id, may_be_verify_retiming, may_be_reject_verification_retiming, may_be_approve_retiming, may_be_refuse_approve_retiming
    end
  end


  def self.check_retiming_cf(issue_id)
    if !issue_id.nil?
      cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
      cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
      cf_verified = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id)
      cf_approved = CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id)
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

      all_tickets_count = IRetimeaccess.active.where(:retime_issue_id => issue_id).count
      if all_tickets_count > 0 
        verified_tickets_count = IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL").where(:retime_issue_id => issue_id).count
        if all_tickets_count != verified_tickets_count
          cf_verified.update_all(:value => 0)
          cf_approved.update_all(:value => 0)
          cf_verified_v = 0
          cf_approved_v = 0
        else
          approved_tickets_count = IRetimeaccess.active.where("i_retimeaccesses.r_approved_by_id IS NOT NULL").where(:retime_issue_id => issue_id).count
          if all_tickets_count != approved_tickets_count
            cf_approved.update_all(:value => 0)
            cf_approved_v = 0
          else
           
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
      end
      return cf_verified_v.to_i,cf_approved_v.to_i
    else
      return 0,0
    end
  end





  def self.verify_tickets_by_security(issue_id, user_id)
    IRetimeaccess.active.where(:retime_issue_id => issue_id).update_all(:r_verified_by_id => user_id, :r_verified_at => Time.now)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
  end

  def self.reject_tickets_by_security(issue_id, user_id)
    IRetimeaccess.active.where(:retime_issue_id => issue_id).update_all(:r_verified_by_id => nil, :r_verified_at => nil)
    cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
    CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
  end

  def self.approve_retiming_by_owner(issue_id, owner_id, r_uid = nil)
    iretimeaccesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    r_uids = iretimeaccesses.map(&:r_uid).uniq
    r_uids.each do |r_uid|
      accesses_ids = iretimeaccesses.where(:r_uid => r_uid).map(&:i_access_id)
      accesses_ids.each do |access_id|
        user_ids = ITicket.joins(:iaccesses).where("i_accesses.id = ?",access_id).map(&:user_id)
        if ITicket.active.where(:r_uid => r_uid, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0
          user_ids.each do |r_user_id|
            ITicket.where(:r_uid => r_uid, :user_id => r_user_id).update_all(:e_date => iretimeaccesses.where(:i_access_id => access_id).first[:r_date])
            iretimeaccesses.where(:r_uid => r_uid, :i_access_id => access_id).update_all(:r_approved_by_id => owner_id, :r_approved_at => Time.now)
          end
        end
      end
    end
    IRetimeaccess.check_retime_issue_for_approved(issue_id)
  end

  def self.refuse_approve_retiming_by_owner(issue_id, owner_id, r_uid = nil)
    iretimeaccesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    r_uids = iretimeaccesses.map(&:r_uid).uniq
    r_uids.each do |r_uid|
      accesses_ids = iretimeaccesses.where(:r_uid => r_uid).map(&:i_access_id)
      accesses_ids.each do |access_id|
        user_ids = ITicket.joins(:iaccesses).where("i_accesses.id = ?",access_id).map(&:user_id)
        if ITicket.active.where(:r_uid => r_uid, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0
          user_ids.each do |r_user_id|
            ITicket.where(:r_uid => r_uid, :user_id => r_user_id).update_all(:e_date => iretimeaccesses.where(:i_access_id => access_id).first[:old_e_date])
            iretimeaccesses.where(:r_uid => r_uid, :i_access_id => access_id).update_all(:r_approved_by_id => nil, :r_approved_at => nil)
          end
        end
      end
    end
    IRetimeaccess.check_retime_issue_for_approved(issue_id)
  end



  def self.may_be_verify_retiming(issue_id, user_id)
    ITicket.check_security_officer( User.where(:id => user_id).first) 
    #&& IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NULL").where(:retime_issue_id => issue_id).count > 0 ? 1 : 0 
  end

  def self.may_be_reject_verification_retiming(issue_id, user_id)
    ITicket.check_security_officer( User.where(:id => user_id).first) && IRetimeaccess.active.where("i_retimeaccesses.r_approved_by_id IS NULL").where(:retime_issue_id => issue_id).count == IRetimeaccess.active.where(:retime_issue_id => issue_id).count
  end

  def self.may_be_approve_retiming(issue_id, owner_id, r_uid = nil)
    ITicket.active.where(:r_uid => IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NULL").where(:retime_issue_id => issue_id).map(&:r_uid).uniq, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0
  end

  def self.may_be_refuse_approve_retiming(issue_id, owner_id, r_uid = nil)
    iretimeaccesses = IRetimeaccess.active.where(:retime_issue_id => issue_id)
    if iretimeaccesses.count > 0
      r_uids = iretimeaccesses.map(&:r_uid).uniq
      issue_created_at = iretimeaccesses.first.created_at
      ITicket.active.where(:r_uid => IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL").where(:retime_issue_id => issue_id).map(&:r_uid).uniq, :i_resource_id => IResowner.where(:user_id => owner_id).map(&:i_resource_id)).count > 0 && IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL AND i_retimeaccesses.r_approved_by_id IS NOT NULL AND i_retimeaccesses.retime_issue_id != %d AND i_retimeaccesses.created_at > '%s'", issue_id, issue_created_at).where(:r_uid => r_uids).empty?
    else
      false
    end

  end

  def self.check_retime_issue_for_verified(issue_id) # Not used
    if IRetimeaccess.active.where(:retime_issue_id => issue_id).count > 0 
      cf_verified_id = ISetting.active.where(:param => "cf_verified_id").first.value
      if IRetimeaccess.active.where(:retime_issue_id => issue_id).count == IRetimeaccess.active.where("i_retimeaccesses.r_verified_by_id IS NOT NULL").where(:retime_issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_verified_id).update_all(:value => 0)
      end
    end
  end

  def self.check_retime_issue_for_approved(issue_id)
    if IRetimeaccess.active.where(:retime_issue_id => issue_id).count > 0
      cf_approved_id = ISetting.active.where(:param => "cf_approved_id").first.value
      if IRetimeaccess.active.where(:retime_issue_id => issue_id).count == IRetimeaccess.active.where("i_retimeaccesses.r_approved_by_id IS NOT NULL").where(:retime_issue_id => issue_id).count
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 1)
      else
        CustomValue.where(:customized_type => "Issue",:customized_id => issue_id, :custom_field_id => cf_approved_id).update_all(:value => 0)
      end
    end
  end


end
