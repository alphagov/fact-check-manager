'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4FormSetup () {}

  Ga4FormSetup.prototype.init = function () {
    let forms
    const modules = document.querySelectorAll(
      "[data-module~='ga4-form-setup']"
    )

    Array.from(modules).forEach(function (module) {
      forms = module.querySelectorAll('form')
    })

    Array.from(forms).forEach(function (form) {
      this.addDataAttributes(form)
      this.callFormChangeTracker(form)
    }.bind(this))
  }

  Ga4FormSetup.prototype.addDataAttributes = function (form) {
    const section = form.closest('[data-ga4-section]').getAttribute('data-ga4-section')
    const type = 'new'
    const action = form.querySelector('button[type="submit"]').textContent.toLowerCase()

    const eventData = {
      event_name: 'form_response',
      type,
      section,
      action
    }

    form.setAttribute('data-ga4-form-include-text', '')
    form.setAttribute('data-ga4-form-change-tracking', '')
    form.setAttribute('data-ga4-form-record-json', '')
    form.setAttribute('data-ga4-form-use-text-count', '')
    form.setAttribute('data-ga4-form', JSON.stringify(eventData))
  }

  Ga4FormSetup.prototype.callFormChangeTracker = function (form) {
    const ga4FormChangeTracker = new window.GOVUK.Modules.Ga4FormChangeTracker(form)

    ga4FormChangeTracker.init()
  }

  Modules.Ga4FormSetup = Ga4FormSetup
})(window.GOVUK.Modules)
