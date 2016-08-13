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

class IresourcesController < ApplicationController

  def set_groups_availability
    if ( ITicket.check_security_officer(User.current) && params[:iresugroups].present? && params[:resource_id].present? )
      IResugroup.where('i_resource_id = ? and group_id not in (?)', params[:resource_id], params[:iresugroups]).destroy_all
      iresource = IResource.find(params[:resource_id])
      iresugroups = []
      params[:iresugroups].each do |i|
        iresugroups.push(i.to_i)
      end
      new_iresugroups =  iresugroups - iresource.iresugroups.map(&:group_id).uniq
      if new_iresugroups.length > 0
        new_iresugroups.each do |i|
          iresource.iresugroups.create(:group_id => i)
        end
      end
      iresugroups = iresource.iresugroups.map(&:group_id).uniq
      groups = []
      Group.where(:id => IGrouplider.group_ids()).each do |obj|
        group = {}
        group[:id] = obj[:id]
        group[:name] = obj.lastname
        groups.push(group)
      end
      respond_to do |format|
        format.json { render :json => {:status => 1, :resugroups => iresugroups, :groups => groups } }
      end
    else
      head :forbidden
    end
  end


  def groups_availability
    if ITicket.check_security_officer(User.current) && params[:resource_id].present?
      groups = []
      Group.where(:id => IGrouplider.group_ids()).each do |obj|
        group = {}
        group[:id] = obj[:id]
        group[:name] = obj.lastname
        groups.push(group)
      end
      resugroups = IResource.find(params[:resource_id]).iresugroups.map(&:group_id).uniq
      respond_to do |format|
        format.json { render :json => {:status => 1, :resugroups => resugroups, :groups => groups } }
      end
    else
      redirect_to(:back)
    end
  end


	def show_resource
		if params[:resource_id].present? #&& 
      if IResource.available_for_user(params[:resource_id], User.current.id)
  			@resource_editable = false
  			@entities_editable = false
  			@users = User.active.where('id != 1')#.all
  			@resource = IResource.find(params[:resource_id])
  			if @resource.has_entities
  				@ies = @resource.ientities.active.select(['i_entities.id',:ipv4,:name, :description]).to_json
  			end
  			@box_label = l(:at_resource_details)
  	    respond_to do |format|
  	      format.js { render :template => 'isettings/edit_resource_details' }
  	    end
      else
        redirect_to(:back)
      end
		else
			redirect_to(:back)
		end
	end

	def edit_resource
		if params[:resource_id].present? && ( ITicket.check_security_officer(User.current) || IResgranter.is_granter_for_resource(User.current.id,params[:resource_id]) || IResowner.is_owner_for_resource(User.current.id,params[:resource_id]) )
			@entities_editable = true
			if ITicket.check_security_officer(User.current)
				@resource_editable = true
        @groups = Group.where(:id =>IGrouplider.all.map(&:group_id).uniq)
			else
				@resource_editable = false
			end
			@users = User.active.where('id != 1')#.all
			@resource = IResource.find(params[:resource_id])
			if @resource.has_entities
				@ies = @resource.ientities.active.select(['i_entities.id',:ipv4,:name, :description]).to_json
			end
			@box_label = l(:at_resource_details)
	    respond_to do |format|
	      format.js { render :template => 'isettings/edit_resource_details' }
	    end
		else
			redirect_to(:back)
		end
	end

  def resources_list
    respond_to do |format|
      format.html {
        render :template => 'isettings/resources_list'
      }
    end
  end

  def show_resources_list
    if params[:short].present?
      resources_list = IResource.available_audit_resources(User.current.id)
    else
      resources_list = IResource.resources_list(User.current.id)
    end
    respond_to do |format|
      format.json { render :json => {:status => 1, :iresources => resources_list } }
    end
  end


  def set_has_ip
    if ( ITicket.check_security_officer(User.current) && params[:has_ip].present? && params[:res_id].present? )
      iresource = IResource.active.where(:id => params[:res_id]).first
      iresource[:has_ip] = params[:has_ip]
      if iresource.save
        respond_to do |format|
	        format.json { render :json => {:status => 1,:has_ip => iresource[:has_ip] ? 1 : 0 } }
	    	end
      else
        respond_to do |format|
	        format.json { render :json => {:status => 0 } }
	    	end
      end
    else
      head :forbidden
    end
  end

  def set_has_entities
    if ( ITicket.check_security_officer(User.current) && params[:has_entities].present? && params[:res_id].present? )
      iresource = IResource.active.where(:id => params[:res_id]).first
      iresource[:has_entities] = params[:has_entities]
      if iresource.save
        respond_to do |format|
	        format.json { render :json => {:status => 1, :has_entities => iresource[:has_entities] ? 1 : 0, :ientities => iresource.ientities.active.select(['i_entities.id',:ipv4,:name,:description]) } }
	    	end
      else
        respond_to do |format|
        	format.json { render :json => {:status => 0 } }
    		end
      end
    else
			head :forbidden
    end
  end


  def set_owners
		if ITicket.check_security_officer(User.current) && params[:iresowners].present? && params[:res_id].present? 
			IResowner.where('i_resource_id = ? and user_id not in (?)', params[:res_id], params[:iresowners]).destroy_all
			iresource = IResource.active.where(:id => params[:res_id]).first
			iresowners = []
			params[:iresowners].each do |i|
				iresowners.push(i.to_i)
			end
			iresowners = iresowners | [1]
			new_iresowners =  iresowners - iresource.iresowners.map(&:user_id).uniq
			if new_iresowners.length > 0
				new_iresowners.each do |i|
					iresource.iresowners.create(:user_id => i)
				end
			end
			iresowners = iresource.iresowners.map(&:user_id).uniq - [1]
			users = [] 
			User.active.each do |obj|
				user = {}
				user[:id] = obj[:id]
				user[:name] = obj.name
				users.push(user)
			end
			respond_to do |format|
        format.json { render :json => {:status => 1, :iresowners => iresowners, :users => users } }
    	end
		else
			head :forbidden
		end
  end

  def set_granters
		if ITicket.check_security_officer(User.current) && params[:iresgranters].present? && params[:res_id].present? 
			IResgranter.where('i_resource_id = ? and user_id not in (?)', params[:res_id], params[:iresgranters]).destroy_all
			iresource = IResource.active.where(:id => params[:res_id]).first
			iresgranters = []
			params[:iresgranters].each do |i|
				iresgranters.push(i.to_i)
			end
			iresgranters = iresgranters | [1]
			new_iresgranters =  iresgranters - iresource.iresgranters.map(&:user_id).uniq
			if new_iresgranters.length > 0
				new_iresgranters.each do |i|
					iresource.iresgranters.create(:user_id => i)
				end
			end
			iresgranters = iresource.iresgranters.map(&:user_id).uniq - [1]
			users = [] 
			User.active.each do |obj|
				user = {}
				user[:id] = obj[:id]
				user[:name] = obj.name
				users.push(user)
			end
			respond_to do |format|
        format.json { render :json => {:status => 1, :iresgranters => iresgranters, :users => users } }
    	end
		else
			head :forbidden
		end
  end

  def show_details
    if params[:id].present? && IResource.available_for_user(params[:id], User.current.id)
  	  iresource = IResource.active.where(:id => params[:id]).first
      if iresource
  			irls = iresource.iroles.active.select([:id,:name])
  			if iresource.iresowners.count > 0
  				iresowners = iresource.iresowners.map(&:user_id)
  			else
  				iresowners = 0
  			end 
  			if iresource.iresgranters.count > 0
  				iresgranters = iresource.iresgranters.map(&:user_id)
  			else
  				iresgranters = 0
  			end 
  			users = [] 
  			User.active.each do |obj|
  				user = {}
  				user[:id] = obj[:id]
  				user[:name] = obj.name
  				users.push(user)
  			end

  			ies = []
  			respond_to do |format|
  				format.json { render :json => {:i_roles => irls, :users => users, :iresowners => iresowners, :iresgranters => iresgranters, :has_ip => iresource.has_ip, :ientities => ies} }
  			end
      else
        render :inline => "{ data: false }"
      end
    else
      head :forbidden
    end
  end


  def add_resource
		if ITicket.check_security_officer(User.current)
	    iresource = IResource.new(:name => params[:name] )
	    iresource[:updated_by_id] = User.current.id
	    if iresource.save
		    resources_list = IResource.resources_list(User.current.id)
			  respond_to do |format|
		      format.json { render :json => {:status => 1, :iresources => resources_list } }
		    end
	    else
	      render :inline => "{ status: false }"
	    end
		else
			head :forbidden
		end
  end

  def save_resource
  	if params[:resource_id].present? && params[:name].present?
			if ITicket.check_security_officer(User.current)
		    iresource = IResource.active.find(params[:resource_id])
		    iresource[:name] = params[:name]
		    if params[:description].present?
		    	iresource[:description] = params[:description]
		    end
        iresource[:updated_by_id] = User.current.id
		    if iresource.save
					iresources = IResource.resources_list(User.current.id)
					respond_to do |format|
					  format.json { render :json => {:status => 1, :iresources => iresources } }
					end 
		    else
		      redirect_to(:back)
		    end
			else
				head :forbidden
			end
		else
			head :forbidden
		end
  end

  def remove_resource
  	if params[:resource_id].present?
			if ITicket.check_security_officer(User.current)
			    iresource = IResource.active.find(params[:resource_id])
			    if iresource.delete
			   	   iresource.iroles.each do |i|
			   	     i.deleted = true
			   	     i.save
			   	   end
			       iresources = IResource.resources_list(User.current.id)
			       respond_to do |format|
			         format.json { render :json => {:status => 1, :iresources => iresources } }
			       end 
			    else
			      redirect_to(:back)
			    end
			else
				head :forbidden
			end
		else
			head :forbidden
		end
  end

end
