f = Festival.find_by_name("Nyege Nyege Festival 2019")
f.update! timezone: "Africa/Kampala"

fs = Festival.where(timezone: nil)

fs.each do |festival|
  festival.update! timezone: "Europe/London"
end