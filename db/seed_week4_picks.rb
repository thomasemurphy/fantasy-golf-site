tournament = Tournament.find(4) # THE PLAYERS Championship

GOLFER_ALIASES = {
  "Xander Schuaffle"  => "Xander Schauffele",
  "Xander Schuaffele" => "Xander Schauffele",
  "Ludvig Aberg"      => "Ludvig Åberg",
  "Grame Watson"      => "Graeme Watson",
}

picks_data = [
  { player: "Mike Feeley",        golfer: "Xander Schauffele",  dd: true,  auto: false },
  { player: "Kyle Shaffer",       golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Chad Squires Jr.",   golfer: "Patrick Cantlay",    dd: false, auto: false },
  { player: "Michael Amira",      golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Brian Feeley",       golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Kyle Frazho",        golfer: "Cam Young",          dd: true,  auto: false },
  { player: "CJ Sturges",         golfer: "Xander Schauffele",  dd: false, auto: false },
  { player: "Jay Waugh",          golfer: "Tommy Fleetwood",    dd: false, auto: false },
  { player: "Chad Squires Sr.",   golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Zach Jonas",         golfer: "Ludvig Åberg",       dd: false, auto: false },
  { player: "Jerry Heath",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Paul Cacciotti",     golfer: "Viktor Hovland",     dd: true,  auto: false },
  { player: "Jack Murphy",        golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Tom Murphy",         golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Jimmy Nelson",       golfer: "Xander Schauffele",  dd: true,  auto: false },
  { player: "Michael Lukas",      golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Kyle O'Neil",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Chris Piper",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Daniel Jaffe",       golfer: "Daniel Berger",      dd: true,  auto: false },
  { player: "Andrew Lunder",      golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Michael Barile",     golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Roberto Scheinerle", golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Brian Szepelak",     golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Robert Chambers",    golfer: "Hideki Matsuyama",   dd: true,  auto: false },
  { player: "Mike Davis",         golfer: "Collin Morikawa",    dd: false, auto: false },
  { player: "Mike Murphy",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Jack Gunst",         golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Katie King",         golfer: "Collin Morikawa",    dd: false, auto: false },
  { player: "Luke Grasso",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Pat Lang",           golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Anthony Cerruti",    golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Jason DuBois",       golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Jim Cooke",          golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "JT Ozerities",       golfer: "Min Woo Lee",        dd: false, auto: false },
  { player: "Kevin Hobbs",        golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Graeme Watson",      golfer: "Scottie Scheffler",  dd: true,  auto: false },
  { player: "Ben Engler",         golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Bree Svigelj",       golfer: "Xander Schauffele",  dd: true,  auto: false },
  { player: "Kevin Lang",         golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Daren Wamsley",      golfer: "Collin Morikawa",    dd: false, auto: true  },
  { player: "Nick Scarimbolo",    golfer: "Si Woo Kim",         dd: true,  auto: false },
  { player: "Dustin Daniels",     golfer: "Min Woo Lee",        dd: false, auto: false },
  { player: "Justin Mungarro",    golfer: "Russell Henley",     dd: true,  auto: false },
  { player: "Tim Cooney",         golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Nate Hill",          golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Dan Jaffe",          golfer: "Si Woo Kim",         dd: true,  auto: false },
  { player: "Ryan Finstad",       golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Chad Gauvin",        golfer: "Si Woo Kim",         dd: true,  auto: false },
  { player: "Andy Stepic",        golfer: "Xander Schauffele",  dd: false, auto: false },
  { player: "Reise Kelly",        golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Dylan Linke",        golfer: "Collin Morikawa",    dd: false, auto: false },
  { player: "Matt VanDixhorn",    golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Adam Feeley",        golfer: "Hideki Matsuyama",   dd: true,  auto: false },
  { player: "Jason Mungarro",     golfer: "Xander Schauffele",  dd: true,  auto: false },
  { player: "Dylan Chambers",     golfer: "Collin Morikawa",    dd: true,  auto: false },
  { player: "Nick Cristobal",     golfer: "Ludvig Åberg",       dd: true,  auto: false },
  { player: "Fernando Gomez",     golfer: "Scottie Scheffler",  dd: true,  auto: false },
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
    puts "SKIP: #{user.name} already has a pick for week 4"
    skipped += 1
    next
  end

  pick = Pick.new(
    user:             user,
    tournament:       tournament,
    golfer:           golfer,
    is_double_down:   pd[:dd],
    auto_assigned:    pd[:auto],
    earnings_cents:   0,
  )
  pick.save!(validate: false)
  puts "OK: #{user.name} → #{golfer.name}#{pd[:dd] ? ' [2x]' : ''}#{pd[:auto] ? ' [auto]' : ''}"
  seeded += 1
end

puts ""
puts "Done: #{seeded} seeded, #{skipped} skipped, #{errors} errors"

# Fix double_downs_remaining
puts ""
puts "Fixing double_downs_remaining..."
User.where(admin: false).each do |u|
  used = Pick.where(user_id: u.id, is_double_down: true).count
  correct = 5 - used
  if u.double_downs_remaining != correct
    u.update_column(:double_downs_remaining, correct)
    puts "Fixed #{u.name}: #{u.double_downs_remaining} -> #{correct} (#{used} used)"
  end
end
puts "DD fix done"
