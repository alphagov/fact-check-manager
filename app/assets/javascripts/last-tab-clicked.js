window.GOVUK = window.GOVUK || {}

window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  function LastTabClicked (self) {
    this.tab = self
    this.button = document.querySelector('.js-response-button')
    if (!this.button) return

    this.originalButtonUrl = this.button.href
    this.tab.addEventListener('click', this.onClick.bind(this))
  }

  LastTabClicked.prototype.onClick = function (event) {
    const tab = event.target.closest('.govuk-tabs__tab')
    if (!tab) return

    const url = new URL(tab.href)
    const newUrl = new URL(this.originalButtonUrl)
    newUrl.searchParams.set('previousPageTab', url.hash.replace('#', ''))
    this.button.href = newUrl
  }

  Modules.LastTabClicked = LastTabClicked
})(window.GOVUK.Modules)
