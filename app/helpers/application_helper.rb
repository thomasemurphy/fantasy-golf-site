module ApplicationHelper
  TOURNAMENT_NAME_OVERRIDES = {
    "CJ Cup Byron Nelson"  => "Byron Nelson",
    "RBC Canadian Open"    => "Canadian Open",
    "Genesis Scottish Open" => "Scottish Open",
  }.freeze

  # Shortens a tournament name for compact display (e.g. tooltip columns and tab labels)
  def short_tournament_name(name)
    return TOURNAMENT_NAME_OVERRIDES[name] if TOURNAMENT_NAME_OVERRIDES.key?(name)
    n = name.dup
    n.sub!(/^The\s+/, "")
    n.sub!(/\s+at\s+.+$/, "")
    n.sub!(/\s+of\s+.+$/, "")
    n.sub!(/^Texas\s+Children's\s+/, "")
    n.sub!(/\s+(Championship|Invitational|Tournament|Classic|Open|Challenge)$/, "")
    n.strip
  end

  # Formats a score-to-par integer for display: nil → "—", 0 → "E", -8 → "-8", 2 → "+2"
  def format_score(score)
    return content_tag(:span, "—", class: "text-muted") if score.nil?
    return "E" if score == 0
    score > 0 ? "+#{score}" : score.to_s
  end

  TOURNAMENT_TYPE_COLORS = { "major" => "#c0392b", "side_event" => "#198754", "pink_event" => "#e07ab8" }.freeze

  # Returns the display color for a tournament type, or nil for regular events
  def tournament_type_color(tournament)
    TOURNAMENT_TYPE_COLORS[tournament.tournament_type]
  end

  # Returns a hue (0=red, 120=green) for rank coloring, or nil if unrankable
  def rank_hue(rank_str, total)
    return nil if rank_str.nil? || rank_str.to_s == "—" || total.to_i <= 1
    n = rank_str.to_s.sub(/\AT/, "").to_i
    return nil if n == 0
    pct = [(n - 1).to_f / (total - 1), 1.0].min
    ((1.0 - pct) * 120).round
  end

  # Abbreviates an earnings amount (in cents) to millions, always one decimal:
  # $10,123,456 → "$10.1m", $10,000,000 → "$10.0m", $250,000 → "$0.3m"
  def abbreviated_earnings(earnings_cents)
    millions = earnings_cents.to_i / 100.0 / 1_000_000.0
    "$#{number_with_precision(millions, precision: 1)}m"
  end

  # Returns a hue (0=red, 120=green) for earnings coloring, or nil if zero
  def earnings_hue(earnings_cents, max_earnings_cents)
    return nil if max_earnings_cents.to_i <= 0 || earnings_cents.to_i <= 0
    pct = [earnings_cents.to_f / max_earnings_cents, 1.0].min
    (pct * 120).round
  end

  # Renders one <tr> for a player's pick-history tooltip. cp is a { pick:, position: } hash.
  # hidden: true tags the row with .ph-hidden so it collapses until "Show more" is hovered.
  def pick_history_tooltip_row(cp, hidden: false)
    pick = cp[:pick]
    t    = pick.tournament
    tc   = tournament_type_color(t)

    wk_td   = content_tag(:td, "Wk#{t.week_number}", style: "color:#aaa;padding-right:10px;white-space:nowrap")
    name_td = content_tag(:td, short_tournament_name(t.name), style: "padding-right:12px;white-space:nowrap")

    golfer_parts = [pick.golfer.name]
    golfer_parts << content_tag(:span, "2x", style: "color:#b8860b;font-size:10px;font-weight:600") if pick.is_double_down?
    golfer_parts << content_tag(:span, "(auto)", style: "color:#aaa;font-size:10px") if pick.auto_assigned?
    golfer_td = content_tag(:td, safe_join(golfer_parts, " "), style: "padding-right:12px;white-space:nowrap")

    pos_td = content_tag(:td, cp[:position] || "—", style: "padding-right:12px;white-space:nowrap;color:#6c757d")

    earn_html =
      if pick.auto_assigned? || pick.earnings_cents.to_i <= 0
        content_tag(:span, "$0", style: "color:#aaa")
      else
        "$#{number_with_delimiter((pick.earnings_cents / 100.0).to_i)}"
      end
    earn_td = content_tag(:td, earn_html, style: "text-align:right;white-space:nowrap")

    content_tag(:tr, safe_join([wk_td, name_td, golfer_td, pos_td, earn_td]),
                class: ("ph-hidden" if hidden),
                style: ("color:#{tc}" if tc))
  end

  # For team events, returns "w/ [partner name]" or nil. Pass pairings (preloaded) to avoid N+1.
  def team_partner_label(golfer, pairings)
    return nil if pairings.blank?
    pairing = pairings.find { |p| p.golfer_a_id == golfer.id || p.golfer_b_id == golfer.id }
    return nil unless pairing
    partner = pairing.golfer_a_id == golfer.id ? pairing.golfer_b : pairing.golfer_a
    "+ #{partner.name}"
  end

  # Renders a sortable <th> link.
  # base_params: hash of query params to keep (e.g. { tab: "live" } or { tournament_id: 5 })
  # natural_dir: the "expected first click" direction for this column ("asc" or "desc")
  def sort_header(label, col, base_params, current_sort, current_dir, natural_dir: "asc")
    active   = current_sort == col
    next_dir = active ? (current_dir == "asc" ? "desc" : "asc") : natural_dir
    indicator = active ? (current_dir == "asc" ? " ↑" : " ↓") : ""
    link_to standings_path(base_params.merge(sort: col, dir: next_dir)),
            class: "sort-link#{" sort-active" if active}" do
      (label + indicator).html_safe
    end
  end
end
