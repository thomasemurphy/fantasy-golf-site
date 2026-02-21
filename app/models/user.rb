class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :picks, dependent: :destroy

  validates :name, presence: true

  before_create { self.approved = true }

  def total_earnings_cents
    picks.where.not(earnings_cents: nil).sum(:earnings_cents)
  end

  def majors_earnings_cents
    picks.joins(:tournament)
         .where(tournaments: { tournament_type: "major" })
         .where.not(earnings_cents: nil)
         .sum(:earnings_cents)
  end

  def side_events_earnings_cents
    picks.joins(:tournament)
         .where(tournaments: { tournament_type: "side_event" })
         .where.not(earnings_cents: nil)
         .sum(:earnings_cents)
  end

  def first_half_earnings_cents
    picks.joins(:tournament)
         .where(tournaments: { week_number: 1..14 })
         .where.not(earnings_cents: nil)
         .sum(:earnings_cents)
  end

  def second_half_earnings_cents
    picks.joins(:tournament)
         .where(tournaments: { week_number: 15..27 })
         .where.not(earnings_cents: nil)
         .sum(:earnings_cents)
  end

  def no_cut_streak_alive?
    completed_picks = picks.joins(:tournament)
                           .where(tournaments: { status: "completed" })
                           .where.not(made_cut: nil)
                           .where(auto_assigned: false)
    return true if completed_picks.none?

    completed_picks.all?(&:made_cut?)
  end

  def used_golfer_ids
    picks.pluck(:golfer_id)
  end
end
