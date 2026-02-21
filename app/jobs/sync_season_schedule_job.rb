class SyncSeasonScheduleJob < ApplicationJob
  queue_as :default

  # Maps SportsDataIO tournament categories to our types
  MAJOR_NAMES = [
    "Masters Tournament",
    "U.S. Open",
    "The Open Championship",
    "PGA Championship"
  ].freeze

  SIDE_EVENT_NAMES = [
    "Arnold Palmer Invitational",
    "Memorial Tournament",
    "FedEx St. Jude Championship",
    "Zurich Classic",
    "Travelers Championship"
  ].freeze

  def perform(season = Date.current.year)
    api = SportsDataIo.new
    tournaments = api.tournaments(season)

    tournaments.each_with_index do |t_data, index|
      tournament_type = determine_type(t_data["Name"])
      start_date = parse_date(t_data["StartDate"])
      next unless start_date

      # picks lock Thursday 6am ET of tournament week
      picks_locked_at = picks_lock_time(start_date)

      Tournament.find_or_initialize_by(sportsdata_id: t_data["TournamentID"].to_s).tap do |t|
        t.name = t_data["Name"]
        t.start_date = start_date
        t.end_date = parse_date(t_data["EndDate"])
        t.purse_cents = ((t_data["Purse"] || 0) * 100).to_i
        t.tournament_type = tournament_type
        t.status = t_data["IsOver"] ? "completed" : "upcoming"
        t.week_number ||= index + 1
        t.picks_locked_at = picks_locked_at
        t.save!
      end
    end

    Rails.logger.info "[SyncSeasonScheduleJob] Synced #{tournaments.size} tournaments for #{season}"
  end

  private

  def determine_type(name)
    return "major" if MAJOR_NAMES.any? { |m| name.include?(m) }
    return "side_event" if SIDE_EVENT_NAMES.any? { |s| name.include?(s) }
    "regular"
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str)
  rescue Date::Error
    nil
  end

  def picks_lock_time(start_date)
    # Tournament week starts on Thursday; picks lock Thursday 6am ET
    # PGA Tour events run Thursday–Sunday; start_date is typically Thursday
    eastern = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    eastern.local(start_date.year, start_date.month, start_date.day, 6, 0, 0)
  end
end
