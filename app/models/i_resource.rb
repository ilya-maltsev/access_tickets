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

class IResource < ActiveRecord::Base
  scope :deleted, -> { where(deleted: true) }
  scope :active, -> { where(deleted: false) }

  attr_accessible :name, :has_ip, :has_entities, :deleted, :description, :updated_by_id
  #belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  has_many :iresowners, :class_name => "IResowner"
  has_many :owners, through: :iresowners

  has_many :iresgranters, :class_name => "IResgranter"
  has_many :granters, through: :iresgranters

  has_many :iresentities, :class_name => "IResentity"
  has_many :ientities, through: :iresentities, :class_name => "IEntity"

  has_many :iresugroups, :class_name => "IResugroup"
  has_many :groups, through: :iresugroups


  has_many :iroles, :class_name => "IRole", dependent: :destroy

  has_many :igroupentities, :class_name => "IGroupEntities"

  has_many :itickets, :class_name => "ITicket"
  validates :name, length: { in: 2..64 }
  validates :description, length: { in: 0..256 }
  #before_create :default
  after_create :set_default_params
  before_validation(on: :create) do
    self.deleted = 0
    self.has_ip = 0
    self.has_entities = 0
    self.description = ""
    self.updated_by_id = User.current.id
  end

  def delete
    self.deleted = true
    self.save
  end



  #def default
  #  self.deleted = 0
  #  self.has_ip = 0
  #  self.has_entities = 0
  #end

  def set_default_params
    self.iresowners.create(:user_id => User.current.id)
    self.iresgranters.create(:user_id => User.current.id)
  end


  def self.available_audit_resources(user_id)
    if ITicket.check_security_officer(User.find(user_id)) 
      IResource.active.all
    elsif IResgranter.is_resgranter(user_id) || IResowner.is_resowner(user_id)
      IResource.active.where(:id => (IResgranter.where(:user_id => user_id).map(&:i_resource_id).uniq | IResowner.where(:user_id => user_id).map(&:i_resource_id).uniq) ) 
    else
      []
    end
  end

  def self.available_resources(user_id)
    available_resources = []
    if ITicket.check_security_officer(User.find(user_id)) 
      available_resources = IResource.active.all
    else
      groups = User.find(user_id).groups.map(&:id).uniq
      a_res_ids = IResugroup.where(:group_id => groups).map(&:i_resource_id).uniq
      available_resources = IResource.active.where(:id => a_res_ids)   
      if IResgranter.is_resgranter(user_id) || IResowner.is_resowner(user_id)
        available_resources = available_resources | IResource.active.where(:id => (IResgranter.where(:user_id => user_id).map(&:i_resource_id).uniq | IResowner.where(:user_id => user_id).map(&:i_resource_id).uniq) )
      end
    end
  available_resources

  end


  def self.available_for_user(resource_id, user_id)
    ITicket.check_security_officer(User.find(user_id)) || !IResugroup.where(:group_id => User.find(user_id).groups.map(&:id).uniq | IGrouplider.where(:user_id => user_id).map(&:group_id).uniq, :i_resource_id => resource_id).empty? || IResgranter.is_granter_for_resource(user_id,resource_id) || IResowner.is_owner_for_resource(user_id,resource_id)
  end

  def self.resources_list(user_id)
    resources_list = []
    granted_resources = IResgranter.where(:user_id => user_id).map(&:i_resource_id)
    owned_resources = IResowner.where(:user_id => user_id).map(&:i_resource_id)
    resources = IResource.active.all
    resources.each do |resource|
      if IResource.available_for_user(resource[:id], user_id)
        object = {}
        roles = []
        object[:id] = resource[:id]
        object[:iroles] = []
        object[:iresowners] = []
        object[:iresgranters] = []
        if IResowner.is_owner_for_resource(user_id,object[:id]) || IResgranter.is_granter_for_resource(user_id,object[:id]) || ITicket.check_security_officer(User.find(user_id))
          object[:editable] = 1
        else
          object[:editable] = 0
        end
        if ITicket.check_security_officer(User.find(user_id))
          object[:removable] = 1
        else
          object[:removable] = 0
        end
        object[:name] = resource[:name]
        object[:has_ip] = resource[:has_ip]
        object[:has_entities] = resource[:has_entities]
        if resource.iroles.active.count > 0
          object[:roles] = resource.iroles.active.select([:id,:name])
          object[:roles].each do |irole|
            object[:iroles].push(IRole.find(irole.id).name)
          end
        else
          object[:roles] = []
        end     
        object[:roles] = object[:roles].to_a.sort_by! {|r| r[:name]} 
        if resource.iresowners.count > 0
          object[:resowners] = resource.iresowners.map(&:user_id) - [1]
          object[:resowners].each do |resowner|
            owner = {}
            owner[:id] = resowner
            owner[:name] = User.find(resowner).name
            object[:iresowners].push(owner)
          end
        else
          object[:resowners] = []
        end 
        object[:iresowners] = object[:iresowners].to_a.sort_by! {|r| r[:name]} 
        if resource.iresgranters.count > 0
          object[:resgranters] = resource.iresgranters.map(&:user_id) - [1]
          object[:resgranters].each do |resgranter|
            granter = {}
            granter[:id] = resgranter
            granter[:name] = User.find(resgranter).name
            object[:iresgranters].push(granter)
          end
        else
          object[:resgranters] = []
        end 
        object[:iresgranters] = object[:iresgranters].to_a.sort_by! {|r| r[:name]} 
        object[:i_entities] = []
        if resource[:has_entities] == true
          if resource.ientities.active.count > 0
            resource.ientities.active.each do |ientity|  
              entity = {}
              entity[:id] = ientity.id
              entity[:caption] = ientity.name
              if resource[:has_ip]
                ip = ientity.ipv4
                entity[:caption] = entity[:caption] + " [" + ip + "];"
              end
              object[:i_entities].push(entity)
            end
          end 
        else
          object[:i_entities] = []
        end
        resources_list.push(object)
      end
    end
    resources_list
  end


end
