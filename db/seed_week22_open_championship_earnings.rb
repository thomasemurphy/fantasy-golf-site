tournament = Tournament.find_by!(week_number: 22)

# [position_int, position_display, golfer_name, earnings_cents]
# Source: https://www.pgatour.com/article/news/betting-dfs/2026/07/19/points-and-payout-see-what-each-player-earned-at-british-open-royal-birkdale
RESULTS = [
  [ 1, "1",   "Ryan Fox",                    320_000_000],
  [ 2, "2",   "Cameron Young",               184_200_000],
  [ 3, "3",   "Sam Burns",                   118_100_000],
  [ 4, "T4",  "Scottie Scheffler",            82_750_000],
  [ 4, "T4",  "Tommy Fleetwood",              82_750_000],
  [ 6, "T6",  "Casey Jarvis",                 55_088_300],
  [ 6, "T6",  "Lucas Herbert",                55_088_300],
  [ 6, "T6",  "Si Woo Kim",                   55_088_300],
  [ 9, "T9",  "Adam Scott",                   33_638_000],
  [ 9, "T9",  "Russell Henley",               33_638_000],
  [ 9, "T9",  "Rasmus Neergaard-Petersen",    33_638_000],
  [ 9, "T9",  "Ludvig Åberg",                 33_638_000],
  [ 9, "T9",  "Ryan Gerard",                  33_638_000],
  [14, "T14", "Corey Conners",                23_432_500],
  [14, "T14", "Sungjae Im",                   23_432_500],
  [14, "T14", "Hideki Matsuyama",             23_432_500],
  [14, "T14", "Bryson DeChambeau",            23_432_500],
  [18, "T18", "Rickie Fowler",                16_457_500],
  [18, "T18", "Chris Gotterup",               16_457_500],
  [18, "T18", "Bud Cauley",                   16_457_500],
  [18, "T18", "Marco Penge",                  16_457_500],
  [18, "T18", "Alex Noren",                   16_457_500],
  [18, "T18", "Collin Morikawa",              16_457_500],
  [18, "T18", "Jordan Smith",                 16_457_500],
  [18, "T18", "Kristoffer Reitan",            16_457_500],
  [18, "T18", "Dan Brown",                    16_457_500],
  [18, "T18", "Xander Schauffele",            16_457_500],
  [28, "T28", "John Parry",                   10_281_700],
  [28, "T28", "Victor Perez",                 10_281_700],
  [28, "T28", "Patrick Cantlay",              10_281_700],
  [28, "T28", "Brooks Koepka",                10_281_700],
  [28, "T28", "Pierceson Coody",              10_281_700],
  [28, "T28", "Robert MacIntyre",             10_281_700],
  [28, "T28", "Jacob Bridgeman",              10_281_700],
  [28, "T28", "Max Homa",                     10_281_700],
  [28, "T28", "Shane Lowry",                  10_281_700],
  [28, "T28", "Cameron John",                 10_281_700],
  [28, "T28", "Kazuma Kobori",                10_281_700],
  [28, "T28", "Jackson Suber",                10_281_700],
  [40, "T40", "Thomas Detry",                  6_975_000],
  [40, "T40", "J.J. Spaun",                    6_975_000],
  [40, "T40", "Kurt Kitayama",                 6_975_000],
  [40, "T40", "Michael Thorbjornsen",          6_975_000],
  [40, "T40", "Matt Wallace",                  6_975_000],
  [40, "T40", "Rory McIlroy",                  6_975_000],
  [46, "T46", "Matthew Southgate",             5_170_700],
  [46, "T46", "Eugenio Chacarra",              5_170_700],
  [46, "T46", "Patrick Reed",                  5_170_700],
  [46, "T46", "Francesco Molinari",            5_170_700],
  [46, "T46", "Hennie Du Plessis",             5_170_700],
  [46, "T46", "Jose Luis Ballester",           5_170_700],
  [46, "T46", "Jon Rahm",                      5_170_700],
  [53, "T53", "Ryo Hisatsune",                 4_518_300],
  [53, "T53", "Michael Brennan",               4_518_300],
  [53, "T53", "Shaun Norris",                  4_518_300],
  [53, "T53", "Sahith Theegala",               4_518_300],
  [53, "T53", "Alex Smalley",                  4_518_300],
  [53, "T53", "Eric Cole",                     4_518_300],
  [59, "T59", "Ben Griffin",                   4_302_500],
  [59, "T59", "Aldrich Potgieter",             4_302_500],
  [59, "T59", "Min Woo Lee",                   4_302_500],
  [59, "T59", "Nick Taylor",                   4_302_500],
  [59, "T59", "Naoyuki Kataoka",               4_302_500],
  [59, "T59", "Johnny Keefer",                 4_302_500],
  [65, "T65", "Peter Uihlein",                 4_198_800],
  [65, "T65", "Justin Thomas",                 4_198_800],
  [67, "T67", "Sepp Straka",                   4_135_000],
  [67, "T67", "Nico Echavarria",               4_135_000],
  [69, "T69", "Andy Sullivan",                 4_080_000],
  [69, "T69", "Tyrrell Hatton",                4_080_000],
  [71, "T71", "Laurie Canter",                 4_045_000],
  [71, "T71", "MJ Daffue",                     4_045_000],
  [71, "T71", "Alex Fitzpatrick",              4_045_000],
  [74, "T74", "Keegan Bradley",                4_007_500],
  [74, "T74", "Kazuki Higa",                   4_007_500],
  [74, "T74", "Marcus Plunkett",               4_007_500],
  [77, "77",  "Jack McDonald",                 3_982_500],
  [78, "78",  "Jesper Svensson",               3_970_000],
].freeze

# Picked-but-missed-cut golfers (no entry in payout table)
MISSED_CUT_PICKS = [
  "Joaquin Niemann",
  "Justin Rose",
  "Matt Fitzpatrick",
  "Viktor Hovland",
  "Wyndham Clark",
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
