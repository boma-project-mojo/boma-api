class BomaMiningStatusWorker
  include Sidekiq::Worker

  sidekiq_retry_in do |count, exception|
  	10
  end

  def perform(*args)
  	token = Token.find(args[0])
    BomaTokenService.new.update_token_state(token)
  end
end
