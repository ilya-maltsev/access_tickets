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


class IGrouplider < ActiveRecord::Base

  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :group, :class_name => "Group", :foreign_key => "group_id"


  def self.lider_for_user(user_id, lider_id)
    is_group_lider = IGrouplider.is_group_lider(lider_id)
    if is_group_lider
      groups = IGrouplider.where(:user_id => lider_id).map(&:group_id)
      users_ids_all = []
      groups.each do |group|
        users_ids = User.active.in_group(group).map(&:id)
        users_ids_all = users_ids_all | users_ids
      end
      if user_id.in?(users_ids_all)
        true
      else
        false
      end
    else
      false
    end
  end

  def self.available_users(user)
    users_nosort = []
    if ITicket.check_security_officer(user)
      users = User.select([:id,:firstname,:lastname])
      users.each do |user|
        option = {}
        option[:id]=user.id
        option[:name]=user.firstname + " " + user.lastname
        users_nosort.push(option)
      end
    else
      if IGrouplider.is_group_lider(user.id)
        groups = IGrouplider.where(:user_id => user.id).map(&:group_id)
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
    option = {}
    option[:id] = user.id
    option[:name] = User.find(user.id).name
    if users_nosort.detect{|w| w[:id] == option[:id]}.nil?
      users_nosort.push(option)
    end
    users_nosort.to_a.sort_by! {|u| u[:name]}
  end

  def self.is_group_lider(user_id)
    IGrouplider.where(:user_id => user_id).count > 0
  end

  def self.is_lider_for_group(group_id, user_id)
    IGrouplider.where(:group_id => group_id, :user_id => user_id).count > 0 || user_id == 1 || user_id.in?(User.active.in_group(ISetting.active.where(:param => "sec_group_id").first.value.to_i).map(&:id))
  end

  def self.group_ids(user_id = nil)
    if user_id.nil?
      IGrouplider.all.map(&:group_id).uniq
    else
      if ITicket.check_security_officer(User.find(user_id))
        IGrouplider.all.map(&:group_id).uniq
      else
        IGrouplider.where(:user_id => user_id).map(&:group_id).uniq
      end
    end
  end
end
