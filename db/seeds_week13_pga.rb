tournament = Tournament.find_by!(week_number: 13)

ALIASES_W13 = {
  "Cam Young"         => "Cameron Young",
  "Xander Schuaffele" => "Xander Schauffele",
  "Ludvig Aberg"      => "Ludvig Åberg",
  "Tyrrel Hatton"     => "Tyrrell Hatton",
}.freeze

PICKS_W13 = [
  # [player,               golfer,                  dd,    auto]
  ["Kyle Frazho",        "Jon Rahm",               false, false],
  ["Mike Feeley",        "Bryson DeChambeau",       true,  false],
  ["Andy Stepic",        "Rory McIlroy",            true,  false],
  ["Tom Murphy",         "Tommy Fleetwood",         false, false],
  ["Michael Amira",      "Xander Schuaffele",       true,  false],
  ["Jim Cooke",          "Bryson DeChambeau",       false, false],
  ["Pat Lang",           "Tommy Fleetwood",         false, false],
  ["CJ Sturges",         "Jon Rahm",                false, false],
  ["Bree Svigelj",       "Jon Rahm",                false, false],
  ["Michael Lukas",      "Matt Fitzpatrick",        false, false],
  ["Andrew Lunder",      "Cam Young",               true,  false],
  ["Justin Mungarro",    "Rickie Fowler",            false, false],
  ["Mike Murphy",        "Xander Schuaffele",       true,  false],
  ["Kyle Shaffer",       "Scottie Scheffler",       true,  false],
  ["Jimmy Nelson",       "Cam Young",               false, false],
  ["Nate Hill",          "Cam Young",               true,  false],
  ["Luke Grasso",        "Jordan Spieth",            false, false],
  ["Zach Jonas",         "Tommy Fleetwood",         false, false],
  ["Jason Mungarro",     "Scottie Scheffler",       true,  false],
  ["Kevin Hobbs",        "Scottie Scheffler",       true,  false],
  ["Chad Squires Jr.",   "Justin Rose",             true,  false],
  ["Brian Szepelak",     "Ludvig Aberg",             false, false],
  ["Kyle O'Neil",        "Rickie Fowler",            false, false],
  ["Jay Waugh",          "Scottie Scheffler",       true,  false],
  ["Robert Chambers",    "Scottie Scheffler",       true,  false],
  ["Ben Engler",         "Tommy Fleetwood",         false, false],
  ["Chad Gauvin",        "Cam Young",               false, true],   # auto
  ["Chad Squires Sr.",   "Harris English",           false, false],
  ["Matt VanDixhorn",    "Justin Rose",             false, false],
  ["Fernando Gomez",     "Cam Young",               true,  false],
  ["Jack Murphy",        "Rory McIlroy",             false, false],
  ["Anthony Cerruti",    "Cam Young",               true,  false],
  ["Jack Gunst",         "Bryson DeChambeau",       false, false],
  ["Reise Kelly",        "Ludvig Aberg",             false, false],
  ["Graeme Watson",      "Bryson DeChambeau",       true,  false],
  ["Roberto Scheinerle", "Scottie Scheffler",       true,  false],
  ["Jason DuBois",       "Scottie Scheffler",       true,  false],
  ["Michael Barile",     "Tyrrel Hatton",            false, false],
  ["JT Ozerities",       "Justin Thomas",            false, false],
  ["Brian Feeley",       "Jon Rahm",                true,  false],
  ["Daniel Jaffe",       "Tommy Fleetwood",         false, false],
  ["Nick Cristobal",     "Jordan Spieth",            false, false],
  ["Katie King",         "Bryson DeChambeau",       false, false],
  ["Tim Cooney",         "Scottie Scheffler",       true,  false],
  ["Paul Cacciotti",     "Tyrrell Hatton",           false, false],
  ["Jerry Heath",        "Scottie Scheffler",       true,  false],
  ["Nick Scarimbolo",    "Scottie Scheffler",       false, true],   # auto
  ["Adam Feeley",        "Joaquin Niemann",          false, false],
  ["Dustin Daniels",     "Jon Rahm",                false, false],
  ["Mike Davis",         "Jon Rahm",                false, false],
  ["Daren Wamsley",      "Cam Young",               false, false],
  ["Dylan Linke",        "Patrick Cantlay",          true,  false],
  ["Kevin Lang",         "Scottie Scheffler",       true,  false],
  ["Ryan Finstad",       "Cam Young",               true,  false],
  ["Dan Jaffe",          "Rickie Fowler",            false, false],
  ["Dylan Chambers",     "Scottie Scheffler",       false, false],
].freeze

errors  = []
created = 0
skipped = 0

PICKS_W13.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name)
  unless user
    errors << "User not found: #{player_name}"
    next
  end

  golfer_name = ALIASES_W13[golfer_raw] || golfer_raw
  golfer = Golfer.find_by(name: golfer_name)
  unless golfer
    golfer = Golfer.create!(name: golfer_name)
    puts "Created golfer: #{golfer_name}"
  end

  if Pick.exists?(user: user, tournament: tournament)
    skipped += 1
    next
  end

  Pick.new(
    user:           user,
    tournament:     tournament,
    golfer:         golfer,
    is_double_down: is_dd,
    auto_assigned:  is_auto
  ).save!(validate: false)
  created += 1
end

puts "\nCreated: #{created}, Skipped: #{skipped}"
errors.each { |e| puts "ERROR: #{e}" }

# Fix DD counts
User.where(admin: false).each do |u|
  used    = Pick.where(user_id: u.id, is_double_down: true).count
  correct = 5 - used
  u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
end
puts "DD counts updated."

puts "\nWeek 13 picks (#{tournament.name}):"
tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
  dd   = p.is_double_down? ? " [DD]" : ""
  auto = p.auto_assigned?  ? " (auto)" : ""
  puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
end
