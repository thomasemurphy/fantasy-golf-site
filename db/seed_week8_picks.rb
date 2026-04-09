tournament = Tournament.find_by!(week_number: 8)

# Ensure golfers not yet in DB are created
[
  "Bryson DeChambeau",
  "Patrick Reed",
].each do |name|
  Golfer.find_or_create_by!(name: name)
end

picks_data = [
  # player name,            golfer name,                dd,    auto
  ["Kyle Frazho",           "Ludvig Åberg",              true,  false],
  ["Mike Feeley",           "Scottie Scheffler",         true,  false],
  ["Jimmy Nelson",          "Bryson DeChambeau",         true,  false],
  ["Zach Jonas",            "Bryson DeChambeau",         true,  false],
  ["Bree Svigelj",          "Ludvig Åberg",              false, false],
  ["Nate Hill",             "Scottie Scheffler",         true,  false],
  ["Andy Stepic",           "Scottie Scheffler",         true,  false],
  ["Roberto Scheinerle",    "Bryson DeChambeau",         false, false],
  ["CJ Sturges",            "Scottie Scheffler",         true,  false],
  ["Jason Mungarro",        "Bryson DeChambeau",         true,  false],
  ["Brian Szepelak",        "Jon Rahm",                  true,  false],
  ["Jason DuBois",          "Jon Rahm",                  true,  false],
  ["Andrew Lunder",         "Jon Rahm",                  false, false],
  ["Michael Amira",         "Bryson DeChambeau",         true,  false],
  ["Jack Gunst",            "Xander Schauffele",         true,  false],
  ["Kevin Hobbs",           "Bryson DeChambeau",         true,  false],
  ["Jay Waugh",             "Bryson DeChambeau",         true,  false],
  ["Michael Lukas",         "Bryson DeChambeau",         true,  false],
  ["Michael Barile",        "Patrick Reed",              false, false],
  ["Kyle Shaffer",          "Bryson DeChambeau",         true,  false],
  ["Nick Cristobal",        "Bryson DeChambeau",         true,  false],
  ["Chris Piper",           "Bryson DeChambeau",         false, true],
  ["Brian Feeley",          "Patrick Reed",              true,  false],
  ["Chad Squires Jr.",      "Scottie Scheffler",         true,  false],
  ["Katie King",            "Jon Rahm",                  true,  false],
  ["Jim Cooke",             "Xander Schauffele",         true,  false],
  ["Chad Squires Sr.",      "Jon Rahm",                  true,  false],
  ["Pat Lang",              "Ludvig Åberg",              true,  false],
  ["Justin Mungarro",       "Xander Schauffele",         true,  false],
  ["Jack Murphy",           "Ludvig Åberg",              true,  false],
  ["Paul Cacciotti",        "Bryson DeChambeau",         true,  false],
  ["Daren Wamsley",         "Bryson DeChambeau",         true,  false],
  ["Tom Murphy",            "Jon Rahm",                  false, false],
  ["Daniel Jaffe",          "Xander Schauffele",         true,  false],
  ["Anthony Cerruti",       "Jon Rahm",                  true,  false],
  ["Ben Engler",            "Xander Schauffele",         true,  false],
  ["Matt VanDixhorn",       "Jon Rahm",                  true,  false],
  ["Reise Kelly",           "Xander Schauffele",         true,  false],
  ["Mike Murphy",           "Scottie Scheffler",         true,  false],
  ["Graeme Watson",         "Shane Lowry",               true,  false],
  ["Fernando Gomez",        "Xander Schauffele",         false, false],
  ["Robert Chambers",       "Xander Schauffele",         true,  false],
  ["Kyle O'Neil",           "Xander Schauffele",         true,  false],
  ["Jerry Heath",           "Bryson DeChambeau",         false, false],
  ["JT Ozerities",          "Xander Schauffele",         false, false],
  ["Adam Feeley",           "Matt Fitzpatrick",          true,  false],
  ["Tim Cooney",            "Bryson DeChambeau",         true,  false],
  ["Ryan Finstad",          "Ludvig Åberg",              true,  false],
  ["Kevin Lang",            "Matt Fitzpatrick",          false, false],
  ["Mike Davis",            "Ludvig Åberg",              true,  false],
  ["Nick Scarimbolo",       "Jon Rahm",                  true,  false],
  ["Luke Grasso",           "Scottie Scheffler",         true,  false],
  ["Chad Gauvin",           "Matt Fitzpatrick",          true,  false],
  ["Dustin Daniels",        "Ludvig Åberg",              true,  false],
  ["Dan Jaffe",             "Xander Schauffele",         false, false],
  ["Dylan Linke",           "Bryson DeChambeau",         true,  false],
  ["Dylan Chambers",        "Ludvig Åberg",              true,  false],
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

puts "Seeded week 8 picks (#{Pick.where(tournament: tournament).count} total)"
