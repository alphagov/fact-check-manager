describe('GA4LinksSetup', function () {
  'use strict'

  var module, ga4LinksSetup

  beforeEach(function () {
    var moduleHtml =
      `<header data-module="ga4-links-setup">
          <a id="rootLink">Fact Check Manager</a>
          <a id="signoutLink">Sign out</a>
        </header>
        <main data-module="ga4-links-setup">
          <div>
            <div class="gem-c-heading">
              <h1>The page title</h1>
            </div>
          </div>
          <div>
            <p>Some content</p>
            <a id="bodyLink_1">The first link</a>
          </div>
          <div>
            <div class="gem-c-heading">
              <h2>The first section heading</h2>
            </div>
            <p>Some more content</p>
            <a id="bodyLink_2">The second link</a>
            <div class="gem-c-heading">
              <h2>The second section heading</h2>
            </div>
            <p>Even more content</p>
            <a id="bodyLink_3">The third link</a>
            <a id="bodyLink_4">The fourth link</a>
          </div>
        </main>`

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

    it('adds the correct parameters to the links in the main section', function () {
      var main = module.querySelector('main')
      var bodyLink_1 = main.querySelector('a#bodyLink_1')
      var bodyLink_2 = main.querySelector('a#bodyLink_2')
      var bodyLink_3 = main.querySelector('a#bodyLink_3')
      var bodyLink_4 = main.querySelector('a#bodyLink_4')
      var bodyLink_1_GA4Data = JSON.parse(bodyLink_1.dataset.ga4Link)
      var bodyLink_2_GA4Data = JSON.parse(bodyLink_2.dataset.ga4Link)
      var bodyLink_3_GA4Data = JSON.parse(bodyLink_3.dataset.ga4Link)
      var bodyLink_4_GA4Data = JSON.parse(bodyLink_4.dataset.ga4Link)

      expect(bodyLink_1_GA4Data.event_name).toBe('navigation')
      expect(bodyLink_1_GA4Data.type).toBe('generic_link')
      // expect(bodyLink_1_GA4Data.index_link).toBe('1')
      // expect(bodyLink_1_GA4Data.index_section).toBe('1')
      // expect(bodyLink_1_GA4Data.index_section_count).toBe('2')
      // expect(bodyLink_1_GA4Data.index_total).toBe('2')
      expect(bodyLink_1_GA4Data.section).toBe('')

      expect(bodyLink_2_GA4Data.event_name).toBe('navigation')
      expect(bodyLink_2_GA4Data.type).toBe('generic_link')
      // expect(bodyLink_2_GA4Data.index_link).toBe('1')
      // expect(bodyLink_2_GA4Data.index_section).toBe('1')
      // expect(bodyLink_2_GA4Data.index_section_count).toBe('2')
      // expect(bodyLink_2_GA4Data.index_total).toBe('2')
      expect(bodyLink_2_GA4Data.section).toBe('The first section heading')

      expect(bodyLink_3_GA4Data.event_name).toBe('navigation')
      expect(bodyLink_3_GA4Data.type).toBe('generic_link')
      // expect(bodyLink_3_GA4Data.index_link).toBe('1')
      // expect(bodyLink_3_GA4Data.index_section).toBe('1')
      // expect(bodyLink_3_GA4Data.index_section_count).toBe('2')
      // expect(bodyLink_3_GA4Data.index_total).toBe('2')
      expect(bodyLink_3_GA4Data.section).toBe('The second section heading')
    })
  })
})
