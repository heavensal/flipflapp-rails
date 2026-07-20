import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "checkbox"]

  connect() {
    this.refresh()
  }

  refresh() {
    if (!this.hasSubmitTarget) return

    this.submitTarget.disabled = !this.checkboxTargets.some((checkbox) => checkbox.checked)
  }
}
