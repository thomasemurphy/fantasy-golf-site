tournament = Tournament.find_by!(week_number: 27)

# Previously-held-back rows: OK'd by admin to reuse Wyndham Clark since this
# is the last tournament of the pool (unique constraint dropped in
# RemoveUniqueConstraintFromPicksUserGolfer).
HELD_BACK_W27 = [
  ["Kevin Hobbs",      "Wyndham Clark", false, true],
  ["Jimmy Nelson",     "Wyndham Clark", false, true],
  ["Matt VanDixhorn",  "Wyndham Clark", false, true],
  ["Anthony Cerruti",  "Wyndham Clark", false, true],
  ["Jay Waugh",        "Wyndham Clark", false, true],
  ["Michael Barile",   "Wyndham Clark", false, true],
  ["Jerry Heath",      "Wyndham Clark", false, true],
  ["Dylan Linke",      "Wyndham Clark", false, true],
  ["Daren Wamsley",    "Wyndham Clark", false, true],
  ["Nick Scarimbolo",  "Wyndham Clark", false, true],
  ["Zach Jonas",       "Wyndham Clark", false, false], # regular pick, not DD (already at 5 DDs)
].freeze

apply = ENV["APPLY"] == "1"
puts apply ? "=== APPLYING week 27 part 2 ===" : "=== DRY RUN (set APPLY=1 to write) ==="

created = 0
skipped = 0

HELD_BACK_W27.each do |player_name, golfer_name, is_dd, is_auto|
  user   = User.find_by!(name: player_name)
  golfer = Golfer.find_by!(name: golfer_name)

  if Pick.exists?(user: user, tournament: tournament)
    skipped += 1
    next
  end

  if apply
    Pick.new(
      user:           user,
      tournament:     tournament,
      golfer:         golfer,
      is_double_down: is_dd,
      auto_assigned:  is_auto
    ).save!(validate: false)
    created += 1
  end
end

puts "Created: #{created}, Skipped(existing): #{skipped}"

# --- Dustin Daniels correction (poolrunner spreadsheet source of truth) ---
# Week 19 (Travelers) was actually Justin Thomas, DOUBLE, $0 earnings — not
# Sam Burns. This week (BMW) he doubles Sam Burns again (already used, but
# admin says fine, he won't be in the money).
dustin = User.find_by!(name: "Dustin Daniels")
week19_pick = Pick.joins(:tournament).where(user: dustin, tournaments: { week_number: 19 }).first!
sam_burns   = Golfer.find_by!(name: "Sam Burns")
justin_thomas = Golfer.find_by!(name: "Justin Thomas")

if apply
  week19_pick.update_columns(
    golfer_id:       justin_thomas.id,
    is_double_down:  true,
    earnings_cents:  0
  )
  puts "Dustin Daniels week 19 corrected: Justin Thomas [DD], $0"

  unless Pick.exists?(user: dustin, tournament: tournament)
    Pick.new(
      user:           dustin,
      tournament:     tournament,
      golfer:         sam_burns,
      is_double_down: true,
      auto_assigned:  false
    ).save!(validate: false)
    puts "Dustin Daniels week 27 created: Sam Burns [DD]"
  end
else
  puts "WOULD correct Dustin Daniels week 19 -> Justin Thomas [DD] $0, and add week 27 -> Sam Burns [DD]"
end

if apply
  User.where(admin: false).each do |u|
    used    = Pick.where(user_id: u.id, is_double_down: true).count
    correct = 5 - used
    u.update_column(:double_downs_remaining, correct) if u.double_downs_remaining != correct
  end
  puts "\nDD counts recalculated."

  puts "\nWeek 27 picks (#{tournament.name}):"
  tournament.picks.includes(:user, :golfer).sort_by { |p| p.user.name }.each do |p|
    dd   = p.is_double_down? ? " [DD]" : ""
    auto = p.auto_assigned?  ? " (auto)" : ""
    puts "  #{p.user.name}: #{p.golfer.name}#{dd}#{auto}"
  end
end
