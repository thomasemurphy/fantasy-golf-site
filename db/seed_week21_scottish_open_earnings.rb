tournament = Tournament.find_by!(week_number: 21)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/07/12/prize-money-purse-payouts-breakdown-fund-genesis-scottish-open-The-Renaissance-club1
RESULTS = [
  [ 1, "1",   "Tom Kim",                      157_500_000],
  [ 2, "2",   "Min Woo Lee",                   98_550_000],
  [ 3, "T3",  "Keita Nakajima",                43_188_750],
  [ 3, "T3",  "Johnny Keefer",                 43_188_750],
  [ 3, "T3",  "Matt Fitzpatrick",              43_188_750],
  [ 3, "T3",  "Robert MacIntyre",              43_188_750],
  [ 7, "T7",  "Rory McIlroy",                  27_067_500],
  [ 7, "T7",  "Michael Thorbjornsen",          27_067_500],
  [ 9, "T9",  "Victor Perez",                  22_320_000],
  [ 9, "T9",  "Si Woo Kim",                    22_320_000],
  [11, "T11", "Kevin Roy",                     18_967_500],
  [11, "T11", "Chris Gotterup",                18_967_500],
  [13, "T13", "Viktor Hovland",                15_345_000],
  [13, "T13", "Patrick Reed",                  15_345_000],
  [13, "T13", "Tommy Fleetwood",               15_345_000],
  [13, "T13", "Wyndham Clark",                 15_345_000],
  [17, "T17", "Francesco Molinari",            12_375_000],
  [17, "T17", "Joost Luiten",                  12_375_000],
  [17, "T17", "Tyrrell Hatton",                12_375_000],
  [17, "T17", "Alejandro Del Rey",             12_375_000],
  [21, "T21", "Cam Davis",                      9_765_000],
  [21, "T21", "Casey Jarvis",                   9_765_000],
  [21, "T21", "Matti Schmid",                   9_765_000],
  [21, "T21", "Jordan Smith",                   9_765_000],
  [21, "T21", "Danny Willett",                  9_765_000],
  [26, "T26", "Nick Taylor",                    7_875_000],
  [26, "T26", "Nicolai Højgaard",               7_875_000],
  [26, "T26", "Ryan Gerard",                    7_875_000],
  [26, "T26", "Marcus Armitage",                7_875_000],
  [30, "T30", "Andy Sullivan",                  6_536_250],
  [30, "T30", "Ryan Fox",                       6_536_250],
  [30, "T30", "Austin Eckroat",                 6_536_250],
  [30, "T30", "Tom McKibbin",                   6_536_250],
  [30, "T30", "Karl Vilips",                    6_536_250],
  [30, "T30", "Mac Meissner",                   6_536_250],
  [36, "T36", "Shaun Norris",                   4_997_813],
  [36, "T36", "Brian Harman",                   4_997_813],
  [36, "T36", "Rasmus Højgaard",                4_997_813],
  [36, "T36", "Max Greyserman",                 4_997_813],
  [36, "T36", "Nico Echavarria",                4_997_813],
  [36, "T36", "Jon Rahm",                       4_997_813],
  [36, "T36", "Oliver Lindell",                 4_997_813],
  [36, "T36", "Rasmus Neergaard-Petersen",      4_997_813],
  [44, "T44", "Kurt Kitayama",                  3_745_500],
  [44, "T44", "Ricky Castillo",                 3_745_500],
  [44, "T44", "Darius Van Driel",               3_745_500],
  [44, "T44", "Calum Hill",                     3_745_500],
  [44, "T44", "Mikael Lindberg",                3_745_500],
  [44, "T44", "J.J. Spaun",                     3_745_500],
  [50, "T50", "Laurie Canter",                  3_145_500],
  [50, "T50", "Justin Thomas",                  3_145_500],
  [52, "T52", "Eugenio Chacarra",               2_723_143],
  [52, "T52", "Michael Brennan",                2_723_143],
  [52, "T52", "Corey Conners",                  2_723_143],
  [52, "T52", "Andrew Putnam",                  2_723_143],
  [52, "T52", "Nicolai Von Dellingshausen",     2_723_143],
  [52, "T52", "Jesper Svensson",                2_723_143],
  [52, "T52", "Sudarshan Yellamaraju",          2_723_143],
  [59, "T59", "Jacques Kruyswijk",               2_457_000],
  [59, "T59", "Guido Migliozzi",                 2_457_000],
  [61, "T61", "Hennie Du Plessis",               2_268_000],
  [61, "T61", "Yuto Katsuragawa",                2_268_000],
  [61, "T61", "Andrew Novak",                    2_268_000],
  [61, "T61", "Adrien Saddier",                  2_268_000],
  [61, "T61", "Chris Kirk",                      2_268_000],
  [66, "T66", "Adam Scott",                      1_971_000],
  [66, "T66", "Sahith Theegala",                 1_971_000],
  [68, "68",  "Nacho Elvira",                    1_944_000],
  [69, "69",  "Davis Riley",                     1_926_000],
  [70, "70",  "Eric Cole",                       1_908_000],
  [71, "71",  "Scott Jamieson",                  1_890_000],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = [
  "Shane Lowry",
  "Xander Schauffele",
  "Alex Fitzpatrick",
  "Kristoffer Reitan",
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
