tournament = Tournament.find_by!(name: "Valspar Championship")

puts "Reverting earnings for #{tournament.name}..."

# Clear official earnings from tournament results (keeps current_earnings_cents/projections intact)
count = TournamentResult.where(tournament: tournament).update_all(earnings_cents: nil)
puts "  Cleared earnings_cents on #{count} tournament result rows"

# Clear earnings from picks so they no longer count in standings
pick_count = Pick.where(tournament: tournament).update_all(earnings_cents: nil)
puts "  Cleared earnings_cents on #{pick_count} pick rows"

# Re-mark as in_progress
tournament.update_column(:status, "in_progress")
puts "  Marked tournament as in_progress"

puts "Done. Valspar standings impact has been removed."
