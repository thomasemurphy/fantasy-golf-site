g = Golfer.find_by(name: 'Stephan Jaeger')
puts "Golfer: #{g&.name} id=#{g&.id}"

puts "Picks for golfer_id=#{g&.id}:"
Pick.where(golfer_id: g&.id).includes(:user, :tournament).each do |p|
  puts "  #{p.user.name} | wk#{p.tournament.week_number} #{p.tournament.name}"
end

puts "TournamentResults for golfer_id=#{g&.id}:"
TournamentResult.where(golfer_id: g&.id).includes(:tournament).each do |r|
  puts "  #{r.tournament.name} | #{r.current_position_display} #{r.current_score_to_par}"
end

puts "Picks for Houston Open (t6) with user Daniel Jaffe or Justin Mungarro:"
['Daniel Jaffe', 'Justin Mungarro'].each do |name|
  u = User.find_by(name: name)
  p = Pick.find_by(user_id: u.id, tournament_id: 6)
  puts "  #{name}: golfer_id=#{p&.golfer_id} golfer=#{p&.golfer&.name}"
end
