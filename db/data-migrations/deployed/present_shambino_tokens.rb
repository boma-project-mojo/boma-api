TokenType.find(7).tokens.where(aasm_state: :queued).each do |token|
	BomaPresentTokenWorker.perform_async(token.id)
end