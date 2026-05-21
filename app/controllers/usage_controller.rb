class UsageController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @players = User.where(approved: true)
                   .where.not(name: %w[Commissioner Administrator])
                   .where(admin: false)
                   .to_a

    picks = Pick.includes(:golfer, :tournament)
                .where(user_id: @players.map(&:id))
                .to_a

    # Golfer columns: only golfers picked at least once, most-picked first.
    # Player rows: descending total earnings (same order as Main Pot standings).
    counts_by_golfer = Hash.new(0)
    earnings_by_user = Hash.new(0)
    picks.each do |p|
      counts_by_golfer[p.golfer_id] += 1
      earnings_by_user[p.user_id]   += p.earnings_cents.to_i
    end

    @players.sort_by! { |u| [-earnings_by_user[u.id], u.name] }

    # Overall rank (ties share a "T#" rank), matching Main Pot standings.
    @overall_rank = {}
    rank = 1
    @players.chunk_while { |a, b| earnings_by_user[a.id] == earnings_by_user[b.id] }.each do |group|
      display = group.size > 1 ? "T#{rank}" : rank.to_s
      group.each { |u| @overall_rank[u.id] = display }
      rank += group.size
    end

    golfers_by_id = picks.map(&:golfer).uniq.index_by(&:id)
    @golfers = golfers_by_id.values.sort_by { |g| [-counts_by_golfer[g.id], g.name] }
    @pick_count_by_golfer = counts_by_golfer

    # Matrix cell lookup: { [user_id, golfer_id] => pick }
    @pick_by_cell = picks.index_by { |p| [p.user_id, p.golfer_id] }
  end
end
