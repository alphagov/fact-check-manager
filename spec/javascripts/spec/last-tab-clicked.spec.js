describe('GOVUK.Modules.LastTabClicked', () => {
  'use strict'

  let container, tabsElement, formattedTabElement, markdownTabElement, panelLinkElement, buttonElement, lastTabClicked

  const moduleHtml =
      `<div class="govuk-tabs">
        <a class="govuk-tabs__tab" id="formatted-view" href="#formatted-view">Formatted view</a>
        <a class="govuk-tabs__tab" id="markdown-view" href="#markdown-view">Markdown view</a>
        <div class="govuk-tabs__panel">
          <p>Some content <a id="panel-link" href="https://www.gov.uk/other">a link</a></p>
        </div>
      </div>
      <a class="js-response-button" href="https://www.gov.uk/test">Submit</a>`

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = moduleHtml
    document.body.appendChild(container)

    tabsElement = container.querySelector('.govuk-tabs')
    formattedTabElement = container.querySelector('#formatted-view')
    markdownTabElement = container.querySelector('#markdown-view')
    panelLinkElement = container.querySelector('#panel-link')
    buttonElement = container.querySelector('.js-response-button')

    panelLinkElement.addEventListener('click', (event) => event.preventDefault())

    lastTabClicked = new window.GOVUK.Modules.LastTabClicked(tabsElement)
  })

  afterEach(() => {
    document.body.removeChild(container)
  })

  describe('when a tab is clicked', () => {
    it('instantiates the module correctly', function () {
      expect(lastTabClicked).toBeDefined()
    })

    it('appends the tab hash to the button URL as previousPageTab', () => {
      formattedTabElement.click()

      expect(buttonElement.href).toBe('https://www.gov.uk/test?previousPageTab=formatted-view')
    })
  })

  describe('when two tabs are clicked', () => {
    it('appends the second tab hash clicked to the button URL as previousPageTab', () => {
      formattedTabElement.click()
      markdownTabElement.click()

      expect(buttonElement.href).toBe('https://www.gov.uk/test?previousPageTab=markdown-view')
    })
  })

  describe('when no tab is clicked', () => {
    it('retains the default button url', () => {
      expect(buttonElement.href).toBe('https://www.gov.uk/test')
    })
  })

  describe('when something other than a tab is clicked', () => {
    it('retains the default button url', () => {
      container.querySelector('.govuk-tabs__panel p').click()
      panelLinkElement.click()

      expect(buttonElement.href).toBe('https://www.gov.uk/test')
    })
  })

  describe('when there is no response button', () => {
    it('does not throw', () => {
      buttonElement.remove()

      expect(() => new window.GOVUK.Modules.LastTabClicked(tabsElement)).not.toThrow()
      expect(() => formattedTabElement.click()).not.toThrow()
    })
  })
})
