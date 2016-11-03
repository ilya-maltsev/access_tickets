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

class IRole < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :name, :deleted, :updated_by_id, :description
  belongs_to :iresource, :class_name => "IResource", :foreign_key => "i_resource_id"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by_id"
  validates :name, length: { in: 2..32 }
  validates :description, length: { in: 0..255 }
  #before_create :default
  before_validation(on: :create) do
    self.deleted = 0
    self.description = ""
    self.updated_by_id = User.current.id
  end

  def delete     
    self.deleted = true
    self.save
  end

  #def default
	# self.deleted = 0
  #end
end
