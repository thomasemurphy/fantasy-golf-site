tournament = Tournament.find_by!(week_number: 7)

picks_data = [
  # player name,            golfer name,                dd,    auto
  ["Kyle Frazho",           "Michael Thorbjornsen",     false, false],
  ["Mike Feeley",           "Russell Henley",            false, false],
  ["Jimmy Nelson",          "Tommy Fleetwood",           false, false],
  ["Bree Svigelj",          "Keith Mitchell",            false, false],
  ["Nate Hill",             "Russell Henley",            false, false],
  ["Zach Jonas",            "Robert MacIntyre",          false, false],
  ["Andy Stepic",           "Tommy Fleetwood",           false, false],
  ["CJ Sturges",            "J.T. Poston",               false, false],
  ["Jason Mungarro",        "Russell Henley",            false, false],
  ["Brian Szepelak",        "Si Woo Kim",                false, false],
  ["Jason DuBois",          "Sudarshan Yellamaraju",     false, false],
  ["Andrew Lunder",         "Si Woo Kim",                false, false],
  ["Jack Gunst",            "Michael Thorbjornsen",      false, false],
  ["Roberto Scheinerle",    "Robert MacIntyre",          false, false],
  ["Michael Amira",         "Si Woo Kim",                false, false],
  ["Jay Waugh",             "Sepp Straka",               false, false],
  ["Michael Barile",        "Alex Noren",                false, false],
  ["Kevin Hobbs",           "Ryo Hisatsune",             false, false],
  ["Chris Piper",           "Robert MacIntyre",          false, true],
  ["Nick Cristobal",        "Hideki Matsuyama",          false, false],
  ["Brian Feeley",          "Jordan Spieth",             false, false],
  ["Chad Squires Jr.",      "Sepp Straka",               false, false],
  ["Michael Lukas",         "Robert MacIntyre",          false, false],
  ["Kyle Shaffer",          "Robert MacIntyre",          false, false],
  ["Jim Cooke",             "Russell Henley",            false, false],
  ["Paul Cacciotti",        "Michael Thorbjornsen",      false, false],
  ["Daren Wamsley",         "Jordan Spieth",             false, false],
  ["Katie King",            "Ludvig Åberg",              false, false],
  ["Tom Murphy",            "Jordan Spieth",             false, false],
  ["Jack Murphy",           "Si Woo Kim",                false, false],
  ["Pat Lang",              "Ryo Hisatsune",             false, false],
  ["Anthony Cerruti",       "Jordan Spieth",             false, false],
  ["Chad Squires Sr.",      "Robert MacIntyre",          false, false],
  ["Reise Kelly",           "Keith Mitchell",            false, false],
  ["Mike Murphy",           "Michael Thorbjornsen",      false, false],
  ["Graeme Watson",         "Michael Thorbjornsen",      false, false],
  ["Daniel Jaffe",          "Ryo Hisatsune",             false, false],
  ["Robert Chambers",       "Sepp Straka",               false, false],
  ["Kyle O'Neil",           "Michael Thorbjornsen",      false, false],
  ["Justin Mungarro",       "Robert MacIntyre",          false, false],
  ["Jerry Heath",           "Will Zalatoris",            false, false],
  ["JT Ozerities",          "Sepp Straka",               false, false],
  ["Ryan Finstad",          "Sepp Straka",               false, false],
  ["Kevin Lang",            "Keith Mitchell",            false, false],
  ["Nick Scarimbolo",       "Sepp Straka",               false, false],
  ["Mike Davis",            "Jordan Spieth",             false, false],
  ["Luke Grasso",           "Russell Henley",            false, false],
  ["Ben Engler",            "Robert MacIntyre",          false, false],
  ["Tim Cooney",            "Si Woo Kim",                false, false],
  ["Adam Feeley",           "Ludvig Åberg",              false, false],
  ["Matt VanDixhorn",       "Robert MacIntyre",          false, false],
  ["Chad Gauvin",           "Jordan Spieth",             false, false],
  ["Dan Jaffe",             "Keith Mitchell",            false, false],
  ["Fernando Gomez",        "Robert MacIntyre",          false, false],
  ["Dylan Linke",           "Sepp Straka",               false, false],
  ["Dustin Daniels",        "Hideki Matsuyama",          false, false],
  ["Dylan Chambers",        "Jordan Spieth",             false, false],
]

picks_data.each do |user_name, golfer_name, is_dd, is_auto|
  user   = User.find_by!(name: user_name)
  golfer = Golfer.find_by!(name: golfer_name)

  next if Pick.exists?(user: user, tournament: tournament)

  pick = Pick.new(
    user:           user,
    tournament:     tournament,
    golfer:         golfer,
    is_double_down: is_dd,
    auto_assigned:  is_auto,
    earnings_cents: is_auto ? 0 : nil
  )
  pick.save!(validate: false)
end

puts "Seeded week 7 picks (#{Pick.where(tournament: tournament).count} total)"
