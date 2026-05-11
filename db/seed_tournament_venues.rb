# course_name, city, state (use country/region for international events)
VENUES = {
  1  => ["Riviera Country Club",                  "Pacific Palisades", "CA"],
  2  => ["PGA National Resort (Champion Course)", "Palm Beach Gardens", "FL"],
  3  => ["Bay Hill Club & Lodge",                 "Orlando",            "FL"],
  4  => ["TPC Sawgrass (Stadium Course)",         "Ponte Vedra Beach",  "FL"],
  5  => ["Innisbrook Resort (Copperhead Course)", "Palm Harbor",        "FL"],
  6  => ["Memorial Park Golf Course",             "Houston",            "TX"],
  7  => ["TPC San Antonio (Oaks Course)",         "San Antonio",        "TX"],
  8  => ["Augusta National Golf Club",            "Augusta",            "GA"],
  9  => ["Harbour Town Golf Links",               "Hilton Head Island", "SC"],
  10 => ["TPC Louisiana",                         "Avondale",           "LA"],
  11 => ["Trump National Doral (Blue Monster)",   "Doral",              "FL"],
  12 => ["Quail Hollow Club",                     "Charlotte",          "NC"],
  13 => ["Aronimink Golf Club",                    "Newtown Square",     "PA"],
  14 => ["TPC Craig Ranch",                       "McKinney",           "TX"],
  15 => ["Colonial Country Club",                 "Fort Worth",         "TX"],
  16 => ["Muirfield Village Golf Club",           "Dublin",             "OH"],
  17 => ["Hamilton Golf and Country Club",        "Ancaster, Ontario",  "Canada"],
  18 => ["Shinnecock Hills Golf Club",            "Southampton",        "NY"],
  19 => ["TPC River Highlights",                  "Cromwell",           "CT"],
  20 => ["TPC Deere Run",                         "Silvis",             "IL"],
  21 => ["The Renaissance Club",                  "North Berwick",      "Scotland"],
  22 => ["Royal Portrush Golf Club",              "Portrush",           "N. Ireland"],
  23 => ["TPC Twin Cities",                       "Blaine",             "MN"],
  24 => ["Detroit Golf Club",                     "Detroit",            "MI"],
  25 => ["Sedgefield Country Club",               "Greensboro",         "NC"],
  26 => ["TPC Southwind",                         "Memphis",            "TN"],
  27 => ["Caves Valley Golf Club",                "Owings Mills",       "MD"],
}.freeze

VENUES.each do |week, (course, city, state)|
  t = Tournament.find_by(week_number: week)
  next unless t
  t.update_columns(course_name: course, city: city, state: state)
  puts "Wk#{week}: #{course}, #{city}, #{state}"
end
puts "Done."
