tournament = Tournament.find_by!(week_number: 15)

# Golfer name corrections / accent normalization → canonical DB names
ALIASES_W15 = {
  "Ludvig Aberg"      => "Ludvig Åberg",
  "Robert MacIntrye"  => "Robert MacIntyre",  # typo
}.freeze

# [player, golfer, double_down?, auto?]
PICKS_W15 = [
  ["Kyle Frazho",        "Rickie Fowler",       false, false],
  ["Mike Feeley",        "Akshay Bhatia",       false, false],
  ["Andy Stepic",        "Russell Henley",      false, false],
  ["Michael Amira",      "Ludvig Aberg",        false, false],
  ["Tom Murphy",         "Rickie Fowler",       false, false],
  ["CJ Sturges",         "Russell Henley",      false, false],
  ["Jim Cooke",          "Robert MacIntrye",    false, false],
  ["Bree Svigelj",       "Justin Thomas",       false, false],
  ["Pat Lang",           "Akshay Bhatia",       false, false],
  ["Michael Lukas",      "JJ Spaun",            false, false],
  ["Kyle Shaffer",       "Justin Thomas",       false, false],
  ["Justin Mungarro",    "Justin Thomas",       true,  false],  # DD
  ["Mike Murphy",        "Ludvig Aberg",        false, false],
  ["Andrew Lunder",      "Rickie Fowler",       false, false],
  ["Luke Grasso",        "Ludvig Aberg",        false, false],
  ["Jimmy Nelson",       "Justin Thomas",       false, false],
  ["Nate Hill",          "Hideki Matsuyama",    false, false],
  ["Jason Mungarro",     "JJ Spaun",            false, false],
  ["Kevin Hobbs",        "Justin Thomas",       false, false],
  ["Chad Squires Jr.",   "Ryo Hisatsune",       false, false],
  ["Zach Jonas",         "Sungjae Im",          false, false],
  ["Brian Szepelak",     "Rickie Fowler",       false, false],
  ["Brian Feeley",       "Tony Finau",          false, false],
  ["Jay Waugh",          "Rickie Fowler",       false, false],
  ["Kyle O'Neil",        "Ben Griffin",         false, false],
  ["Robert Chambers",    "Tony Finau",          false, false],
  ["Matt VanDixhorn",    "Rickie Fowler",       false, false],
  ["Ben Engler",         "Rickie Fowler",       false, false],
  ["Anthony Cerruti",    "Ludvig Aberg",        false, false],
  ["Chad Squires Sr.",   "Justin Thomas",       true,  false],  # DD
  ["Jack Gunst",         "Akshay Bhatia",       false, false],
  ["Fernando Gomez",     "Ludvig Aberg",        false, false],
  ["Jack Murphy",        "Justin Thomas",       false, false],
  ["Reise Kelly",        "Rickie Fowler",       false, false],
  ["Chad Gauvin",        "Akshay Bhatia",       false, false],
  ["Roberto Scheinerle", "Russell Henley",      false, false],
  ["Graeme Watson",      "Rickie Fowler",       false, false],
  ["Jason DuBois",       "Keegan Bradley",      false, false],
  ["JT Ozerities",       "Russell Henley",      false, false],
  ["Nick Cristobal",     "Rickie Fowler",       false, false],
  ["Paul Cacciotti",     "Robert MacIntrye",    false, false],
  ["Michael Barile",     "Justin Thomas",       false, false],
  ["Dustin Daniels",     "Justin Thomas",       false, false],
  ["Mike Davis",         "Hideki Matsuyama",    true,  false],  # DD
  ["Tim Cooney",         "Russell Henley",      false, false],
  ["Jerry Heath",        "Ludvig Aberg",        false, false],
  ["Adam Feeley",        "Akshay Bhatia",       false, false],
  ["Daniel Jaffe",       "JJ Spaun",            false, false],
  ["Daren Wamsley",      "Ludvig Aberg",        false, false],
  ["Katie King",         "Russell Henley",      true,  false],  # DD
  ["Kevin Lang",         "Rickie Fowler",       false, false],
  ["Nick Scarimbolo",    "Rickie Fowler",       false, true],   # auto
  ["Ryan Finstad",       "Justin Thomas",       false, false],
  ["Dylan Linke",        "Justin Thomas",       false, true],   # auto
  ["Dylan Chambers",     "Justin Thomas",       false, true],   # auto
  ["Dan Jaffe",          "JJ Spaun",            false, false],
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 15 picks ===" : "=== DRY RUN (set APPLY=1 to write) ==="

def norm_apostrophe(s) = s.tr("’", "'")

errors  = []
created = 0
skipped = 0
dd_planned = Hash.new(0)

PICKS_W15.each do |player_name, golfer_raw, is_dd, is_auto|
  user = User.find_by(name: player_name) || User.find_by(name: norm_apostrophe(player_name))
  unless user
    errors << "USER NOT FOUND: #{player_name}"
    next
  end

  golfer_name = ALIASES_W15[golfer_raw] || golfer_raw
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
PICKS_W15.map { |p| p[0] }.uniq.each do |player_name|
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

  puts "\nWeek 15 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
