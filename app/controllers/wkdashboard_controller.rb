# ERPmine - ERP for service industry
# Copyright (C) 2011-2020  Adhi software pvt ltd
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class WkdashboardController < WkbaseController

	before_action :require_login
	accept_api_auth :getGraphs
	require 'yaml'

	include WkdashboardHelper 
	include WkcrmHelper
	include WktimeHelper
	include WkpayrollHelper

	def index
		if !showDashboard || !hasSettingPerm
			redirect_to set_module
		else
			set_filter_session
			setMembers
			retrieve_date_range
		end	
	end

	def graph(path="")
		path = params[:gPath] if params[:gPath].present?
		retrieve_date_range
		data = nil
		@group_id = session[controller_name].try(:[], :group_id)
		@project_id = session[controller_name].try(:[], :project_id)

		@from = params[:from].present? ? params[:from].to_date : @from
		@to = params[:to].present? ? params[:to].to_date : @to

		if @from.blank? && @to.blank?
			@to = User.current.today.end_of_month
			@from = User.current.today.end_of_month - 12.months + 1.days
		elsif @from.blank? && !@to.blank?
			@from = @to - 12.months + 1.days
		elsif @to.blank? && !@from.blank?
			@to = @from + 12.months - 1.days
		end
		@to = User.current.today if @to > User.current.today

		yml_data = YAML.load(ERB.new(File.read("#{Rails.root}/#{path}")).result).first   
		field_names = eval(yml_data[1]['code_str'])
		field_values = []
		title_names = []
		yml_data[1]['names_of_data'].each do |data_name|
			field_values << eval(data_name['data'])
			title_names << label_check(data_name['title'])
		end
			
			data = {:labels=> field_names['fields'], :graphpoints1=> field_values[0], :graphpoints2=> field_values[1], :graphtype=> yml_data[1]['chart_type'], :legentTitle1=> title_names[0], :legentTitle2=> title_names[1], :xTitle=> label_check(yml_data[1]['x_title']), :yTitle=> label_check(yml_data[1]['y_title']), :graphName=> yml_data[0]}
			
		if data
			params[:gPath].blank? ? data : render(json: data)
		else
			render_404
		end
	end
  
	def set_filter_session
		filters = [:project_id, :group_id, :period, :from, :to]
		super(filters)
	end

	def setMembers		
		@groups = Group.sorted.all
	end

	def getGraphs
		graphs = get_graphs_yaml_path().sort
		graphDetails = []
		graphs.each{ |path| graphDetails << graph(path) }
		render json: {graphs: graphDetails, unseen_count: @unseen_count}
	end
end