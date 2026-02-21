class Golfer < ApplicationRecord
  has_many :tournament_entries, dependent: :destroy
  has_many :tournaments, through: :tournament_entries
  has_many :picks, dependent: :destroy
  has_many :tournament_results, dependent: :destroy

  validates :name, presence: true
  validates :sportsdata_id, uniqueness: true, allow_nil: true
end
