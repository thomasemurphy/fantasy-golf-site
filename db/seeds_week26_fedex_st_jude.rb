tournament = Tournament.find_by!(week_number: 26)

# Golfer name typo corrections → canonical DB names
ALIASES_W26 = {
  "Robert MacIntrye"  => "Robert MacIntyre",
  "Ludvig Aberg"       => "Ludvig Åberg",
  "Cam Young"          => "Cameron Young",
  "Xander Schuaffele"  => "Xander Schauffele",
  "Hideki Mastuyama"   => "Hideki Matsuyama",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W26 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W26 = [
  ["Kyle Frazho",       "Sam Burns",          false, false],
  ["Andy Stepic",       "Robert MacIntrye",   false, false],
  ["Mike Feeley",       "Wyndham Clark",      false, false],
  ["CJ Sturges",        "Ludvig Aberg",       false, false],
  ["Bree Svigelj",      "Viktor Hovland",     false, false],
  ["Tom Murphy",        "Xander Schauffele",  true,  false], # DD
  ["Michael Amira",     "Hideki Matsuyama",   false, false],
  ["Jim Cooke",         "Collin Morikawa",    true,  false], # DD
  ["Pat Lang",          "Sam Burns",          false, false],
  ["Michael Lukas",     "Sam Burns",          true,  false], # DD
  ["Justin Mungarro",   "Cam Young",          true,  false], # DD
  ["Luke Grasso",       "Justin Rose",        true,  false], # DD
  ["Kyle Shaffer",      "Jordan Spieth",      false, false],
  ["Mike Murphy",       "Tom Kim",            false, false],
  ["Andrew Lunder",     "Hideki Matsuyama",   false, false],
  ["Fernando Gomez",    "Hideki Matsuyama",   false, false],
  ["Zach Jonas",        "Xander Schuaffele",  true,  false], # DD
  ["Jimmy Nelson",      "Sam Burns",          false, true],  # auto
  ["Kevin Hobbs",       "Russell Henley",     false, false],
  ["Nate Hill",         "Matt Fitzpatrick",   false, false],
  ["Chad Squires Jr.",  "Sam Burns",          false, false],
  ["Jason Mungarro",    "Wyndham Clark",      false, false],
  ["Ben Engler",        "Hideki Mastuyama",   false, false],
  ["Chad Squires Sr.",  "Sam Burns",          false, false],
  ["Brian Szepelak",    "Hideki Matsuyama",   false, false],
  ["Kyle O’Neil",       "Tommy Fleetwood",    true,  false], # DD
  ["Matt VanDixhorn",   "Sam Burns",          false, false],
  ["Robert Chambers",   "Viktor Hovland",     true,  false], # DD
  ["Roberto Schnierle", "Hideki Matsuyama",   false, true],  # auto (already used Sam Burns)
  ["Jay Waugh",         "Hideki Matsuyama",   false, true],  # auto (already used Sam Burns)
  ["Brian Feeley",      "Sam Burns",          false, false],
  ["Anthony Cerruti",   "Hideki Matsuyama",   true,  false], # DD
  ["Jack Murphy",       "Hideki Matsuyama",   false, false],
  ["Jack Gunst",        "Cam Young",          true,  false], # DD
  ["Reise Kelly",       "Russell Henley",     false, false],
  ["JT Ozerities",      "Sam Burns",          true,  false], # DD
  ["Mike Davis",        "Viktor Hovland",     false, true],  # auto (already used Koivun & Sam Burns)
  ["Katie King",        "Sam Burns",          false, false],
  ["Adam Feeley",       "Cam Young",          false, false],
  ["Graeme Watson",     "Viktor Hovland",     false, false],
  ["Nick Cristobal",    "Wyndham Clark",      true,  false], # DD
  ["Dustin Daniels",    "Cam Young",          false, false],
  ["Paul Cacciotti",    "Cameron Young",      false, true],  # auto (already used Sam Burns & Matsuyama)
  ["Jason DuBois",      "Hideki Mastuyama",   false, false],
  ["Michael Barile",    "Collin Morikawa",    true,  false], # DD
  ["Chad Gauvin",       "Justin Rose",        false, false],
  ["Dylan Chambers",    "Akshay Bhatia",      false, false],
  ["Jerry Heath",       "Sam Burns",          false, true],  # auto
  ["Tim Cooney",        "Wyndham Clark",      false, true],  # auto (already used Sam Burns, Matsuyama & Cam Young)
  ["Dylan Linke",       "Hideki Matsuyama",   false, true],  # auto (already used Sam Burns)
  ["Daniel Jaffe",      "Hideki Matsuyama",   true,  false], # DD
  ["Dan Jaffe",         "Matt Fitzpatrick",   false, false],
  ["Kevin Lang",        "Sam Burns",          false, true],  # auto
  ["Ryan Finstad",      "Scottie Scheffler",  true,  false], # DD
  ["Daren Wamsley",     "Wyndham Clark",      false, true],  # auto (already used Sam Burns, Matsuyama & Cam Young)
  ["Nick Scarimbolo",   "Hideki Matsuyama",   false, true],  # auto (already used Sam Burns)
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 26 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W26.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W26[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W26[golfer_raw] || golfer_raw
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
    errors << "ALREADY USED: #{player_raw} already picked #{golfer_name} earlier this season"
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
PICKS_W26.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W26[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  next unless user
  existing_dd = Pick.where(user_id: user.id, is_double_down: true).where.not(tournament_id: tournament.id).count
  total = existing_dd + dd_planned[user.id]
  dd_warnings << "DD OVER LIMIT: #{player_raw} would have #{total} DDs (max 5)" if total > 5
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

  puts "\nWeek 26 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
