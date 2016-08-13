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


class IrolesController < ApplicationController

  def show_role_description
    if params[:role_id].present?
      @irole = IRole.find(params[:role_id])
      iresource = @irole.iresource
      if IResource.available_for_user(iresource[:id], User.current.id)
        @resource_name = iresource[:name]
        respond_to do |format|
          format.js { render :template => 'iroles/show_role_description' }
        end
      else
        head :forbidden
      end
    else
        head :forbidden
    end
  end


  def show_role
    if ITicket.check_security_officer(User.current) && params[:role_id].present?
      irole = IRole.where(:id => params[:role_id]).select([:name,:description]).first
      resource_name = IRole.find(params[:role_id]).iresource[:name]
      respond_to do |format|
        format.json { render :json => { :irole => irole, :resource_name => resource_name} }
      end
    else
        head :forbidden
    end
  end


  def add_role
    if ITicket.check_security_officer(User.current) && params[:res_id].present? && params[:name].present? 
	    iresource = IResource.where(:id => params[:res_id]).first
	    irole = iresource.iroles.new(:name => params[:name], :updated_by_id => User.current.id, :description => params[:description])
	    if irole.save
	      irls = iresource.iroles.active.select([:id,:name])
	      respond_to do |format|
		      format.json { render :json => irls }
	      end
	    else
	      head :forbidden
	    end
    else
      head :forbidden
    end
  end

  def edit_role
    if ITicket.check_security_officer(User.current) && params[:role_id].present? && params[:name].present? 
      irole = IRole.active.find(params[:role_id])
      irole.update_attributes(:name => params[:name], :description => params[:description], :updated_by_id => User.current.id)
      irls = irole.iresource.iroles.active.select([:id, :name])
      respond_to do |format|
        format.json { render :json => irls }
      end
    else
      head :forbidden
    end
  end

  def remove_role
    if ITicket.check_security_officer(User.current) && params[:role_id].present?
	    irole = IRole.find(params[:role_id])
      irole.updated_by_id = User.current.id
      iresource = irole.iresource
	    if irole.delete
	     irls = iresource.iroles.active.select([:id, :name])
	     respond_to do |format|
	       format.json { render :json => irls }
	     end
	    else
	      head :forbidden
	    end
    else
      head :forbidden
    end
  end


end
