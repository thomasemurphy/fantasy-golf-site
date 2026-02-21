class Tournament < ApplicationRecord
  has_many :tournament_entries, dependent: :destroy
  has_many :golfers, through: :tournament_entries
  has_many :picks, dependent: :destroy
  has_many :tournament_results, dependent: :destroy

  TYPES = %w[regular major side_event].freeze
  STATUSES = %w[upcoming in_progress completed].freeze

  validates :name, presence: true
  validates :tournament_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :week_number, uniqueness: true, allow_nil: true

  scope :upcoming, -> { where(status: "upcoming").order(:start_date) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed").order(:start_date) }
  scope :majors, -> { where(tournament_type: "major") }
  scope :side_events, -> { where(tournament_type: "side_event") }
  scope :first_half, -> { where(week_number: 1..14) }
  scope :second_half, -> { where(week_number: 15..27) }

  def picks_locked?
    picks_locked_at.present? && Time.current >= picks_locked_at
  end

  def current?
    status.in?(%w[upcoming in_progress]) && start_date <= Date.current + 7
  end

  def purse_dollars
    purse_cents.to_f / 100
  end
end
