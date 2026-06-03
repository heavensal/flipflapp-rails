import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName", "email", "password", "passwordConfirmation", "submit",
                    "passwordHint", "passwordConfirmationHint"]

  static values = {
    minPassword: { type: Number, default: 6 },
    passwordTooShort: String,
    passwordConfirmationMismatch: String
  }

  connect() {
    this.validate()
  }

  validate() {
    this.validatePasswordHint()
    this.validatePasswordConfirmationHint()
    this.toggleSubmit()
  }

  validatePasswordHint() {
    if (!this.hasPasswordHintTarget) return

    const value = this.passwordTarget.value

    if (value.length === 0) {
      this.passwordHintTarget.classList.add("hidden")
    } else if (value.length < this.minPasswordValue) {
      this.passwordHintTarget.textContent = this.passwordTooShortValue
      this.passwordHintTarget.classList.remove("hidden")
    } else {
      this.passwordHintTarget.classList.add("hidden")
    }
  }

  validatePasswordConfirmationHint() {
    if (!this.hasPasswordConfirmationHintTarget) return

    const password = this.passwordTarget.value
    const confirmation = this.passwordConfirmationTarget.value

    if (confirmation.length === 0) {
      this.passwordConfirmationHintTarget.classList.add("hidden")
    } else if (confirmation !== password) {
      this.passwordConfirmationHintTarget.textContent = this.passwordConfirmationMismatchValue
      this.passwordConfirmationHintTarget.classList.remove("hidden")
    } else {
      this.passwordConfirmationHintTarget.classList.add("hidden")
    }
  }

  toggleSubmit() {
    const filled = this.firstNameTarget.value.trim() !== "" &&
                   this.lastNameTarget.value.trim() !== "" &&
                   this.emailTarget.value.trim() !== "" &&
                   this.passwordTarget.value.length >= this.minPasswordValue &&
                   this.passwordConfirmationTarget.value === this.passwordTarget.value &&
                   this.passwordConfirmationTarget.value.length > 0

    this.submitTarget.disabled = !filled
  }
}
