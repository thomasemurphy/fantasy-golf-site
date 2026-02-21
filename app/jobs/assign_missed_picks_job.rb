class AssignMissedPicksJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    tournament = if tournament_id
      Tournament.find(tournament_id)
    else
      # Find the tournament whose picks just locked
      Tournament.where("picks_locked_at <= ?", Time.current)
                .where(status: %w[upcoming in_progress])
                .order(:picks_locked_at)
                .last
    end

    unless tournament
      Rails.logger.info "[AssignMissedPicksJob] No tournament found for pick assignment"
      return
    end

    approved_users = User.where(approved: true)
    users_with_picks = tournament.picks.pluck(:user_id)
    users_without_picks = approved_users.where.not(id: users_with_picks)

    if users_without_picks.none?
      Rails.logger.info "[AssignMissedPicksJob] All users have picks for #{tournament.name}"
      return
    end

    # Build popularity ranking for this tournament
    pick_counts = tournament.picks.group(:golfer_id).count
    field_golfer_ids = tournament.golfer_ids

    # Sort field golfers by pick popularity (most picked first)
    ranked_golfers = field_golfer_ids.sort_by { |id| -pick_counts.fetch(id, 0) }

    users_without_picks.each do |user|
      already_used = user.used_golfer_ids

      # Find most popular golfer this user hasn't already used
      chosen_golfer_id = ranked_golfers.find { |id| id.not_in?(already_used) }

      unless chosen_golfer_id
        Rails.logger.warn "[AssignMissedPicksJob] No valid golfer for user #{user.id} in #{tournament.name}"
        next
      end

      Pick.create!(
        user: user,
        tournament: tournament,
        golfer_id: chosen_golfer_id,
        auto_assigned: true,
        earnings_cents: 0
      )

      Rails.logger.info "[AssignMissedPicksJob] Auto-assigned #{chosen_golfer_id} to user #{user.id}"
    end
  end
end
