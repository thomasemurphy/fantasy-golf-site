User.where(admin: false).each do |u|
  used = Pick.where(user_id: u.id, is_double_down: true).count
  correct = 5 - used
  if u.double_downs_remaining != correct
    u.update_column(:double_downs_remaining, correct)
    puts "Fixed #{u.name}: #{u.double_downs_remaining} -> #{correct} (#{used} used)"
  end
end
puts "Done"
