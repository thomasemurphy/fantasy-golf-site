import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer"]
  static values = { deadline: String }

  connect() {
    this.update()
    this.interval = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  update() {
    const deadline = new Date(this.deadlineValue)
    const now = new Date()
    const diff = deadline - now

    if (diff <= 0) {
      this.timerTarget.textContent = "picks locked"
      clearInterval(this.interval)
      return
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    let parts = []
    if (days > 0) parts.push(`${days}d`)
    parts.push(`${hours}h ${minutes}m ${seconds}s remaining`)

    this.timerTarget.textContent = parts.join(" ")
  }
}
