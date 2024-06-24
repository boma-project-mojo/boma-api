total_beta_testers = 700

tt = TokenType.find(10)

beta_nonces = []

(0...total_beta_testers).each do |index|
  token = Token.create! token_type_id: tt.id, festival_id: 52
  beta_nonces << token.nonce
end

puts beta_nonces