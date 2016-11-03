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


class IEntity < ActiveRecord::Base
  @ip_regex = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/

  #validates :ipv4, 
  #          :format => { :with => @ip_regex } 
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :id, :name, :description, :ipv4, :deleted, :updated_by_id
  #belongs_to :iresource, :class_name => "IResource", :foreign_key => "i_resource_id"
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by_id"
  #has_many :itickets

  has_one :iresentity, :class_name => "IResentity"
  has_one :iresource, through: :iresentity, :class_name => "IResource"

  has_many :itickentities, :class_name => "ITickentity"
  has_many :itickets, through: :itickentities, :class_name => "ITicket"

  validates :name, length: { in: 2..64 }
  validates :description, length: { in: 0..128 }
  validates :ipv4, length: { in: 0..15 }
  #validates :type, inclusion: { in: ["Object", "Group"], message: "%{value} is not a valid type" }],
  #before_create :default
  before_save :set_updater
  before_validation(on: :create) do
    self.deleted = 0
    #self.updated_by_id = User.current.id
  end

def self.import(i_resource_id, file, user_id)
    iresource = IResource.find(i_resource_id)

    ientities = iresource.ientities
    ientities_ids = iresource.ientities.active.map(&:id)
    bad_rows = []

    csv = CSV.new(file,:col_sep => ';')
    array = csv.to_a

    array[1..array.size].each do |row|
      if iresource.has_ip
        if IEntity.where(:id => ientities_ids, :name => row[0]).empty? && IEntity.where(:id => ientities_ids, :ipv4 => row[1]).empty?  # !row[0].nil? && !row[1].nil? && 
          ientity = IEntity.new(:name => row[0], :ipv4 => row[1],:description => row[2], :updated_by_id => user_id)
          ientity.save
          iresentity = iresource.iresentities.new(:i_entity_id => ientity.id)
          iresentity.save
        else
          bad_rows.push(row)
        end
      else
        if  IEntity.where(:id => ientities_ids, :name => row[0]).empty?  # !row[0].nil? &&
          ientity = IEntity.new(:name => row[0], :ipv4 => '127.0.0.1',:description => row[1], :updated_by_id => user_id)
          ientity.save
          iresentity = iresource.iresentities.new(:i_entity_id => ientity.id)
          iresentity.save
        else
          bad_rows.push(row)
        end
      end
    end

    bad_rows
  end 

def self.to_csv(array)

    #attributes = %w{name ipv4 description}

    CSV.generate(:col_sep => ';') do |csv|
      #csv << attributes

      array.each do |entity|
        csv << entity
      end
    end
  end


  def set_updater
    #self.updated_by_id = User.current.login
    if self.ipv4.nil?
      self.ipv4 = "127.0.0.1"
    end
  end

  def delete     
    self.deleted = true
    self.save
  end

  def default
    self.deleted = 0
  end
end
