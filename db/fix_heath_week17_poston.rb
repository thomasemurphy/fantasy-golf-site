# Correction: Jerry Heath's week 17 (RBC Canadian Open) pick was recorded as an
# auto-assigned Wyndham Clark, but he actually picked J.T. Poston (who missed the
# cut → $0). Fixing that frees up Wyndham Clark so it can be his week 19 (Travelers)
# double-down, replacing the auto-assigned Justin Thomas.
apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING Heath correction ===" : "=== DRY RUN (set APPLY=1 to write) ==="

heath  = User.find_by!(name: "Jerry Heath")
t17    = Tournament.find_by!(week_number: 17)
t19    = Tournament.find_by!(week_number: 19)
poston = Golfer.find_by!(name: "J.T. Poston")
clark  = Golfer.find_by!(name: "Wyndham Clark")

p17 = Pick.find_by!(user_id: heath.id, tournament_id: t17.id)
p19 = Pick.find_by!(user_id: heath.id, tournament_id: t19.id)

puts "BEFORE wk17: #{p17.golfer.name} auto=#{p17.auto_assigned?} dd=#{p17.is_double_down?} made_cut=#{p17.made_cut.inspect} earnings=#{p17.earnings_cents.inspect}"
puts "BEFORE wk19: #{p19.golfer.name} auto=#{p19.auto_assigned?} dd=#{p19.is_double_down?} made_cut=#{p19.made_cut.inspect} earnings=#{p19.earnings_cents.inspect}"

if apply
  # Week 17: Wyndham Clark (auto) -> J.T. Poston, a real pick that missed the cut ($0).
  # Do this first so Wyndham Clark is freed before reassigning week 19 (unique index).
  p17.update_columns(golfer_id: poston.id, auto_assigned: false, is_double_down: false,
                     made_cut: false, earnings_cents: 0, updated_at: Time.current)

  # Week 19: Justin Thomas (auto) -> Wyndham Clark double-down (tournament in progress, no result yet).
  p19.update_columns(golfer_id: clark.id, auto_assigned: false, is_double_down: true,
                     made_cut: nil, earnings_cents: nil, updated_at: Time.current)

  # Recompute double-down allowance for everyone (5 - used).
  User.where(admin: false).each do |u|
    used    = Pick.where(user_id: u.id, is_double_down: true).count
    correct = 5 - used
    u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
  end

  p17.reload; p19.reload
  puts "AFTER  wk17: #{p17.golfer.name} auto=#{p17.auto_assigned?} dd=#{p17.is_double_down?} made_cut=#{p17.made_cut.inspect} earnings=#{p17.earnings_cents.inspect}"
  puts "AFTER  wk19: #{p19.golfer.name} auto=#{p19.auto_assigned?} dd=#{p19.is_double_down?} made_cut=#{p19.made_cut.inspect} earnings=#{p19.earnings_cents.inspect}"
  puts "Heath DDs used=#{Pick.where(user_id: heath.id, is_double_down: true).count}, double_downs_remaining=#{heath.reload.double_downs_remaining}"
else
  puts "(dry run — would set wk17 -> J.T. Poston ($0, missed cut) and wk19 -> Wyndham Clark [DD])"
end
