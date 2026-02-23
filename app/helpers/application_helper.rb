module ApplicationHelper
  # Formats a score-to-par integer for display: nil → "—", 0 → "E", -8 → "-8", 2 → "+2"
  def format_score(score)
    return content_tag(:span, "—", class: "text-muted") if score.nil?
    return "E" if score == 0
    score > 0 ? "+#{score}" : score.to_s
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
