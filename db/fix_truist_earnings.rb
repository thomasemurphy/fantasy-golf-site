tournament = Tournament.find_by!(week_number: 12)
tournament.update!(status: "completed")

EARNINGS = {
  "Rickie Fowler"   => 176_000_000,
  "Tommy Fleetwood" =>  73_000_000,
  "JJ Spaun"        =>  73_000_000,
  "Ludvig Åberg"    =>  60_000_000,
  "Patrick Cantlay" =>  50_000_000,
  "Cameron Young"   =>  50_000_000,
  "Justin Thomas"   =>  42_000_000,
  "Xander Schauffele" => 4_250_000,
  "Sam Burns"       =>   8_218_750,
  "Adam Scott"      =>  15_664_286,
  "Rory McIlroy"    =>  24_210_000,
  "Kurt Kitayama"   =>  24_210_000,
  "Ben Griffin"     =>   4_125_000,
  "Si Woo Kim"      =>   4_025_000,
  "Russell Henley"  =>           0,
}.freeze

EARNINGS.each do |name, cents|
  golfer = Golfer.find_by(name: name)
  next puts "WARN: golfer not found — #{name}" unless golfer
  result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
  next unless result
  result.update_columns(earnings_cents: cents)
end

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
