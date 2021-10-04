# ERPmine - ERP for service industry
# Copyright (C) 2011-2021 Adhi software pvt ltd
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

module ReportTrialBalance
	include WkaccountingHelper
  include WkreportHelper

	def calcReportData(userId, groupId, projId, from, to)
		from = from.to_date
		to = to.to_date
		mainEntriesHash = Hash.new
		subEntriesHash = Hash.new
		creditDebitTotalHash = Hash.new
		ledgerArr = ['C', 'L', 'CL', 'SP', 'DI', 'DE', 'II', 'IE', 'SA', 'PA', 'FA', 'CA']
		ledgerArr.each do |type|
			mainEntriesHash[type] = getEachLedgerCDAmt(from, to, type)
			subEntriesHash[type] = getTBSubEntries(from, to, type)
			creditDebitTotalHash[type] = getCreditDebitTotal(mainEntriesHash[type], subEntriesHash[type])
		end
		mainEntriesHash['PL'] = getSubEntries(from, to, 'PL')
		defLedgerEnries = getEachLedgerSumAmt(from, to, ['SY'])
		profitLossHash = mainEntriesHash['PL']['Opening Balance'].to_f + defLedgerEnries.values[0].to_f
		data = {mainEntriesHash: mainEntriesHash, subEntriesHash: subEntriesHash, creditDebitTotalHash: creditDebitTotalHash, ledgerArr: ledgerArr, ledgerType: getLedgerTypeHash, to: to.to_formatted_s(:long),
			 profitLossHash: profitLossHash}
		data
	end

	def getExportData(user_id, group_id, projId, from, to)
    rptData = calcReportData(user_id, group_id, projId, from, to)
    headers = {}
    data = []
		debitTotal = 0
		creditTotal = 0
		headers ={ledger_group: l(:label_particulars), ledger_type: '', ledger: '', debit: l(:label_debit), credit: l(:label_credit)}
		rptData[:ledgerArr].each do |ledger|
			debitTotal += rptData[:creditDebitTotalHash][ledger]['debit'] unless rptData[:creditDebitTotalHash][ledger]['debit'].blank?
			creditTotal += rptData[:creditDebitTotalHash][ledger]['credit'] unless rptData[:creditDebitTotalHash][ledger]['credit'].blank?
			unless (rptData[:creditDebitTotalHash][ledger]['debit'] == 0) && (rptData[:creditDebitTotalHash][ledger]['credit'] == 0)
				data << {ledger_group: getSectionHeader(ledger), ledger_type: '', ledger: '', debit: rptData[:creditDebitTotalHash][ledger]['debit'].round(2), credit: rptData[:creditDebitTotalHash][ledger]['credit'].round(2)}
				unless rptData[:subEntriesHash][ledger].blank?
					rptData[:subEntriesHash][ledger].each do |subledger, subEntry|
						unless subEntry.blank? || subEntry.nil?
							data << {ledger_group: '', ledger_type: getSectionHeader(subledger), ledger: '', debit: '', credit: ''}
							renderLedgerVal(data, subEntry, 'subledger')
						end
					end
				end
				renderLedgerVal(data, rptData[:mainEntriesHash][ledger], 'mainledger')
			end
		end
		creditTotal += rptData[:profitLossHash].round(2) unless rptData[:profitLossHash].blank?
		data << {ledger_group: l(:report_profit_loss), ledger_type: '', ledger: '', debit: '', credit: rptData[:profitLossHash]}
		data << {ledger_group: '', ledger_type: '', ledger: l(:label_total), debit: debitTotal, credit: creditTotal}
		return {data: data, headers: headers}
	end

	def renderLedgerVal(data, entries, type)
		entries.each do |ledgername, entry|
			if !entry.blank? && (!entry["d"].nil? || !entry["c"].nil?)
				data << {ledger_group: '', ledger_type: ledgername, ledger: '', debit: entry["d"], credit: entry["c"]} if type == 'mainledger'
				data << {ledger_group: '', ledger_type: '', ledger: ledgername, debit: entry["d"], credit: entry["c"]} if type == 'subledger'
			end
		end
		data
	end
end