tournament = Tournament.find_by!(week_number: 11)
tournament.update!(status: "in_progress")

g = Golfer.method(:find_by!)

cam_young      = g.(name: "Cam Young")
scheffler      = g.(name: "Scottie Scheffler")
burns          = g.(name: "Sam Burns")
morikawa       = g.(name: "Collin Morikawa")
kitayama       = g.(name: "Kurt Kitayama")
si_woo         = g.(name: "Si Woo Kim")
hovland        = g.(name: "Viktor Hovland")
knapp          = g.(name: "Jake Knapp")
henley         = g.(name: "Russell Henley")
j_thomas       = g.(name: "Justin Thomas")
fleetwood      = g.(name: "Tommy Fleetwood")
min_woo        = g.(name: "Min Woo Lee")
a_scott        = g.(name: "Adam Scott")
gotterup       = g.(name: "Chris Gotterup")
woodland       = g.(name: "Gary Woodland")
j_rose         = g.(name: "Justin Rose")
spieth         = g.(name: "Jordan Spieth")
matsuyama      = g.(name: "Hideki Matsuyama")
spaun          = g.(name: "JJ Spaun")

picks_data = [
  { player: "Mike Feeley",        golfer: cam_young,  dd: false, auto: false },
  { player: "Kyle Frazho",        golfer: scheffler,  dd: true,  auto: false },
  { player: "CJ Sturges",         golfer: burns,      dd: false, auto: false },
  { player: "Andrew Lunder",      golfer: morikawa,   dd: false, auto: false },
  { player: "Andy Stepic",        golfer: cam_young,  dd: true,  auto: false },
  { player: "Nate Hill",          golfer: kitayama,   dd: false, auto: false },
  { player: "Luke Grasso",        golfer: burns,      dd: false, auto: false },
  { player: "Pat Lang",           golfer: cam_young,  dd: false, auto: false },
  { player: "Jimmy Nelson",       golfer: si_woo,     dd: false, auto: false },
  { player: "Tom Murphy",         golfer: cam_young,  dd: true,  auto: false },
  { player: "Jason Mungarro",     golfer: morikawa,   dd: false, auto: false },
  { player: "Chad Squires Jr.",   golfer: hovland,    dd: true,  auto: false },
  { player: "Brian Szepelak",     golfer: morikawa,   dd: true,  auto: false },
  { player: "Bree Svigelj",       golfer: scheffler,  dd: true,  auto: false },
  { player: "Jay Waugh",          golfer: knapp,      dd: false, auto: false },
  { player: "Michael Amira",      golfer: cam_young,  dd: true,  auto: false },
  { player: "Mike Murphy",        golfer: cam_young,  dd: false, auto: false },
  { player: "Jim Cooke",          golfer: cam_young,  dd: true,  auto: false },
  { player: "Justin Mungarro",    golfer: scheffler,  dd: true,  auto: false },
  { player: "Chad Gauvin",        golfer: henley,     dd: false, auto: false },
  { player: "Zach Jonas",         golfer: cam_young,  dd: false, auto: false },
  { player: "Jack Gunst",         golfer: burns,      dd: false, auto: false },
  { player: "Roberto Scheinerle", golfer: morikawa,   dd: false, auto: false },
  { player: "Kyle Shaffer",       golfer: cam_young,  dd: false, auto: false },
  { player: "Fernando Gomez",     golfer: j_thomas,   dd: false, auto: false },
  { player: "Jack Murphy",        golfer: morikawa,   dd: true,  auto: false },
  { player: "Anthony Cerruti",    golfer: fleetwood,  dd: false, auto: false },
  { player: "Graeme Watson",      golfer: min_woo,    dd: false, auto: false },
  { player: "Kevin Hobbs",        golfer: cam_young,  dd: false, auto: false },
  { player: "Reise Kelly",        golfer: a_scott,    dd: false, auto: false },
  { player: "Jason DuBois",       golfer: morikawa,   dd: false, auto: false },
  { player: "Michael Lukas",      golfer: cam_young,  dd: true,  auto: false },
  { player: "Michael Barile",     golfer: gotterup,   dd: false, auto: false },
  { player: "Brian Feeley",       golfer: gotterup,   dd: false, auto: false },
  { player: "Nick Cristobal",     golfer: morikawa,   dd: false, auto: false },
  { player: "Daniel Jaffe",       golfer: woodland,   dd: false, auto: false },
  { player: "Ben Engler",         golfer: cam_young,  dd: false, auto: false },
  { player: "Katie King",         golfer: gotterup,   dd: false, auto: false },
  { player: "Robert Chambers",    golfer: cam_young,  dd: false, auto: false },
  { player: "Kyle O'Neil",        golfer: scheffler,  dd: true,  auto: false },
  { player: "Jerry Heath",        golfer: cam_young,  dd: false, auto: true  },
  { player: "Chad Squires Sr.",   golfer: cam_young,  dd: false, auto: false },
  { player: "Paul Cacciotti",     golfer: j_rose,     dd: false, auto: false },
  { player: "Mike Davis",         golfer: burns,      dd: false, auto: false },
  { player: "Nick Scarimbolo",    golfer: j_rose,     dd: false, auto: false },
  { player: "Daren Wamsley",      golfer: fleetwood,  dd: false, auto: false },
  { player: "JT Ozerities",       golfer: morikawa,   dd: true,  auto: false },
  { player: "Kevin Lang",         golfer: henley,     dd: false, auto: false },
  { player: "Adam Feeley",        golfer: spieth,     dd: false, auto: false },
  { player: "Matt VanDixhorn",    golfer: scheffler,  dd: true,  auto: false },
  { player: "Ryan Finstad",       golfer: gotterup,   dd: false, auto: false },
  { player: "Dustin Daniels",     golfer: morikawa,   dd: false, auto: false },
  { player: "Dylan Linke",        golfer: kitayama,   dd: false, auto: false },
  { player: "Dan Jaffe",          golfer: matsuyama,  dd: false, auto: false },
  { player: "Tim Cooney",         golfer: j_rose,     dd: false, auto: false },
  { player: "Dylan Chambers",     golfer: spaun,      dd: false, auto: false },
  { player: "Chris Piper",        golfer: cam_young,  dd: false, auto: true  },
]

picks_data.each do |pd|
  user = User.find_by!(name: pd[:player])
  next if Pick.exists?(user: user, tournament: tournament)
  pick = Pick.new(
    user:           user,
    tournament:     tournament,
    golfer:         pd[:golfer],
    is_double_down: pd[:dd],
    auto_assigned:  pd[:auto],
    earnings_cents: 0
  )
  pick.save!(validate: false)
end

# Fix double_downs_remaining for all non-admin users
User.where(admin: false).each do |u|
  used    = Pick.where(user_id: u.id, is_double_down: true).count
  correct = 5 - used
  u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
end

puts "Done. Picks: #{Pick.where(tournament: tournament).count}"
