tournament = Tournament.find_by!(week_number: 25)

# Golfer name typo corrections → canonical DB names
ALIASES_W25 = {
  "Cam Young" => "Cameron Young",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W25 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W25 = [
  ["Mike Feeley",       "Ben Griffin",       false, false],
  ["Andy Stepic",       "Hideki Matsuyama",  false, false],
  ["Kyle Frazho",       "Tom Kim",           false, false],
  ["CJ Sturges",        "Jackson Koivun",    false, false],
  ["Bree Svigelj",      "Ryan Gerard",       false, false],
  ["Tom Murphy",        "Patrick Cantlay",   false, false],
  ["Michael Amira",     "Jackson Koivun",    false, false],
  ["Jim Cooke",         "Ben Griffin",       false, false],
  ["Pat Lang",          "Tom Kim",           false, false],
  ["Michael Lukas",     "Ryan Gerard",       false, false],
  ["Justin Mungarro",   "Ben Kohles",        false, false],
  ["Luke Grasso",       "Ben Griffin",       false, false],
  ["Kyle Shaffer",      "Ben Griffin",       false, false],
  ["Mike Murphy",       "Jackson Koivun",    false, false],
  ["Andrew Lunder",     "Jackson Koivun",    false, false],
  ["Fernando Gomez",    "Brooks Koepka",     false, false],
  ["Zach Jonas",        "Jackson Koivun",    false, true],  # auto
  ["Jimmy Nelson",      "Jackson Koivun",    false, true],  # auto
  ["Kevin Hobbs",       "Jackson Koivun",    false, true],  # auto
  ["Nate Hill",         "Jackson Koivun",    false, false],
  ["Chad Squires Jr.",  "Ben Griffin",       false, false],
  ["Jason Mungarro",    "Justin Thomas",     false, false],
  ["Chad Squires Sr.",  "Rickie Fowler",     false, false],
  ["Ben Engler",        "Sungjae Im",        false, false],
  ["Brian Szepelak",    "Sungjae Im",        false, false],
  ["Kyle O'Neil",       "Keegan Bradley",    false, false],
  ["Matt VanDixhorn",   "Jackson Koivun",    false, true],  # auto
  ["Robert Chambers",   "Jackson Koivun",    false, false],
  ["Roberto Schnierle", "Jackson Koivun",    false, false],
  ["Brian Feeley",      "Justin Thomas",     false, false],
  ["Jay Waugh",         "Tom Kim",           false, false],
  ["Anthony Cerruti",   "Jackson Koivun",    false, false],
  ["Jack Gunst",        "Alex Fitzpatrick",  false, false],
  ["Jack Murphy",       "Tom Kim",           false, false],
  ["Reise Kelly",       "Sungjae Im",        false, false],
  ["JT Ozerities",      "Alex Fitzpatrick",  false, false],
  ["Mike Davis",        "Jackson Koivun",    false, true],  # auto
  ["Katie King",        "Ben Griffin",       false, false],
  ["Adam Feeley",       "Harris English",    false, false],
  ["Graeme Watson",     "Tom Kim",           false, false],
  ["Nick Cristobal",    "Justin Thomas",     true,  false], # DD
  ["Dustin Daniels",    "Jackson Koivun",    false, false],
  ["Michael Barile",    "Ben Griffin",       false, false],
  ["Chad Gauvin",       "Seamus Power",      false, false],
  ["Paul Cacciotti",    "Hideki Matsuyama",  false, false],
  ["Dylan Chambers",    "Jackson Koivun",    false, true],  # auto
  ["Jason DuBois",      "Tom Kim",           false, false],
  ["Jerry Heath",       "Jackson Koivun",    false, true],  # auto
  ["Tim Cooney",        "Jackson Koivun",    false, true],  # auto
  ["Dylan Linke",       "Jackson Koivun",    false, true],  # auto
  ["Daniel Jaffe",      "Cam Young",         false, false],
  ["Dan Jaffe",         "Cam Young",         false, false],
  ["Kevin Lang",        "Jackson Koivun",    false, true],  # auto
  # Justin Thomas already used by Ryan Finstad in week 15 → auto to most-popular pick this week
  ["Ryan Finstad",      "Jackson Koivun",    false, true],  # auto
  ["Daren Wamsley",     "Jackson Koivun",    false, true],  # auto
  ["Nick Scarimbolo",   "Jackson Koivun",    false, true],  # auto
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 25 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W25.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W25[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W25[golfer_raw] || golfer_raw
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
PICKS_W25.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W25[player_raw] || player_raw
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

  puts "\nWeek 25 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
