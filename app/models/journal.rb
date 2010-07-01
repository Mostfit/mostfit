require 'builder'
class Journal
  include DataMapper::Resource
 
  property :id,             Serial
  property :comment,        String
  property :transaction_id, String, :index => true  
  property :date,           Date, :index => true  
  property :created_at,     DateTime, :index => true  
  property :batch_id,       Integer, :nullable => true
  belongs_to :batch
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
      journal = Journal.create(:comment => journal_params[:comment], :date =>    journal_params[:date]||Date.today,
                               :transaction_id => journal_params[:transaction_id])

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
  

  def self.xml_tally(hash, target) 
    x = Builder::XmlMarkup.new(:target => target, :indent => 2)
    x.instruct!
    x.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    x.ENVELOPE( "xmlns" => "http://www.w3.org/1999/xhtml" ) { 
      x.HEADER {    
        x.VERSION "1"
        x.TALLYREQUEST "Import"
        x.TYPE "Data"
        x.ID "Vouchers"  
      }
      
      x.BODY { 
        x.DESC
        x.DATA{
          x.TALLYMESSAGE{
            Journal.all(hash).each do |j|
              debit_posting, credit_posting = j.postings
              x.VOUCHER{
                x.DATE j.date
                x.NARRATION j.comment
                x.VOUCHERTYPENAME "Payment"
                x.VOUCHERNUMBER j.id
                x.ALLLEDGERENTRIES_LIST{
                  x.LEDGERNAME credit_posting.account.name
                  x.ISDEEMEDPOSITIVE "Yes"
                  x.AMOUNT credit_posting.amount
                }
                x.ALLLEDGERENTRIES_LIST{
                  x.LEDGERNAME debit_posting.account.name
                  x.ISDEEMEDPOSITIVE "No"
                  x.AMOUNT debit_posting.amount
                }
              }
            end
          }
        }
      }
      
    } 
    
  end 
end
