tournament = Tournament.find_by!(week_number: 13)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/05/17/prize-money-purse-payouts-breakdown-fund-2026-pga-championship
RESULTS = [
  [ 1, "1",   "Aaron Rai",                 369_000_000],
  [ 2, "T2",  "Jon Rahm",                  180_400_000],
  [ 2, "T2",  "Alex Smalley",              180_400_000],
  [ 4, "T4",  "Justin Thomas",              84_386_667],
  [ 4, "T4",  "Ludvig Åberg",               84_386_667],
  [ 4, "T4",  "Matti Schmid",               84_386_667],
  [ 7, "T7",  "Cameron Smith",              63_705_000],
  [ 7, "T7",  "Rory McIlroy",               63_705_000],
  [ 7, "T7",  "Xander Schauffele",          63_705_000],
  [10, "T10", "Kurt Kitayama",              49_670_750],
  [10, "T10", "Chris Gotterup",             49_670_750],
  [10, "T10", "Justin Rose",                49_670_750],
  [10, "T10", "Patrick Reed",               49_670_750],
  [14, "T14", "Matt Fitzpatrick",           36_476_250],
  [14, "T14", "Scottie Scheffler",          36_476_250],
  [14, "T14", "Max Greyserman",             36_476_250],
  [14, "T14", "Ben Griffin",                36_476_250],
  [18, "T18", "Jordan Spieth",              22_912_875],
  [18, "T18", "Stephan Jaeger",             22_912_875],
  [18, "T18", "Padraig Harrington",         22_912_875],
  [18, "T18", "David Puig",                 22_912_875],
  [18, "T18", "Harris English",             22_912_875],
  [18, "T18", "Min Woo Lee",                22_912_875],
  [18, "T18", "Joaquin Niemann",            22_912_875],
  [18, "T18", "Maverick McNealy",           22_912_875],
  [26, "T26", "Alex Noren",                 12_552_333],
  [26, "T26", "Cameron Young",              12_552_333],
  [26, "T26", "Andrew Novak",               12_552_333],
  [26, "T26", "Daniel Hillier",             12_552_333],
  [26, "T26", "Tom Hoge",                   12_552_333],
  [26, "T26", "Sam Burns",                  12_552_333],
  [26, "T26", "Hideki Matsuyama",           12_552_333],
  [26, "T26", "Bud Cauley",                 12_552_333],
  [26, "T26", "Nick Taylor",                12_552_333],
  [35, "T35", "Christiaan Bezuidenhout",     7_880_556],
  [35, "T35", "Patrick Cantlay",             7_880_556],
  [35, "T35", "Ryo Hisatsune",               7_880_556],
  [35, "T35", "Daniel Berger",               7_880_556],
  [35, "T35", "Ryan Fox",                    7_880_556],
  [35, "T35", "Haotong Li",                  7_880_556],
  [35, "T35", "Aldrich Potgieter",           7_880_556],
  [35, "T35", "Si Woo Kim",                  7_880_556],
  [35, "T35", "Martin Kaymer",               7_880_556],
  [44, "T44", "Matt Wallace",                5_034_818],
  [44, "T44", "Shane Lowry",                 5_034_818],
  [44, "T44", "Jhonattan Vegas",             5_034_818],
  [44, "T44", "Denny McCarthy",              5_034_818],
  [44, "T44", "Chandler Blanchet",           5_034_818],
  [44, "T44", "Taylor Pendrith",             5_034_818],
  [44, "T44", "Dustin Johnson",              5_034_818],
  [44, "T44", "Nicolai Højgaard",            5_034_818],
  [44, "T44", "Michael Kim",                 5_034_818],
  [44, "T44", "Kristoffer Reitan",           5_034_818],
  [44, "T44", "Chris Kirk",                  5_034_818],
  [55, "T55", "Collin Morikawa",             3_418_600],
  [55, "T55", "Corey Conners",               3_418_600],
  [55, "T55", "Andrew Putnam",               3_418_600],
  [55, "T55", "Brooks Koepka",               3_418_600],
  [55, "T55", "Mikael Lindberg",             3_418_600],
  [60, "T60", "Sami Valimaki",               2_921_800],
  [60, "T60", "Sahith Theegala",             2_921_800],
  [60, "T60", "Rico Hoey",                   2_921_800],
  [60, "T60", "Rickie Fowler",               2_921_800],
  [60, "T60", "Brian Harman",                2_921_800],
  [65, "T65", "Casey Jarvis",                2_690_000],
  [65, "T65", "Jason Day",                   2_690_000],
  [65, "T65", "Rasmus Højgaard",             2_690_000],
  [65, "T65", "Keith Mitchell",              2_690_000],
  [65, "T65", "Sam Stevens",                 2_690_000],
  [70, "T70", "Luke Donald",                 2_507_000],
  [70, "T70", "Ryan Gerard",                 2_507_000],
  [70, "T70", "John Parry",                  2_507_000],
  [70, "T70", "William Mouw",                2_507_000],
  [70, "T70", "Kazuki Higa",                 2_507_000],
  [75, "T75", "Elvis Smylie",                2_419_250],
  [75, "T75", "Rasmus Neergaard-Petersen",   2_419_250],
  [75, "T75", "Alex Fitzpatrick",            2_419_250],
  [75, "T75", "Daniel Brown",                2_419_250],
  [79, "79",  "Johnny Keefer",               2_397_000],
  [80, "80",  "Ben Kern",                    2_393_000],
  [81, "81",  "Michael Brennan",             2_391_000],
  [82, "82",  "Brian Campbell",              2_390_000],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = ["Tyrrell Hatton", "Tommy Fleetwood", "Bryson DeChambeau"].freeze

tournament.update!(status: "completed")

created_results = 0
updated_results = 0

RESULTS.each do |pos, pos_display, name, cents|
  golfer = Golfer.find_by(name: name) || Golfer.create!(name: name)
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
  golfer = Golfer.find_by(name: name) || Golfer.create!(name: name)
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
