import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "message", "serverMessage", "submit"]

  connect() {
    this.initialEmail = this.inputTarget.value.trim()
    this.validate()
  }

  validate() {
    const email = this.inputTarget.value.trim()
    const isValid = /^[^@\s]+@[^@\s]+$/.test(email)
    const hasChanged = email !== this.initialEmail

    this.submitTarget.disabled = !isValid

    if (this.hasServerMessageTarget && hasChanged) {
      this.serverMessageTarget.classList.add("hidden")
    }

    const showClientError = email.length > 0 &&
      !isValid &&
      (!this.hasServerMessageTarget || hasChanged)
    if (showClientError || this.visibleServerError) {
      this.inputTarget.setAttribute("aria-invalid", "true")
    } else {
      this.inputTarget.removeAttribute("aria-invalid")
    }

    if (this.hasMessageTarget) {
      this.messageTarget.classList.toggle("hidden", !showClientError)
    }
  }

  get visibleServerError() {
    return this.hasServerMessageTarget && !this.serverMessageTarget.classList.contains("hidden")
  }
}
