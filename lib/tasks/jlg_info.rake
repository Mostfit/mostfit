# require "rubygems"

# include Csv

# # Add the local gems dir if found within the app root; any dependencies loaded
# # hereafter will try to load from the local gems before loading system gems.
# if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
#   $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
# end

# require "merb-core"

# # this loads all plugins required in your init file so don't add them
# # here again, Merb will do it for you
# Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

# namespace :mostfit do

#   namespace :report do

#     desc "Support Request #1360: particulars of JLGs"
#     task :jlg_info, :date do |t, args|
#       if args[:date].nil?
#         puts
#         puts "USAGE: rake mostfit:report:jlg_info[<date>]"
#         puts
#         puts "NOTE: The date has to be supplied."
#         puts "      The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
#         puts
#         puts "EXAMPLE: rake mostfit:report:event_logs['06-07-2011']"
#       else
#         date = Date.strptime(args[:date], "%d-%m-%Y")
#         datetime = DateTime.new(date.year, date.month, date.day, 23, 59, 59)
#         data = []
#         data << [
#                  "ID of JLG", 
#                  "Name of JLG", 
#                  "Address of JLG", 
#                  "Name of Centre", 
#                  "Name of branch", 
#                  "Date of formation", 
#                  "No. of Members", 
#                  "Total loan sanctioned", 
#                  "Total loan disbursed", 
#                  "Loans Outstanding"
#                 ]
#         ClientGroup.all('center.creation_date.lte' => date).each do |jlg| 
#           loans = nil
#           loans = jlg.clients.loans(:applied_on.lte => date) unless jlg.clients.empty?
#           loan_ids = jlg.clients.loans.map{|loan| loan.id}
#           data << [
#                    jlg.id, 
#                    jlg.name, 
#                    jlg.center.address.gsub("/n", " ").gsub("/r", " "), 
#                    jlg.center.name, 
#                    jlg.center.branch.name, 
#                    jlg.center.creation_date, 
#                    jlg.clients(:date_joined.lte => date).count, 
#                    (jlg.clients.empty? ? nil : jlg.clients.loans(:applied_on.lte => date, :approved_on.not => nil).sum(:amount)), 
#                    (jlg.clients.empty? ? nil : jlg.clients.loans(:applied_on.lte => date, :disbursal_date.not => nil).sum(:amount)),
#                    LoanHistory.sum_outstanding_for_loans(date, loan_ids)[0].actual_outstanding_total.to_f
#                   ]
#         end
#         folder = File.join(Merb.root, "doc", "csv", "reports")      
#         FileUtils.mkdir_p(folder)
#         filename = File.join(folder, "icash_jlg_as_on_#{args[:date]}.csv")
#         file = get_csv(data, filename)
#       end
#     end

#   end

# end
