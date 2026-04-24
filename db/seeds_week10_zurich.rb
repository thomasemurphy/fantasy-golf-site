tournament = Tournament.find_by!(week_number: 10)
tournament.update!(is_team_event: true, status: "in_progress")

# Ensure new golfers exist
alex_fitz     = Golfer.find_or_create_by!(name: "Alex Fitzpatrick")
n_thorbjornsen = Golfer.find_or_create_by!(name: "Nicolai Thorbjornsen")

# Existing golfers
matt_fitz    = Golfer.find_by!(name: "Matt Fitzpatrick")
koepka       = Golfer.find_by!(name: "Brooks Koepka")
lowry        = Golfer.find_by!(name: "Shane Lowry")
novak        = Golfer.find_by!(name: "Andrew Novak")
griffin      = Golfer.find_by!(name: "Ben Griffin")
rai          = Golfer.find_by!(name: "Aaron Rai")
theegala     = Golfer.find_by!(name: "Sahith Theegala")
clark        = Golfer.find_by!(name: "Wyndham Clark")
t_moore      = Golfer.find_by!(name: "Taylor Moore")
gerard       = Golfer.find_by!(name: "Ryan Gerard")
yellamaraju  = Golfer.find_by!(name: "Sudarshan Yellamaraju")
finau        = Golfer.find_by!(name: "Tony Finau")
greyserman   = Golfer.find_by!(name: "Max Greyserman")
vilips       = Golfer.find_by!(name: "Karl Vilips")

# Team pairings (ESPN display name => [golfer_a, golfer_b])
pairings = {
  "Fitzpatrick/Fitzpatrick" => [matt_fitz,   alex_fitz],
  "Koepka/Lowry"            => [koepka,      lowry],
  "Griffin/Novak"           => [griffin,     novak],
  "Rai/Theegala"            => [rai,         theegala],
  "Clark/Moore"             => [clark,       t_moore],
  "Gerard/Yellamaraju"      => [gerard,      yellamaraju],
  "Finau/Greyserman"        => [finau,       greyserman],
  "Vilips/Thorbjornsen"     => [vilips,      n_thorbjornsen],
}

pairings.each do |espn_name, (ga, gb)|
  TeamPairing.find_or_create_by!(tournament: tournament, espn_team_name: espn_name) do |tp|
    tp.golfer_a = ga
    tp.golfer_b = gb
  end
end

