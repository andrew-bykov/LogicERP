# ERPmine - ERP for service industry
# Copyright (C) 2011-2016  Adhi software pvt ltd
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

class WkAccount < ActiveRecord::Base
  unloadable
  belongs_to :address, :class_name => 'WkAddress'
  has_many :wk_account_projects, foreign_key: "account_id", class_name: "WkAccountProject", :dependent => :destroy
  has_many :invoices, foreign_key: "account_id", class_name: "WkInvoice"
  has_many :invoice_items, through: :invoices
  has_many :projects, through: :wk_account_projects
  has_many :contracts, foreign_key: "account_id", class_name: "WkContract", :dependent => :destroy
  has_many :opportunities, as: :parent, class_name: "WkOpportunity", :dependent => :destroy
  has_many :activities, as: :parent, class_name: 'WkCrmActivity'
  has_many :contacts, as: :parent, class_name: 'WkCrmContact'
  validates_presence_of :name
  validate :hasAnyValues
  
  def hasAnyValues
	name.blank? && address_id.blank? && activity_id.blank? && industry.blank? && annual_revenue.blank? && assigned_user_id.blank? && id.blank?
  end
  
  # Returns account's contracts for the given project
  # or nil if the account do not have contract
  def contract(project)
		contract = contracts.where(:project_id => project.id).first
		contract = contracts[0] if contract.blank?
		contract
  end
  
end
