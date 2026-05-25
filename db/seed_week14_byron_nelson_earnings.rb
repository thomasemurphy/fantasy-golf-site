tournament = Tournament.find_by!(week_number: 14)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/05/24/prize-money-purse-payouts-breakdown-fund-the-cj-cup-byron-nelson
RESULTS = [
  [ 1, "1",   "Wyndham Clark",              185_400_000],
  [ 2, "2",   "Si Woo Kim",                 112_270_000],
  [ 3, "3",   "Scottie Scheffler",           71_070_000],
  [ 4, "4",   "Jackson Suber",               50_470_000],
  [ 5, "5",   "Keith Mitchell",              42_230_000],
  [ 6, "T6",  "Tony Finau",                  34_762_500],
  [ 6, "T6",  "Zach Bauchou",                34_762_500],
  [ 6, "T6",  "Tom Hoge",                    34_762_500],
  [ 9, "T9",  "Johnny Keefer",               26_007_500],
  [ 9, "T9",  "Jesper Svensson",             26_007_500],
  [ 9, "T9",  "Max Greyserman",              26_007_500],
  [ 9, "T9",  "Sungjae Im",                  26_007_500],
  [ 9, "T9",  "Stephan Jaeger",              26_007_500],
  [14, "T14", "Taylor Moore",                18_797_500],
  [14, "T14", "Blades Brown",                18_797_500],
  [14, "T14", "Brooks Koepka",               18_797_500],
  [17, "17",  "Ben Silverman",               16_737_500],
  [18, "18",  "S.Y. Noh",                    15_707_500],
  [19, "T19", "Garrick Higgo",               10_059_667],
  [19, "T19", "Jordan Spieth",               10_059_667],
  [19, "T19", "A.J. Ewart",                  10_059_667],
  [19, "T19", "Seamus Power",                10_059_667],
  [19, "T19", "Pierceson Coody",             10_059_667],
  [19, "T19", "Peter Malnati",               10_059_667],
  [19, "T19", "Rico Hoey",                   10_059_667],
  [19, "T19", "Ryo Hisatsune",               10_059_667],
  [19, "T19", "Rasmus Neergaard-Petersen",   10_059_667],
  [19, "T19", "Kensei Hirata",               10_059_667],
  [19, "T19", "Steven Fisk",                 10_059_667],
  [19, "T19", "Erik van Rooyen",             10_059_667],
  [31, "T31", "Eric Cole",                    5_893_071],
  [31, "T31", "Luke Clanton",                 5_893_071],
  [31, "T31", "Mac Meissner",                 5_893_071],
  [31, "T31", "Doug Ghim",                    5_893_071],
  [31, "T31", "Mark Hubbard",                 5_893_071],
  [31, "T31", "Sam Ryder",                    5_893_071],
  [31, "T31", "Chris Kirk",                   5_893_071],
  [38, "T38", "Emiliano Grillo",              4_789_500],
  [38, "T38", "Chan Kim",                     4_789_500],
  [40, "T40", "Neal Shipley",                 3_862_500],
  [40, "T40", "Adrien Saddier",               3_862_500],
  [40, "T40", "Matthieu Pavon",               3_862_500],
  [40, "T40", "Tyler Duncan",                 3_862_500],
  [40, "T40", "Luke List",                    3_862_500],
  [40, "T40", "Camilo Villegas",              3_862_500],
  [40, "T40", "Austin Eckroat",               3_862_500],
  [47, "T47", "Dan Brown",                    2_697_129],
  [47, "T47", "Fabián Gómez",                 2_697_129],
  [47, "T47", "Taylor Pendrith",              2_697_129],
  [47, "T47", "John Parry",                   2_697_129],
  [47, "T47", "Justin Lower",                 2_697_129],
  [47, "T47", "Patrick Fishburn",             2_697_129],
  [47, "T47", "Patrick Rodgers",              2_697_129],
  [54, "T54", "Adam Svensson",                2_399_900],
  [54, "T54", "Tom Kim",                      2_399_900],
  [54, "T54", "Jeffrey Kang",                 2_399_900],
  [54, "T54", "Charley Hoffman",              2_399_900],
  [54, "T54", "Troy Merritt",                 2_399_900],
  [59, "T59", "Chad Ramey",                   2_317_500],
  [59, "T59", "Jonathan Byrd",                2_317_500],
  [59, "T59", "Jordan Smith",                 2_317_500],
  [62, "T62", "Thorbjørn Olesen",             2_245_400],
  [62, "T62", "Yongjun Bae",                  2_245_400],
  [62, "T62", "Rasmus Højgaard",              2_245_400],
  [62, "T62", "Hank Lebioda",                 2_245_400],
  [66, "66",  "Mackenzie Hughes",             2_193_900],
  [67, "T67", "Lanto Griffin",                2_163_000],
  [67, "T67", "John VanDerLaan",              2_163_000],
  [69, "69",  "Zac Blair",                    2_132_100],
  [70, "70",  "Danny Willett",                2_111_500],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = ["Christiaan Bezuidenhout", "Austin Cook",
                    "Michael Thorbjornsen", "Davis Thompson"].freeze

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
