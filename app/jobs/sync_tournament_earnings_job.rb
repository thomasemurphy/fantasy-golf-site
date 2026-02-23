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

      # Re-save all picks to trigger Pick#calculate_earnings and sync made_cut
      tournament.picks.each(&:save!)
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
