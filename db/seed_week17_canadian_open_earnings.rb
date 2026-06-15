tournament = Tournament.find_by!(week_number: 17)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/06/14/prize-money-purse-payouts-breakdown-fund-rbc-canadian-open-tpc-toronto
RESULTS = [
  [ 1, "1",   "Bud Cauley",                176_400_000],
  [ 2, "2",   "Matt Fitzpatrick",          106_820_000],
  [ 3, "3",   "Viktor Hovland",             67_620_000],
  [ 4, "T4",  "Jimmy Stanger",              39_200_000],
  [ 4, "T4",  "Brice Garnett",              39_200_000],
  [ 4, "T4",  "Jesper Svensson",            39_200_000],
  [ 4, "T4",  "Jackson Suber",              39_200_000],
  [ 8, "T8",  "Aldrich Potgieter",          28_665_000],
  [ 8, "T8",  "Ryan Fox",                   28_665_000],
  [ 8, "T8",  "Sudarshan Yellamaraju",      28_665_000],
  [11, "T11", "Matthew Anderson",           21_805_000],
  [11, "T11", "Jacob Bridgeman",            21_805_000],
  [11, "T11", "Tommy Fleetwood",            21_805_000],
  [11, "T11", "Wyndham Clark",              21_805_000],
  [15, "T15", "Chandler Phillips",          15_925_000],
  [15, "T15", "Tom Kim",                    15_925_000],
  [15, "T15", "Doug Ghim",                  15_925_000],
  [15, "T15", "Robert MacIntyre",           15_925_000],
  [15, "T15", "Billy Horschel",             15_925_000],
  [20, "T20", "Matthieu Pavon",              9_685_667],
  [20, "T20", "Erik van Rooyen",             9_685_667],
  [20, "T20", "Alex Fitzpatrick",            9_685_667],
  [20, "T20", "Emiliano Grillo",             9_685_667],
  [20, "T20", "Keita Nakajima",              9_685_667],
  [20, "T20", "Max Homa",                    9_685_667],
  [20, "T20", "William Mouw",                9_685_667],
  [20, "T20", "David Skinns",                9_685_667],
  [20, "T20", "Sam Burns",                   9_685_667],
  [29, "T29", "Kevin Yu",                    5_885_444],
  [29, "T29", "Ben Kohles",                  5_885_444],
  [29, "T29", "Keith Mitchell",              5_885_444],
  [29, "T29", "Taylor Pendrith",            5_885_444],
  [29, "T29", "A.J. Ewart",                  5_885_444],
  [29, "T29", "Takumi Kanaya",               5_885_444],
  [29, "T29", "Collin Morikawa",             5_885_444],
  [29, "T29", "Patrick Fishburn",            5_885_444],
  [29, "T29", "Shane Lowry",                 5_885_444],
  [39, "39",  "Rasmus Neergaard-Petersen",   4_655_000],
  [40, "T40", "Tony Finau",                  4_067_000],
  [40, "T40", "Harry Hall",                  4_067_000],
  [40, "T40", "Adam Hadwin",                 4_067_000],
  [40, "T40", "Alejandro Tosti",             4_067_000],
  [40, "T40", "Taylor Moore",                4_067_000],
  [45, "T45", "Beau Hossler",                3_011_867],
  [45, "T45", "Davis Thompson",              3_011_867],
  [45, "T45", "Sam Ryder",                   3_011_867],
  [45, "T45", "Dylan Wu",                    3_011_867],
  [45, "T45", "Sahith Theegala",             3_011_867],
  [45, "T45", "Ricky Castillo",              3_011_867],
  [51, "T51", "Max McGreevy",                2_459_800],
  [51, "T51", "Neal Shipley",                2_459_800],
  [51, "T51", "Johnny Keefer",               2_459_800],
  [54, "T54", "Ben Silverman",               2_306_920],
  [54, "T54", "Michael Thorbjornsen",        2_306_920],
  [54, "T54", "Christiaan Bezuidenhout",     2_306_920],
  [54, "T54", "Luke Clanton",                2_306_920],
  [54, "T54", "Ben James",                   2_306_920],
  [59, "59",  "Calen Sanderson",             2_244_200],
  [60, "T60", "Denny McCarthy",              2_185_400],
  [60, "T60", "Kristoffer Reitan",           2_185_400],
  [60, "T60", "Adam Svensson",               2_185_400],
  [60, "T60", "Haotong Li",                  2_185_400],
  [60, "T60", "Lanto Griffin",               2_185_400],
  [65, "T65", "Vince Whaley",                2_116_800],
  [65, "T65", "Nick Taylor",                 2_116_800],
  [67, "T67", "Joey Savoie",                 2_067_800],
  [67, "T67", "Paul Peterson",               2_067_800],
  [67, "T67", "Chandler Blanchet",           2_067_800],
  [70, "70",  "Joe Highsmith",               2_028_600],
  [71, "T71", "Kevin Roy",                   1_999_200],
  [71, "T71", "Kensei Hirata",               1_999_200],
  [73, "73",  "Austin Eckroat",              1_969_800],
  [74, "74",  "Jeremy Paul",                 1_950_200],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = [
  "Aaron Rai",
  "Eric Cole",
  "Justin Rose",
  "Nicolai Højgaard",
  "Corey Conners",
  "Brooks Koepka",
].freeze

def strip_accents(s)
  s.unicode_normalize(:nfkd).chars.reject { |c| c =~ /\p{Mn}/ }.join
end

# Match an existing golfer (exact, then dots-removed, then accent-insensitive)
# to avoid creating duplicates of golfers already synced from ESPN.
def find_golfer(name)
  Golfer.find_by(name: name) ||
    Golfer.find_by(name: name.gsub(".", "").squeeze(" ").strip) ||
    Golfer.all.find { |g| strip_accents(g.name).casecmp?(strip_accents(name)) }
end

tournament.update!(status: "completed")

created_results = 0
updated_results = 0

RESULTS.each do |pos, pos_display, name, cents|
  golfer = find_golfer(name) || Golfer.create!(name: name)
  result = TournamentResult.find_or_initialize_by(tournament: tournament, golfer: golfer)
  is_new = result.new_record?
  result.assign_attributes(
    current_position:         pos,
    current_position_display: pos_display,
    current_thru:             "F",
    made_cut:                 true,
    earnings_cents:           cents
  )
  result.save!
  is_new ? created_results += 1 : updated_results += 1
end

MISSED_CUT_PICKS.each do |name|
  golfer = find_golfer(name) || Golfer.create!(name: name)
  result = TournamentResult.find_or_initialize_by(tournament: tournament, golfer: golfer)
  is_new = result.new_record?
  result.assign_attributes(
    current_position:         nil,
    current_position_display: "CUT",
    current_thru:             nil,
    made_cut:                 false,
    earnings_cents:           0
  )
  result.save!
  is_new ? created_results += 1 : updated_results += 1
end

# Resave picks to trigger Pick#calculate_earnings (sets earnings_cents + made_cut)
warnings = []
tournament.picks.includes(:golfer, :user).each do |pick|
  unless TournamentResult.exists?(tournament: tournament, golfer: pick.golfer)
    warnings << "no result for #{pick.user.name}'s pick (#{pick.golfer.name})"
    next
  end
  pick.save!(validate: false)
end

puts "Results: #{created_results} created, #{updated_results} updated"
warnings.each { |w| puts "WARN: #{w}" }

puts "\nFinal earnings by pick (sorted high → low):"
tournament.picks.includes(:golfer, :user).sort_by { |p| -p.earnings_cents.to_i }.each do |p|
  dd   = p.is_double_down? ? " [2x]" : ""
  auto = p.auto_assigned?  ? " (auto)" : ""
  dollars = (p.earnings_cents.to_i / 100.0)
  puts format("  $%10.2f  %-22s %s%s%s", dollars, p.user.name, p.golfer.name, dd, auto)
end
