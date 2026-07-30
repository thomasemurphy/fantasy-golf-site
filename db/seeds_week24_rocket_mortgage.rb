tournament = Tournament.find_by!(week_number: 24)

# Golfer name typo corrections → canonical DB names
ALIASES_W24 = {
  "SI Woo Kim"             => "Si Woo Kim",
  "Aldrich Potgeiter"      => "Aldrich Potgieter",
  "Ryo Histsune"           => "Ryo Hisatsune",
  "Christian Bezuidenhout" => "Christiaan Bezuidenhout",
}.freeze

# Player name typo corrections → canonical DB names
PLAYER_ALIASES_W24 = {
  "Roberto Schnierle" => "Roberto Scheinerle",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W24 = [
  ["Andy Stepic",        "Jackson Koivun",         false, false],
  ["Kyle Frazho",        "Ben Griffin",            false, false],
  ["Mike Feeley",        "Sungjae Im",             false, false],
  ["CJ Sturges",         "SI Woo Kim",             false, false],
  ["Bree Svigelj",       "Si Woo Kim",             false, false],
  ["Tom Murphy",         "Chris Gotterup",         false, false],
  ["Michael Amira",      "Chris Gotterup",         false, false],
  ["Jim Cooke",          "Jake Knapp",             false, false],
  ["Pat Lang",           "Rickie Fowler",          false, false],
  ["Michael Lukas",      "Wyndham Clark",          false, false],
  ["Luke Grasso",        "Chris Gotterup",         false, false],
  ["Kyle Shaffer",       "Chris Gotterup",         false, false],
  ["Justin Mungarro",    "Ryan Gerard",            false, false],
  ["Mike Murphy",        "Si Woo Kim",             false, false],
  ["Andrew Lunder",      "Jake Knapp",             false, false],
  ["Fernando Gomez",     "Si Woo Kim",             false, false],
  ["Zach Jonas",         "Jake Knapp",             false, false],
  ["Jimmy Nelson",       "Ben Griffin",            false, false],
  ["Kevin Hobbs",        "Sudarshan Yellamaraju",  false, false],
  ["Chad Squires Jr.",   "Chris Gotterup",         false, false],
  ["Nate Hill",          "Si Woo Kim",             false, false],
  ["Jason Mungarro",     "Chris Gotterup",         false, false],
  ["Chad Squires Sr.",   "Aldrich Potgieter",      false, false],
  ["Ben Engler",         "Jake Knapp",             false, false],
  ["Brian Szepelak",     "Chris Gotterup",         false, false],
  ["Kyle O'Neil",        "Chris Gotterup",         false, false],
  ["Matt VanDixhorn",    "Patrick Cantlay",        false, false],
  ["Robert Chambers",    "Chris Gotterup",         false, false],
  ["Roberto Schnierle",  "Chris Gotterup",         false, false],
  ["Jay Waugh",          "Jackson Koivun",         false, false],
  ["Brian Feeley",       "Russell Henley",         false, false],
  ["Anthony Cerruti",    "Christian Bezuidenhout", false, false],
  ["Jack Gunst",         "Wyndham Clark",          false, false],
  ["Jack Murphy",        "Chris Gotterup",         false, false],
  ["JT Ozerities",       "Cam Davis",              false, false],
  ["Reise Kelly",        "Davis Thompson",         false, false],
  ["Mike Davis",         "Chris Gotterup",         false, false],
  ["Katie King",         "Jackson Koivun",         false, false],
  ["Adam Feeley",        "Patrick Cantlay",        false, false],
  ["Graeme Watson",      "Aldrich Potgeiter",      false, false],
  # Russell Henley already used by Nick Cristobal in week 9 → auto to most-popular pick this week
  ["Nick Cristobal",     "Chris Gotterup",         false, true],  # auto
  ["Chad Gauvin",        "Aldrich Potgeiter",      false, false],
  ["Paul Cacciotti",     "Chris Gotterup",         false, false],
  ["Dustin Daniels",     "Michael Kim",            false, false],
  ["Dylan Chambers",     "Brad Dalke",             false, false],
  ["Jason DuBois",       "Ryo Histsune",           false, false],
  ["Michael Barile",     "Hideki Matsuyama",       false, false],
  ["Jerry Heath",        "Chris Gotterup",         false, true],  # auto
  ["Tim Cooney",         "Akshay Bhatia",          false, false],
  # Chris Gotterup already used by Dylan Linke in week 6 → auto cascades past tied 2nd-most (Si Woo Kim/Jake Knapp) to Si Woo Kim
  ["Dylan Linke",        "Si Woo Kim",             false, true],  # auto
  ["Daniel Jaffe",       "Jake Knapp",             false, false],
  ["Dan Jaffe",          "Jackson Koivun",         false, false],
  ["Kevin Lang",         "Chris Gotterup",         false, true],  # auto
  ["Ryan Finstad",       "Patrick Cantlay",        false, false],
  ["Daren Wamsley",      "Chris Gotterup",         false, true],  # auto
  ["Nick Scarimbolo",    "Chris Gotterup",         false, true],  # auto
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 24 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W24.each do |player_raw, golfer_raw, is_dd, is_auto|
  player_name = PLAYER_ALIASES_W24[player_raw] || player_raw
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_raw}"
    next
  end

  golfer_name = ALIASES_W24[golfer_raw] || golfer_raw
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
PICKS_W24.map { |p| p[0] }.uniq.each do |player_raw|
  player_name = PLAYER_ALIASES_W24[player_raw] || player_raw
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

  puts "\nWeek 24 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
