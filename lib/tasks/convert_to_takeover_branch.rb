require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :conversion do
    desc "Creation of Default Repayment Styles, Conversion of Loan Types to use Repayment Styles"
    task :convert_to_repayment_style do
      Mostfit::PaymentStyles.constants.each do |style|
        next if RepaymentStyle.all.aggregate(:style).include? style
        s = RepaymentStyle.new(:name => style.to_s, :style => style, :active => true)
        s.save
    end
  end
end
