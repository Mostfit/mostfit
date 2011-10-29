require "rubygems"
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
require "merb-core"

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :accounts do
    desc "Finds and reports issues with accounting"
    USAGE = "USAGE: rake mostfit:accounts:report_issues"
    task :report_issues do |t, args|
      begin
        # Find postings to non-existent/deleted accounts

        post_to_non_existent_accounts = []
        Posting.all.collect { |posting|
          post_to_non_existent_accounts.push(posting) unless Account.get(posting.account_id)
        }
        unless post_to_non_existent_accounts.empty?
          puts "Postings to non-existent accounts:\n"
          p post_to_non_existent_accounts
        end

        # Find branches that charts have been setup for, and collect accounts
        # for those charts
        branches_and_accounts = {}
        all_branches = Branch.all.collect{|br| br.id}
        all_branches.each { |branch|
          branches_and_accounts[branch] = Account.all(:branch_id => branch)
        }
        branches_and_accounts[0] = Account.all(:branch_id => 0)

        # For each branch, walk through the postings on each account, find the
        # other side of the posting, and ensure that it is an account on the
        # same chart

        journals_and_branches = {}
        branches_and_accounts.each do |branch_id, accounts|
          accounts.each do |account|
            other_side_postings = [];
            account.postings.each { |p|
              journal = p.journal if p.journal
              if journal
                other_side_postings.push(journal.postings.select{ |post| post.id != p.id })
              end
            }

            other_side_postings.flatten.each { |osp|
              journal = osp.journal
              if journal
                posting_branch_id = osp.account.branch_id if osp.account
                if posting_branch_id
                  journals_and_branches[journal] = posting_branch_id if posting_branch_id != branch_id
                end
              end
            }
          end
        end

        unless journals_and_branches.keys.empty?
          puts "Journals with postings to different branches:\n"
          p journals_and_branches
        end

        # Find accounts that do not have a branch_id, not even 0 (zero
        # corresponds to the 'Head Office')
        orphan_accounts = Account.all(:branch => nil)
        unless orphan_accounts.empty?
          puts "Orphan accounts:\n"
          p orphan_accounts
        end

      rescue => ex
        puts "An error has occurred: #{ex.message}"
        puts USAGE
      end
    end
  end
end
