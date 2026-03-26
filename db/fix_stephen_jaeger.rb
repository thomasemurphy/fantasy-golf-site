g = Golfer.find_or_create_by(name: 'Stephen Jaeger')
puts 'Golfer: ' + g.name
t = Tournament.find(6)
['Daniel Jaffe', 'Justin Mungarro'].each do |n|
  u = User.find_by(name: n)
  next puts "User not found: #{n}" unless u
  next puts "SKIP: #{n} already has pick" if Pick.exists?(user: u, tournament: t)
  p = Pick.new(user: u, tournament: t, golfer: g, is_double_down: false, auto_assigned: false, earnings_cents: 0)
  p.save(validate: false)
  puts 'OK: ' + u.name + ' → ' + g.name
end
