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

class IsettingsController < ApplicationController


  def reset_config
    if User.current.admin?
      ISetting.active.update_all(:deleted =>  1)
      redirect_to Redmine::Utils::relative_url_root + "/settings/plugin/access_tickets", :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end

  def set_base_config
    if User.current.admin? && params[:parameters].present? && !ISetting.check_config()
      rawData = JSON.parse(params[:parameters])
      errors = {}
      inputData = []
      rawData.each do |object|
        if object["key"].in?(ISetting.values_map()) || object["key"].in?(ISetting.bs_values_map())
          inputData.push(object)
        end
      end
      if inputData.count == ISetting.bs_values_map().count
        ISetting.set_basic_settings(inputData)
      end
      redirect_to Redmine::Utils::relative_url_root + "/settings/plugin/access_tickets", :status => 302 #root_url
    else
      render_error({:message => :notice_file_not_found, :status => 404})
    end
  end


  def show_group_details
    if ITicket.check_security_officer(User.current) && params[:group_id].present?
      #users = User.active.select([:id,:login])
      users = [] 
      User.active.each do |obj|
        user = {}
        user[:id] = obj[:id]
        user[:name] = obj.name
        users.push(user)
      end
      group_liders = IGrouplider.where(:group_id => params[:group_id]).map(&:user_id)
      #templates = ITicktemplate.select([:id,:name])
      #group_templates = IGrouptemplate.where(:group_id => params[:group_id]).map(&:i_ticktemplate_id).uniq
      respond_to do |format|
        format.json { render :json => {:users => users, :group_liders => group_liders }}#, :templates => templates, :group_templates => group_templates } }
      end
    else
      head :forbidden
    end
  end

  def set_group_liders
    if ( ITicket.check_security_officer(User.current) && params[:group_id].present? )

      IGrouplider.where(:group_id => params[:group_id]).destroy_all

      if params[:group_liders].length > 0
        params[:group_liders].each do |i|
          IGrouplider.create(:user_id => i, :group_id => params[:group_id])
        end
        render :inline => "{ status: ok }"
      else
        render :inline => "{ status: false }"
      end
    else
      head :forbidden
    end
  end

  def set_settings_value
    if ITicket.check_security_officer(User.current)
      params.each do |key,value|
        if key.in?(ISetting.values_map()) 
          IsettingController.save_settings_value(key,value)
        end
      end
    else
      head :forbidden
    end
  end

  def self.save_settings_value(key,value)
    if ISetting.active.where(:param => key).nil?
      new_settings = ISetting.new
      new_settings[:key] = key
      new_settings[:value] = ""
      new_settings.save
    end
    settings = ISetting.active.where(:param => key).first
    settings[:value] = value
    if settings.save
      respond_to do |format|
        format.json { render :json => {:status => "ok"} }
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "false"} }
      end
    end
  end

end
