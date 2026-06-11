tournament = Tournament.find_by!(week_number: 17)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W17 = {
  "Nicolai Hojgaard" => "Nicolai Højgaard",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W17 = [
  ["Kyle Frazho",        "Kristoffer Reitan",  false, false],
  ["Andy Stepic",        "Collin Morikawa",    false, false],
  ["Mike Feeley",        "Tommy Fleetwood",    false, false],
  ["Tom Murphy",         "Kristoffer Reitan",  false, false],
  ["CJ Sturges",         "Aaron Rai",          false, false],
  ["Michael Amira",      "Tommy Fleetwood",    false, false],
  ["Jim Cooke",          "Kristoffer Reitan",  false, false],
  ["Bree Svigelj",       "Wyndham Clark",      false, false],
  ["Michael Lukas",      "Eric Cole",          false, false],
  ["Pat Lang",           "Wyndham Clark",      false, false],
  ["Justin Mungarro",    "Tommy Fleetwood",    false, false],
  ["Kyle Shaffer",       "Wyndham Clark",      false, false],
  ["Mike Murphy",        "Justin Rose",        false, false],
  ["Andrew Lunder",      "Sam Burns",          false, false],
  ["Luke Grasso",        "Wyndham Clark",      false, false],
  ["Jimmy Nelson",       "Wyndham Clark",      false, true],   # auto
  ["Nate Hill",          "Kristoffer Reitan",  false, false],
  ["Kevin Hobbs",        "Wyndham Clark",      false, false],
  ["Jason Mungarro",     "Justin Rose",        false, false],
  ["Brian Szepelak",     "Wyndham Clark",      false, false],
  ["Zach Jonas",         "Alex Fitzpatrick",   false, false],
  ["Kyle O'Neil",        "Nicolai Hojgaard",   false, false],
  ["Chad Squires Jr.",   "Matt Fitzpatrick",   false, false],
  ["Brian Feeley",       "Corey Conners",      false, false],
  ["Robert Chambers",    "Sam Burns",          false, false],
  ["Jay Waugh",          "Wyndham Clark",      false, false],
  ["Matt VanDixhorn",    "Wyndham Clark",      false, false],
  ["Roberto Scheinerle", "Corey Conners",      false, false],
  ["Chad Squires Sr.",   "Matt Fitzpatrick",   false, false],
  ["Ben Engler",         "Alex Fitzpatrick",   false, false],
  ["Jack Gunst",         "Justin Rose",        false, false],
  ["Anthony Cerruti",    "Wyndham Clark",      false, false],
  ["Fernando Gomez",     "Tony Finau",         false, false],
  ["Katie King",         "Tommy Fleetwood",    false, false],
  ["JT Ozerities",       "Wyndham Clark",      false, false],
  ["Jack Murphy",        "Matt Fitzpatrick",   false, false],
  ["Reise Kelly",        "Sam Burns",          false, false],
  ["Chad Gauvin",        "Tommy Fleetwood",    false, false],
  ["Tim Cooney",         "Sam Burns",          false, false],
  ["Graeme Watson",      "Collin Morikawa",    false, false],
  ["Michael Barile",     "Aaron Rai",          false, false],
  ["Jason DuBois",       "Justin Rose",        false, false],
  ["Paul Cacciotti",     "Sam Burns",          false, false],
  ["Nick Cristobal",     "Kristoffer Reitan",  false, false],
  ["Mike Davis",         "Wyndham Clark",      false, true],   # auto
  ["Daniel Jaffe",       "Alex Fitzpatrick",   false, false],
  ["Dustin Daniels",     "Aaron Rai",          false, false],
  ["Adam Feeley",        "Brooks Koepka",      false, false],
  ["Jerry Heath",        "Wyndham Clark",      false, true],   # auto
  ["Daren Wamsley",      "Sam Burns",          false, false],
  ["Kevin Lang",         "Nick Taylor",        false, false],
  ["Dylan Linke",        "Wyndham Clark",      false, false],
  ["Dan Jaffe",          "Wyndham Clark",      false, true],   # auto
  ["Ryan Finstad",       "Sam Burns",          false, false],
  ["Nick Scarimbolo",    "Wyndham Clark",      false, true],   # auto
  ["Dylan Chambers",     "Nick Taylor",        false, false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 17 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W17.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W17[golfer_raw] || golfer_raw
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
PICKS_W17.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 17 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
