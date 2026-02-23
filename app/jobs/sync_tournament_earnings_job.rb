class SyncTournamentEarningsJob < ApplicationJob
  queue_as :default

  def perform(tournament_id)
    tournament = Tournament.find(tournament_id)

    unless tournament.pgatour_id.present?
      Rails.logger.warn "[SyncTournamentEarningsJob] Tournament '#{tournament.name}' has no pgatour_id set"
      return
    end

    payouts = PgaTourScraper.new.payouts(tournament.pgatour_id)

    if payouts.empty?
      Rails.logger.warn "[SyncTournamentEarningsJob] No payout data returned for #{tournament.name}"
      return
    end

    matched   = 0
    unmatched = []

    ApplicationRecord.transaction do
      payouts.each do |payout|
        next if payout[:earnings_cents] == 0 && payout[:position] == "CUT"

        golfer = find_golfer(payout[:name])
        unless golfer
          unmatched << payout[:name]
          next
        end

        result = TournamentResult.find_by(tournament: tournament, golfer: golfer)
        unless result
          unmatched << "#{payout[:name]} (no result row)"
          next
        end

        result.update!(earnings_cents: payout[:earnings_cents])
        matched += 1
      end

      # Re-save all picks to trigger Pick#calculate_earnings
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
