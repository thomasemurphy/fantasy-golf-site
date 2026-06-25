tournament = Tournament.find_by!(week_number: 19)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W19 = {
  "Cam Young"     => "Cameron Young",
  "Ludvig Aberg"  => "Ludvig Åberg",
  "JT Poston"     => "J.T. Poston",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W19 = [
  ["Kyle Frazho",        "Justin Thomas",     false, false],
  ["Andy Stepic",        "Justin Thomas",     false, false],
  ["Mike Feeley",        "Sam Burns",         false, false],
  ["CJ Sturges",         "Cam Young",         false, false],
  ["Tom Murphy",         "Sam Burns",         false, false],
  ["Michael Amira",      "Sam Burns",         false, false],
  ["Jim Cooke",          "Si Woo Kim",        false, false],
  ["Bree Svigelj",       "Collin Morikawa",   true,  false],
  ["Michael Lukas",      "Keegan Bradley",    false, false],
  ["Pat Lang",           "Keegan Bradley",    false, false],
  ["Justin Mungarro",    "Ludvig Aberg",      false, false],
  ["Kyle Shaffer",       "Keegan Bradley",    false, false],
  ["Andrew Lunder",      "Justin Thomas",     false, false],
  ["Mike Murphy",        "Sam Burns",         false, false],
  ["Fernando Gomez",     "Tommy Fleetwood",   false, false],
  ["Luke Grasso",        "Justin Thomas",     false, false],
  ["Jimmy Nelson",       "Patrick Cantlay",   false, false],
  ["Zach Jonas",         "Sam Burns",         true,  false],
  ["Nate Hill",          "JT Poston",         false, false],
  ["Kevin Hobbs",        "Collin Morikawa",   false, false],
  ["Chad Squires Jr.",   "Hideki Matsuyama",  false, false],
  ["Kyle O'Neil",        "Cam Young",         false, false],
  ["Chad Squires Sr.",   "Justin Rose",       false, false],
  ["Jason Mungarro",     "Cam Young",         true,  false],
  ["Brian Szepelak",     "Aaron Rai",         false, false],
  ["Robert Chambers",    "Patrick Cantlay",   false, false],
  ["Roberto Scheinerle", "Sam Burns",         false, false],
  ["Brian Feeley",       "Aaron Rai",         false, false],
  ["Jay Waugh",          "Sam Burns",         false, false],
  ["Matt VanDixhorn",    "Matt Fitzpatrick",  false, false],
  ["Jack Gunst",         "Justin Thomas",     false, false],
  ["Ben Engler",         "Russell Henley",    false, false],
  ["Jack Murphy",        "Justin Rose",       false, false],
  ["Anthony Cerruti",    "Brian Harman",      false, false],
  ["Reise Kelly",        "Justin Thomas",     false, false],
  ["JT Ozerities",       "Sahith Theegala",   false, false],
  ["Katie King",         "Aaron Rai",         false, false],
  ["Nick Cristobal",     "Keegan Bradley",    false, false],
  ["Mike Davis",         "Matt Fitzpatrick",  false, false],
  ["Chad Gauvin",        "Patrick Cantlay",   false, false],
  ["Graeme Watson",      "Justin Thomas",     false, false],
  ["Dustin Daniels",     "Sam Burns",         false, true],   # auto (orig Justin Thomas already used wk15)
  ["Michael Barile",     "Patrick Cantlay",   false, false],
  ["Tim Cooney",         "Chris Gotterup",    false, false],
  ["Adam Feeley",        "Collin Morikawa",   false, false],
  ["Jason DuBois",       "Sam Burns",         true,  false],
  ["Dylan Linke",        "Cam Young",         false, false],
  ["Paul Cacciotti",     "Keith Mitchell",    false, false],
  ["Daniel Jaffe",       "Patrick Cantlay",   false, false],
  ["Jerry Heath",        "Justin Thomas",     false, true],   # auto (orig Wyndham Clark already used wk17)
  ["Dan Jaffe",          "Justin Thomas",     true,  false],
  ["Daren Wamsley",      "Aaron Rai",         false, false],
  ["Kevin Lang",         "Justin Thomas",     true,  false],
  ["Ryan Finstad",       "Matt Fitzpatrick",  false, false],
  ["Nick Scarimbolo",    "Sam Burns",         false, true],   # auto
  ["Dylan Chambers",     "Matt Fitzpatrick",  false, false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 19 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W19.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W19[golfer_raw] || golfer_raw
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
PICKS_W19.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 19 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
