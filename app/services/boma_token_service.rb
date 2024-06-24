# Boma Token Service
#
# This service provides methods:
#
# 1.  To create or update an Address and associated OrganisationAddress
# 2.  To present a Token to the blockchain 
# 3.  To check the status of mining the Token on the blockchain.
#
# For more information on tokens see https://gitlab.com/boma-hq/boma-api#tokens

class BomaTokenService

  attr :client, :abi, :contract

  # Create a Eth:Client object for the provided blockchain.  
  # Params:
  # +token_type+:: An ActiveRecord TokenType object 
  def connect token_type
    if token_type.chain === "ethereum"
      @client = Eth::Client.create(ENV['ethereum_rpc_URI'])
    elsif token_type.chain === "gnosis"
      @client = Eth::Client.create(ENV['gnosis_rpc_URI'])
    end
    @abi = '[{"constant": false,"inputs": [{"name": "participant","type": "address"}],"name": "present","outputs": [],"payable": false,"stateMutability": "nonpayable","type": "function"},{"inputs": [{"name": "_eventName","type": "string"}],"payable": false,"stateMutability": "nonpayable","type": "constructor"},{"constant": true,"inputs": [],"name": "east","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "eventEnds","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "eventName","outputs": [{"name": "","type": "string"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "eventStarts","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [{"name": "participant","type": "address"}],"name": "isPresent","outputs": [{"name": "","type": "bool"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "north","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "owner","outputs": [{"name": "","type": "address"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "south","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"},{"constant": true,"inputs": [],"name": "west","outputs": [{"name": "","type": "uint256"}],"payable": false,"stateMutability": "view","type": "function"}]'
    return self
  end

  # Find or Create an Address but not a related OrganisationAddress
  #
  # Where push notifications are disabled the app doesn't call home so no Address record is created.  
  #
  # This method finds or creates an Address ActiveRecord object and returns it.  
  #
  # We require an Address without an OrganisationAddress for the following use cases:-
  #  1.  Survey responses (each survey response is linked to an Address to make answering multiple times more difficult)
  #
  # Params:
  # +address+:: An ActiveRecord Address object 
  def create_or_find_address address
    @address = Address.find_or_create_by address: address

    return @address
  end

  # Create or update an Address and associated AddressOrganisation.  
  # Params:
  # +address_params+:: The params to create or update the address with.  
  def create_or_update_wallet address_params
    @wallet = Address.where(address: address_params[:address]).first_or_initialize

    @wallet = create_or_update_wallet_organisation @wallet, address_params

    @wallet.save

    return @wallet
  end

  # Create or update an OrganisationAddress
  # Params:
  # +wallet+:: ActiveRecord Address object
  # +address_params+:: The params to create or update the OrganisationAddress with.  
  def create_or_update_wallet_organisation wallet, address_params
    @organisation_addresses = wallet.organisation_addresses.where(organisation_id: address_params[:organisation_id]).first_or_initialize
    @organisation_addresses.settings = address_params[:settings]
    @organisation_addresses.device_details = address_params[:device_details]

    @organisation_addresses.fcm_token = address_params[:fcm_token] if address_params[:fcm_token]
    @organisation_addresses.app_version = address_params[:app_version] if address_params[:app_version]
    @organisation_addresses.unread_push_notifications = address_params[:unread_push_notifications] if address_params[:unread_push_notifications]

    @organisation_addresses.registration_type = address_params[:registration_type] if address_params[:registration_type]
    @organisation_addresses.registration_id = address_params[:registration_id] if address_params[:registration_id]

    wallet.organisation_addresses << @organisation_addresses

    return wallet
  end

  # Present a token to the blockchain in sequencial order, if there is a token in mining state force sidekiq to retry
  # Params:
  # +token+:: ActiveRecord Token object
  def present token
    self.connect token.token_type

    @contract = Eth::Contract.from_abi(name: "BomaPresence", address: token.token_type.contract_address, abi: abi)
    key = self.set_key(token)

    # @contract.gas_limit = 21000
    # @contract.gas_price = 100000000

    address = Eth::Address.new token[:address]
    unless address.valid?
      raise "not a valid address"
    end

    # if we've made it here then the token has been successfully presented
    # update the token state to mining...
    begin
      # do the transaction
      tx = @client.transact(@contract, 'present', token[:address].downcase, sender_key: key, nonce: token.transaction_nonce);
      token.update! aasm_state: :mining
    rescue Exception => e
      token.update! aasm_state: :queued
      raise "Issue when presenting token to contract #{e.inspect}"
    end

    # ...then start the worker that checks the token status
    BomaMiningStatusWorker.perform_in(30.second, token.id)
  end

  # Check a token has been successfully mined on the blockchain.  
  # Params:
  # +token+:: ActiveRecord Token object
  def is_present token
    self.connect token.token_type

    begin
      @contract = Eth::Contract.from_abi(name: "BomaPresence", address: token.token_type.contract_address, abi: abi)

      key = self.set_key(token)
      @contract.key = key

      address = Eth::Address.new token[:address]
      unless address.valid?
        raise "not a valid address"
      end

      is_present = @client.call(@contract, 'isPresent', token[:address].downcase);

      return is_present
    rescue Exception => e
      puts e.inspect
    end
  end

  # Check a token has been mined on the blockchain and if so update the token state.  
  # Params:
  # +token+:: ActiveRecord Token object
  def update_token_state token
    is_mined = self.is_present token
    if is_mined
      token.mined! unless token.mined?
    else
      # If the token isn't mined force an error response for the delayed job to force it to retry
      raise "Token isn't mined, check again in 30 seconds"
    end
  end

  # Update the token states of all tokens in the :mining state
  def update_all_token_states
    Token.mining.each do |token|
      self.update_token_state token
    end
  end

  # Set the key to be used when presenting or checking token mining state.  
  # Params:
  # +token+:: ActiveRecord Token object
  def set_key token
    if token.token_type.chain === "ethereum"
      raise "SET PRIVATE KEY IN .env for -> #{token.organisation.name.parameterize(separator: '_')}_ethereum_priv_key" if ENV["#{token.organisation.name.parameterize(separator: '_')}_ethereum_priv_key"].nil?
      key = Eth::Key.new priv: ENV["#{token.organisation.name.parameterize(separator: '_')}_ethereum_priv_key"]
    elsif token.token_type.chain === "gnosis"
      raise "SET PRIVATE KEY IN .env for -> #{token.organisation.name.parameterize(separator: '_')}_gnosis_priv_key" if ENV["#{token.organisation.name.parameterize(separator: '_')}_gnosis_priv_key"].nil?
      key = Eth::Key.new priv: ENV["#{token.organisation.name.parameterize(separator: '_')}_gnosis_priv_key"]
    end
  end

end