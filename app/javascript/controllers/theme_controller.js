import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sun", "moon"]

  connect() {
    this.applyTheme(this.getTheme())

    // Listen for system preference changes (only when no stored preference)
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQuery.addEventListener("change", this.onSystemChange)
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.onSystemChange)
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-bs-theme")
    this.setTheme(current === "dark" ? "light" : "dark")
  }

  // Private

  getTheme() {
    const stored = localStorage.getItem("theme")
    if (stored) return stored
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  setTheme(theme) {
    localStorage.setItem("theme", theme)
    this.applyTheme(theme)
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-bs-theme", theme)
    // Show sun in dark mode (click to go light), moon in light mode (click to go dark)
    if (this.hasSunTarget && this.hasMoonTarget) {
      this.sunTarget.style.display = theme === "dark" ? "block" : "none"
      this.moonTarget.style.display = theme === "dark" ? "none" : "block"
    }
  }

  onSystemChange = (e) => {
    if (!localStorage.getItem("theme")) {
      this.applyTheme(e.matches ? "dark" : "light")
    }
  }
}