picks_data = [
  { player: "Mike Feeley",        golfer: koepka,      dd: false, auto: false },
  { player: "Kyle Frazho",        golfer: alex_fitz,   dd: false, auto: false },
  { player: "Andy Stepic",        golfer: novak,       dd: false, auto: false },
  { player: "CJ Sturges",         golfer: alex_fitz,   dd: false, auto: false },
  { player: "Nate Hill",          golfer: alex_fitz,   dd: false, auto: true  },
  { player: "Jimmy Nelson",       golfer: rai,         dd: false, auto: false },
  { player: "Andrew Lunder",      golfer: alex_fitz,   dd: false, auto: false },
  { player: "Brian Szepelak",     golfer: koepka,      dd: false, auto: false },
  { player: "Jason Mungarro",     golfer: novak,       dd: false, auto: false },
  { player: "Chad Squires Jr.",   golfer: novak,       dd: false, auto: false },
  { player: "Jay Waugh",          golfer: lowry,       dd: false, auto: false },
  { player: "Luke Grasso",        golfer: alex_fitz,   dd: false, auto: false },
  { player: "Mike Murphy",        golfer: koepka,      dd: false, auto: false },
  { player: "Pat Lang",           golfer: alex_fitz,   dd: false, auto: false },
  { player: "Chad Gauvin",        golfer: koepka,      dd: false, auto: false },
  { player: "Tom Murphy",         golfer: alex_fitz,   dd: false, auto: false },
  { player: "Zach Jonas",         golfer: koepka,      dd: false, auto: false },
  { player: "Jack Gunst",         golfer: koepka,      dd: false, auto: false },
  { player: "Bree Svigelj",       golfer: alex_fitz,   dd: false, auto: false },
  { player: "Kevin Hobbs",        golfer: koepka,      dd: false, auto: false },
  { player: "Roberto Scheinerle", golfer: t_moore,     dd: false, auto: false },
  { player: "Reise Kelly",        golfer: gerard,      dd: false, auto: false },
  { player: "Michael Amira",      golfer: alex_fitz,   dd: false, auto: false },
  { player: "Jason DuBois",       golfer: lowry,       dd: false, auto: false },
  { player: "Michael Lukas",      golfer: rai,         dd: false, auto: false },
  { player: "Michael Barile",     golfer: theegala,    dd: false, auto: false },
  { player: "Brian Feeley",       golfer: yellamaraju, dd: false, auto: false },
  { player: "Jim Cooke",          golfer: alex_fitz,   dd: false, auto: false },
  { player: "Justin Mungarro",    golfer: alex_fitz,   dd: false, auto: false },
  { player: "Ben Engler",         golfer: greyserman,  dd: false, auto: false },
  { player: "Kyle Shaffer",       golfer: alex_fitz,   dd: false, auto: false },
  { player: "Daniel Jaffe",       golfer: rai,         dd: false, auto: false },
  { player: "Nick Cristobal",     golfer: novak,       dd: false, auto: false },
  { player: "Fernando Gomez",     golfer: alex_fitz,   dd: false, auto: false },
  { player: "Robert Chambers",    golfer: rai,         dd: false, auto: false },
  { player: "Chris Piper",        golfer: alex_fitz,   dd: false, auto: true  },
  { player: "Jack Murphy",        golfer: alex_fitz,   dd: false, auto: false },
  { player: "Kyle O'Neil",        golfer: koepka,      dd: false, auto: false },
  { player: "Jerry Heath",        golfer: greyserman,  dd: false, auto: false },
  { player: "Katie King",         golfer: novak,       dd: false, auto: false },
  { player: "Chad Squires Sr.",   golfer: rai,         dd: false, auto: false },
  { player: "Anthony Cerruti",    golfer: alex_fitz,   dd: false, auto: false },
  { player: "Paul Cacciotti",     golfer: rai,         dd: false, auto: false },
  { player: "Mike Davis",         golfer: rai,         dd: false, auto: false },
  { player: "Nick Scarimbolo",    golfer: rai,         dd: false, auto: false },
  { player: "Daren Wamsley",      golfer: theegala,    dd: false, auto: false },
  { player: "JT Ozerities",       golfer: rai,         dd: false, auto: false },
  { player: "Kevin Lang",         golfer: rai,         dd: false, auto: false },
  { player: "Adam Feeley",        golfer: lowry,       dd: false, auto: false },
  { player: "Matt VanDixhorn",    golfer: koepka,      dd: false, auto: false },
  { player: "Graeme Watson",      golfer: alex_fitz,   dd: false, auto: false },
  { player: "Ryan Finstad",       golfer: vilips,      dd: false, auto: false },
  { player: "Dustin Daniels",     golfer: alex_fitz,   dd: false, auto: true  },
  { player: "Dylan Linke",        golfer: rai,         dd: false, auto: false },
  { player: "Dan Jaffe",          golfer: rai,         dd: false, auto: false },
  { player: "Tim Cooney",         golfer: theegala,    dd: false, auto: false },
  { player: "Dylan Chambers",     golfer: alex_fitz,   dd: false, auto: true  },
]

picks_data.each do |pd|
  user = User.find_by!(name: pd[:player])
  next if Pick.exists?(user: user, tournament: tournament)

  pick = Pick.new(
    user:             user,
    tournament:       tournament,
    golfer:           pd[:golfer],
    is_double_down:   pd[:dd],
    auto_assigned:    pd[:auto],
    earnings_cents:   0
  )
  pick.save!(validate: false)
end

puts "Done. Picks: #{Pick.where(tournament: tournament).count}, Pairings: #{TeamPairing.where(tournament: tournament).count}"
