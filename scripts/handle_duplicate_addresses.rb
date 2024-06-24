# A bug has been occuring where multiple addresses/organisation_addresses are being created becuase 
# two identical requests are being sent simultaneously and both are completing - the ActiveRecord validation
# to protect again duplicate addresses isn't good enough to protect against this scenario.  

# This script removes duplicate addresses/organisation_addresses (removing only one created most recently
# as the first has been updated more recently in all cases)

ActiveRecord::Base.logger = nil

affected_addresses = Address.select(:address).group(:address).having("count(*) > 1").collect(&:address)

# Check assumptions that first address is the one that has been updated most recently.  
affected_addresses.each do |address|
  asses = Address.where(address: address)

  if asses.last.created_at != asses.last.updated_at
    raise "Stop!!!  Your assumptions aren't correct anymore!"
  end
end

# remove most recently created address and organisation addresses.  
affected_addresses.each do |address|
  puts "removing #{asses.last.id} (#{address})"

  asses.last.organisation_addresses.each do |oa|
    oa.destroy!
  end
  
  asses.last.destroy!
end
