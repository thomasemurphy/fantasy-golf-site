tournament = Tournament.find_by!(week_number: 9)

# Ensure golfers not yet in DB are created
[
  "Sahith Theegala",
  "Akshay Bhatia",
  "Robert MacIntyre",
].each do |name|
  Golfer.find_or_create_by!(name: name)
end

picks_data = [
  # player name,            golfer name,                dd,    auto
  ["Kyle Frazho",           "Jordan Spieth",             false, false],
  ["Mike Feeley",           "Matt Fitzpatrick",          false, false],
  ["Nate Hill",             "Brian Harman",              false, false],
  ["Andy Stepic",           "Ludvig Åberg",              false, false],
  ["CJ Sturges",            "Patrick Cantlay",           false, false],
  ["Chad Squires Jr.",      "Tommy Fleetwood",           false, false],
  ["Mike Murphy",           "Robert MacIntyre",          false, false],
  ["Luke Grasso",           "Patrick Cantlay",           false, false],
  ["Jimmy Nelson",          "Matt Fitzpatrick",          false, false],
  ["Zach Jonas",            "Russell Henley",            false, false],
  ["Jack Gunst",            "Tommy Fleetwood",           false, false],
  ["Bree Svigelj",          "Russell Henley",            false, false],
  ["Roberto Scheinerle",    "Patrick Cantlay",           false, false],
  ["Brian Szepelak",        "Matt Fitzpatrick",          false, false],
  ["Jason DuBois",          "Tommy Fleetwood",           false, false],
  ["Jason Mungarro",        "Matt Fitzpatrick",          false, false],
  ["Andrew Lunder",         "Scottie Scheffler",         true,  false],
  ["Jim Cooke",             "Matt Fitzpatrick",          false, true],
  ["Michael Barile",        "Russell Henley",            false, false],
  ["Michael Amira",         "Patrick Cantlay",           false, false],
  ["Brian Feeley",          "Brian Harman",              false, false],
  ["Justin Mungarro",       "Jordan Spieth",             false, false],
  ["Kevin Hobbs",           "Si Woo Kim",                false, false],
  ["Jay Waugh",             "Matt Fitzpatrick",          false, false],
  ["Michael Lukas",         "Patrick Cantlay",           false, false],
  ["Daniel Jaffe",          "Russell Henley",            false, false],
  ["Ben Engler",            "Sam Burns",                 false, false],
  ["Kyle Shaffer",          "Sam Burns",                 false, false],
  ["Nick Cristobal",        "Russell Henley",            false, false],
  ["Chris Piper",           "Russell Henley",            false, true],
  ["Reise Kelly",           "Si Woo Kim",                false, false],
  ["Fernando Gomez",        "Akshay Bhatia",             false, false],
  ["Robert Chambers",       "Russell Henley",            false, false],
  ["Pat Lang",              "Matt Fitzpatrick",          false, false],
  ["Kyle O'Neil",           "Jordan Spieth",             false, false],
  ["Jack Murphy",           "Russell Henley",            false, false],
  ["Katie King",            "Cameron Young",             false, false],
  ["Chad Squires Sr.",      "Russell Henley",            false, false],
  ["Paul Cacciotti",        "Russell Henley",            false, false],
  ["Tom Murphy",            "Matt Fitzpatrick",          false, false],
  ["Anthony Cerruti",       "Xander Schauffele",         false, false],
  ["Daren Wamsley",         "Russell Henley",            false, true],
  ["JT Ozerities",          "Tommy Fleetwood",           false, false],
  ["Adam Feeley",           "Viktor Hovland",            false, false],
  ["Matt VanDixhorn",       "Russell Henley",            false, false],
  ["Graeme Watson",         "Sahith Theegala",           false, false],
  ["Ryan Finstad",          "Russell Henley",            false, false],
  ["Mike Davis",            "Patrick Cantlay",           false, false],
  ["Chad Gauvin",           "Scottie Scheffler",         true,  false],
  ["Jerry Heath",           "Russell Henley",            false, true],
  ["Kevin Lang",            "Patrick Cantlay",           false, false],
  ["Dan Jaffe",             "Russell Henley",            false, false],
  ["Nick Scarimbolo",       "Collin Morikawa",           false, false],
  ["Tim Cooney",            "Viktor Hovland",            false, false],
  ["Dustin Daniels",        "Xander Schauffele",         false, false],
  ["Dylan Chambers",        "Russell Henley",             false, true],
  ["Dylan Linke",           "Ludvig Åberg",              false, false],
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

puts "Seeded week 9 picks (#{Pick.where(tournament: tournament).count} total)"
