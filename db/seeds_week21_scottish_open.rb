tournament = Tournament.find_by!(week_number: 21)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W21 = {
  "Robert Macintyre"  => "Robert MacIntyre",
  "Nicolai Hojgaard"  => "Nicolai Højgaard",
  "Kristopher Reitan" => "Kristoffer Reitan",
  "Xander Schuaffele" => "Xander Schauffele",
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W21 = [
  ["Kyle Frazho",        "Tyrrell Hatton",     false, false],
  ["Andy Stepic",        "Wyndham Clark",      false, false],
  ["Mike Feeley",        "Jon Rahm",           false, false],
  ["Bree Svigelj",       "Tyrrell Hatton",     false, false],
  ["CJ Sturges",         "Robert Macintyre",   false, false],
  ["Tom Murphy",         "Tyrrell Hatton",     false, false],
  ["Michael Amira",      "Robert Macintyre",   false, false],
  ["Jim Cooke",          "Wyndham Clark",      false, false],
  ["Michael Lukas",      "Tyrrell Hatton",     false, false],
  ["Pat Lang",           "Robert Macintyre",   false, false],
  ["Kyle Shaffer",       "Tyrrell Hatton",     false, false],
  ["Justin Mungarro",    "Nicolai Hojgaard",   false, false],
  ["Mike Murphy",        "Tyrrell Hatton",     false, false],
  ["Andrew Lunder",      "Wyndham Clark",      false, false],
  ["Fernando Gomez",     "Viktor Hovland",     false, false],
  ["Luke Grasso",        "Robert Macintyre",   false, false],
  ["Zach Jonas",         "Chris Gotterup",     false, false],
  ["Jimmy Nelson",       "Robert Macintyre",   false, false],
  ["Kevin Hobbs",        "Matt Fitzpatrick",   false, false],
  ["Nate Hill",          "Rory McIlroy",       false, false],
  ["Chad Squires Jr.",   "Robert Macintyre",   false, false],
  ["Kyle O'Neil",        "Jon Rahm",           false, false],
  ["Chad Squires Sr.",   "Kristopher Reitan",  false, false],
  ["Jason Mungarro",     "Robert Macintyre",   false, false],
  ["Brian Szepelak",     "Alex Fitzpatrick",   false, false],
  ["Robert Chambers",    "Tyrrell Hatton",     false, false],
  ["Matt VanDixhorn",    "Chris Gotterup",     false, false],
  ["Roberto Scheinerle", "Tyrrell Hatton",     false, false],
  ["Jay Waugh",          "Justin Thomas",      false, false],
  ["Brian Feeley",       "Tyrrell Hatton",     false, false],
  ["Ben Engler",         "Tyrrell Hatton",     false, false],
  ["Jack Gunst",         "Jon Rahm",           false, false],
  ["Jack Murphy",        "Tyrrell Hatton",     false, false],
  ["Anthony Cerruti",    "Robert Macintyre",   false, false],
  ["Reise Kelly",        "Tyrrell Hatton",     false, false],
  ["Mike Davis",         "Tommy Fleetwood",    false, false],
  ["JT Ozerities",       "Shane Lowry",        false, false],
  ["Adam Feeley",        "Jon Rahm",           false, false],
  ["Katie King",         "Matt Fitzpatrick",   false, false],
  ["Nick Cristobal",     "Brooks Koepka",      false, false],
  ["Chad Gauvin",        "Justin Thomas",      false, false],
  ["Graeme Watson",      "Matt Fitzpatrick",   false, false],
  ["Michael Barile",     "Wyndham Clark",      false, false],
  ["Jason DuBois",       "Wyndham Clark",      false, false],
  ["Dustin Daniels",     "Tyrrell Hatton",     false, false],
  ["Jerry Heath",        "Tyrrell Hatton",     false, true],   # auto
  ["Tim Cooney",         "Shane Lowry",        false, false],
  ["Dylan Linke",        "Tommy Fleetwood",    true,  false],
  ["Paul Cacciotti",     "Tom Kim",            false, false],
  ["Daniel Jaffe",       "Nicolai Hojgaard",   false, false],
  ["Dan Jaffe",          "Viktor Hovland",     false, false],
  ["Ryan Finstad",       "Jon Rahm",           false, false],
  ["Kevin Lang",         "Tyrrell Hatton",     false, false],
  ["Daren Wamsley",      "Tyrrell Hatton",     false, true],   # auto
  ["Dylan Chambers",     "Xander Schuaffele",  false, false],
  ["Nick Scarimbolo",    "Tyrrell Hatton",     false, true],   # auto
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 21 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W21.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W21[golfer_raw] || golfer_raw
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
PICKS_W21.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 21 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
