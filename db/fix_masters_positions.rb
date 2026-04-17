# Fix Masters 2026 finishing positions (current_position_display + position)
# Run: heroku run rails runner db/fix_masters_positions.rb --app ftc

MASTERS_POSITIONS = {
  "Rory McIlroy"        => ["1",   1],
  "Scottie Scheffler"   => ["2",   2],
  "Tyrrell Hatton"      => ["T3",  3],
  "Russell Henley"      => ["T3",  3],
  "Justin Rose"         => ["T3",  3],
  "Cameron Young"       => ["T3",  3],
  "Collin Morikawa"     => ["T7",  7],
  "Sam Burns"           => ["T7",  7],
  "Max Homa"            => ["T9",  9],
  "Xander Schauffele"   => ["T9",  9],
  "Jake Knapp"          => ["11",  11],
  "Jordan Spieth"       => ["T12", 12],
  "Hideki Matsuyama"    => ["T12", 12],
  "Brooks Koepka"       => ["T12", 12],
  "Patrick Reed"        => ["T12", 12],
  "Patrick Cantlay"     => ["T12", 12],
  "Jason Day"           => ["T12", 12],
  "Viktor Hovland"      => ["T18", 18],
  "Maverick McNealy"    => ["T18", 18],
  "Matt Fitzpatrick"    => ["T18", 18],
  "Keegan Bradley"      => ["T21", 21],
  "Ludvig Åberg"        => ["T21", 21],
  "Wyndham Clark"       => ["T21", 21],
  "Matt McCarty"        => ["T24", 24],
  "Adam Scott"          => ["T24", 24],
  "Sam Stevens"         => ["T24", 24],
  "Chris Gotterup"      => ["T24", 24],
  "Michael Brennan"     => ["T24", 24],
  "Brian Campbell"      => ["T24", 24],
  "Alex Noren"          => ["T30", 30],
  "Harris English"      => ["T30", 30],
  "Shane Lowry"         => ["T30", 30],
  "Gary Woodland"       => ["T33", 33],
  "Dustin Johnson"      => ["T33", 33],
  "Brian Harman"        => ["T33", 33],
  "Tommy Fleetwood"     => ["T33", 33],
  "Ben Griffin"         => ["T33", 33],
  "Jon Rahm"            => ["T38", 38],
  "Ryan Gerard"         => ["T38", 38],
  "Haotong Li"          => ["T38", 38],
  "Justin Thomas"       => ["T41", 41],
  "Sepp Straka"         => ["T41", 41],
  "Jacob Bridgeman"     => ["T41", 41],
  "Kristoffer Reitan"   => ["T41", 41],
  "Nick Taylor"         => ["T41", 41],
  "Sungjae Im"          => ["46",  46],
  "Si Woo Kim"          => ["47",  47],
  "Aaron Rai"           => ["48",  48],
  "Corey Conners"       => ["T49", 49],
  "Marco Penge"         => ["T49", 49],
  "Kurt Kitayama"       => ["51",  51],
  "Sergio García"       => ["52",  52],
  "Rasmus Højgaard"     => ["53",  53],
  "Charl Schwartzel"    => ["54",  54],
}.freeze

tournament = Tournament.find(8)
updated = 0
not_found = []

MASTERS_POSITIONS.each do |name, (display, pos)|
  golfer = Golfer.find_by(name: name)
  unless golfer
    not_found << name
    next
  end
  result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
  unless result
    puts "  WARNING: No result row for #{name}"
    next
  end
  result.update_columns(current_position_display: display, position: pos)
  updated += 1
end

# Set CUT for all missed-cut golfers
cut_count = TournamentResult.where(tournament: tournament, made_cut: false)
                             .update_all(current_position_display: "CUT", position: nil)

puts "Positions set: #{updated} finishers, #{cut_count} CUT"
puts "Not found: #{not_found.join(', ')}" if not_found.any?
puts "Done."
