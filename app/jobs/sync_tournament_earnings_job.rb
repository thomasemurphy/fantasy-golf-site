class SyncTournamentEarningsJob < ApplicationJob
  queue_as :default

  def perform(tournament_id)
    tournament = Tournament.find(tournament_id)

    unless tournament.pgatour_id.present?
      Rails.logger.warn "[SyncTournamentEarningsJob] Tournament '#{tournament.name}' has no pgatour_id set"
      return
    end

    results = PgaTourScraper.new.results(tournament.pgatour_id)

    if results.empty?
      Rails.logger.warn "[SyncTournamentEarningsJob] No results data returned for #{tournament.name}"
      return
    end

    # Sanity-check: verify returned players overlap with our known field.
    # If the API returns stale data (e.g. prior year's results), last names won't match.
    known_last_names = TournamentResult.where(tournament: tournament)
                                       .joins(:golfer)
                                       .pluck("golfers.name")
                                       .map { |n| n.split.last.downcase }
                                       .to_set

    if known_last_names.any?
      matched = results.count { |r| known_last_names.include?(r[:name].to_s.split.last.downcase) }
      match_rate = matched.to_f / [results.size, known_last_names.size].min
      if match_rate < 0.5
        Rails.logger.warn "[SyncTournamentEarningsJob] Only #{(match_rate * 100).round}% of returned " \
                          "players match known #{tournament.name} field — API may be returning a " \
                          "different tournament or year. Skipping to avoid writing wrong earnings."
        return
      end
    end

    matched   = 0
    unmatched = []

    ApplicationRecord.transaction do
      results.each do |r|
        golfer = find_golfer(r[:name])
        unless golfer
          unmatched << r[:name]
          next
        end

        tr = TournamentResult.find_by(tournament: tournament, golfer: golfer)
        unless tr
          unmatched << "#{r[:name]} (no result row)"
          next
        end

        # Overwrite ESPN live data with authoritative PGA Tour final results
        tr.update!(
          current_position:         r[:position],
          current_position_display: r[:position_display],
          current_score_to_par:     r[:score_to_par],
          current_thru:             "F",
          made_cut:                 r[:made_cut],
          earnings_cents:           r[:earnings_cents]
        )
        matched += 1
      end

      # Recalculate earnings on each pick (skip validations — picks are already valid)
      tournament.picks.each { |pick| pick.save!(validate: false) }
    end

    Rails.logger.info "[SyncTournamentEarningsJob] #{tournament.name}: " \
                      "#{matched} matched, #{unmatched.size} unmatched"
    Rails.logger.warn "[SyncTournamentEarningsJob] Unmatched: #{unmatched.join(', ')}" if unmatched.any?
  end

  private

  def find_golfer(name)
    return Golfer.find_by(name: name) if Golfer.exists?(name: name)

    normalized = name.gsub(".", "").squeeze(" ").strip
    return Golfer.find_by(name: normalized) if Golfer.exists?(name: normalized)

    last_name = name.split.last
    matches   = Golfer.where("name ILIKE ?", "%#{last_name}")
    matches.first if matches.one?
  end
end
