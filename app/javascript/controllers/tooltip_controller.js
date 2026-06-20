import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { title: String, earnings: String, rank: String, position: String, rankHue: Number, earningsHue: Number }

  // The popup is built lazily on first hover rather than in connect(). A single
  // page can carry hundreds of these tooltips; building and appending a popup
  // for every one on connect() (and again on every Turbo render) was the main
  // cause of slow sorting on mobile, where the popups are never even shown.
  buildPopup() {
    if (this.popup) return

    this.popup = document.createElement("div")
    this.popup.className = "pick-tooltip-popup"

    const isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark'
    const l = isDark ? '60%' : '42%'
    const hslColor = (hue) => `hsl(${hue}, 65%, ${l})`

    let html = ""
    if (this.titleValue) {
      const rankStyle = this.hasRankHueValue ? ` style="color:${hslColor(this.rankHueValue)}"` : ""
      html += `<div class="pick-tooltip-title">
        <span>${this.titleValue}</span>
        ${this.rankValue ? `<span class="pick-tooltip-rank"${rankStyle}>${this.rankValue}</span>` : ""}
        ${this.earningsValue ? `<span class="pick-tooltip-total"${rankStyle}>${this.earningsValue}</span>` : ""}
      </div>`
    }
    html += this.contentTarget.innerHTML
    this.popup.innerHTML = html
    document.body.appendChild(this.popup)

    // A popup with a collapsible "Show more" section must be hoverable so the
    // user can reach the toggle. Keep it open while the cursor is over it.
    this.interactive = !!this.popup.querySelector(".ph-expand")
    if (this.interactive) {
      this.popup.style.pointerEvents = "auto"
      this.popup.addEventListener("mouseenter", () => this.cancelHide())
      this.popup.addEventListener("mouseleave", () => this.scheduleHide())
      // Unfurl the collapsed weeks on click of the "Show more"/"Show less" row.
      this.popup.addEventListener("click", (e) => {
        const moreRow = e.target.closest(".ph-more-row")
        if (!moreRow) return
        moreRow.closest("tbody.ph-expand")?.classList.toggle("ph-open")
      })
    }
  }

  disconnect() {
    this.cancelHide()
    if (this.popup) this.popup.remove()
  }

  show() {
    this.buildPopup()
    this.cancelHide()
    const rect = this.triggerTarget.getBoundingClientRect()
    const below = this.positionValue === "below"
    this.popup.style.top = below
      ? (rect.bottom + window.scrollY + 6) + "px"
      : (rect.top + window.scrollY - 12) + "px"
    this.popup.style.left = (rect.left + window.scrollX - 16) + "px"
    this.popup.style.transitionDelay = "0.3s"
    this.popup.style.opacity = "1"
    this.popup.style.visibility = "visible"
  }

  hide() {
    // Interactive popups delay hiding so the cursor can travel from the name
    // into the popup without it disappearing.
    if (this.interactive) {
      this.scheduleHide()
    } else {
      this.doHide()
    }
  }

  scheduleHide() {
    this.cancelHide()
    this.hideTimer = setTimeout(() => this.doHide(), 200)
  }

  cancelHide() {
    if (this.hideTimer) {
      clearTimeout(this.hideTimer)
      this.hideTimer = null
    }
  }

  doHide() {
    if (!this.popup) return
    this.popup.style.transitionDelay = "0s"
    this.popup.style.opacity = "0"
    this.popup.style.visibility = "hidden"
  }
}
