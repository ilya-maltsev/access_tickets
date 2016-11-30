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

class IentitiesController < ApplicationController

  def ientity_show_list
    if User.current.anonymous? 
      head :forbidden
    else 
      if params[:res_id].present?
        iresource = IResource.where(:id => params[:res_id]).first
        if iresource.has_entities && IResource.available_for_user(params[:res_id], User.current.id)
          if iresource.has_ip
            ies = iresource.ientities.active.select(['i_entities.id',:name, :ipv4])
          else
            ies = iresource.ientities.active.select(['i_entities.id',:name])
          end
        else
          ies = []
        end
        respond_to do |format|
          format.json { render :json => { :ientities => ies, :has_ip => iresource.has_ip, :has_entities => iresource.has_entities } }
        end
      else
        head :forbidden
      end
    end
  end

  def add_entity
    if ( ( ITicket.check_security_officer(User.current) || IResgranter.is_granter_for_resource(User.current.id,params[:res_id]) || IResowner.is_owner_for_resource(User.current.id,params[:res_id]) ) && params[:name].present?  )
      iresource = IResource.where(:id => params[:res_id]).first
      if iresource.has_entities
        ientity = IEntity.new(:name => params[:name], :description => params[:description], :updated_by_id => User.current.id)
        if params[:ipv4].present? && iresource.has_ip
          ientity.ipv4 = params[:ipv4]
        else
          ientity.ipv4 = '127.0.0.1'
        end
        ientity.updated_by_id = User.current.id
        ientity.save
        iresentity = iresource.iresentities.new(:i_entity_id => ientity.id)
        iresentity.save
        ies = iresource.ientities.active.select(['i_entities.id',:ipv4,:name,:description])
        respond_to do |format|
          format.json { render :json => { :status => 1, :ientities => ies } }
        end
      else
          head :forbidden
      end
    else
        head :forbidden
    end
  end

  def save_entity
    if ( ( ITicket.check_security_officer(User.current) || IResgranter.is_granter_for_resource(User.current.id,params[:res_id]) || IResowner.is_owner_for_resource(User.current.id,params[:res_id])) && params[:ie_id].present? )
      iresource = IResource.where(:id => params[:res_id]).first
      if params[:ie_id].to_i.in?(iresource.ientities.map(&:id))
        ie = IEntity.where(:id => params[:ie_id]).first
        if ( ie.iresource.has_ip && params[:ipv4].present? )
          ie.update_attributes(:ipv4 => params[:ipv4])
        end
        if params[:name].present?
          ie.update_attributes(:name => params[:name])
        end
        if params[:description].present?
          ie.update_attributes(:description => params[:description])
        end
        ie.update_attributes(:updated_by_id => User.current.id)
        ies = ie.iresource.ientities.active.select(['i_entities.id',:ipv4,:name,:description])
        respond_to do |format|
          format.json { render :json => { :status => 1, :ientities => ies } }
        end
      else
        head :forbidden
      end

    else
        head :forbidden
    end
  end

  def remove_entity
    if ( ( ITicket.check_security_officer(User.current) || IResgranter.is_granter_for_resource(User.current.id,params[:res_id]) || IResowner.is_owner_for_resource(User.current.id,params[:res_id])) && params[:ie_id].present? )
      iresource = IResource.where(:id => params[:res_id]).first
      if params[:ie_id].to_i.in?(iresource.ientities.map(&:id))
        ie = IEntity.where(:id => params[:ie_id]).first
        ie.update_attributes(:updated_by_id => User.current.id)
        ie.delete
        ies = iresource.ientities.active.select(['i_entities.id',:ipv4,:name,:description])
        respond_to do |format|
          format.json { render :json => { :status => 1, :ientities => ies } }
        end
      else
        head :forbidden
      end
    else
        head :forbidden
    end
  end


end
