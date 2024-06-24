TokenType.first.update! contract_address: "0xdA1B637DEEba405053f7B811BDC528151AE1e5EF"

@festival = Festival.find(1)
@festival.update! center_lat: "52.41280976465001", center_long: "-0.9227243086204999", location_radius: "1"

@festival = Festival.find(3)
@festival.update! center_lat: "52.41280976465001", center_long: "-0.9227243086204999", location_radius: "1"


BomaTokenService.new.update_all_token_states