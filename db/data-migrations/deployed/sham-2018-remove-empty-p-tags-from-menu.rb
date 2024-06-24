AppData::Venue.all.each do |v|
  v.update! menu: "" if v.menu == "<p></p>" || v.menu == "<p>&nbsp;</p>"
end