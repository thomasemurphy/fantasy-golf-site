tournament = Tournament.find_by!(week_number: 16)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W16 = {
  "Ludvig Aberg"        => "Ludvig Åberg",
  "Xander Schuaffele"   => "Xander Schauffele",   # typo
  "Hideki Matsuayama"   => "Hideki Matsuyama",    # typo
  "Cam Young"           => "Cameron Young",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W16 = [
  ["Kyle Frazho",        "Patrick Cantlay",     false, false],
  ["Andy Stepic",        "Patrick Cantlay",     false, false],
  ["Mike Feeley",        "Patrick Cantlay",     false, false],
  ["CJ Sturges",         "Matt Fitzpatrick",    false, false],
  ["Michael Amira",      "Matt Fitzpatrick",    false, false],
  ["Tom Murphy",         "Rory McIlroy",        true,  false],  # DD
  ["Jim Cooke",          "Rory McIlroy",        true,  false],  # DD
  ["Bree Svigelj",       "Patrick Cantlay",     false, false],
  ["Pat Lang",           "Justin Thomas",       false, false],
  ["Michael Lukas",      "Rory McIlroy",        true,  false],  # DD
  ["Justin Mungarro",    "Patrick Cantlay",     false, false],
  ["Kyle Shaffer",       "Xander Schuaffele",   false, false],
  ["Mike Murphy",        "Russell Henley",      false, false],
  ["Andrew Lunder",      "Russell Henley",      false, false],
  ["Luke Grasso",        "Tommy Fleetwood",     false, false],
  ["Jimmy Nelson",       "Scottie Scheffler",   true,  false],  # DD
  ["Nate Hill",          "Patrick Cantlay",     false, false],
  ["Jason Mungarro",     "Hideki Matsuayama",   false, false],
  ["Kevin Hobbs",        "Tommy Fleetwood",     false, false],
  ["Chad Squires Jr.",   "Ludvig Aberg",        false, false],
  ["Zach Jonas",         "Si Woo Kim",          false, false],
  ["Brian Szepelak",     "Rory McIlroy",        true,  false],  # DD
  ["Kyle O'Neil",        "Rory McIlroy",        true,  false],  # DD
  ["Brian Feeley",       "Ludvig Aberg",        false, false],
  ["Jay Waugh",          "Xander Schauffele",   true,  false],  # DD
  ["Robert Chambers",    "Rory McIlroy",        false, false],
  ["Matt VanDixhorn",    "Ludvig Aberg",        false, false],
  ["Roberto Scheinerle", "Matt Fitzpatrick",    false, false],
  ["Chad Squires Sr.",   "Scottie Scheffler",   true,  false],  # DD
  ["Anthony Cerruti",    "JJ Spaun",            false, false],
  ["Ben Engler",         "Rory McIlroy",        true,  false],  # DD
  ["Katie King",         "Patrick Cantlay",     false, true],   # auto
  ["JT Ozerities",       "Jordan Spieth",       false, false],
  ["Jack Gunst",         "Scottie Scheffler",   true,  false],  # DD
  ["Jack Murphy",        "Cam Young",           false, false],
  ["Fernando Gomez",     "Rory McIlroy",        true,  false],  # DD
  ["Chad Gauvin",        "Xander Schuaffele",   false, true],   # auto
  ["Reise Kelly",        "Cam Young",           false, false],
  ["Tim Cooney",         "Ludvig Aberg",        false, false],
  ["Graeme Watson",      "Xander Schuaffele",   false, false],
  ["Jason DuBois",       "Cam Young",           false, false],
  ["Nick Cristobal",     "Cam Young",           false, false],
  ["Michael Barile",     "Scottie Scheffler",   true,  false],  # DD
  ["Paul Cacciotti",     "Rory McIlroy",        false, false],
  ["Mike Davis",         "Xander Schauffele",   true,  false],  # DD
  ["Dustin Daniels",     "Matt Fitzpatrick",    false, false],
  ["Daniel Jaffe",       "Scottie Scheffler",   true,  false],  # DD
  ["Jerry Heath",        "Patrick Cantlay",     false, true],   # auto
  ["Adam Feeley",        "Xander Schauffele",   true,  false],  # DD
  ["Daren Wamsley",      "Patrick Cantlay",     false, true],   # auto
  ["Kevin Lang",         "Cam Young",           true,  false],  # DD
  ["Nick Scarimbolo",    "Rory McIlroy",        false, true],   # auto
  ["Ryan Finstad",       "Xander Schauffele",   false, false],
  ["Dylan Linke",        "Sam Burns",           false, false],
  ["Dan Jaffe",          "Scottie Scheffler",   true,  false],  # DD
  ["Dylan Chambers",     "Justin Rose",         false, false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 16 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W16.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W16[golfer_raw] || golfer_raw
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
PICKS_W16.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 16 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
