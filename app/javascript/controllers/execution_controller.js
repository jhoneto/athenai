import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loadingIndicator"]

  connect() {
    this.element.addEventListener("turbo:submit-start", this.showLoading.bind(this))
    this.element.addEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.showLoading.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  showLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add("hidden")
    }
  }
}