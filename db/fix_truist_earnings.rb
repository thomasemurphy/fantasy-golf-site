tournament = Tournament.find_by!(week_number: 12)
tournament.update!(status: "completed")

# Full payout table — all 72 finishers + 0 for missed cut / WD
EARNINGS = {
  "Kristoffer Reitan"     => 360_000_000,
  "Rickie Fowler"         => 176_000_000,
  "Nicolai Højgaard"      => 176_000_000,
  "Alex Fitzpatrick"      =>  96_000_000,
  "Tommy Fleetwood"       =>  73_000_000,
  "Sungjae Im"            =>  73_000_000,
  "JJ Spaun"              =>  73_000_000,
  "Ludvig Åberg"          =>  60_000_000,
  "Harry Hall"            =>  60_000_000,
  "Patrick Cantlay"       =>  50_000_000,
  "Matt McCarty"          =>  50_000_000,
  "Cameron Young"         =>  50_000_000,
  "Justin Thomas"         =>  42_000_000,
  "Min Woo Lee"           =>  36_000_000,
  "Chris Gotterup"        =>  36_000_000,
  "Nick Taylor"           =>  36_000_000,
  "Alex Smalley"          =>  31_000_000,
  "Gary Woodland"         =>  31_000_000,
  "Austin Smotherman"     =>  24_210_000,
  "Rory McIlroy"          =>  24_210_000,
  "Keegan Bradley"        =>  24_210_000,
  "Sudarshan Yellamaraju" =>  24_210_000,
  "Kurt Kitayama"         =>  24_210_000,
  "Patrick Rodgers"       =>  15_664_286,
  "Pierceson Coody"       =>  15_664_286,
  "Adam Scott"            =>  15_664_286,
  "Andrew Novak"          =>  15_664_286,
  "Harris English"        =>  15_664_286,
  "J.T. Poston"           =>  15_664_286,
  "David Lipsky"          =>  15_664_286,
  "Brian Harman"          =>  11_441_667,
  "Viktor Hovland"        =>  11_441_667,
  "Alex Noren"            =>  11_441_667,
  "Tony Finau"            =>  11_441_667,
  "Nico Echavarria"       =>  11_441_667,
  "Corey Conners"         =>  11_441_667,
  "Sam Burns"             =>   8_218_750,
  "Maverick McNealy"      =>   8_218_750,
  "Akshay Bhatia"         =>   8_218_750,
  "Taylor Pendrith"       =>   8_218_750,
  "Matt Wallace"          =>   8_218_750,
  "Andrew Putnam"         =>   8_218_750,
  "Bud Cauley"            =>   8_218_750,
  "Lucas Glover"          =>   8_218_750,
  "Justin Rose"           =>   6_000_000,
  "Daniel Berger"         =>   6_000_000,
  "Ryo Hisatsune"         =>   6_000_000,
  "Denny McCarthy"        =>   5_000_000,
  "Aldrich Potgieter"     =>   5_000_000,
  "Webb Simpson"          =>   5_000_000,
  "Michael Kim"           =>   5_000_000,
  "Mackenzie Hughes"      =>   4_518_750,
  "Max Homa"              =>   4_518_750,
  "Brian Campbell"        =>   4_518_750,
  "Jhonattan Vegas"       =>   4_518_750,
  "Matt Fitzpatrick"      =>   4_518_750,
  "Chandler Blanchet"     =>   4_518_750,
  "Jordan Spieth"         =>   4_518_750,
  "Jacob Bridgeman"       =>   4_518_750,
  "Xander Schauffele"     =>   4_250_000,
  "Robert MacIntyre"      =>   4_250_000,
  "Ricky Castillo"        =>   4_250_000,
  "Ben Griffin"           =>   4_125_000,
  "Sepp Straka"           =>   4_125_000,
  "Ryan Gerard"           =>   4_025_000,
  "Si Woo Kim"            =>   4_025_000,
  "Ryan Fox"              =>   3_950_000,
  "Jason Day"             =>   3_900_000,
  "Sahith Theegala"       =>   3_800_000,
  "Sam Stevens"           =>   3_750_000,
  "Hideki Matsuyama"      =>   3_700_000,
  "Tom Hoge"              =>   3_600_000,
  # Missed cut / WD — not in payout table
  "Russell Henley"        =>           0,
}.freeze

# Update tournament_results for all golfers in the payout table
EARNINGS.each do |name, cents|
  golfer = Golfer.find_by(name: name)
  next puts "WARN: golfer not found — #{name}" unless golfer
  result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
  next unless result
  result.update_columns(earnings_cents: cents)
end

# Update picks (auto → $0, DD → 2x)
tournament.picks.includes(:golfer).each do |pick|
  cents = pick.auto_assigned? ? 0 : EARNINGS.fetch(pick.golfer.name, nil)
  next puts "WARN: no earnings entry for #{pick.golfer.name}" if cents.nil?
  multiplier = pick.is_double_down? ? 2 : 1
  pick.update_column(:earnings_cents, cents * multiplier)
end

puts "Done."
tournament.picks.includes(:golfer, :user).sort_by { |p| -p.earnings_cents.to_i }.each do |p|
  dd   = p.is_double_down? ? " [2x]" : ""
  auto = p.auto_assigned?  ? " (auto)" : ""
  puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto} → $#{p.earnings_cents / 100}"
end
