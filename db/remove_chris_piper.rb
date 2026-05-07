user = User.find_by!(name: "Chris Piper")
picks_count = Pick.where(user: user).count
Pick.where(user: user).delete_all
user.destroy!
puts "Removed Chris Piper (#{picks_count} picks deleted)."
