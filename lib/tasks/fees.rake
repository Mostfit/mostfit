require "rubygems"

# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :payments do
    desc "Fill fee ids in payments"
    task :fill_fees do
      ids = Payment.all(:type => :fees, :fee_id => nil, :comment => "card fee").map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=3 WHERE id in (#{ids.join(",")})")

      ids=Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee 3%").map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=1 WHERE id in (#{ids.join(",")})")      

      ids = (Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee 2.5%") + Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee")).map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=2 WHERE id in (#{ids.join(",")})")
    end
  end

  namespace :fees do
    desc "levy fees on objects"
    task :levy do
      Client.all(:fields => [:id]).each{|cid|
        c = Client.get(cid.id)
        next unless c
        c.levy_fees
        c.loans.each{|l|
          l.levy_fees
        }
      }
    end


    desc "pay all applicable fees"
    task :pay_all do
      ApplicableFee.all.each do |af|
        m = Kernel.const_get(af.applicable_type).get(af.applicable_id)
        rb = af.applicable_type == "Loan" ? m.client.center.manager : m.center.manager
        p = Payment.new(:received_on => af.applicable_on, :received_by => rb, :amount => af.amount, :type => :fees, :fee_id => af.fee_id,
                        :created_by_user_id => 1, :loan_id => m.is_a? (Loan) ? m.id : nil, :client_id => m.is_a? (Loan) ? m.client.id : m.id)
        if p.save
          puts "Paid #{p.amount} as #{af.fee.name}"
        else
          puts "failed to pay applicable fee #{af.id}"
        end
      end
    end


  end


end
