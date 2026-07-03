'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4LinksSetup () {}

  Ga4LinksSetup.prototype.init = function () {
    var modules = document.querySelectorAll(
      "[data-module~='ga4-links-setup']"
    )

    Array.from(modules).forEach(function (module) {
      this.addDataAttributes(module)
    }.bind(this))
  }

  Ga4LinksSetup.prototype.addDataAttributes = function (module) {
    if (module.tagName.toLowerCase() === 'header') {
      var links = module.querySelectorAll('a')
      var linkData = {
        event_name: 'navigation',
        type: 'header',
        index_link: '',
        index_section: '',
        index_section_count: links.length.toString(),
        index_total: links.length.toString(),
        section: ''
      }

      Array.from(links).forEach(function (link, index) {
        linkData.index_link = (index + 1).toString()
        linkData.index_section = (index + 1).toString()

        if (link.textContent.includes('Fact Check Manager')) {
          linkData.section = 'Fact Check Manager'
        } else if (link.textContent.includes('Sign out')) {
          linkData.section = 'Sign out'
        }

        link.setAttribute('data-ga4-link', JSON.stringify(linkData))
      })
    }
  }

  Modules.Ga4LinksSetup = Ga4LinksSetup
})(window.GOVUK.Modules)
