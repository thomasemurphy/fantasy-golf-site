tournament = Tournament.find_by!(week_number: 15)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/05/31/prize-money-purse-payouts-breakdown-fund-charles-schwab-challenge-colonial-country-club
RESULTS = [
  [ 1, "1",   "Russell Henley",            178_200_000],
  [ 2, "2",   "Eric Cole",                 107_910_000],
  [ 3, "T3",  "Ben Griffin",                52_470_000],
  [ 3, "T3",  "Alex Smalley",               52_470_000],
  [ 3, "T3",  "Mac Meissner",               52_470_000],
  [ 6, "T6",  "Gary Woodland",              32_298_750],
  [ 6, "T6",  "Michael Brennan",            32_298_750],
  [ 6, "T6",  "Nico Echavarria",            32_298_750],
  [ 6, "T6",  "J.J. Spaun",                 32_298_750],
  [10, "T10", "Steven Fisk",                24_997_500],
  [10, "T10", "Mackenzie Hughes",           24_997_500],
  [10, "T10", "Ryan Gerard",                24_997_500],
  [13, "T13", "Jordan Smith",               19_387_500],
  [13, "T13", "Justin Thomas",              19_387_500],
  [13, "T13", "Hideki Matsuyama",           19_387_500],
  [16, "16",  "Michael Thorbjornsen",       17_077_500],
  [17, "T17", "Rico Hoey",                  14_107_500],
  [17, "T17", "Michael Kim",                14_107_500],
  [17, "T17", "Andrew Putnam",              14_107_500],
  [17, "T17", "A.J. Ewart",                 14_107_500],
  [17, "T17", "Ludvig Åberg",               14_107_500],
  [22, "T22", "Max Homa",                    9_240_000],
  [22, "T22", "Brice Garnett",               9_240_000],
  [22, "T22", "Zach Bauchou",                9_240_000],
  [22, "T22", "Matt Kuchar",                 9_240_000],
  [22, "T22", "Pierceson Coody",             9_240_000],
  [22, "T22", "Brian Harman",                9_240_000],
  [28, "T28", "Brandt Snedeker",             6_930_000],
  [28, "T28", "Keita Nakajima",              6_930_000],
  [28, "T28", "Akshay Bhatia",               6_930_000],
  [28, "T28", "Doug Ghim",                   6_930_000],
  [32, "T32", "Garrick Higgo",               5_907_000],
  [32, "T32", "Lanto Griffin",               5_907_000],
  [32, "T32", "Christiaan Bezuidenhout",     5_907_000],
  [35, "T35", "J.T. Poston",                 4_723_714],
  [35, "T35", "Keegan Bradley",              4_723_714],
  [35, "T35", "Max McGreevy",                4_723_714],
  [35, "T35", "Kevin Yu",                    4_723_714],
  [35, "T35", "Davis Thompson",              4_723_714],
  [35, "T35", "Lee Hodges",                  4_723_714],
  [35, "T35", "Johnny Keefer",               4_723_714],
  [42, "T42", "Kevin Streelman",             2_976_600],
  [42, "T42", "Joel Dahmen",                 2_976_600],
  [42, "T42", "Emiliano Grillo",             2_976_600],
  [42, "T42", "Adrien Saddier",              2_976_600],
  [42, "T42", "Ricky Castillo",              2_976_600],
  [42, "T42", "Jeffrey Kang",                2_976_600],
  [42, "T42", "Rasmus Neergaard-Petersen",   2_976_600],
  [42, "T42", "Austin Smotherman",           2_976_600],
  [42, "T42", "Sam Stevens",                 2_976_600],
  [42, "T42", "Robert MacIntyre",            2_976_600],
  [42, "T42", "Billy Horschel",              2_976_600],
  [42, "T42", "Chandler Blanchet",           2_976_600],
  [54, "T54", "Seamus Power",                2_296_800],
  [54, "T54", "Luke Clanton",                2_296_800],
  [54, "T54", "Takumi Kanaya",               2_296_800],
  [54, "T54", "Patrick Fishburn",            2_296_800],
  [54, "T54", "Andrew Novak",                2_296_800],
  [54, "T54", "Tom Kim",                     2_296_800],
  [60, "T60", "Mark Hubbard",                2_178_000],
  [60, "T60", "Patrick Rodgers",             2_178_000],
  [60, "T60", "Nick Dunlap",                 2_178_000],
  [60, "T60", "Matt McCarty",                2_178_000],
  [60, "T60", "Sahith Theegala",             2_178_000],
  [60, "T60", "Taylor Moore",                2_178_000],
  [66, "66",  "Ryo Hisatsune",               2_108_700],
  [67, "T67", "Thorbjørn Olesen",            2_069_100],
  [67, "T67", "Jackson Suber",               2_069_100],
  [67, "T67", "Austin Eckroat",              2_069_100],
  [70, "70",  "Erik van Rooyen",             2_029_500],
  [71, "T71", "Tom Hoge",                     1_989_900],
  [71, "T71", "Lucas Glover",                1_989_900],
  [71, "T71", "Davis Riley",                  1_989_900],
  [74, "T74", "Kevin Roy",                    1_940_400],
  [74, "T74", "Adam Schenk",                  1_940_400],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = ["Rickie Fowler", "Sungjae Im", "Tony Finau"].freeze

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
