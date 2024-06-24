class BomaPresentTokenWorker
  include Sidekiq::Worker

  sidekiq_retry_in do |count, exception|
  	10
  end

  def perform(*args)
  	token = Token.find(args[0])
    BomaTokenService.new.present(token)
  end
end
