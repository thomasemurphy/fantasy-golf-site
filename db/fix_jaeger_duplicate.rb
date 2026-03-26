# Two Stephan Jaeger records exist:
# id=124 - created by sync jobs, has all TournamentResults
# id=329 - created by fix script (was "Stephen Jaeger"), has the week-6 picks
# Fix: point all picks from id=329 to id=124, then delete id=329

canonical = Golfer.find(124) # has results
duplicate = Golfer.find(329) # has picks

puts "Canonical: #{canonical.name} (id=#{canonical.id})"
puts "Duplicate: #{duplicate.name} (id=#{duplicate.id})"

picks_moved = Pick.where(golfer_id: duplicate.id).update_all(golfer_id: canonical.id)
puts "Picks moved: #{picks_moved}"

duplicate.destroy
puts "Duplicate deleted"

puts "Picks now on canonical:"
Pick.where(golfer_id: canonical.id).includes(:user, :tournament).each do |p|
  puts "  #{p.user.name} | wk#{p.tournament.week_number}"
end
