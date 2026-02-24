import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { title: String, earnings: String }

  connect() {
    this.popup = document.createElement("div")
    this.popup.className = "pick-tooltip-popup"

    let html = ""
    if (this.titleValue) {
      html += `<div class="pick-tooltip-title">
        <span>${this.titleValue}</span>
        ${this.earningsValue ? `<span class="pick-tooltip-total">${this.earningsValue}</span>` : ""}
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
    this.popup.style.top = (rect.bottom + window.scrollY + 6) + "px"
    this.popup.style.left = rect.left + window.scrollX + "px"
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
