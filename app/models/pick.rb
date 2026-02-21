class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :golfer

  validates :user_id, uniqueness: { scope: :tournament_id, message: "already has a pick for this tournament" }
  validates :golfer_id, uniqueness: { scope: :user_id, message: "has already been used this season" }
  validate :golfer_in_field, unless: :auto_assigned?
  validate :picks_not_locked, on: :create, unless: :auto_assigned?
  validate :user_has_double_downs_remaining, if: -> { is_double_down? && !auto_assigned? }

  before_save :calculate_earnings, if: :result_available?

  def earnings_dollars
    (earnings_cents || 0).to_f / 100
  end

  def effective_earnings_cents
    return 0 if auto_assigned?
    return 0 if earnings_cents.nil?
    is_double_down? ? earnings_cents * 2 : earnings_cents
  end

  private

  def golfer_in_field
    return if tournament.nil? || golfer.nil?
    unless tournament.golfers.include?(golfer)
      errors.add(:golfer, "is not in this tournament's field")
    end
  end

  def picks_not_locked
    return if tournament.nil?
    if tournament.picks_locked?
      errors.add(:base, "Picks are locked for this tournament")
    end
  end

  def user_has_double_downs_remaining
    return if user.nil?
    if user.double_downs_remaining <= 0
      errors.add(:base, "You have no double-downs remaining")
    end
  end

  def result_available?
    tournament&.status == "completed" && tournament_result.present?
  end

  def tournament_result
    @tournament_result ||= TournamentResult.find_by(tournament: tournament, golfer: golfer)
  end

  def calculate_earnings
    result = tournament_result
    return unless result

    self.made_cut = result.made_cut
    if auto_assigned?
      self.earnings_cents = 0
    else
      base = result.earnings_cents || 0
      self.earnings_cents = is_double_down? ? base * 2 : base
    end
  end
end
