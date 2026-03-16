t = Tournament.find(2)

# 1. Remove Rory McIlroy's bogus Cognizant result (was Kevin Roy's stolen slot)
rory = Golfer.find_by(name: 'Rory McIlroy')
r = TournamentResult.find_by(tournament_id: t.id, golfer_id: rory.id)
if r
  r.destroy
  puts "Removed Rory McIlroy from Cognizant Classic"
else
  puts "Rory McIlroy result not found (already removed?)"
end

# 2. Check Joe Highsmith's result (may have been overwritten by Jordan Smith's data)
joe = Golfer.find_by(name: 'Joe Highsmith')
joe_r = TournamentResult.find_by(tournament_id: t.id, golfer_id: joe.id)
puts "Joe Highsmith: pos=#{joe_r&.current_position_display} score=#{joe_r&.current_score_to_par}"

# 3. Count current -7 players after Rory removal
neg7 = TournamentResult.where(tournament_id: t.id).to_a.select { |r| r.current_score_to_par.to_i == -7 }
puts "Players at -7 now: #{neg7.count}"
neg7.each { |r| puts "  #{Golfer.find(r.golfer_id).name}" }

# 4. Create Kevin Roy with T23 result at -7
kevin_roy = Golfer.find_by(name: 'Kevin Roy') || Golfer.create!(name: 'Kevin Roy')
kr_result = TournamentResult.find_or_initialize_by(tournament: t, golfer: kevin_roy)
kr_result.assign_attributes(
  current_position: 23,
  current_position_display: 'T23',
  current_score_to_par: -7,
  current_thru: 'F',
  current_round: 4,
  made_cut: true
)
kr_result.save
puts "Kevin Roy: #{kr_result.persisted? ? 'saved' : 'failed'} - #{kr_result.errors.full_messages}"

# 5. Create Jordan Smith with T23 result at -7
jordan_smith = Golfer.find_by(name: 'Jordan Smith') || Golfer.create!(name: 'Jordan Smith')
js_result = TournamentResult.find_or_initialize_by(tournament: t, golfer: jordan_smith)
js_result.assign_attributes(
  current_position: 23,
  current_position_display: 'T23',
  current_score_to_par: -7,
  current_thru: 'F',
  current_round: 4,
  made_cut: true
)
js_result.save
puts "Jordan Smith: #{js_result.persisted? ? 'saved' : 'failed'} - #{js_result.errors.full_messages}"

puts ""
neg7_after = TournamentResult.where(tournament_id: t.id).to_a.select { |r| r.current_score_to_par.to_i == -7 }
puts "Players at -7 after fix: #{neg7_after.count}"
neg7_after.each { |r| puts "  #{Golfer.find(r.golfer_id).name}" }
