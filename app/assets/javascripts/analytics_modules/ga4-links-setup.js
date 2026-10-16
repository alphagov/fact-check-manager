'use strict'

window.GOVUK = window.GOVUK || {}
window.GOVUK.analyticsGa4 = window.GOVUK.analyticsGa4 || {}
window.GOVUK.analyticsGa4.analyticsModules = window.GOVUK.analyticsGa4.analyticsModules || {}

;(function (Modules) {
  function Ga4LinksSetup (module) {
    this.module = module
  }

  Ga4LinksSetup.prototype.init = function () {
    this.addDataAttributes(this.module)
  }

  Ga4LinksSetup.prototype.addDataAttributes = function (module) {
    var linkData
    var links = module.querySelectorAll('a')

    if (module.tagName.toLowerCase() === 'header') {
      linkData = {
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
    } else {
      linkData = {
        event_name: 'navigation',
        type: 'generic_link'
      }

      Array.from(links).forEach(function (link, index) {
        var href = link.getAttribute('href')
        // Links can carry preview JWTs, which must not be sent to GA4.
        // These links sit inside data-ga4-do-not-redact, so the tracker's
        // own query string stripping does not apply to them.
        if (href) {
          linkData.url = this.stripTokens(href)
        } else {
          delete linkData.url
        }

        link.setAttribute('data-ga4-link', JSON.stringify(linkData))
      }, this)
    }
  }

  Ga4LinksSetup.prototype.stripTokens = function (url) {
    return url.replace(/((?:\?|&)token=)(?:[^&#\s]*)/g, '$1[token]')
  }

  Modules.Ga4LinksSetup = Ga4LinksSetup
})(window.GOVUK.Modules)
