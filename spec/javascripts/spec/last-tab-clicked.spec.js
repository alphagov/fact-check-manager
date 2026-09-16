describe('GOVUK.Modules.LastTabClicked', () => {
  'use strict'

  let container, formattedTabElement, markdownTabElement, buttonElement, formattedLastTabClicked, markdownLastTabClicked

  const moduleHtml =
      `<div>
        <a id="formatted-view" href="#formatted-view">Formatted view/a>
        <a id="markdown-view" href="#markdown-view">Markdown view/a>
        <a class="js-response-button" href="https://www.gov.uk/test">Submit</a>
      </div>`

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = moduleHtml
    document.body.appendChild(container)

    formattedTabElement = container.querySelector('#formatted-view')
    markdownTabElement = container.querySelector('#markdown-view')
    buttonElement = container.querySelector('.js-response-button')

    formattedLastTabClicked = new window.GOVUK.Modules.LastTabClicked(formattedTabElement)
    markdownLastTabClicked = new window.GOVUK.Modules.LastTabClicked(markdownTabElement)
  })

  afterEach(() => {
    document.body.removeChild(container)
  })

  describe('when a tab is clicked', () => {
    it('instantiates the module correctly', function () {
      expect(formattedLastTabClicked).toBeDefined()
      expect(markdownLastTabClicked).toBeDefined()
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
})
