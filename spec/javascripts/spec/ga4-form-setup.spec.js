describe('GA4FormSetup', function () {
  'use strict'

  var module, ga4FormSetup

  beforeEach(function () {
    var moduleHtml =
      `<div data-module="ga4-form-setup" data-ga4-section="The section name">
        <form>
          <fieldset>
            <legend>The legend</legend>
          </fieldset>
          <button type="submit">Continue</button>
        </form>
      </div>`

    module = document.createElement('div')
    module.innerHTML = moduleHtml
    document.body.appendChild(module)

    ga4FormSetup = new window.GOVUK.Modules.Ga4FormSetup()
    ga4FormSetup.init()
  })

  afterEach(function () {
    document.body.removeChild(module)
  })

  describe('when loaded', function () {
    var form, formGA4Data, formEventData

    it('adds the correct parameters to the form', function () {
      form = module.querySelectorAll('form')[0]
      formGA4Data = form.dataset
      formEventData = JSON.parse(formGA4Data.ga4Form)

      expect(formEventData.action).toBe('continue')
      expect(formEventData.event_name).toBe('form_response')
      expect(formEventData.section).toBe('The section name')
      expect(formEventData.type).toBe('new')
      expect(Object.keys(formGA4Data)).toContain('ga4FormIncludeText')
      expect(Object.keys(formGA4Data)).toContain('ga4FormChangeTracking')
      expect(Object.keys(formGA4Data)).toContain('ga4FormRecordJson')
      expect(Object.keys(formGA4Data)).toContain('ga4FormUseTextCount')
    })
  })
})
