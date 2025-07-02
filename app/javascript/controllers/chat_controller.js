import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form", "submit"]
  static values = { agentId: Number, chatId: Number }

  connect() {
    this.scrollToBottom()
    this.setupAutoResize()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  setupAutoResize() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('input', this.autoResize.bind(this))
      this.inputTarget.addEventListener('keydown', this.handleKeyDown.bind(this))
    }
  }

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = 'auto'
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px'
  }

  handleKeyDown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.submitForm()
    }
  }

  submitForm() {
    if (this.hasFormTarget && this.hasInputTarget) {
      const content = this.inputTarget.value.trim()
      if (content) {
        this.disableForm()
        this.submitMessage(content)
      }
    }
  }

  async submitMessage(content) {
    try {
      const formData = new FormData()
      formData.append('message[content]', content)
      
      const response = await fetch(this.formTarget.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        this.addUserMessage(content)
        this.clearInput()
        this.showTyping()
        
        // Simular resposta do agente (substituir por integração real)
        setTimeout(() => {
          this.hideTyping()
          this.addAgentMessage("Esta é uma resposta simulada do agente. Integração com LLM será implementada.")
        }, 1500)
      }
    } catch (error) {
      console.error('Erro ao enviar mensagem:', error)
      this.showError()
    } finally {
      this.enableForm()
    }
  }

  addUserMessage(content) {
    const messageHTML = `
      <div class="flex justify-end">
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-blue-500 text-white">
          <div class="text-sm">${this.escapeHtml(content)}</div>
          <div class="text-xs mt-1 text-blue-100">
            ${new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML('beforeend', messageHTML)
    this.scrollToBottom()
  }

  addAgentMessage(content) {
    const messageHTML = `
      <div class="flex justify-start">
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-white text-gray-900 shadow-sm">
          <div class="text-sm">${this.escapeHtml(content)}</div>
          <div class="text-xs mt-1 text-gray-500">
            ${new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML('beforeend', messageHTML)
    this.scrollToBottom()
  }

  showTyping() {
    const typingHTML = `
      <div class="flex justify-start" data-typing>
        <div class="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-white text-gray-900 shadow-sm">
          <div class="flex items-center space-x-1">
            <div class="flex space-x-1">
              <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
              <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
              <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
            </div>
            <span class="text-xs text-gray-500 ml-2">digitando...</span>
          </div>
        </div>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML('beforeend', typingHTML)
    this.scrollToBottom()
  }

  hideTyping() {
    const typingElement = this.messagesTarget.querySelector('[data-typing]')
    if (typingElement) {
      typingElement.remove()
    }
  }

  showError() {
    const errorHTML = `
      <div class="text-center py-4">
        <span class="text-red-500 text-sm">Erro ao enviar mensagem. Tente novamente.</span>
      </div>
    `
    this.messagesTarget.insertAdjacentHTML('beforeend', errorHTML)
    this.scrollToBottom()
  }

  clearInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
      this.inputTarget.style.height = 'auto'
    }
  }

  disableForm() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.textContent = 'Enviando...'
    }
    if (this.hasInputTarget) {
      this.inputTarget.disabled = true
    }
  }

  enableForm() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = 'Enviar'
    }
    if (this.hasInputTarget) {
      this.inputTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    }
    return text.replace(/[&<>"']/g, (m) => map[m])
  }
}