venues = [
  {name: "The Shambala Stage", order: 1},
  {name: "The Kamikaze", order: 2},
  {name: "Chai Wallahs", order: 3},
  {name: "Sankofa's", order: 4},
  {name: "Barrio Afrika", order: 5},
  {name: "The Social Club", order: 6},
  {name: "Phantom Laundry", order: 7},
  {name: "The House Party", order: 8},
  {name: "The Roots Yard", order: 9},
  {name: "Compass Presents", order: 10},
  {name: "Madame Bayou's", order: 11},
  {name: "The House Party", order: 12},
  {name: "Botanical Disco", order: 14},
  {name: "The Imaginarium", order: 15},
  {name: "Rebel Soul", order: 16},
  {name: "The Enchanted Woods", order: 17},
  {name: "Swingamajig", order: 19},
  {name: "The Coyote Moon", order: 20},
  {name: "Puppet Parlour", order: 21},
  {name: "The Garden O' Feeden", order: 23},
  {name: "Cirque De Lune", order: 24},
  {name: "The Lost Picture Show", order: 25},
  {name: "The SanQtuary", order: 26},
  {name: "Woodland Tribe", order: 27},
  {name: "Shambala Springs", order: 28},
  {name: "Harmony Yurt", order: 29},
  {name: "Random Workshops", order: 30},
  {name: "Permaculture", order: 31},
  {name: "Phantom Laundry Workshop Tent", order: 32},
  {name: "Melody Yurt", order: 33},
  {name: "The Shamanic Tipi", order: 34},
  {name: "The Waiting Room", order: 35},
  {name: "The Exchange", order: 36},
  {name: "Granny's Cat Cafe", order: 37},
  {name: "Womb With A View", order: 38},
  {name: "Guerilla Science Laboratory", order: 39},
  {name: "The Mayflower Project: Teen Tent", order: 40},
  {name: "The Healing Meadows", order: 41},
  {name: "Dance Workshops", order: 42},
  {name: "The Family Yurt", order: 43},
  {name: "The Craft Area", order: 44},
  {name: "Carnival Tent", order: 45},
  {name: "The Red Sea Travel Agency", order: 46},
  {name: "Playtopia", order: 47},
]

venues.each do |venue|
  v = AppData::Venue.find_by_name(venue[:name])
  if v.nil?
    puts "Venue not found #{venue[:name]}"
  else
    v.update! list_order: venue[:order]
  end
end