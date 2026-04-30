all    = Golfer.where(name: "Cameron Young").order(:id).to_a
keeper = all.first
all.drop(1).each do |dupe|
  TournamentResult.where(golfer_id: dupe.id).update_all(golfer_id: keeper.id)
  Pick.where(golfer_id: dupe.id).update_all(golfer_id: keeper.id)
  dupe.destroy!
  puts "Merged golfer id=#{dupe.id} into id=#{keeper.id}"
end
puts "Done. results=#{TournamentResult.where(golfer_id: keeper.id).count} picks=#{Pick.where(golfer_id: keeper.id).count}"
