import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["headersContainer", "headerRow", "emptyState", "headersField", "headerKey", "headerValue"]

  connect() {
    this.updateHeadersField()
  }

  addHeader() {
    const template = this.createHeaderRowTemplate()
    this.headersContainerTarget.insertAdjacentHTML("beforeend", template)
    this.updateEmptyState()
    this.updateHeadersField()
  }

  removeHeader(event) {
    event.target.closest("[data-mcp-server-form-target='headerRow']").remove()
    this.updateEmptyState()
    this.updateHeadersField()
  }

  updateHeadersField() {
    const headers = {}
    this.headerRowTargets.forEach(row => {
      const key = row.querySelector("[data-mcp-server-form-target='headerKey']").value.trim()
      const value = row.querySelector("[data-mcp-server-form-target='headerValue']").value.trim()
      
      if (key && value) {
        headers[key] = value
      }
    })
    
    this.headersFieldTarget.value = JSON.stringify(headers)
  }

  updateEmptyState() {
    const hasHeaders = this.headerRowTargets.length > 0
    if (hasHeaders) {
      this.emptyStateTarget.classList.add("hidden")
    } else {
      this.emptyStateTarget.classList.remove("hidden")
    }
  }

  createHeaderRowTemplate() {
    return `
      <div class="header-row bg-white p-3 rounded border" data-mcp-server-form-target="headerRow">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Nome do Header</label>
            <input type="text" data-mcp-server-form-target="headerKey" data-action="input->mcp-server-form#updateHeadersField"
                   class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                   placeholder="Authorization, Content-Type, etc.">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Valor</label>
            <input type="text" data-mcp-server-form-target="headerValue" data-action="input->mcp-server-form#updateHeadersField"
                   class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                   placeholder="Bearer token123, application/json, etc.">
          </div>
          <div class="flex items-end">
            <button type="button" data-mcp-server-form-target="removeHeader" 
                    data-action="click->mcp-server-form#removeHeader"
                    class="w-full bg-red-600 text-white px-2 py-1 text-sm rounded hover:bg-red-700">
              Remover
            </button>
          </div>
        </div>
      </div>
    `
  }
}