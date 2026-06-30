tournament = Tournament.find_by!(week_number: 19)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/06/28/prize-money-purse-payouts-breakdown-fund-travelers-championship-tpc-river-highlands-signature-event
# 2026 Travelers Championship @ TPC River Highlands — signature event, no cut, purse $20M, winner's share $3.6M
RESULTS = [
  [ 1, "1",   "Viktor Hovland",       360_000_000],
  [ 2, "2",   "Scottie Scheffler",    216_000_000],
  [ 3, "3",   "Collin Morikawa",      136_000_000],
  [ 4, "4",   "Matt Fitzpatrick",      96_000_000],
  [ 5, "T5",  "Wyndham Clark",         76_000_000],
  [ 5, "T5",  "Akshay Bhatia",         76_000_000],
  [ 7, "T7",  "Corey Conners",         62_333_333],
  [ 7, "T7",  "J.J. Spaun",            62_333_333],
  [ 7, "T7",  "Alex Fitzpatrick",      62_333_333],
  [10, "T10", "Robert MacIntyre",      52_000_000],
  [10, "T10", "Ben Griffin",           52_000_000],
  [12, "T12", "Russell Henley",        44_000_000],
  [12, "T12", "Sam Burns",             44_000_000],
  [14, "T14", "Nicolai Højgaard",      31_000_000],
  [14, "T14", "Keegan Bradley",        31_000_000],
  [14, "T14", "Tommy Fleetwood",       31_000_000],
  [14, "T14", "Denny McCarthy",        31_000_000],
  [14, "T14", "Bud Cauley",            31_000_000],
  [14, "T14", "Hideki Matsuyama",      31_000_000],
  [14, "T14", "Justin Thomas",         31_000_000],
  [14, "T14", "Patrick Cantlay",       31_000_000],
  [22, "T22", "Kristoffer Reitan",     20_683_333],
  [22, "T22", "Keith Mitchell",        20_683_333],
  [22, "T22", "Shane Lowry",           20_683_333],
  [25, "T25", "Nick Taylor",           15_450_000],
  [25, "T25", "Daniel Berger",         15_450_000],
  [25, "T25", "Kurt Kitayama",         15_450_000],
  [25, "T25", "Justin Rose",           15_450_000],
  [25, "T25", "Brian Harman",          15_450_000],
  [30, "T30", "Andrew Novak",          11_462_500],
  [30, "T30", "Michael Kim",           11_462_500],
  [30, "T30", "Matt McCarty",          11_462_500],
  [30, "T30", "Nico Echavarria",       11_462_500],
  [30, "T30", "Sungjae Im",            11_462_500],
  [30, "T30", "Aaron Rai",             11_462_500],
  [30, "T30", "Jackson Suber",         11_462_500],
  [30, "T30", "Chris Gotterup",        11_462_500],
  [38, "T38", "Brandt Snedeker",        8_216_667],
  [38, "T38", "Rickie Fowler",          8_216_667],
  [38, "T38", "Harris English",         8_216_667],
  [38, "T38", "Tom Hoge",               8_216_667],
  [38, "T38", "Ryo Hisatsune",          8_216_667],
  [38, "T38", "Eric Cole",              8_216_667],
  [44, "T44", "Ryan Gerard",            6_400_000],
  [44, "T44", "Mac Meissner",           6_400_000],
  [44, "T44", "Si Woo Kim",             6_400_000],
  [47, "T47", "Cameron Young",          5_200_000],
  [47, "T47", "Alex Smalley",           5_200_000],
  [47, "T47", "Jacob Bridgeman",        5_200_000],
  [47, "T47", "Brian Campbell",         5_200_000],
  [51, "T51", "Sahith Theegala",        4_675_000],
  [51, "T51", "Jhonattan Vegas",        4_675_000],
  [51, "T51", "Harry Hall",             4_675_000],
  [51, "T51", "Xander Schauffele",      4_675_000],
  [55, "T55", "Ludvig Åberg",           4_425_000],
  [55, "T55", "Alex Noren",             4_425_000],
  [55, "T55", "Jason Day",              4_425_000],
  [55, "T55", "Jake Knapp",             4_425_000],
  [55, "T55", "Tony Finau",             4_425_000],
  [55, "T55", "Maverick McNealy",       4_425_000],
  [61, "61",  "Taylor Pendrith",        4_250_000],
  [62, "T62", "Min Woo Lee",            4_150_000],
  [62, "T62", "Sam Stevens",            4_150_000],
  [62, "T62", "Ben James",              4_150_000],
  [65, "65",  "Adam Scott",             4_050_000],
  [66, "T66", "Ryan Fox",               3_950_000],
  [66, "T66", "Jordan Spieth",          3_950_000],
  [66, "T66", "Lucas Glover",           3_950_000],
  [69, "69",  "J.T. Poston",            3_800_000],
  [70, "70",  "Mark Hubbard",           3_750_000],
  [71, "71",  "Gary Woodland",          3_700_000],
  [72, "72",  "Sepp Straka",            3_600_000],
].freeze

# Signature event — no cut, every player in the field was paid.
MISSED_CUT_PICKS = [].freeze

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
