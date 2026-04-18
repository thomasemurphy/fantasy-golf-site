import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { title: String, earnings: String, rank: String, position: String, rankHue: Number, earningsHue: Number }

  connect() {
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
  }

  disconnect() {
    this.popup.remove()
  }

  show() {
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
    this.popup.style.transitionDelay = "0s"
    this.popup.style.opacity = "0"
    this.popup.style.visibility = "hidden"
  }
}
