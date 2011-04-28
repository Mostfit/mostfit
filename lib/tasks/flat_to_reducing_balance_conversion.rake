require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :conversion do
    desc "Conversion of Flat to Reducing Balance Loans"
    task :flat_to_reducing, :loan_id do |task, args|
      last_date = Date.new(2011, 03, 31)
      hash = {:loan_product_id => [2, 13]}
      f = File.open("tmp/flat_to_reducing.csv", "w")
      f.puts("\"Loan Id\",\"Amount\", \"Interest Rate\", \"status\", \"errors\"")


      if args[:loan_id]
        lid = args[:loan_id].to_i
        hash[:id] = lid
      else
        hash[:discriminator] = DefaultLoan
      end

      Loan.all(hash).each{|l|
        last_history = LoanHistory.first(:loan_id => l.id, :date.lte => last_date, :order => [:date.desc])
        next unless last_history
        next unless last_history.status == :outstanding
        l.discriminator = "EquatedWeekly"
        if l.loan_product_id == 13
          l.interest_rate = 31.504/100
        elsif l.loan_product_id == 2
          l.interest_rate = 29.2501/100
        end
        l.save!
        loan = Loan.get(l.id)
        errors = []
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
              errors << ["only one payment found on #{lh.date}"]
            elsif ps.length == 2
              if (pdue + idue) > 0
                div = ((ps[0].amount + ps[1].amount).to_i / (pdue + idue))
                if ps[0].amount + ps[1].amount - (pdue + idue) > 0.01 and (div - div.to_i) > 0.01
                  errors << ["Difference in figures on #{lh.date} of #{ps[0].amount + ps[1].amount - (pdue + idue)}"]
                end
              end
            elsif ps.length > 2
              errors << ["more than two payments found on #{lh.date}"]
            end
          end
        }
        Loan.get(l.id).update_history
        if errors.length > 0
          f.puts("#{l.id}, #{l.amount}, #{l.interest_rate}, errors, #{errors.join(';')}")
        else
          f.puts("#{l.id}, #{l.amount}, #{l.interest_rate}, success, #{errors.join(';')}")
        end
      }
      f.close
    end
  end
end
