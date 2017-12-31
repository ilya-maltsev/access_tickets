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

class IResgranter < ActiveRecord::Base

  belongs_to :granter, :class_name => "User", :foreign_key => "user_id"
  belongs_to :iresource, :class_name => "IResource", :foreign_key => "i_resource_id"
  #attr_accessible :name
  #belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  def self.is_resgranter(user_id)
    IResgranter.where(:user_id => user_id).count > 0
  end

  def self.is_granter_for_resource(user_id, resource_id)
    IResgranter.where(:user_id => user_id, :i_resource_id => resource_id).count > 0
  end

  #def self.is_granter_for_issue(user_id, issue_id)
  #  ungranted_res_id = ITicket.active.joins(:iaccesses).where('i_accesses.granted_by_id is NULL').where(:issue_id => issue_id).map(&:i_resource_id).uniq
    #user_id.in?(IResgranter.where(:i_resource_id => ungranted_res_id).map(&:user_id).uniq )
  #end

end
