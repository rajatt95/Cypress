describe "Project Nav", ->
  beforeEach ->
    cy.fixture("user").as("user")
    cy.fixture("projects").as("projects")
    cy.fixture("projects_statuses").as("projectStatuses")
    cy.fixture("config").as("config")
    cy.fixture("runs").as("runs")
    cy.fixture("specs").as("specs")

    cy.visit("/?projectPath=/foo/bar").then (win) ->
      { start, @ipc } = win.App

      cy.stub(@ipc, "getOptions").resolves({})
      cy.stub(@ipc, "updaterCheck").resolves(false)
      cy.stub(@ipc, "getCurrentUser").resolves(@user)
      cy.stub(@ipc, "getRuns").resolves(@runs)
      cy.stub(@ipc, "getSpecs").yields(null, @specs)
      cy.stub(@ipc, "getRecordKeys").resolves([])
      cy.stub(@ipc, "launchBrowser")
      cy.stub(@ipc, "closeBrowser").resolves(null)
      cy.stub(@ipc, "openProject")
      cy.stub(@ipc, "closeProject")
      cy.stub(@ipc, "externalOpen")
      cy.stub(@ipc, "offOpenProject")
      cy.stub(@ipc, "offGetSpecs")
      cy.stub(@ipc, "offOnFocusTests")

      start()

  context "project nav", ->
    beforeEach ->
      @ipc.openProject.yield(null, @config)

    it "displays projects nav", ->
      cy
        .get(".empty").should("not.be.visible")
        .get(".navbar-default")

    it "displays 'Specs' nav as active", ->
      cy
      .get(".navbar-default").contains("a", "Tests")
      .should("have.class", "active")

    describe "when project loads", ->
      beforeEach ->
        cy.wait(600)

      it "displays 'Specs' page", ->
        cy.contains("integration")

    describe "runs page", ->
      beforeEach ->
        cy
          .fixture("runs").as("runs")
          .get(".navbar-default")
            .contains("a", "Runs").as("runsNav").click()

      it "highlights runs on click", ->
        cy
          .get("@runsNav")
            .should("have.class", "active")

      it "displays runs page", ->
        cy
          .get(".runs-container li")
          .should("have.length", 4)

    describe "settings page", ->
      beforeEach ->
        cy
          .get(".navbar-default")
            .contains("a", "Settings").as("settingsNav").click()

      it "highlights config on click", ->
        cy
          .get("@settingsNav")
            .should("have.class", "active")

      it "displays settings page", ->
        cy.contains("Configuration")

  context "browsers dropdown", ->
    describe "browsers available", ->
      beforeEach ->
        @ipc.openProject.yield(null, @config)

      context "normal browser list behavior", ->
        it "lists browsers", ->
          cy
            .get(".browsers-list").parent()
            .find(".dropdown-menu").first().find("li").should("have.length", 2)
            .should ($li) ->
              expect($li.first()).to.contain("Chromium")
              expect($li.last()).to.contain("Canary")

        it "does not display stop button", ->
          cy
            .get(".close-browser").should("not.exist")

        describe "default browser", ->
          it "displays default browser name in chosen", ->
            cy
              .get(".browsers-list>a").first()
                .should("contain", "Chrome")

          it "displays default browser icon in chosen", ->
            cy
              .get(".browsers-list>a").first()
                .find(".fa-chrome")

      context "switch browser", ->
        beforeEach ->
          cy
            .get(".browsers-list>a").first().click()
            .get(".browsers-list").find(".dropdown-menu")
              .contains("Chromium").click()

        afterEach ->
          cy.clearLocalStorage()

        it "switches text in button on switching browser", ->
          cy
            .get(".browsers-list>a").first().contains("Chromium")

        it "swaps the chosen browser into the dropdown", ->
          cy
            .get(".browsers-list").find(".dropdown-menu")
            .find("li").should("have.length", 2)
            .should ($li) ->
              expect($li.first()).to.contain("Chrome")
              expect($li.last()).to.contain("Canary")

        it "saves chosen browser in local storage", ->
          expect(localStorage.getItem("chosenBrowser")).to.eq("chromium")

      context "opening browser by choosing spec", ->
        beforeEach ->
          cy.contains(".file", "app_spec").click()

        it "displays browser icon as spinner", ->
          cy
            .get(".browsers-list>a").first().find("i")
              .should("have.class", "fa fa-refresh fa-spin")

        it "disables browser dropdown", ->
          cy
            .get(".browsers-list>a").first()
              .and("have.class", "disabled")

      context "browser opened after choosing spec", ->
        beforeEach ->
          @ipc.launchBrowser.yields(null, {browserOpened: true})
          cy.contains(".file", "app_spec").click()

        it "displays browser icon as opened", ->
          cy
            .get(".browsers-list>a").first().find("i")
              .should("have.class", "fa fa-check-circle-o")

        it "disables browser dropdown", ->
          cy
            .get(".browsers-list>a").first()
              .should("have.class", "disabled")

        it "displays stop browser button", ->
          cy
            .get(".close-browser").should("be.visible")

        describe "stop browser", ->
          beforeEach ->
            cy.get(".close-browser").click()

          it "calls close:browser on click of stop button", ->
            expect(@ipc.closeBrowser).to.be.called

          it "hides close button on click of stop", ->
            cy.get(".close-browser").should("not.exist")

          it "re-enables browser dropdown", ->
            cy
              .get(".browsers-list>a").first()
                .should("not.have.class", "disabled")

          it "displays default browser icon", ->
            cy
              .get(".browsers-list>a").first()
                .find(".fa-chrome")

        describe "browser is closed manually", ->
          beforeEach ->
            @ipc.launchBrowser.yield(null, {browserClosed: true})

          it "hides close browser button", ->
            cy.get(".close-browser").should("not.be.visible")

          it "re-enables browser dropdown", ->
            cy.get(".browsers-list>a").first()
              .and("not.have.class", "disabled")

          it "displays default browser icon", ->
            cy.get(".browsers-list>a").first()
              .find(".fa-chrome")

    describe "local storage saved browser", ->
      beforeEach ->
        localStorage.setItem("chosenBrowser", "chromium")
        @ipc.openProject.yield(null, @config)

      afterEach ->
        cy.clearLocalStorage()

      it "displays local storage browser name in chosen", ->
        cy
          .get(".browsers-list>a").first()
            .should("contain", "Chromium")

      it "displays local storage browser icon in chosen", ->
        cy
          .get(".browsers-list>a").first()
            .find(".fa-chrome")

    describe "when browser saved in local storage no longer exists", ->
      beforeEach ->
        localStorage.setItem("chosenBrowser", "netscape-navigator")
        @ipc.openProject.yield(null, @config)

      it "defaults to first browser", ->
        cy
          .get(".browsers-list>a").first()
            .should("contain", "Chrome")

    describe "only one browser available", ->
      beforeEach ->
        @oneBrowser = [{
          "name": "electron"
          "version": "50.0.2661.86"
          "path": ""
          "majorVersion": "50"
        }]

        @config.browsers = @oneBrowser
        @ipc.openProject.yield(null, @config)

      it "displays no dropdown btn", ->
        cy
          .get(".browsers-list")
            .find(".dropdown-toggle").should("not.be.visible")

    describe "browser with info", ->
      beforeEach ->
        @info = "The Electron browser is the version of Chrome that is bundled with Electron. Cypress uses this browser when running headlessly, so it may be useful for debugging issues that occur only in headless mode."
        @config.browsers = [{
          "name": "electron"
          "version": "50.0.2661.86"
          "path": ""
          "majorVersion": "50"
          "info": @info
        }]

        @ipc.openProject.yield(null, @config)

      it "shows info icon with tooltip", ->
        cy
          .get(".browsers .fa-info-circle")
          .then ($el) ->
            $el[0].dispatchEvent(new Event("mouseover", {bubbles: true}))
          .get(".cy-tooltip")
          .should("contain", @info)
