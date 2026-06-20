import { Controller } from "@hotwired/stimulus"

// Localizes a server-rendered tee time to the viewer's own timezone.
// The element is a <time datetime="<utc-iso>"> whose text is an Eastern-time
// fallback (e.g. "1:45p ET"); on connect we rewrite it to local time
// (e.g. "10:45a PT" for a Pacific viewer). Re-runs automatically when the live
// leaderboard re-renders, since Stimulus reconnects on Turbo Frame updates.
export default class extends Controller {
  connect() {
    const iso = this.element.getAttribute("datetime")
    if (!iso) return
    const d = new Date(iso)
    if (isNaN(d.getTime())) return
    this.element.textContent = this.format(d)
  }

  format(d) {
    const time = d
      .toLocaleTimeString([], { hour: "numeric", minute: "2-digit", hour12: true })
      .replace(/\s?([AP])M/i, (_, p) => p.toLowerCase()) // "1:45 PM" → "1:45p"
      .replace(/\s+/g, "")
    const zone = this.zoneAbbrev(d)
    return zone ? `${time} ${zone}` : time
  }

  zoneAbbrev(d) {
    try {
      const parts = new Intl.DateTimeFormat([], { timeZoneName: "short" }).formatToParts(d)
      const name = parts.find((p) => p.type === "timeZoneName")?.value || ""
      // "EDT"/"EST" → "ET", "PDT"/"PST" → "PT", etc. Non-US labels (e.g. "GMT+1")
      // pass through unchanged.
      return name.replace(/^([A-Z])[DS]T$/, "$1T")
    } catch (e) {
      return ""
    }
  }
}
