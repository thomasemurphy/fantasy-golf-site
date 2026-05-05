tournament = Tournament.find_by!(week_number: 10)

# Double all non-zero earnings on tournament results
updated_results = TournamentResult.where(tournament: tournament)
                                  .where("earnings_cents > 0")
                                  .update_all("earnings_cents = earnings_cents * 2")
puts "Updated #{updated_results} tournament result rows"

# Double all non-zero earnings on picks (auto-assigned picks are already $0, skip them)
updated_picks = Pick.where(tournament: tournament)
                    .where("earnings_cents > 0")
                    .update_all("earnings_cents = earnings_cents * 2")
puts "Updated #{updated_picks} pick rows"

puts "\nDone."
tournament.picks.includes(:golfer, :user).where("earnings_cents > 0").sort_by { |p| -p.earnings_cents.to_i }.each do |p|
  dd = p.is_double_down? ? " [2x]" : ""
  puts "  #{p.user.name}: #{p.golfer.name}#{dd} → $#{p.earnings_cents / 100}"
end
