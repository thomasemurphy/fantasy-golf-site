tournament = Tournament.find_by!(week_number: 23)

# Golfer name typo corrections → canonical DB names
ALIASES_W23 = {
  "Kieth Mitchell" => "Keith Mitchell",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W23 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W23 = [
  ["Kyle Frazho",        "Pierceson Coody",       false, false],
  ["Andy Stepic",        "Kurt Kitayama",         false, false],
  ["Mike Feeley",        "Hideki Matsuyama",      false, false],
  ["CJ Sturges",         "Kurt Kitayama",         false, false],
  ["Bree Svigelj",       "Taylor Moore",          false, false],
  ["Tom Murphy",         "Kurt Kitayama",         false, false],
  ["Michael Amira",      "Kurt Kitayama",         false, false],
  ["Jim Cooke",          "Sungjae Im",            false, false],
  ["Pat Lang",           "Kurt Kitayama",         false, false],
  ["Michael Lukas",      "Corey Conners",         false, false],
  ["Kyle Shaffer",       "Kurt Kitayama",         false, false],
  ["Justin Mungarro",    "Jordan Smith",          false, false],
  ["Luke Grasso",        "Hideki Matsuyama",      false, false],
  ["Mike Murphy",        "Maverick McNealy",      false, false],
  ["Andrew Lunder",      "Doug Ghim",             false, false],
  ["Fernando Gomez",     "Max Homa",              false, false],
  ["Jimmy Nelson",       "Kurt Kitayama",         false, true],  # auto
  ["Zach Jonas",         "Tom Kim",               false, false],
  ["Kevin Hobbs",        "Tom Kim",               false, false],
  ["Nate Hill",          "Lucas Glover",          false, false],
  ["Chad Squires Jr.",   "Kurt Kitayama",         false, false],
  ["Jason Mungarro",     "Tom Kim",               false, false],
  ["Ben Engler",         "Kurt Kitayama",         false, true],  # auto
  ["Chad Squires Sr.",   "Jake Knapp",            false, false],
  ["Kyle O'Neil",        "Max Homa",              false, false],
  ["Brian Szepelak",     "Tom Kim",               false, false],
  ["Robert Chambers",    "Sungjae Im",            false, false],
  ["Matt VanDixhorn",    "Tom Kim",               false, false],
  ["Roberto Schnierle",  "Kurt Kitayama",         false, false],
  ["Jay Waugh",          "Maverick McNealy",      false, false],
  ["Brian Feeley",       "Gary Woodland",         false, false],
  ["Anthony Cerruti",    "Max Homa",              false, false],
  ["Jack Gunst",         "Kurt Kitayama",         false, false],
  ["Jack Murphy",        "Kieth Mitchell",        false, false],
  ["Reise Kelly",        "Johnny Keefer",         false, false],
  ["Mike Davis",         "Maverick McNealy",      false, false],
  ["Katie King",         "Kurt Kitayama",         true,  false],
  ["Adam Feeley",        "Tony Finau",            false, false],
  ["JT Ozerities",       "Emiliano Grillo",       true,  false],
  ["Graeme Watson",      "Kurt Kitayama",         false, false],
  ["Nick Cristobal",     "Kurt Kitayama",         false, false],
  ["Chad Gauvin",        "Kurt Kitayama",         false, true],  # auto
  ["Dylan Chambers",     "Tony Finau",            false, false],
  ["Paul Cacciotti",     "Kurt Kitayama",         false, false],
  ["Jason DuBois",       "Sungjae Im",            false, false],
  ["Dustin Daniels",     "Gary Woodland",         false, false],
  ["Michael Barile",     "Jackson Suber",         false, false],
  ["Tim Cooney",         "Sudarshan Yellamaraju", false, false],
  ["Jerry Heath",        "Kurt Kitayama",         false, false],
  ["Dylan Linke",        "Maverick McNealy",      false, true],  # auto; most-popular (Kurt Kitayama) & 2nd (Tom Kim) already used by Dylan
  ["Daniel Jaffe",       "Jackson Suber",         false, false],
  ["Dan Jaffe",          "Tom Kim",               false, false],
  ["Kevin Lang",         "Gary Woodland",         true,  false],
  ["Ryan Finstad",       "Maverick McNealy",      false, false],
  ["Daren Wamsley",      "Kurt Kitayama",         false, true],  # auto
  ["Nick Scarimbolo",    "Kurt Kitayama",         false, true],  # auto
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 23 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W23.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W23[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W23[golfer_raw] || golfer_raw
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
PICKS_W23.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W23[player_raw] || player_raw
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

  puts "\nWeek 23 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
