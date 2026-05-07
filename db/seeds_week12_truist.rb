tournament = Tournament.find_by!(week_number: 12)
tournament.update!(status: "in_progress")

PICKS = [
  ["Kyle Frazho",       "Rory McIlroy",       true,  false],
  ["Mike Feeley",       "Ludvig Åberg",        false, false],
  ["Andy Stepic",       "Si Woo Kim",          false, false],
  ["Tom Murphy",        "Si Woo Kim",          false, false],
  ["Michael Amira",     "Rory McIlroy",        true,  false],
  ["Jim Cooke",         "Ludvig Åberg",        false, false],
  ["Pat Lang",          "Xander Schauffele",   false, false],
  ["CJ Sturges",        "Rory McIlroy",        true,  false],
  ["Bree Svigelj",      "Sam Burns",           false, false],
  ["Michael Lukas",     "Tommy Fleetwood",     false, false],
  ["Andrew Lunder",     "Rory McIlroy",        true,  false],
  ["Justin Mungarro",   "Rory McIlroy",        false, false],
  ["Mike Murphy",       "Rory McIlroy",        true,  false],
  ["Nate Hill",         "Xander Schauffele",   false, false],
  ["Kyle Shaffer",      "Ludvig Åberg",        false, false],
  ["Jimmy Nelson",      "Ludvig Åberg",        false, false],
  ["Luke Grasso",       "Xander Schauffele",   false, false],
  ["Zach Jonas",        "Rory McIlroy",        false, true],
  ["Kevin Hobbs",       "Xander Schauffele",   false, false],
  ["Chad Squires Jr.",  "Russell Henley",      false, false],
  ["Jason Mungarro",    "Ludvig Åberg",        false, false],
  ["Brian Szepelak",    "Ben Griffin",         false, false],
  ["Kyle O'Neil",       "Ludvig Åberg",        false, false],
  ["Ben Engler",        "Si Woo Kim",          false, false],
  ["Jay Waugh",         "Patrick Cantlay",     false, false],
  ["Robert Chambers",   "Ludvig Åberg",        false, false],
  ["Chad Squires Sr.",  "Ben Griffin",         false, false],
  ["Matt VanDixhorn",   "Xander Schauffele",   false, false],
  ["Fernando Gomez",    "Adam Scott",          false, false],
  ["Chad Gauvin",       "Ludvig Åberg",        false, false],
  ["Jack Murphy",       "Xander Schauffele",   false, false],
  ["Anthony Cerruti",   "Rory McIlroy",        false, false],
  ["Reise Kelly",       "Rory McIlroy",        true,  false],
  ["Graeme Watson",     "Cameron Young",       false, false],
  ["Jack Gunst",        "JJ Spaun",            false, false],
  ["Roberto Scheinerle","Rory McIlroy",        true,  false],
  ["Jason DuBois",      "Rory McIlroy",        true,  false],
  ["Michael Barile",    "Rory McIlroy",        true,  false],
  ["Brian Feeley",      "Xander Schauffele",   false, false],
  ["Nick Cristobal",    "Xander Schauffele",   false, false],
  ["Daniel Jaffe",      "Rory McIlroy",        false, false],
  ["Katie King",        "Si Woo Kim",          false, true],
  ["Jerry Heath",       "Rory McIlroy",        false, true],
  ["Paul Cacciotti",    "Tommy Fleetwood",     false, false],
  ["Mike Davis",        "Si Woo Kim",          false, false],
  ["Daren Wamsley",     "Rory McIlroy",        false, true],
  ["Nick Scarimbolo",   "Justin Thomas",       false, false],
  ["Adam Feeley",       "Kurt Kitayama",       false, false],
  ["JT Ozerities",      "Rickie Fowler",       false, false],
  ["Dylan Linke",       "Xander Schauffele",   false, false],
  ["Kevin Lang",        "Xander Schauffele",   false, false],
  ["Ryan Finstad",      "Si Woo Kim",          false, false],
  ["Dustin Daniels",    "Tommy Fleetwood",     false, false],
  ["Dan Jaffe",         "Ben Griffin",         false, false],
  ["Tim Cooney",        "Rory McIlroy",        false, true],
  ["Dylan Chambers",    "Rory McIlroy",        false, true],
].freeze

errors = []
PICKS.each do |user_name, golfer_name, dd, auto|
  user = User.find_by(name: user_name)
  unless user
    errors << "User not found: #{user_name}"
    next
  end
  golfer = Golfer.find_by(name: golfer_name)
  unless golfer
    errors << "Golfer not found: #{golfer_name}"
    next
  end
  pick = Pick.find_or_initialize_by(tournament: tournament, user: user)
  pick.golfer         = golfer
  pick.is_double_down = dd
  pick.auto_assigned  = auto
  pick.save!(validate: false)
end

if errors.any?
  puts "ERRORS:"
  errors.each { |e| puts "  #{e}" }
else
  puts "All #{PICKS.size} picks seeded successfully."
end

# Fix double_downs_remaining
User.where(admin: false).each do |u|
  used    = Pick.where(user_id: u.id, is_double_down: true).count
  correct = 5 - used
  u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
end
puts "Double down counts updated."
