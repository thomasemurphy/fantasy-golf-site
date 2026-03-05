picks_data = [
  { player: 'Kyle Shaffer',       golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Brian Feeley',       golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Chad Squires Jr.',   golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Michael Amira',      golfer: 'Russell Henley',    double: false, auto: false },
  { player: 'Jerry Heath',        golfer: 'Xander Schauffele', double: false, auto: false },
  { player: 'Jack Murphy',        golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Paul Cacciotti',     golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Chris Piper',        golfer: 'Rory McIlroy',      double: true,  auto: false },
  { player: "Kyle O'Neil",        golfer: 'Hideki Matsuyama',  double: false, auto: false },
  { player: 'Kyle Frazho',        golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Michael Barile',     golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Andrew Lunder',      golfer: 'Tommy Fleetwood',   double: true,  auto: false },
  { player: 'Roberto Scheinerle', golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Brian Szepelak',     golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Mike Davis',         golfer: 'Rory McIlroy',      double: false, auto: false },
  { player: 'Katie King',         golfer: 'Rory McIlroy',      double: true,  auto: false },
  { player: 'CJ Sturges',         golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Pat Lang',           golfer: 'Rory McIlroy',      double: true,  auto: false },
  { player: 'Mike Murphy',        golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Jason DuBois',       golfer: 'Patrick Cantlay',   double: false, auto: false },
  { player: 'Luke Grasso',        golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Tom Murphy',         golfer: 'Scottie Scheffler', double: true,  auto: false },
  { player: 'Anthony Cerruti',    golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Kevin Hobbs',        golfer: 'Rory McIlroy',      double: true,  auto: false },
  { player: 'Mike Feeley',        golfer: 'Collin Morikawa',   double: true,  auto: false },
  { player: 'Jim Cooke',          golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Graeme Watson',      golfer: 'Sam Burns',         double: false, auto: false },
  { player: 'Ben Engler',         golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Bree Svigelj',       golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Kevin Lang',         golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Zach Jonas',         golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'JT Ozerities',       golfer: 'Scottie Scheffler', double: true,  auto: false },
  { player: 'Jay Waugh',          golfer: 'Ludvig Aberg',      double: false, auto: false },
  { player: 'Dustin Daniels',     golfer: 'Rory McIlroy',      double: false, auto: false },
  { player: 'Jimmy Nelson',       golfer: 'Russell Henley',    double: false, auto: false },
  { player: 'Michael Lukas',      golfer: 'Sahith Theegala',   double: false, auto: false },
  { player: 'Dan Jaffe',          golfer: 'Shane Lowry',       double: false, auto: false },
  { player: 'Justin Mungarro',    golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Nate Hill',          golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Nick Scarimbolo',    golfer: 'Tommy Fleetwood',   double: true,  auto: false },
  { player: 'Tim Cooney',         golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Daren Wamsley',      golfer: 'Scottie Scheffler', double: false, auto: false },
  { player: 'Ryan Finstad',       golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Daniel Jaffe',       golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Chad Gauvin',        golfer: 'Rory McIlroy',      double: false, auto: false },
  { player: 'Dylan Linke',        golfer: 'Rory McIlroy',      double: false, auto: false },
  { player: 'Chad Squires Sr.',   golfer: 'Ludvig Aberg',      double: false, auto: false },
  { player: 'Matt VanDixhorn',    golfer: 'Tommy Fleetwood',   double: false, auto: true  },
  { player: 'Robert Chambers',    golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Reise Kelly',        golfer: 'Matt Fitzpatrick',  double: false, auto: false },
  { player: 'Jack Gunst',         golfer: 'Collin Morikawa',   double: false, auto: false },
  { player: 'Dylan Chambers',     golfer: 'Tommy Fleetwood',   double: false, auto: true  },
  { player: 'Adam Feeley',        golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Jason Mungarro',     golfer: 'Tommy Fleetwood',   double: false, auto: false },
  { player: 'Andy Stepic',        golfer: 'Harris English',    double: false, auto: false },
  { player: 'Fernando Gomez',     golfer: 'Shane Lowry',       double: false, auto: false },
  { player: 'Nick Cristobal',     golfer: 'Tommy Fleetwood',   double: false, auto: false },
]

tournament = Tournament.find(3)
errors = []
created = 0

picks_data.each do |pd|
  user = User.where('lower(name) = ?', pd[:player].downcase).first
  unless user
    errors << "User not found: #{pd[:player]}"
    next
  end

  golfer = Golfer.all.find { |g| g.name.strip.downcase == pd[:golfer].strip.downcase } ||
           Golfer.all.find { |g| g.name.strip.downcase.gsub(/[^a-z ]/, '') == pd[:golfer].strip.downcase.gsub(/[^a-z ]/, '') }
  unless golfer
    errors << "Golfer not found: #{pd[:golfer]}"
    next
  end

  pick = Pick.new(
    user_id: user.id,
    tournament_id: tournament.id,
    golfer_id: golfer.id,
    is_double_down: pd[:double],
    auto_assigned: pd[:auto],
    earnings_cents: 0
  )
  pick.save!(validate: false)
  puts "Created: #{user.name} -> #{golfer.name}#{' (DD)' if pd[:double]}#{' (AUTO)' if pd[:auto]}"
  created += 1
end

puts "\n=== Done: #{created} picks created ==="
errors.each { |e| puts "ERROR: #{e}" }

tournament.update!(status: 'active')
puts "Tournament 3 (#{tournament.name}) marked as active."
