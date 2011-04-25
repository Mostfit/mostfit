require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :conversion do
    desc "Conversion of Flat to Reducing Balance Loans"
    task :flat_to_reducing, :loan_id do |task, args|
      hash = {:loan_product_id => 2}
      f = File.open("tmp/flat_to_reducing.csv", "w")
      f.puts("\"Loan Id\",\"Amount\", \"Interest Rate\", \"status\", \"errors\"")


      if args[:loan_id]
        lid = args[:loan_id].to_i
        hash[:id] = lid
      else
        hash[:discriminator] = DefaultLoan
      end

      Loan.all(hash).each{|l|
        next unless Loan.get(l.id).status == :outstanding
        l.discriminator = "EquatedWeekly"
        l.interest_rate = 29.2501/100
        l.save!
        loan = Loan.get(l.id)
        error = []
        loan.loan_history.each{|lh|
          ps = Payment.all(:type => [:principal, :interest], :received_on => lh.date, :loan_id => lh.loan_id)
          pdue = loan.scheduled_principal_due_on(lh.date)
          idue = loan.scheduled_interest_due_on(lh.date)
          if ps.length==2 and loan.payment_schedule[lh.date] and pdue + idue > 0 and (1..10).to_a.include?((ps[0].amount + ps[1].amount).to_i / (pdue + idue).to_i)
            installments_paid = (ps[0].amount + ps[1].amount).to_i / (pdue + idue).to_i
            ps[0].amount = ps[1].amount = 0
            date = lh.date
            installments_paid.times{
              ps[0].amount += loan.send("scheduled_#{ps[0].type}_due_on", date)
              ps[1].amount += loan.send("scheduled_#{ps[1].type}_due_on", date)
              date = loan.shift_date_by_installments(date, 1)
            }
            ps[0].save!
            ps[1].save!            
          else
            if ps.length == 1
              error << ["only one payment found on #{lh.date}"]
            elsif ps.length == 2
              error << ["Difference in figures on #{lh.date} of #{ps[0].amount + ps[1].amount - (pdue + idue)}"] if ps[0].amount + ps[1].amount - (pdue + idue) > 0.01
            elsif ps.length > 2
              error << ["more than two payments found on #{lh.date}"]
            end
          end
        }
        Loan.get(l.id).update_history
        f.puts("#{l.id}, #{l.amount}, #{l.interest_rate}, success, \"#{errors.join(';')}\"")
      }
      f.close
    end
  end
end
