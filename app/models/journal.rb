require 'builder'
class Journal
  include DataMapper::Resource
 
  property :id,             Serial
  property :comment,        String
  property :transaction_id, String, :index => true  
  property :date,           DateTime, :index => true  
  property :created_at,     DateTime, :index => true  
  property :batch_id,       Integer, :nullable => true
  belongs_to :batch
  belongs_to :journal_type
  has n, :postings
 
  
  def validity_check
    debit_account_posting, credit_account_posting = self.postings.sort_by{|x| x.amount}
    return false if credit_account_posting.account_id == debit_account_posting.account_id    
    return true
  end


  def self.create_transaction(journal_params, debit_account, credit_account)
    status = false
    journal = nil
    transaction do |t|
      journal = Journal.create(:comment => journal_params[:comment], :date =>journal_params[:date]||Time.now,
                               :transaction_id => journal_params[:transaction_id],
                               :journal_type_id => journal_params[:journal_type_id])

      amount = journal_params[:amount] ? journal_params[:amount].to_i : 0
      
      debit_post = Posting.create(:amount => amount * -1, :journal_id => journal.id, :account => debit_account, :currency => journal_params[:currency])

      credit_post = Posting.create(:amount => amount, :journal_id => journal.id, :account => credit_account, :currency => journal_params[:currency])

      # Rollback in case of both accounts being the same
      if journal.validity_check
        status = true
      else
        t.rollback
        status = false
      end
    end

    return [status, journal]
  end
  
  def self.for_branch(branch, offset=0, limit=25)
    sql  = %Q{
              SELECT j.id, j.date, j.comment, debit.amount, 
              FROM accounts a, postings p, journals j
              LEFT OUTER JOIN postings debit  ON debit.journal_id=j.id
              LEFT OUTER JOIN postings credit ON credit.journal_id=j.id
              WHERE a.branch_id=#{branch.id} AND a.id = p.account_id AND p.journal_id=j.id
              GROUP BY j.id
              ORDER BY j.date              
              OFFSET #{offset}
              LIMIT #{limit}
              }
    repository.adapter.query(sql)

  end
  

  def self.xml_tally(hash={}) 
    xml_file = '/tmp/voucher.xml'
    f = File.open(xml_file,'w')
    
    x = Builder::XmlMarkup.new(:indent => 1)
    x.ENVELOPE{
      x.HEADER {    
        x.VERSION "1"
        x.TALLYREQUEST "Import"
        x.TYPE "Data"
        x.ID "Vouchers"  
      }
      
      x.BODY { 
        x.DESC{
        }
        x.DATA{
          x.TALLYMESSAGE{
            Journal.all(hash).each do |j|
              debit_posting, credit_posting = j.postings
              x.VOUCHER{
                x.DATE j.date.strftime("%Y%m%d")
                x.NARRATION j.comment
                x.VOUCHERTYPENAME j.journal_type.name
                x.VOUCHERNUMBER j.id
                x.tag! 'ALLLEDGERENTRIES.LIST' do
                  x.LEDGERNAME(credit_posting.account.name)
                  x.ISDEEMEDPOSITIVE("No")
                  x.AMOUNT(credit_posting.amount)
                end
                x.tag! 'ALLLEDGERENTRIES.LIST' do
                  x.LEDGERNAME(debit_posting.account.name)
                  x.ISDEEMEDPOSITIVE("Yes")
                  x.AMOUNT(debit_posting.amount)
                end
              }
            end
          }
        }
      }
    } 
    f.write(x)
    f.close
  end 
end
