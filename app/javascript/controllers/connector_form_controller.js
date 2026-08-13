import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["kind", "openapiField"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    this.openapiFieldTarget.classList.toggle("hidden", this.kindTarget.value !== "openapi")
  }
}
