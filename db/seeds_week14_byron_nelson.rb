tournament = Tournament.find_by!(week_number: 14)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W14 = {
  "David Thompson"         => "Davis Thompson",        # typo: no PGA "David Thompson"
  "Christian Bezuidenhout" => "Christiaan Bezuidenhout",
  "Rasmus Hojgaard"        => "Rasmus Højgaard",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W14 = [
  ["Kyle Frazho",        "David Thompson",          false, false],
  ["Mike Feeley",        "Si Woo Kim",              false, false],
  ["Andy Stepic",        "Keith Mitchell",          false, false],
  ["Michael Amira",      "Jordan Spieth",           false, false],
  ["Tom Murphy",         "Brooks Koepka",           false, false],
  ["CJ Sturges",         "Sungjae Im",              false, false],
  ["Jim Cooke",          "Brooks Koepka",           false, false],
  ["Bree Svigelj",       "Christian Bezuidenhout",  false, false],
  ["Pat Lang",           "Jordan Spieth",           false, false],
  ["Michael Lukas",      "Brooks Koepka",           false, false],
  ["Mike Murphy",        "Jordan Spieth",           false, false],
  ["Andrew Lunder",      "Jordan Spieth",           false, false],
  ["Kyle Shaffer",       "Si Woo Kim",              false, false],
  ["Justin Mungarro",    "Si Woo Kim",              false, false],
  ["Jimmy Nelson",       "Jordan Spieth",           false, false],
  ["Nate Hill",          "Jordan Spieth",           false, true],   # auto
  ["Luke Grasso",        "Si Woo Kim",              false, false],
  ["Jason Mungarro",     "Jordan Spieth",           false, false],
  ["Kevin Hobbs",        "Austin Cook",             false, false],
  ["Chad Squires Jr.",   "Jordan Spieth",           false, false],
  ["Zach Jonas",         "Ryo Hisatsune",           false, false],
  ["Brian Szepelak",     "Ryo Hisatsune",           false, false],
  ["Jay Waugh",          "Michael Thorbjornsen",    false, false],
  ["Robert Chambers",    "Jordan Spieth",           false, false],
  ["Kyle O'Neil",        "Sungjae Im",              false, false],
  ["Brian Feeley",       "Si Woo Kim",              false, false],
  ["Ben Engler",         "Ryo Hisatsune",           false, false],
  ["Matt VanDixhorn",    "Si Woo Kim",              false, false],
  ["Chad Squires Sr.",   "Brooks Koepka",           false, false],
  ["Chad Gauvin",        "Tom Kim",                 false, false],
  ["Reise Kelly",        "Rasmus Hojgaard",         false, false],
  ["Jack Murphy",        "Brooks Koepka",           false, false],
  ["Fernando Gomez",     "Sungjae Im",              false, false],
  ["Roberto Scheinerle", "Jordan Spieth",           false, false],
  ["Anthony Cerruti",    "Si Woo Kim",              false, false],
  ["Jack Gunst",         "Si Woo Kim",              false, false],
  ["Graeme Watson",      "Tony Finau",              false, false],
  ["Jason DuBois",       "Jordan Spieth",           false, false],
  ["JT Ozerities",       "Brooks Koepka",           false, false],
  ["Michael Barile",     "Brooks Koepka",           false, false],
  ["Dustin Daniels",     "Jordan Spieth",           false, false],
  ["Mike Davis",         "Tom Kim",                 false, false],
  ["Tim Cooney",         "Brooks Koepka",           false, false],
  ["Nick Cristobal",     "Si Woo Kim",              false, false],
  ["Daniel Jaffe",       "Eric Cole",               false, false],
  ["Jerry Heath",        "Brooks Koepka",           true,  false],  # DD
  ["Katie King",         "Brooks Koepka",           false, false],
  ["Paul Cacciotti",     "Scottie Scheffler",       true,  false],  # DD
  ["Kevin Lang",         "Tony Finau",              false, false],
  ["Adam Feeley",        "Si Woo Kim",              false, false],
  ["Nick Scarimbolo",    "Jordan Spieth",           false, false],
  ["Daren Wamsley",      "Si Woo Kim",              false, false],
  ["Ryan Finstad",       "Ryo Hisatsune",           false, false],
  ["Dylan Linke",        "Jordan Spieth",           false, true],   # auto
  ["Dylan Chambers",     "Brooks Koepka",           false, false],
  ["Dan Jaffe",          "Brooks Koepka",           false, false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 14 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W14.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W14[golfer_raw] || golfer_raw
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
PICKS_W14.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 14 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
