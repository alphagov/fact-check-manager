describe('GA4LinksSetup', function () {
  'use strict'

  let module, moduleHtml, ga4LinksSetup

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when loaded', function () {
    it('adds the correct parameters to the links in the header section', function () {
      moduleHtml = `
        <a id="rootLink">Fact Check Manager</a>
        <a id="signoutLink">Sign out</a>`
      module = document.createElement('header')
      module.innerHTML = moduleHtml
      document.body.appendChild(module)

      ga4LinksSetup = new window.GOVUK.Modules.Ga4LinksSetup(module)
      ga4LinksSetup.init()

      const rootLink = module.querySelector('a#rootLink')
      const signoutLink = module.querySelector('a#signoutLink')
      const rootLinkGA4Data = JSON.parse(rootLink.dataset.ga4Link)
      const signoutLinkGA4Data = JSON.parse(signoutLink.dataset.ga4Link)

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

    it('adds the correct parameters to the links in the main section', function () {
      moduleHtml =
        `<div>
          <p>Some content</p>
          <a id="bodyLink_1">The first link</a>
        </div>
        <div>
          <p>Some more content</p>
          <a id="bodyLink_2">The second link</a>
          <p>Even more content</p>
          <a id="bodyLink_3">The third link</a>
        </div>`
      module = document.createElement('main')
      module.innerHTML = moduleHtml
      document.body.appendChild(module)

      ga4LinksSetup = new window.GOVUK.Modules.Ga4LinksSetup(module)
      ga4LinksSetup.init()

      const bodyLink1 = module.querySelector('a#bodyLink_1')
      const bodyLink2 = module.querySelector('a#bodyLink_2')
      const bodyLink3 = module.querySelector('a#bodyLink_3')
      const bodyLink1GA4Data = JSON.parse(bodyLink1.dataset.ga4Link)
      const bodyLink2GA4Data = JSON.parse(bodyLink2.dataset.ga4Link)
      const bodyLink3GA4Data = JSON.parse(bodyLink3.dataset.ga4Link)

      expect(bodyLink1GA4Data.event_name).toBe('navigation')
      expect(bodyLink1GA4Data.type).toBe('generic_link')

      expect(bodyLink2GA4Data.event_name).toBe('navigation')
      expect(bodyLink2GA4Data.type).toBe('generic_link')

      expect(bodyLink3GA4Data.event_name).toBe('navigation')
      expect(bodyLink3GA4Data.type).toBe('generic_link')
    })
  })
})
