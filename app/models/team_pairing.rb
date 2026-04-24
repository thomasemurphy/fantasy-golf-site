class TeamPairing < ApplicationRecord
  belongs_to :tournament
  belongs_to :golfer_a, class_name: "Golfer"
  belongs_to :golfer_b, class_name: "Golfer"

  validates :espn_team_name, presence: true,
    uniqueness: { scope: :tournament_id }

  def golfers
    [golfer_a, golfer_b]
  end
end
