tournament = Tournament.find_by!(week_number: 16)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/06/07/prize-money-purse-payouts-breakdown-fund-the-memorial-muirfield-village-golf-club
RESULTS = [
  [ 1, "1",   "J.T. Poston",                400_000_000],
  [ 2, "2",   "Ryan Gerard",                220_000_000],
  [ 3, "3",   "Wyndham Clark",              140_000_000],
  [ 4, "T4",  "Tommy Fleetwood",             92_000_000],
  [ 4, "T4",  "Sam Burns",                   92_000_000],
  [ 6, "T6",  "Alex Fitzpatrick",            73_000_000],
  [ 6, "T6",  "Kristoffer Reitan",           73_000_000],
  [ 8, "8",   "Eric Cole",                   64_600_000],
  [ 9, "9",   "Alex Noren",                  60_000_000],
  [10, "T10", "Si Woo Kim",                  53_500_000],
  [10, "T10", "Maverick McNealy",            53_500_000],
  [12, "T12", "Adam Scott",                  40_180_000],
  [12, "T12", "Rory McIlroy",                40_180_000],
  [12, "T12", "Justin Rose",                 40_180_000],
  [12, "T12", "Scottie Scheffler",           40_180_000],
  [12, "T12", "J.J. Spaun",                  40_180_000],
  [17, "T17", "Patrick Cantlay",             31_900_000],
  [17, "T17", "Harris English",              31_900_000],
  [19, "T19", "Aaron Rai",                   26_933_333],
  [19, "T19", "Justin Thomas",               26_933_333],
  [19, "T19", "Keegan Bradley",              26_933_333],
  [22, "T22", "Bud Cauley",                  20_020_000],
  [22, "T22", "Matt Kuchar",                 20_020_000],
  [22, "T22", "Russell Henley",              20_020_000],
  [22, "T22", "Shane Lowry",                 20_020_000],
  [22, "T22", "Kurt Kitayama",               20_020_000],
  [27, "T27", "Chris Gotterup",              15_750_000],
  [27, "T27", "Ryan Fox",                    15_750_000],
  [29, "T29", "Tony Finau",                  14_000_000],
  [29, "T29", "Xander Schauffele",           14_000_000],
  [29, "T29", "Harry Hall",                  14_000_000],
  [32, "T32", "Sungjae Im",                  12_250_000],
  [32, "T32", "Sahith Theegala",             12_250_000],
  [34, "T34", "Denny McCarthy",              11_150_000],
  [34, "T34", "Jacob Bridgeman",             11_150_000],
  [36, "T36", "Matt Fitzpatrick",             9_900_000],
  [36, "T36", "Gary Woodland",                9_900_000],
  [36, "T36", "Brandt Snedeker",              9_900_000],
  [39, "39",  "Ludvig Åberg",                 9_000_000],
  [40, "T40", "Sepp Straka",                  8_200_000],
  [40, "T40", "Sudarshan Yellamaraju",        8_200_000],
  [40, "T40", "Nico Echavarria",              8_200_000],
  [43, "T43", "Nick Taylor",                  7_000_000],
  [43, "T43", "Taylor Pendrith",              7_000_000],
  [43, "T43", "Hideki Matsuyama",             7_000_000],
  [46, "T46", "Lucas Glover",                 5_866_667],
  [46, "T46", "Cameron Young",                5_866_667],
  [46, "T46", "Mac Meissner",                 5_866_667],
  [49, "T49", "Patrick Rodgers",              5_300_000],
  [49, "T49", "Michael Kim",                  5_300_000],
  [51, "51",  "Tom Hoge",                     5_100_000],
  [52, "52",  "Ryo Hisatsune",               5_000_000],
  [53, "53",  "Corey Conners",               4_900_000],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = ["Jordan Spieth"].freeze

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
