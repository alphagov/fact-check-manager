window.GOVUK = window.GOVUK || {}

window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
    'use strict'

    function LastTabClicked(self) {
        this.tab = self
        this.button = document.querySelector('.js-response-button')
        this.originalButtonUrl = this.button.href
        this.tab.addEventListener('click', this.onClick.bind(this))
    }

    LastTabClicked.prototype.onClick = function (event) {
        const url = new URL(event.target.href)
        const newUrl = new URL(this.originalButtonUrl)
        newUrl.searchParams.set('previousPageTab', url.hash.replace('#', ''))
        this.button.href = newUrl
    }

    Modules.LastTabClicked = LastTabClicked
})(window.GOVUK.Modules);