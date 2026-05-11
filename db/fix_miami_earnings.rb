tournament = Tournament.find_by!(week_number: 11)
tournament.update!(status: "completed")

# Full payout table — all 72 finishers + 0 for WD/not in field
EARNINGS = {
  "Cameron Young"          => 360_000_000,
  "Scottie Scheffler"      => 216_000_000,
  "Ben Griffin"            => 136_000_000,
  "Adam Scott"             =>  82_666_667,
  "Sepp Straka"            =>  82_666_667,
  "Si Woo Kim"             =>  82_666_667,
  "Alex Smalley"           =>  64_500_000,
  "Alex Noren"             =>  64_500_000,
  "Alex Fitzpatrick"       =>  50_000_000,
  "Kurt Kitayama"          =>  50_000_000,
  "Rickie Fowler"          =>  50_000_000,
  "Nick Taylor"            =>  50_000_000,
  "Matt McCarty"           =>  50_000_000,
  "Lucas Glover"           =>  35_000_000,
  "JJ Spaun"               =>  35_000_000,
  "Aldrich Potgieter"      =>  35_000_000,
  "Kristoffer Reitan"      =>  35_000_000,
  "Sam Stevens"            =>  26_060_000,
  "Min Woo Lee"            =>  26_060_000,
  "Andrew Putnam"          =>  26_060_000,
  "Jordan Spieth"          =>  26_060_000,
  "Michael Kim"            =>  26_060_000,
  "Tommy Fleetwood"        =>  16_714_286,
  "Justin Thomas"          =>  16_714_286,
  "Matt Wallace"           =>  16_714_286,
  "Nicolai Højgaard"       =>  16_714_286,
  "Shane Lowry"            =>  16_714_286,
  "Daniel Berger"          =>  16_714_286,
  "Akshay Bhatia"          =>  16_714_286,
  "Ryan Fox"               =>  11_462_500,
  "Sudarshan Yellamaraju"  =>  11_462_500,
  "Denny McCarthy"         =>  11_462_500,
  "Maverick McNealy"       =>  11_462_500,
  "Ryan Gerard"            =>  11_462_500,
  "Corey Conners"          =>  11_462_500,
  "Harry Hall"             =>  11_462_500,
  "Sahith Theegala"        =>  11_462_500,
  "Max Homa"               =>   7_218_182,
  "Taylor Pendrith"        =>   7_218_182,
  "Gary Woodland"          =>   7_218_182,
  "Pierceson Coody"        =>   7_218_182,
  "Jason Day"              =>   7_218_182,
  "Chris Gotterup"         =>   7_218_182,
  "Sam Burns"              =>   7_218_182,
  "Max Greyserman"         =>   7_218_182,
  "Brian Harman"           =>   7_218_182,
  "Bud Cauley"             =>   7_218_182,
  "Viktor Hovland"         =>   7_218_182,
  "Brian Campbell"         =>   4_850_000,
  "Keegan Bradley"         =>   4_850_000,
  "Russell Henley"         =>   4_850_000,
  "J.T. Poston"            =>   4_850_000,
  "Michael Thorbjornsen"   =>   4_600_000,
  "Hideki Matsuyama"       =>   4_600_000,
  "Ricky Castillo"         =>   4_450_000,
  "Jordan Smith"           =>   4_450_000,
  "Harris English"         =>   4_450_000,
  "Nico Echavarria"        =>   4_450_000,
  "Keith Mitchell"         =>   4_450_000,
  "Jhonattan Vegas"        =>   4_275_000,
  "Austin Smotherman"      =>   4_275_000,
  "Collin Morikawa"        =>   4_150_000,
  "Tom Hoge"               =>   4_150_000,
  "Joel Dahmen"            =>   4_150_000,
  "Patrick Rodgers"        =>   3_908_333,
  "Jacob Bridgeman"        =>   3_908_333,
  "Ryo Hisatsune"          =>   3_908_333,
  "Sungjae Im"             =>   3_908_333,
  "Andrew Novak"           =>   3_908_333,
  "Justin Rose"            =>   3_908_333,
  "David Lipsky"           =>   3_700_000,
  "Chandler Blanchet"      =>   3_600_000,
  # WD / not in field
  "Jake Knapp"             =>           0,
}.freeze

# Update tournament_results for all golfers
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
