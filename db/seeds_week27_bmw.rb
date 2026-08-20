tournament = Tournament.find_by!(week_number: 27)

# Golfer name typo corrections → canonical DB names
ALIASES_W27 = {
  "Ludvig Aberg"       => "Ludvig Åberg",
  "Cam Young"          => "Cameron Young",
  "Xander Schuaffele"  => "Xander Schauffele",
  "Kristopher Reitan"  => "Kristoffer Reitan",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W27 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W27 = [
  ["Kyle Frazho",       "Xander Schauffele",  false, false],
  ["Mike Feeley",       "Tom Kim",            false, false],
  ["Andy Stepic",       "Jake Knapp",         false, false],
  ["CJ Sturges",        "Chris Gotterup",     true,  false], # DD
  ["Tom Murphy",        "Ludvig Aberg",       false, false],
  ["Bree Svigelj",      "Cam Young",          true,  false], # DD
  ["Michael Amira",     "Wyndham Clark",      false, false],
  ["Pat Lang",          "Viktor Hovland",     true,  false], # DD
  ["Michael Lukas",     "Xander Schauffele",  false, false],
  ["Jim Cooke",         "Tom Kim",            false, false],
  ["Justin Mungarro",   "Wyndham Clark",      false, false],
  ["Luke Grasso",       "Cam Young",          false, false],
  ["Kyle Shaffer",      "Akshay Bhatia",      false, false],
  ["Andrew Lunder",     "Tom Kim",            false, false],
  ["Mike Murphy",       "Sungjae Im",         false, false],
  ["Fernando Gomez",    "Sam Burns",          false, false],
  ["Chad Squires Jr.",  "Wyndham Clark",      false, false],
  ["Ryan Finstad",      "Viktor Hovland",     false, false],
  ["Nate Hill",         "Wyndham Clark",      false, false],
  ["Chad Squires Sr.",  "Chris Gotterup",     false, false],
  ["Jason Mungarro",    "Jake Knapp",         false, false],
  ["Kyle O’Neil",       "Wyndham Clark",      false, true],  # auto
  ["Ben Engler",        "Wyndham Clark",      false, false],
  ["Brian Szepelak",    "Xander Schuaffele",  false, false],
  ["Brian Feeley",      "Hideki Matsuyama",   true,  false], # DD
  ["JT Ozerities",      "Ludvig Aberg",       true,  false], # DD
  ["Robert Chambers",   "Tom Kim",            false, false],
  ["Roberto Schnierle", "Wyndham Clark",      false, true],  # auto
  ["Nick Cristobal",    "Sungjae Im",         false, false],
  ["Jack Murphy",       "Viktor Hovland",     true,  false], # DD
  ["Katie King",        "Hideki Matsuyama",   false, false],
  ["Jack Gunst",        "Tom Kim",            false, false],
  ["Reise Kelly",       "Scottie Scheffler",  false, false],
  ["Graeme Watson",     "Wyndham Clark",      false, true],  # auto
  ["Mike Davis",        "Bud Cauley",         false, false],
  ["Adam Feeley",       "Rickie Fowler",      false, false],
  ["Jason DuBois",      "Viktor Hovland",     false, false],
  ["Paul Cacciotti",    "Kristopher Reitan",  true,  false], # DD
  ["Chad Gauvin",       "Wyndham Clark",      false, true],  # auto
  ["Dylan Chambers",    "Wyndham Clark",      false, true],  # auto
  ["Daniel Jaffe",      "Ludvig Aberg",       true,  false], # DD
  ["Tim Cooney",        "Xander Schuaffele",  false, false],
  ["Dan Jaffe",         "Jake Knapp",         false, false],
  ["Kevin Lang",        "Wyndham Clark",      false, true],  # auto
].freeze

# Held back pending clarification — see chat: these would violate the
# once-per-season rule (Wyndham Clark/Sam Burns already used earlier this
# season by these users) or the 5-DD season limit (Zach Jonas).
PICKS_W27_HOLD = [
  ["Kevin Hobbs",       "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Jimmy Nelson",      "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Matt VanDixhorn",   "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Anthony Cerruti",   "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Jay Waugh",         "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Dustin Daniels",    "Sam Burns",          true,  false], # DD — ALREADY USED
  ["Michael Barile",    "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Jerry Heath",       "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Dylan Linke",       "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Daren Wamsley",     "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Nick Scarimbolo",   "Wyndham Clark",      false, true],  # auto — ALREADY USED
  ["Zach Jonas",        "Wyndham Clark",      true,  false], # DD — would be 6th DD this season (max 5)
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 27 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W27.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W27[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W27[golfer_raw] || golfer_raw
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
PICKS_W27.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W27[player_raw] || player_raw
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

  puts "\nWeek 27 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
