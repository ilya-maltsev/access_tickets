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

class IGrouptemplate < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :deleted, :i_ticktemplate_id, :group_id

  belongs_to :iticktemplate, :class_name => "ITicktemplate", :foreign_key => "i_ticktemplate_id"
  belongs_to :group, :class_name => "Group", :foreign_key => "group_id"


  def self.group_id_by_template(ticktemplate_id)
    if IGrouptemplate.where(:i_ticktemplate_id => ticktemplate_id).count > 0
      IGrouptemplate.where(:i_ticktemplate_id => ticktemplate_id).map(&:group_id).first
    end
  end

end
