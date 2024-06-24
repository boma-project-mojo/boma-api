# Token created with error in production, destroy it
# has address object rather than string in address attribute
begin
	Token.find(1205).destroy
rescue
end
# has no TokenType
Token.find(834).destroy
Token.find(1023).destroy
Token.find(1034).destroy

# Shambala Tokens from Shambala 2018
# These tokens need to investigated and the transactions remined on the ETH blockchain at some point in the future.  
Token.where(aasm_state: :mining).where(token_type_id: 1).each {|t| t.update! aasm_state: :failed}

# Shambino Tokens
# These tokens need to be mined on the gnosis chain.  
Token.where(aasm_state: :mining).where(token_type_id: 7).each {|t| t.update! aasm_state: :queued}