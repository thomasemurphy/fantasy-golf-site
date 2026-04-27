tournament = Tournament.find_by!(week_number: 10)
tournament.update!(status: "completed")

# Final earnings per golfer in cents (per-player amounts from PGA Tour payout article)
EARNINGS = {
  "Alex Fitzpatrick"      => 137_275_000,
  "Matt Fitzpatrick"      => 137_275_000,
  "Andrew Novak"          => 11_249_583,
  "Ben Griffin"           => 11_249_583,
  "Karl Vilips"           => 6_949_250,
  "Aaron Rai"             => 2_555_500,
  "Sahith Theegala"       => 2_555_500,
  "Taylor Moore"          => 3_610_000,
  "Ryan Gerard"           => 1_947_500,
  "Sudarshan Yellamaraju" => 1_947_500,
  # Missed cut — not in payout table
  "Brooks Koepka"         => 0,
  "Shane Lowry"           => 0,
  "Max Greyserman"        => 0,
}

# Update tournament_results.earnings_cents
EARNINGS.each do |name, cents|
  golfer = Golfer.find_by(name: name)
  next unless golfer
  result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
  next unless result
  result.update_columns(earnings_cents: cents)
end

# Update picks.earnings_cents (auto-assigned picks always earn $0)
tournament.picks.includes(:golfer).each do |pick|
  cents = pick.auto_assigned? ? 0 : EARNINGS.fetch(pick.golfer.name, nil)
  next if cents.nil?
  multiplier = pick.is_double_down? ? 2 : 1
  pick.update_column(:earnings_cents, cents * multiplier)
end

puts "Done."
puts tournament.picks.includes(:golfer).map { |p|
  "#{p.user_id} #{p.golfer.name}: $#{p.earnings_cents / 100}"
}.join("\n")
