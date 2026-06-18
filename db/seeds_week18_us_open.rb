tournament = Tournament.find_by!(week_number: 18)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W18 = {
  "Cam Smith"          => "Cameron Smith",
  "Cam Young"          => "Cameron Young",
  "Xander Schuaffele"  => "Xander Schauffele",
  "Ludvig Aberg"       => "Ludvig Åberg",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W18 = [
  ["Kyle Frazho",        "Brooks Koepka",      false, false],
  ["Andy Stepic",        "Jon Rahm",           true,  false],
  ["Mike Feeley",        "Rory McIlroy",       true,  false],
  ["Tom Murphy",         "Russell Henley",     false, false],
  ["CJ Sturges",         "Tommy Fleetwood",    true,  false],
  ["Michael Amira",      "Jon Rahm",           false, false],
  ["Jim Cooke",          "Jon Rahm",           false, false],
  ["Bree Svigelj",       "Tommy Fleetwood",    false, false],
  ["Michael Lukas",      "Patrick Reed",       false, false],
  ["Pat Lang",           "Jon Rahm",           false, false],
  ["Justin Mungarro",    "JJ Spaun",           false, false],
  ["Kyle Shaffer",       "Jon Rahm",           true,  false],
  ["Mike Murphy",        "Jon Rahm",           true,  false],
  ["Andrew Lunder",      "Matt Fitzpatrick",   false, false],
  ["Luke Grasso",        "Jon Rahm",           true,  false],
  ["Jimmy Nelson",       "Rory McIlroy",       true,  false],
  ["Nate Hill",          "Patrick Reed",       true,  false],
  ["Kevin Hobbs",        "Jon Rahm",           true,  false],
  ["Chad Squires Jr.",   "Jon Rahm",           true,  false],
  ["Jason Mungarro",     "Jon Rahm",           false, false],
  ["Brian Szepelak",     "Patrick Reed",       false, false],
  ["Zach Jonas",         "Scottie Scheffler",  true,  false],
  ["Kyle O'Neil",        "Tyrrell Hatton",     false, false],
  ["Chad Squires Sr.",   "Tommy Fleetwood",    true,  false],
  ["Brian Feeley",       "Cam Smith",          false, false],
  ["Robert Chambers",    "Tommy Fleetwood",    true,  false],
  ["Jay Waugh",          "Jon Rahm",           true,  false],
  ["Matt VanDixhorn",    "Cam Young",          true,  false],
  ["Roberto Scheinerle", "Xander Schuaffele",  true,  false],
  ["Ben Engler",         "Patrick Reed",       true,  false],
  ["Jack Murphy",        "Jon Rahm",           true,  false],
  ["Anthony Cerruti",    "Adam Scott",         false, false],
  ["Jack Gunst",         "Matt Fitzpatrick",   true,  false],
  ["Fernando Gomez",     "Wyndham Clark",      false, false],
  ["Katie King",         "Viktor Hovland",     false, false],
  ["JT Ozerities",       "Justin Rose",        false, false],
  ["Chad Gauvin",        "Jon Rahm",           true,  false],
  ["Reise Kelly",        "Tommy Fleetwood",    true,  false],
  ["Tim Cooney",         "Cam Young",          false, false],
  ["Graeme Watson",      "Ludvig Aberg",       true,  false],
  ["Michael Barile",     "Xander Schuaffele",  true,  false],
  ["Jason DuBois",       "Matt Fitzpatrick",   false, false],
  ["Paul Cacciotti",     "Jon Rahm",           false, false],
  ["Nick Cristobal",     "Scottie Scheffler",  true,  false],
  ["Daniel Jaffe",       "Patrick Reed",       false, false],
  ["Mike Davis",         "Scottie Scheffler",  true,  false],
  ["Dustin Daniels",     "Scottie Scheffler",  true,  false],
  ["Adam Feeley",        "Scottie Scheffler",  true,  false],
  ["Jerry Heath",        "Tommy Fleetwood",    true,  false],
  ["Daren Wamsley",      "Jon Rahm",           false, true],   # auto
  ["Dylan Linke",        "Scottie Scheffler",  true,  false],
  ["Kevin Lang",         "Jon Rahm",           false, false],
  ["Dan Jaffe",          "Tommy Fleetwood",    true,  false],
  ["Ryan Finstad",       "Rory McIlroy",       true,  false],
  ["Nick Scarimbolo",    "Patrick Reed",       false, true],   # auto (Rahm already used wk8 → next most-popular available)
  ["Dylan Chambers",     "Jon Rahm",           true,  false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 18 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W18.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W18[golfer_raw] || golfer_raw
  golfer = Golfer.find_by(name: golfer_name)

  if golfer.nil?
    if apply
      golfer = Golfer.create!(name: golfer_name)
      puts "  created golfer: #{golfer_name}"
    else
      puts "  WOULD CREATE golfer: #{golfer_name}"
    end
  end

  # once-per-season rule (also a unique DB index → would hard-fail)
  if golfer && Pick.where(user_id: user.id, golfer_id: golfer.id).exists?
    errors << "ALREADY USED: #{player_name} already picked #{golfer_name} earlier this season"
  end

  if Pick.exists?(user: user, tournament: tournament)
    skipped += 1
    next
  end

  dd_planned[user.id] += 1 if is_dd

  if apply
    Pick.new(
      user:           user,
      tournament:     tournament,
      golfer:         golfer,
      is_double_down: is_dd,
      auto_assigned:  is_auto
    ).save!(validate: false)
    created += 1
  end
end

# Double-down sanity: ensure nobody exceeds 5 for the season
dd_warnings = []
PICKS_W18.map { |p| p[0] }.uniq.each do |player_name|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  next unless user
  existing_dd = Pick.where(user_id: user.id, is_double_down: true).where.not(tournament_id: tournament.id).count
  total = existing_dd + dd_planned[user.id]
  dd_warnings << "DD OVER LIMIT: #{player_name} would have #{total} DDs (max 5)" if total > 5
end

puts ""
puts "Created: #{created}, Skipped(existing): #{skipped}"
(errors + dd_warnings).each { |e| puts "  !! #{e}" }
puts "  (no blocking issues)" if (errors + dd_warnings).empty?

if apply
  # Recompute double_downs_remaining for everyone (controller decrement is bypassed)
  User.where(admin: false).each do |u|
    used    = Pick.where(user_id: u.id, is_double_down: true).count
    correct = 5 - used
    u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
  end
  puts "\nDD counts recalculated."

  tournament.update!(status: "in_progress")
  puts "Tournament status: #{tournament.status}"

  puts "\nWeek 18 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
