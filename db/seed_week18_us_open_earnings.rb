tournament = Tournament.find_by!(week_number: 18)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/06/21/prize-money-purse-payouts-breakdown-fund-us-open-2026-major-shinnecock-hills
# 2026 U.S. Open @ Shinnecock Hills — purse $22.5M, winner's share $4.5M
RESULTS = [
  [ 1, "1",   "Wyndham Clark",                450_000_000],
  [ 2, "2",   "Sam Burns",                    243_000_000],
  [ 3, "3",   "Tom Kim",                      153_253_000],
  [ 4, "T4",  "J.T. Poston",                   92_088_200],
  [ 4, "T4",  "Keith Mitchell",                92_088_200],
  [ 4, "T4",  "Scottie Scheffler",             92_088_200],
  [ 7, "T7",  "Joaquin Niemann",               61_709_000],
  [ 7, "T7",  "Tyrrell Hatton",                61_709_000],
  [ 7, "T7",  "Gary Woodland",                 61_709_000],
  [ 7, "T7",  "Sam Stevens",                   61_709_000],
  [11, "T11", "Justin Rose",                   40_586_200],
  [11, "T11", "Aaron Rai",                     40_586_200],
  [11, "T11", "John Parry",                    40_586_200],
  [11, "T11", "Tommy Fleetwood",               40_586_200],
  [11, "T11", "Xander Schauffele",             40_586_200],
  [11, "T11", "Sahith Theegala",               40_586_200],
  [17, "T17", "Ludvig Åberg",                  28_096_600],
  [17, "T17", "Justin Thomas",                 28_096_600],
  [17, "T17", "Ben Griffin",                   28_096_600],
  [17, "T17", "Akshay Bhatia",                 28_096_600],
  [17, "T17", "Collin Morikawa",               28_096_600],
  [22, "22",  "Matt Fitzpatrick",              23_022_000],
  [23, "T23", "Ben James",                     18_110_100],
  [23, "T23", "Ryan Fox",                      18_110_100],
  [23, "T23", "Jackson Koivun",                         0], # amateur
  [23, "T23", "Ben Kohles",                    18_110_100],
  [23, "T23", "Pierceson Coody",               18_110_100],
  [23, "T23", "Ryder Cowan",                            0], # amateur
  [23, "T23", "Alex Fitzpatrick",              18_110_100],
  [23, "T23", "Corey Conners",                 18_110_100],
  [23, "T23", "Emiliano Grillo",               18_110_100],
  [32, "T32", "Max McGreevy",                  12_875_600],
  [32, "T32", "Dustin Johnson",                12_875_600],
  [32, "T32", "Rory McIlroy",                  12_875_600],
  [32, "T32", "Maverick McNealy",              12_875_600],
  [32, "T32", "Brian Harman",                  12_875_600],
  [32, "T32", "Zac Blair",                     12_875_600],
  [32, "T32", "Keegan Bradley",                12_875_600],
  [39, "T39", "Jacob Bridgeman",               10_185_900],
  [39, "T39", "Johnny Keefer",                 10_185_900],
  [39, "T39", "Miles Russell",                          0], # amateur
  [39, "T39", "Robert MacIntyre",              10_185_900],
  [43, "T43", "Max Greyserman",                 7_259_200],
  [43, "T43", "Chris Gotterup",                 7_259_200],
  [43, "T43", "Harry Higgs",                    7_259_200],
  [43, "T43", "Michael Brennan",                7_259_200],
  [43, "T43", "Cameron Young",                  7_259_200],
  [43, "T43", "Laurie Canter",                  7_259_200],
  [43, "T43", "Niklas Nørgaard",                7_259_200],
  [43, "T43", "Ryo Hisatsune",                  7_259_200],
  [43, "T43", "Sungjae Im",                     7_259_200],
  [43, "T43", "Michael Kim",                    7_259_200],
  [53, "T53", "Adrien Dumont de Chassart",      5_146_700],
  [53, "T53", "Kurt Kitayama",                  5_146_700],
  [53, "T53", "Angel Hidalgo",                  5_146_700],
  [56, "T56", "Peter Uihlein",                  4_862_500],
  [56, "T56", "Nico Echavarria",                4_862_500],
  [56, "T56", "Marek Fleming",                          0], # amateur
  [56, "T56", "Jordan Spieth",                  4_862_500],
  [56, "T56", "Bud Cauley",                     4_862_500],
  [61, "T61", "Jackson Van Paris",              4_724_200],
  [61, "T61", "Spencer Tibbits",                4_724_200],
  [63, "T63", "Eric Lee",                               0], # amateur
  [63, "T63", "Caleb Surratt",                  4_655_100],
  [65, "T65", "James Nicholas",                 4_493_800],
  [65, "T65", "Russell Henley",                 4_493_800],
  [65, "T65", "Neal Shipley",                   4_493_800],
  [65, "T65", "Hideki Matsuyama",               4_493_800],
  [65, "T65", "Andrew Putnam",                  4_493_800],
  [65, "T65", "William Mouw",                   4_493_800],
  [71, "71",  "Patrick Rodgers",                4_332_400],
  [72, "72",  "Dylan Wu",                       4_285_800],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = [
  "Brooks Koepka",
  "Jon Rahm",
  "Patrick Reed",
  "JJ Spaun",
  "Cameron Smith",
  "Adam Scott",
  "Viktor Hovland",
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
