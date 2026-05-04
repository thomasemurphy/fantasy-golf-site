tournament = Tournament.find_by!(week_number: 11)
tournament.update!(status: "completed")

EARNINGS = {
  "Cameron Young"        => 360_000_000,
  "Scottie Scheffler"    => 216_000_000,
  "Si Woo Kim"           => 82_666_667,
  "Adam Scott"           => 82_666_667,
  "Kurt Kitayama"        => 50_000_000,
  "JJ Spaun"             => 35_000_000,
  "Jordan Spieth"        => 26_060_000,
  "Min Woo Lee"          => 26_060_000,
  "Tommy Fleetwood"      => 16_714_286,
  "Justin Thomas"        => 16_714_286,
  "Shane Lowry"          => 16_714_286,
  "Sudarshan Yellamaraju"=> 11_462_500,
  "Ryan Gerard"          => 11_462_500,
  "Sahith Theegala"      => 11_462_500,
  "Viktor Hovland"       => 7_218_182,
  "Gary Woodland"        => 7_218_182,
  "Chris Gotterup"       => 7_218_182,
  "Sam Burns"            => 7_218_182,
  "Max Greyserman"       => 7_218_182,
  "Russell Henley"       => 4_850_000,
  "Hideki Matsuyama"     => 4_600_000,
  "Collin Morikawa"      => 4_150_000,
  "Andrew Novak"         => 3_908_333,
  "Justin Rose"          => 3_908_333,
  # Not in payout table (WD or not in field)
  "Jake Knapp"           => 0,
}.freeze

EARNINGS.each do |name, cents|
  golfer = Golfer.find_by(name: name)
  next unless golfer
  result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
  next unless result
  result.update_columns(earnings_cents: cents)
end

tournament.picks.includes(:golfer).each do |pick|
  cents = pick.auto_assigned? ? 0 : EARNINGS.fetch(pick.golfer.name, nil)
  next if cents.nil?
  multiplier = pick.is_double_down? ? 2 : 1
  pick.update_column(:earnings_cents, cents * multiplier)
end

puts "Done."
tournament.picks.includes(:golfer, :user).sort_by { |p| -p.earnings_cents.to_i }.each do |p|
  dd = p.is_double_down? ? " [2x]" : ""
  auto = p.auto_assigned? ? " (auto)" : ""
  puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto} → $#{p.earnings_cents / 100}"
end
