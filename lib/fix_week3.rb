tournament = Tournament.find(3)
golfer = Golfer.find(59) # Ludvig Åberg

['Jay Waugh', 'Chad Squires Sr.'].each do |name|
  user = User.where('lower(name) = ?', name.downcase).first
  unless user
    puts "User not found: #{name}"
    next
  end
  pick = Pick.new(user_id: user.id, tournament_id: tournament.id, golfer_id: golfer.id, is_double_down: false, auto_assigned: false, earnings_cents: 0)
  pick.save!(validate: false)
  puts "Created: #{user.name} -> #{golfer.name}"
end

tournament.update!(status: 'in_progress')
puts "Tournament 3 (#{tournament.name}) set to in_progress."
