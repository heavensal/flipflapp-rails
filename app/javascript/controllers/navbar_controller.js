import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = [ "menu", "overlay" ]

  connect() {
  }

  openMenu() {
    this.menuTarget.classList.remove("translate-x-full")
    this.overlayTarget.classList.remove("hidden")
  }

  closeMenu() {
    this.menuTarget.classList.add("translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}
