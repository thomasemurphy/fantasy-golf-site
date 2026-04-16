# Fix Masters 2026 earnings from official PGA Tour payout data
# Run: heroku run rails runner db/fix_masters_earnings.rb --app ftc

MASTERS_PAYOUTS = {
  "Rory McIlroy"        => 4_500_000,
  "Scottie Scheffler"   => 2_430_000,
  "Tyrrell Hatton"      =>   1_080_000,
  "Russell Henley"      =>   1_080_000,
  "Justin Rose"         =>   1_080_000,
  "Cameron Young"       =>   1_080_000,
  "Collin Morikawa"     =>     725_625,
  "Sam Burns"           =>     725_625,
  "Max Homa"            =>     630_000,
  "Xander Schauffele"   =>     630_000,
  "Jake Knapp"          =>     562_500,
  "Jordan Spieth"       =>     427_500,
  "Hideki Matsuyama"    =>     427_500,
  "Brooks Koepka"       =>     427_500,
  "Patrick Reed"        =>     427_500,
  "Patrick Cantlay"     =>     427_500,
  "Jason Day"           =>     427_500,
  "Viktor Hovland"      =>     315_000,
  "Maverick McNealy"    =>     315_000,
  "Matt Fitzpatrick"    =>     315_000,
  "Keegan Bradley"      =>     252_000,
  "Ludvig Åberg"        =>     252_000,
  "Wyndham Clark"       =>     252_000,
  "Matt McCarty"        =>     182_250,
  "Adam Scott"          =>     182_250,
  "Sam Stevens"         =>     182_250,
  "Chris Gotterup"      =>     182_250,
  "Michael Brennan"     =>     182_250,
  "Brian Campbell"      =>     182_250,
  "Alex Noren"          =>     146_250,
  "Harris English"      =>     146_250,
  "Shane Lowry"         =>     146_250,
  "Gary Woodland"       =>     121_500,
  "Dustin Johnson"      =>     121_500,
  "Brian Harman"        =>     121_500,
  "Tommy Fleetwood"     =>     121_500,
  "Ben Griffin"         =>     121_500,
  "Jon Rahm"            =>     101_250,
  "Ryan Gerard"         =>     101_250,
  "Haotong Li"          =>     101_250,
  "Justin Thomas"       =>      83_250,
  "Sepp Straka"         =>      83_250,
  "Jacob Bridgeman"     =>      83_250,
  "Kristoffer Reitan"   =>      83_250,
  "Nick Taylor"         =>      83_250,
  "Sungjae Im"          =>      69_750,
  "Si Woo Kim"          =>      65_250,
  "Aaron Rai"           =>      61_650,
  "Corey Conners"       =>      57_600,
  "Marco Penge"         =>      57_600,
  "Kurt Kitayama"       =>      55_350,
  "Sergio Garcia"       =>      54_000,
  "Rasmus Højgaard"     =>      53_100,
  "Charl Schwartzel"    =>      52_200,
}.freeze

tournament = Tournament.find(8)
puts "Tournament: #{tournament.name} (id=#{tournament.id}, status=#{tournament.status})"
puts "---"

updated_results = 0
skipped_results = 0
not_found = []

MASTERS_PAYOUTS.each do |name, dollars|
  cents = dollars * 100

  golfer = Golfer.where("name ILIKE ?", name).first
  unless golfer
    not_found << name
    next
  end

  result = TournamentResult.find_by(tournament_id: tournament.id, golfer_id: golfer.id)
  unless result
    puts "  WARNING: No TournamentResult for #{name} (golfer_id=#{golfer.id})"
    next
  end

  old = result.earnings_cents
  result.update_columns(earnings_cents: cents, current_earnings_cents: cents, made_cut: true)
  puts "  Updated #{name}: $#{old.to_i / 100} → $#{dollars}"
  updated_results += 1
end

# Zero out any results for golfers who missed the cut (not in payout list)
missed_cut_results = TournamentResult.where(tournament_id: tournament.id)
                                     .where.not(golfer_id: Golfer.where("name ILIKE ANY (ARRAY[?])", MASTERS_PAYOUTS.keys).pluck(:id))
missed_cut_results.each do |r|
  r.update_columns(earnings_cents: 0, current_earnings_cents: 0, made_cut: false)
  puts "  Zeroed (missed cut): #{r.golfer.name}"
end

puts "---"
puts "Results updated: #{updated_results}"
puts "Golfers not found in DB: #{not_found.join(', ')}" if not_found.any?

# Now recalculate Pick earnings for the Masters
puts "\nRecalculating pick earnings for Masters picks..."
picks_updated = 0

Pick.where(tournament_id: tournament.id).each do |pick|
  result = TournamentResult.find_by(tournament_id: tournament.id, golfer_id: pick.golfer_id)
  unless result
    puts "  No result for pick: #{pick.user.email} → #{pick.golfer.name}"
    next
  end

  base_cents = pick.auto_assigned? ? 0 : (result.earnings_cents || 0)
  effective_cents = pick.is_double_down? ? base_cents * 2 : base_cents
  made_cut = result.made_cut

  old_earnings = pick.earnings_cents
  pick.update_columns(earnings_cents: effective_cents, made_cut: made_cut)
  dd_label = pick.is_double_down? ? " (2x DD)" : ""
  puts "  #{pick.user.email} → #{pick.golfer.name}#{dd_label}: $#{old_earnings.to_i / 100} → $#{effective_cents / 100}"
  picks_updated += 1
end

puts "Picks updated: #{picks_updated}"
puts "Done."
