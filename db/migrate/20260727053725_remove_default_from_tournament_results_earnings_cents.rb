class RemoveDefaultFromTournamentResultsEarningsCents < ActiveRecord::Migration[8.1]
  def change
    # SyncTournamentResultsJob's earnings_finalized? guard treats any non-nil
    # earnings_cents as "authoritative earnings already synced". With a DB
    # default of 0, every row starts non-nil the moment it's created (before
    # SyncTournamentEarningsJob ever runs), so a single failed/skipped sync
    # attempt permanently disables retries and the row is stuck at 0 forever.
    # nil must mean "not yet synced" so the guard can tell that apart from a
    # real $0 payout (e.g. missed cut).
    change_column_default :tournament_results, :earnings_cents, from: 0, to: nil
  end
end
