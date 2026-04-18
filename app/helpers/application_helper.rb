module ApplicationHelper
  # Shortens a tournament name for compact display (e.g. tooltip columns)
  def short_tournament_name(name)
    n = name.dup
    return "U.S. Open" if n == "U.S. Open"
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

  # Returns a hue (0=red, 120=green) for rank coloring, or nil if unrankable
  def rank_hue(rank_str, total)
    return nil if rank_str.nil? || rank_str.to_s == "—" || total.to_i <= 1
    n = rank_str.to_s.sub(/\AT/, "").to_i
    return nil if n == 0
    pct = [(n - 1).to_f / (total - 1), 1.0].min
    ((1.0 - pct) * 120).round
  end

  # Returns a hue (0=red, 120=green) for earnings coloring, or nil if zero
  def earnings_hue(earnings_cents, max_earnings_cents)
    return nil if max_earnings_cents.to_i <= 0 || earnings_cents.to_i <= 0
    pct = [earnings_cents.to_f / max_earnings_cents, 1.0].min
    (pct * 120).round
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
