// Connects to data-controller="home--hide-scroll-btn"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  toggle() {
    if (window.scrollY > 0) {
      this.linkTarget.classList.add("hidden")
      this.linkTarget.classList.remove("inline-grid")
    } else {
      this.linkTarget.classList.remove("hidden")
      this.linkTarget.classList.add("inline-grid")
    }
  }
}
