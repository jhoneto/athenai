import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parametersContainer", "parameterRow", "addParam", "removeParam", "emptyState"]

  connect() {
    this.parameterIndex = this.parameterRowTargets.length
    this.updateEmptyState()
  }

  addParameter() {
    const template = this.createParameterTemplate(this.parameterIndex)
    this.parametersContainerTarget.insertAdjacentHTML('beforeend', template)
    this.parameterIndex++
    this.updateEmptyState()
  }

  removeParameter(event) {
    event.target.closest('[data-function-form-target="parameterRow"]').remove()
    this.updateEmptyState()
  }

  updateEmptyState() {
    const hasParameters = this.parameterRowTargets.length > 0
    if (hasParameters) {
      this.emptyStateTarget.classList.add('hidden')
    } else {
      this.emptyStateTarget.classList.remove('hidden')
    }
  }

  createParameterTemplate(index) {
    return `
      <div class="parameter-row bg-white p-3 rounded border" data-function-form-target="parameterRow">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Nome</label>
            <input type="text" name="function[parameters][${index}][name]" value="" 
                   class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                   placeholder="nome_parametro">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Tipo</label>
            <select name="function[parameters][${index}][type]" 
                    class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500">
              <option value="string">String</option>
              <option value="integer">Integer</option>
              <option value="float">Float</option>
              <option value="boolean">Boolean</option>
              <option value="array">Array</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Obrigatório</label>
            <select name="function[parameters][${index}][required]" 
                    class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500">
              <option value="false">Não</option>
              <option value="true">Sim</option>
            </select>
          </div>
          <div class="flex items-end">
            <button type="button" data-function-form-target="removeParam" 
                    data-action="click->function-form#removeParameter"
                    class="w-full bg-red-600 text-white px-2 py-1 text-sm rounded hover:bg-red-700">
              Remover
            </button>
          </div>
        </div>
        <div class="mt-2">
          <label class="block text-xs font-medium text-gray-600 mb-1">Descrição</label>
          <input type="text" name="function[parameters][${index}][description]" value="" 
                 class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                 placeholder="Descrição do parâmetro">
        </div>
      </div>
    `
  }
}