describe('GA4LinksSetup', function () {
  'use strict'

  var module, ga4LinksSetup

  beforeEach(function () {
    var moduleHtml =
      `<header data-module="ga4-links-setup">
          <a id="rootLink">Fact Check Manager</a>
          <a id="signoutLink">Sign out</a>
        </header>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    ga4LinksSetup = new window.GOVUK.Modules.Ga4LinksSetup()
    ga4LinksSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when loaded', function () {
    it('adds the correct parameters to the links in the header', function () {
      var header = module.querySelector('header')
      var rootLink = header.querySelector('a#rootLink')
      var signoutLink = header.querySelector('a#signoutLink')
      var rootLinkGA4Data = JSON.parse(rootLink.dataset.ga4Link)
      var signoutLinkGA4Data = JSON.parse(signoutLink.dataset.ga4Link)

      expect(rootLinkGA4Data.event_name).toBe('navigation')
      expect(rootLinkGA4Data.type).toBe('header')
      expect(rootLinkGA4Data.index_link).toBe('1')
      expect(rootLinkGA4Data.index_section).toBe('1')
      expect(rootLinkGA4Data.index_section_count).toBe('2')
      expect(rootLinkGA4Data.index_total).toBe('2')
      expect(rootLinkGA4Data.section).toBe('Fact Check Manager')

      expect(signoutLinkGA4Data.event_name).toBe('navigation')
      expect(signoutLinkGA4Data.type).toBe('header')
      expect(signoutLinkGA4Data.index_link).toBe('2')
      expect(signoutLinkGA4Data.index_section).toBe('2')
      expect(signoutLinkGA4Data.index_section_count).toBe('2')
      expect(signoutLinkGA4Data.index_total).toBe('2')
      expect(signoutLinkGA4Data.section).toBe('Sign out')
    })
  })
})
