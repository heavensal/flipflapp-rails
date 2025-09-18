import { Controller } from "@hotwired/stimulus"
import { Loader } from "@googlemaps/js-api-loader"

// Connects to data-controller="maps--autocomplete"
export default class extends Controller {
  static targets = ["address", "latitude", "longitude"]

  async connect() {

    const loader = new Loader({
      apiKey: window.googleMapsKey,
      libraries: ["places"],
    })

    // Charge uniquement la lib "places"
    await loader.importLibrary("places")
    this.initAutocomplete()
  }

  initAutocomplete() {
    // On cible bien l'input texte
    this.autocomplete = new google.maps.places.Autocomplete(this.addressTarget, {
      fields: ["formatted_address", "geometry"],
    })

    this.autocomplete.addListener("place_changed", () => {
      const place = this.autocomplete.getPlace()
      if (!place.geometry) return

      this.addressTarget.value = place.formatted_address
      this.latitudeTarget.value = place.geometry.location.lat()
      this.longitudeTarget.value = place.geometry.location.lng()
    })
  }
}
