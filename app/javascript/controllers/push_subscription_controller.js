import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-subscription"
export default class extends Controller {
  static targets = ["button", "status"]
  static values = {
    vapidKey: String,
    createUrl: String,
    destroyUrl: String,
    labels: Object
  }

  connect() {
    if (!this.isSupported()) {
      this.setStatus(this.labelsValue.unsupported)
      this.disableButton()
      return
    }

    this.registerServiceWorker().then(() => this.syncState())
  }

  async enable(event) {
    event.preventDefault()
    if (!this.isSupported()) return

    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        this.setStatus(this.labelsValue.denied)
        return
      }

      await this.subscribeAndPersist()
      this.setStatus(this.labelsValue.enabled)
      this.updateButton(true)
    } catch (_error) {
      this.setStatus(this.labelsValue.error)
    }
  }

  async syncState() {
    if (Notification.permission === "denied") {
      this.setStatus(this.labelsValue.denied)
      this.disableButton()
      return
    }

    if (Notification.permission === "granted") {
      try {
        await this.subscribeAndPersist()
        this.setStatus(this.labelsValue.enabled)
        this.updateButton(true)
        return
      } catch (_error) {
        this.setStatus(this.labelsValue.error)
        return
      }
    }

    this.setStatus(this.labelsValue.prompt)
    this.updateButton(false)
  }

  async registerServiceWorker() {
    this.registration = await navigator.serviceWorker.register("/service-worker", { scope: "/" })
    await navigator.serviceWorker.ready
    return this.registration
  }

  async subscribeAndPersist() {
    const registration = this.registration || await this.registerServiceWorker()
    let subscription = await registration.pushManager.getSubscription()

    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidKeyValue)
      })
    }

    await this.persistSubscription(subscription)
  }

  async persistSubscription(subscription) {
    const json = subscription.toJSON()
    const token = document.querySelector("meta[name='csrf-token']")?.content

    const response = await fetch(this.createUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({
        push_subscription: {
          endpoint: json.endpoint,
          p256dh: json.keys.p256dh,
          auth: json.keys.auth
        }
      })
    })

    if (!response.ok) throw new Error("Failed to persist push subscription")
  }

  isSupported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window && this.vapidKeyValue
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text || ""
  }

  updateButton(enabled) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.disabled = enabled
    this.buttonTarget.textContent = enabled ? this.labelsValue.enabledButton : this.labelsValue.enableButton
  }

  disableButton() {
    if (!this.hasButtonTarget) return
    this.buttonTarget.disabled = true
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)))
  }
}
