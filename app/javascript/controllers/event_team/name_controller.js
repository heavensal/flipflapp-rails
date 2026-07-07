import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "counter", "emptyMessage", "invalidMessage", "submit" ]
  static values = {
    maxLength: { type: Number, default: 24 },
    emptyMessage: String,
    invalidMessage: String,
    counterSuffix: String
  }

  connect() {
    this.validate()
  }

  validate() {
    const original = this.inputTarget.value
    let sanitized = original.replace(/[^\p{L}\p{N} ]/gu, "")
    const strippedInvalid = sanitized !== original

    if (sanitized.length > this.maxLengthValue) {
      sanitized = sanitized.slice(0, this.maxLengthValue)
    }

    if (sanitized !== original) {
      this.inputTarget.value = sanitized
    }

    const trimmed = sanitized.trim()
    const isEmpty = trimmed.length === 0
    const remaining = this.maxLengthValue - sanitized.length

    this.updateCounter(remaining)
    this.toggleMessage(this.emptyMessageTarget, this.emptyMessageValue, isEmpty)
    this.toggleMessage(this.invalidMessageTarget, this.invalidMessageValue, strippedInvalid)
    this.submitTarget.disabled = isEmpty

    if (isEmpty || strippedInvalid) {
      this.inputTarget.setAttribute("aria-invalid", "true")
    } else {
      this.inputTarget.removeAttribute("aria-invalid")
    }
  }

  updateCounter(remaining) {
    this.counterTarget.textContent = `${remaining} ${this.counterSuffixValue}`
  }

  toggleMessage(target, message, visible) {
    target.textContent = message
    target.classList.toggle("hidden", !visible)
  }
}
