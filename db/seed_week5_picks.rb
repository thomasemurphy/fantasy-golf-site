tournament = Tournament.find(5) # Valspar Championship

GOLFER_ALIASES = {
  "Xander Schuaffele" => "Xander Schauffele",
  "Grame Watson"      => "Graeme Watson",
}

picks_data = [
  { player: "Kyle Frazho",          golfer: "Ryo Hisatsune" },
  { player: "Mike Feeley",          golfer: "Viktor Hovland" },
  { player: "Jimmy Nelson",         golfer: "Brooks Koepka" },
  { player: "Bree Svigelj",         golfer: "Ryo Hisatsune" },
  { player: "Jason Mungarro",       golfer: "Jacob Bridgeman" },
  { player: "CJ Sturges",           golfer: "Corey Conners" },
  { player: "Andrew Lunder",        golfer: "Jacob Bridgeman" },
  { player: "Michael Barile",       golfer: "Ryo Hisatsune" },
  { player: "Roberto Scheinerle",   golfer: "Justin Thomas" },
  { player: "Jack Gunst",           golfer: "Viktor Hovland" },
  { player: "Jason DuBois",         golfer: "Brooks Koepka" },
  { player: "Kevin Hobbs",          golfer: "Jacob Bridgeman" },
  { player: "Michael Amira",        golfer: "Viktor Hovland" },
  { player: "Brian Feeley",         golfer: "Ryo Hisatsune" },
  { player: "Jay Waugh",            golfer: "Jacob Bridgeman" },
  { player: "Chad Squires Jr.",     golfer: "Justin Thomas" },
  { player: "Nate Hill",            golfer: "Corey Conners" },
  { player: "Zach Jonas",           golfer: "Corey Conners" },
  { player: "Kyle Shaffer",         golfer: "Sahith Theegala" },
  { player: "Paul Cacciotti",       golfer: "Ryo Hisatsune" },
  { player: "Nick Cristobal",       golfer: "Jacob Bridgeman" },
  { player: "Andy Stepic",          golfer: "Matt Fitzpatrick" },
  { player: "Jack Murphy",          golfer: "Ryo Hisatsune" },
  { player: "Michael Lukas",        golfer: "Justin Thomas" },
  { player: "Brian Szepelak",       golfer: "Corey Conners" },
  { player: "Pat Lang",             golfer: "Ben Griffin" },
  { player: "Anthony Cerruti",      golfer: "Viktor Hovland" },
  { player: "Chad Squires Sr.",     golfer: "Ryo Hisatsune" },
  { player: "Jim Cooke",            golfer: "Patrick Cantlay" },
  { player: "Robert Chambers",      golfer: "Ryo Hisatsune" },
  { player: "Jerry Heath",          golfer: "Viktor Hovland" },
  { player: "Graeme Watson",        golfer: "Corey Conners" },
  { player: "Justin Mungarro",      golfer: "Ryo Hisatsune" },
  { player: "Daniel Jaffe",         golfer: "Jacob Bridgeman" },
  { player: "Tom Murphy",           golfer: "Jacob Bridgeman" },
  { player: "Kyle O'Neil",          golfer: "Corey Conners" },
  { player: "Chris Piper",          golfer: "Matt Fitzpatrick" },
  { player: "Mike Davis",           golfer: "Justin Thomas" },
  { player: "Mike Murphy",          golfer: "Jacob Bridgeman" },
  { player: "Katie King",           golfer: "Xander Schauffele" },
  { player: "JT Ozerities",         golfer: "Ben Griffin" },
  { player: "Luke Grasso",          golfer: "Ryo Hisatsune" },
  { player: "Ben Engler",           golfer: "Sahith Theegala" },
  { player: "Fernando Gomez",       golfer: "Ryo Hisatsune" },
  { player: "Dustin Daniels",       golfer: "Sahith Theegala" },
  { player: "Kevin Lang",           golfer: "Jacob Bridgeman" },
  { player: "Nick Scarimbolo",      golfer: "Jacob Bridgeman" },
  { player: "Adam Feeley",          golfer: "Wyndham Clark" },
  { player: "Daren Wamsley",        golfer: "Xander Schauffele" },
  { player: "Dan Jaffe",            golfer: "Jacob Bridgeman" },
  { player: "Tim Cooney",           golfer: "Jacob Bridgeman" },
  { player: "Chad Gauvin",          golfer: "Ryo Hisatsune" },
  { player: "Ryan Finstad",         golfer: "Jacob Bridgeman" },
  { player: "Reise Kelly",          golfer: "Corey Conners" },
  { player: "Dylan Linke",          golfer: "Tom Kim" },
  { player: "Matt VanDixhorn",      golfer: "Sahith Theegala" },
  { player: "Dylan Chambers",       golfer: "Viktor Hovland" },
]

seeded = 0
skipped = 0
errors = 0

picks_data.each do |pd|
  user = User.find_by(name: pd[:player])
  unless user
    puts "ERROR: User not found: #{pd[:player]}"
    errors += 1
    next
  end

  golfer_name = GOLFER_ALIASES[pd[:golfer]] || pd[:golfer]
  golfer = Golfer.find_by(name: golfer_name) ||
           Golfer.all.find { |g| g.name.strip.downcase.gsub(/[^a-z ]/, '') == golfer_name.strip.downcase.gsub(/[^a-z ]/, '') }
  unless golfer
    puts "ERROR: Golfer not found: #{golfer_name}"
    errors += 1
    next
  end

  if Pick.exists?(user: user, tournament: tournament)
    puts "SKIP: #{user.name} already has a pick for week 5"
    skipped += 1
    next
  end

  pick = Pick.new(
    user:           user,
    tournament:     tournament,
    golfer:         golfer,
    is_double_down: false,
    auto_assigned:  false,
    earnings_cents: 0,
  )
  pick.save!(validate: false)
  puts "OK: #{user.name} → #{golfer.name}"
  seeded += 1
end

puts ""
puts "Done: #{seeded} seeded, #{skipped} skipped, #{errors} errors"
