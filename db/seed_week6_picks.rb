def strip_accents(str)
  accents = {"À"=>"A","Á"=>"A","Â"=>"A","Ã"=>"A","Ä"=>"A","Å"=>"A","à"=>"a","á"=>"a","â"=>"a","ã"=>"a","ä"=>"a","å"=>"a","Ø"=>"O","ø"=>"o","Ö"=>"O","ö"=>"o","Ü"=>"U","ü"=>"u","É"=>"E","é"=>"e","È"=>"E","è"=>"e","Ê"=>"E","ê"=>"e","Ë"=>"E","ë"=>"e","Í"=>"I","í"=>"i","Ì"=>"I","ì"=>"i","Î"=>"I","î"=>"i","Ï"=>"I","ï"=>"i","Ú"=>"U","ú"=>"u","Ù"=>"U","ù"=>"u","Û"=>"U","û"=>"u","Ó"=>"O","ó"=>"o","Ò"=>"O","ò"=>"o","Ô"=>"O","ô"=>"o","Ñ"=>"N","ñ"=>"n","Ç"=>"C","ç"=>"c","ß"=>"ss"}
  str.chars.map { |c| accents[c] || c }.join
end

tournament = Tournament.find(6) # Houston Open

GOLFER_ALIASES = {
  "Kieth Mitchell"        => "Keith Mitchell",
  "Stephan Jaeger"        => "Stephen Jaeger",
  "Grame Watson"          => "Graeme Watson",
  "Nicolai Hojgaard"      => "Nicolai Højgaard",
}

picks_data = [
  { player: "Kyle Frazho",          golfer: "Chris Gotterup" },
  { player: "Mike Feeley",          golfer: "Jake Knapp" },
  { player: "Jimmy Nelson",         golfer: "Rickie Fowler" },
  { player: "Bree Svigelj",         golfer: "Michael Thorbjornsen" },
  { player: "Jason Mungarro",       golfer: "Rickie Fowler" },
  { player: "CJ Sturges",           golfer: "Keith Mitchell" },
  { player: "Andy Stepic",          golfer: "Chris Gotterup" },
  { player: "Andrew Lunder",        golfer: "Chris Gotterup" },
  { player: "Michael Barile",       golfer: "Kurt Kitayama" },
  { player: "Roberto Scheinerle",   golfer: "Jake Knapp" },
  { player: "Jason DuBois",         golfer: "Min Woo Lee" },
  { player: "Jack Gunst",           golfer: "Min Woo Lee" },
  { player: "Kevin Hobbs",          golfer: "Marco Penge" },
  { player: "Chris Piper",          golfer: "Marco Penge" },
  { player: "Michael Amira",        golfer: "Min Woo Lee" },
  { player: "Jay Waugh",            golfer: "Min Woo Lee" },
  { player: "Brian Feeley",         golfer: "Rickie Fowler" },
  { player: "Nate Hill",            golfer: "Gary Woodland" },
  { player: "Zach Jonas",           golfer: "Gary Woodland" },
  { player: "Chad Squires Jr.",     golfer: "Brooks Koepka" },
  { player: "Kyle Shaffer",         golfer: "Rickie Fowler" },
  { player: "Nick Cristobal",       golfer: "Min Woo Lee" },
  { player: "Paul Cacciotti",       golfer: "Marco Penge" },
  { player: "Jack Murphy",          golfer: "Sam Burns" },
  { player: "Brian Szepelak",       golfer: "Gary Woodland" },
  { player: "Michael Lukas",        golfer: "Min Woo Lee" },
  { player: "Jim Cooke",            golfer: "Min Woo Lee" },
  { player: "Chad Squires Sr.",     golfer: "Jordan Spieth" },
  { player: "Pat Lang",             golfer: "Chris Gotterup" },
  { player: "Anthony Cerruti",      golfer: "Chris Gotterup" },
  { player: "Graeme Watson",        golfer: "Brooks Koepka" },
  { player: "Robert Chambers",      golfer: "Brooks Koepka" },
  { player: "Daniel Jaffe",         golfer: "Stephen Jaeger" },
  { player: "Jerry Heath",          golfer: "Rickie Fowler" },
  { player: "Katie King",           golfer: "Min Woo Lee" },
  { player: "Tom Murphy",           golfer: "Min Woo Lee" },
  { player: "Justin Mungarro",      golfer: "Stephen Jaeger" },
  { player: "Kyle O'Neil",          golfer: "Sam Burns" },
  { player: "Mike Murphy",          golfer: "Jake Knapp" },
  { player: "Mike Davis",           golfer: "Brooks Koepka" },
  { player: "Luke Grasso",          golfer: "Tony Finau" },
  { player: "JT Ozerities",         golfer: "Jake Knapp" },
  { player: "Daren Wamsley",        golfer: "Nicolai Højgaard" },
  { player: "Kevin Lang",           golfer: "Jake Knapp" },
  { player: "Nick Scarimbolo",      golfer: "Jake Knapp" },
  { player: "Ben Engler",           golfer: "Chris Gotterup" },
  { player: "Fernando Gomez",       golfer: "Rickie Fowler" },
  { player: "Dan Jaffe",            golfer: "Jordan Smith" },
  { player: "Tim Cooney",           golfer: "Jake Knapp" },
  { player: "Dustin Daniels",       golfer: "Brooks Koepka" },
  { player: "Adam Feeley",          golfer: "Jake Knapp" },
  { player: "Ryan Finstad",         golfer: "Min Woo Lee" },
  { player: "Chad Gauvin",          golfer: "Chris Gotterup" },
  { player: "Reise Kelly",          golfer: "Nicolai Højgaard" },
  { player: "Dylan Linke",          golfer: "Chris Gotterup" },
  { player: "Matt VanDixhorn",      golfer: "Min Woo Lee" },
  { player: "Dylan Chambers",       golfer: "Jake Knapp" },
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
           Golfer.all.find { |g| strip_accents(g.name) == strip_accents(golfer_name) }

  unless golfer
    puts "ERROR: Golfer not found: #{golfer_name}"
    errors += 1
    next
  end

  if Pick.exists?(user: user, tournament: tournament)
    puts "SKIP: #{user.name} already has a pick for week 6"
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
