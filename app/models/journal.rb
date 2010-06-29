require 'builder'
class Journal
  include DataMapper::Resource
 
  property :id,             Serial
  property :comment,        String, :index => true  
  property :transaction_id, Integer
  property :date,           Date
  property :created_at,     DateTime
  property :batch_id,       Integer, :nullable => true
  belongs_to :batch
  has n, :postings


  def self.xml_tally(hash, target) 
    x = Builder::XmlMarkup.new(:target => target, :indent => 1)
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
