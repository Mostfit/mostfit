class DuplicateClientsReport < Report
  attr_accessor :date
  SDX1, SDX2 = 'AEHIOUWYBFPVCGJKQSXZDTLMNR', '00000000111122222222334556'
  def initialize
    self.date = Date.today
  end

  def name
    "Duplicate clients as of #{self.start_date}"
  end

  def soundex1(string)
    copy = string.upcase.tr '^A-Z', ''
    return "" if copy.empty?
    first_letter = copy[0,1]
    copy.tr_s! SDX1, SDX2
    copy.sub!(/^(.)\1*/, '').gsub!(/0/, '')
    return "#{first_letter}#{copy.ljust(3,"0")}"
  end

  def generate
    t0 = Time.now
    @report = []
    data = [] #account number can be nil, others cannot be 
    soundex_names, soundex_spouse_names, account_numbers = {}, {}, {}
    duplicates = Hash.new() #this one stores info like name, center_name, branch_name etc. hashed by ID
    duplicates[:same_name_and_dob]        = []
    duplicates[:same_spouse_name_and_dob] = []
    duplicates[:same_account_number]      = []          

    clients = Client.all(:fields => [:id, :name, :spouse_name, :account_number, :date_of_birth]).map{|cl| [cl.id, cl]}.to_hash

    clients.each do |cid, client|
      #duplicate first name
      firstchar, name_rest    = soundex3(client.name)

      soundex_names[firstchar] ||= []
      soundex_names[firstchar].each{|other_client|
        if other_client[:rest] == name_rest and client.date_of_birth and client.date_of_birth == other_client[:client].date_of_birth
          duplicates[:same_name_and_dob].push([client, other_client[:client]])
        end
      }
      soundex_names[firstchar].push({:client => client, :rest => name_rest})          

      #duplicate spouse name
      if client.spouse_name and not client.spouse_name.blank?
        firstchar, spouse_name_rest = soundex3(client.spouse_name)

        soundex_spouse_names[firstchar] ||= []
        soundex_spouse_names[firstchar].each_with_index{|other_client, idx|          
          if other_client[:rest] == spouse_name_rest and client.date_of_birth == other_client[:client].date_of_birth and client.date_of_birth
            duplicates[:same_spouse_name_and_dob].push([client, other_client[:client]])
          end
        }
        soundex_spouse_names[firstchar].push({:client => client, :rest => spouse_name_rest})
      end

      #duplicate account number
      if client.account_number and client.account_number.length>0 and client.account_number.to_i>0

        if account_numbers.key?(client.account_number)
          duplicates[:same_account_number].push([client, account_numbers[client.account_number][:client]])
        else
          account_numbers[client.account_number] = client
        end
      end
    end

    self.raw = duplicates.map{|reason, all_duplicates|
      {
        reason => all_duplicates.map{|dups|
          dups.map{|dup|
            [dup.id, dup.name, dup.spouse_name, dup.date_of_birth, dup.account_number]
          }
        }
      }
    }
    self.start_date = Date.today
    self.report = Marshal.dump(self.raw)
    self.generation_time = Time.now - t0
    self.save
    return @report
  end

  #this function returns an array consisting of
  #1) first char of the full name
  #2) soundex of full name(done on each word in the name separately and then they are combined)
  def soundex3(string)
    total_soundex=""
    string.split.each do |word| total_soundex+=(soundex1(word)+" ") end
    return string[0,1], total_soundex
  end
end

