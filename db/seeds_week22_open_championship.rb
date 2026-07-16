tournament = Tournament.find_by!(week_number: 22)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W22 = {
  "Robert Macintyre"  => "Robert MacIntyre",
  "Xander Schuaffele" => "Xander Schauffele",
  "Cam Young"          => "Cameron Young",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W22 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W22 = [
  ["Kyle Frazho",        "Matt Fitzpatrick",   true,  false],
  ["Andy Stepic",        "Viktor Hovland",     true,  false],
  ["Mike Feeley",        "Robert Macintyre",   false, false],
  ["CJ Sturges",         "Tyrrell Hatton",     true,  false],
  ["Bree Svigelj",       "Rory McIlroy",       true,  false],
  ["Tom Murphy",         "Robert Macintyre",   false, false],
  ["Michael Amira",      "Tyrrell Hatton",     false, false],
  ["Jim Cooke",          "Chris Gotterup",     false, false],
  ["Pat Lang",           "Collin Morikawa",    true,  false],
  ["Michael Lukas",      "Justin Rose",        false, false],
  ["Kyle Shaffer",       "Justin Rose",        false, false],
  ["Justin Mungarro",    "Viktor Hovland",     false, false],
  ["Mike Murphy",        "Matt Fitzpatrick",   false, false],
  ["Andrew Lunder",      "Justin Rose",        false, false],
  ["Luke Grasso",        "Rory McIlroy",       true,  false],
  ["Fernando Gomez",     "Matt Fitzpatrick",   true,  false],
  ["Zach Jonas",         "Matt Fitzpatrick",   true,  false],
  ["Jimmy Nelson",       "Jon Rahm",           true,  false],
  ["Kevin Hobbs",        "Robert Macintyre",   false, false],
  ["Chad Squires Jr.",   "Rory McIlroy",       true,  false],
  ["Nate Hill",          "Robert Macintyre",   true,  false],
  ["Jason Mungarro",     "Rory McIlroy",       true,  false],
  ["Kyle O'Neil",        "Matt Fitzpatrick",   false, false],
  ["Chad Squires Sr.",   "Rory McIlroy",       false, false],   # would exceed 5 DD limit; saved as non-DD per instruction
  ["Brian Szepelak",     "Robert MacIntyre",   true,  false],
  ["Robert Chambers",    "Matt Fitzpatrick",   false, false],
  ["Matt VanDixhorn",    "Rory McIlroy",       true,  false],
  ["Roberto Schnierle",  "Justin Rose",        false, false],
  ["Jay Waugh",          "Rory McIlroy",       true,  false],
  ["Brian Feeley",       "Justin Rose",        false, false],
  ["Ben Engler",         "Scottie Scheffler",  true,  false],
  ["Jack Gunst",         "Joaquin Niemann",    false, false],
  ["Anthony Cerruti",    "Collin Morikawa",    true,  false],
  ["Jack Murphy",        "Robert Macintyre",   false, false],
  ["Reise Kelly",        "Jon Rahm",           true,  false],
  ["Katie King",         "Justin Rose",        false, false],
  ["Mike Davis",         "Tyrrell Hatton",     true,  false],
  ["JT Ozerities",       "Rory McIlroy",       false, true],    # already used Min Woo Lee (wk4); auto-assigned most-picked golfer this week
  ["Adam Feeley",        "Rory McIlroy",       true,  false],
  ["Graeme Watson",      "Rory McIlroy",       true,  false],
  ["Nick Cristobal",     "Rory McIlroy",       false, false],
  ["Chad Gauvin",        "Viktor Hovland",     true,  false],
  ["Paul Cacciotti",     "Min Woo Lee",        true,  false],
  ["Michael Barile",     "Viktor Hovland",     false, false],
  ["Jason DuBois",       "Xander Schuaffele",  false, false],
  ["Dustin Daniels",     "Robert MacIntyre",   true,  false],
  ["Jerry Heath",        "Justin Rose",        false, false],
  ["Tim Cooney",         "Rory McIlroy",       true,  false],
  ["Dylan Linke",        "Matt Fitzpatrick",   true,  false],
  ["Daniel Jaffe",       "Wyndham Clark",      false, false],
  ["Dan Jaffe",          "Collin Morikawa",    true,  false],
  ["Ryan Finstad",       "Justin Rose",        false, false],
  ["Kevin Lang",         "Bryson DeChambeau",  false, false],
  ["Daren Wamsley",      "Matt Fitzpatrick",   false, true],    # auto
  ["Dylan Chambers",     "Cam Young",          true,  false],
  ["Nick Scarimbolo",    "Matt Fitzpatrick",   false, true],    # auto
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 22 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W22.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W22[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W22[golfer_raw] || golfer_raw
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
PICKS_W22.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W22[player_raw] || player_raw
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

  puts "\nWeek 22 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
