token_params = {
  festival_id: 3,
  token_type_id: 2,
  address: "0x333fe02746707007eed3ac7def8eeeb9d3befca5",
}

# 0xe3a298c30ee47e28b2f37a26cd0e06f898e7ce09

token = Token.create! token_params

if token.save
  BomaTokenService.new.present(token)
end