({
    /*
     *	Calls Apex controller to load the resources of a specific site. Gets the site from
     *	the component passed through as a parameter.
     */
    loadCliniciansAndEvents: function(component) {
        component.set('v.isLoading', true);
        let action = component.get("c.getClinicianAndEvents");
        action.setParams({
            today: moment().format(),
        });

        action.setCallback(this, function(response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                const clinicians = result.clinicians;
                const events = result.events;
                const loggedInUser = result.loggedInUser;
                let clinicianArray = [];
                let self = this;

                for (let i of clinicians) {
                    if (!i.siteName) i.siteName = 'Uncategorized';

                    clinicianArray.push(i);
                }

                component.set("v.totalEvents", self.formatEvents(events));
                component.set("v.filteredEvents", self.formatEvents(events));
                component.set('v.loggedInUser', loggedInUser);
                component.set('v.workers', clinicians);
                component.set('v.clinicians', clinicianArray);
                component.set('v.filteredClinicians', clinicianArray);
                component.set('v.isLoading', false);

                self.loadCalendar(component);
                self.setActiveClass(component);
            }
        });
        $A.enqueueAction(action);
    },
    handleFetchWithFilters: function(component) {
        component.set('v.isLoading', true);
        const site = JSON.parse(JSON.stringify(component.get('v.site')));
        const discipline = component.get('v.discipline');
        let clinician = component.get('v.searchclinicianIds');

        if (clinician.length > 0) {
            const defaultUser = {
                Id: component.get('v.loggedInUser').Id,
                Name: component.get('v.loggedInUser').Name
            };

            clinician.push(defaultUser);
        }

        if (typeof site.Name == 'undefined' && discipline == '' && clinician.length == 0) {
            this.reloadData(component);
        } else {
            if (typeof site.Name != 'undefined' && discipline == '' && clinician.length == 0) { // only site
                this.fetchContactWithSite(component, site.Name)
            } else if (typeof site.Name == 'undefined' && discipline != '' && clinician.length == 0) { // only discipline
                this.fetchContactWithDiscipline(component, discipline);
            } else if (typeof site.Name == 'undefined' && discipline == '' && clinician.length > 0) { // only multi lookup
                this.fetchContactWithMultiLookup(component, clinician);
            } else if (typeof site.Name != 'undefined' && discipline != '' && clinician.length == 0) { // site and discipline
                this.fetchContactWithSiteAndDiscipline(component, site.Name, discipline);
            } else if (typeof site.Name != 'undefined' && discipline == '' && clinician.length > 0) { // site and multi lookup
                this.fetchContactWithMultipleFilter(component, site.Name, discipline, clinician);
            } else if (typeof site.Name == 'undefined' && discipline != '' && clinician.length > 0) { // discipline and multi lookup
                this.fetchContactWithMultipleFilter(component, site.Name, discipline, clinician);
            } else if (typeof site.Name != 'undefined' && discipline != '' && clinician.length > 0) { // site, discipline and multi lookup
                this.fetchContactWithMultipleFilter(component, site.Name, discipline, clinician);
            }
        }
    },
    fetchContactWithMultipleFilter: function(component, site, discipline, clinician) {
       	let m = component.get('v.goToDate') == '' ? moment() : moment(component.get('v.goToDate'));
        let action = component.get("c.getContactWithMultipleFilter");

        action.setParams({
            today: m.format(),
            site,
            discipline,
            multiLookup: JSON.stringify(clinician)
        });

        // Check if searched clinician via multilookup is already searched
        this.handleActionCallback(component, action, false);
    },
    fetchContactWithMultiLookup: function(component, searchClinicians) {
        if (searchClinicians.length == 0) {
            this.resetData(component);
            return
        };

        let text = searchClinicians;
        // Do not remove
        // let text = this.removeSearchedClinician(component, searchClinicians);

        if (text.length == 0) {
            this.showMyToast('dismissible', 'info', '', `All searched clinicians are already in the list`);
            component.set('v.isLoading', false);
            return
        }

       	let m = component.get('v.goToDate') == '' ? moment() : moment(component.get('v.goToDate'));
        let action = component.get("c.getClinicianAndEventsByMultiLookup");
        action.setParams({
            today: m.format(),
            multiLookup: JSON.stringify(text)
        });

        // Check if searched clinician via multilookup is already searched
        this.handleActionCallback(component, action, true);
    },
    fetchContactWithSiteAndDiscipline: function(component, site, discipline) {
        if (site == '' && discipline == '') {
            this.resetData(component);
            return
        }

       	let m = component.get('v.goToDate') == '' ? moment() : moment(component.get('v.goToDate'));
        let action = component.get("c.getClinicianAndEventsBySiteAndDiscipline");
        action.setParams({
            today: m.format(),
            site,
            discipline
        });
        this.handleActionCallback(component, action);
    },
    fetchContactWithDiscipline: function(component, text) {
        if (text == '') {
            this.resetData(component);
            return
        }

       	let m = component.get('v.goToDate') == '' ? moment() : moment(component.get('v.goToDate'));
        let action = component.get("c.getClinicianAndEventsByDiscipline");
        action.setParams({
            today: m.format(),
            discipline: text
        });
        this.handleActionCallback(component, action);
    },
    fetchContactWithSite: function(component, text) {
        if (text == '') {
            this.resetData(component);
            return
        }

       	let m = component.get('v.goToDate') == '' ? moment() : moment(component.get('v.goToDate'));
        let action = component.get("c.getClinicianAndEventsBySite");
        action.setParams({
            today: m.format(),
            site: text
        });
        this.handleActionCallback(component, action);
    },
    removeSearchedClinician: function(component, searchClinicians) {
        let clinicians = component.get('v.filteredClinicians');

        if (searchClinicians.length > 0) {
            for (let clinician of clinicians) {
                for (let i = 0; i < searchClinicians.length; i++) {
                    if (clinician.Id == searchClinicians[i].Id) {
                        searchClinicians.splice(i, 1);
                    }
                }
            }
        }

        return searchClinicians;
    },
    fetchContactWithDate: function(component, date, isFrommGoToDate=false) {
        component.set('v.isLoading', true);
        const calendar = component.get('v.calendar');
        calendar.destroy();

        const m = moment(date);
        const nextSeven = moment(calendar.getDate()).add(6, 'days');
        const prevSeven = moment(calendar.getDate()).subtract(6, 'days');

        if (date == '') {
            this.resetData(component);
            return
        }

        // Check if selected date is between seven days from today or seven days ago
        if (isFrommGoToDate && !m.isAfter(nextSeven, 'day') && !m.isBefore(prevSeven, 'day')) {
            this.loadCalendar(component);
            this.setActiveClass(component);

            component.set('v.isLoading', false);
            return
        }

        let workerIds = [];

        for (let i of component.get('v.filteredClinicians')) {
            workerIds.push(i.id)
        }

        let action = component.get("c.getEventsByDate");

        action.setParams({
            startDate: moment(m).subtract(6, 'days'),
            endDate: moment(m).add(6, 'days'),
            workerIds
        });

        action.setCallback(this, function(response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                const events = result.events;
                let self = this;
                component.set("v.filteredEvents", self.formatEvents(events));
                self.loadCalendar(component);
                self.setActiveClass(component);
                component.set('v.isNetxPrev', false);
                component.set('v.isLoading', false);
            } else {
                // print if error
                component.set('v.isLoading', false);
            }
        });

        $A.enqueueAction(action);
    },
    handleActionCallback: function(component, action, isMultiLookup=false) {
        action.setCallback(this, function(response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                component.set('v.didClickFilter', true);
                const result = response.getReturnValue();
                const clinicians = result.clinicians;
                const events = result.events;
                let self = this;
                let initialEvents = component.get('v.totalEvents');
                let initialClinicians = component.get('v.clinicians');
                let eventArray = self.formatEvents(events);
                let clinicianArray = [];

                // Push newly searched clinicians and their events to default data
                if (isMultiLookup) {
                    // Number of clinicians from multi lookup minus 1 for the loggedin user
                    self.showMyToast('dismissible', 'success', 'Success!', `Successfully added ${clinicians.length - 1} to the list`);
                }

                for (let i of clinicians) {
                    if (!i.siteName) i.siteName = 'Uncategorized';

                    clinicianArray.push(i);
                }

                for (let i of initialEvents) {
                    eventArray.push(i);
                }

                self.setCalendarData(component, events, [...initialClinicians, ...clinicianArray]);
                self.reloadCalendar(component);

                component.set('v.isLoading', false);
            } else {
                // print if error
                component.set('v.isLoading', false);
            }
        });

        $A.enqueueAction(action);
    },
    showMyToast: function(mode, type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: mode,
            title: title,
            message: message,
            type : type
        });
        toastEvent.fire();
    },
    closeModals: function(component) {
        component.set('v.createFormVisible', false);
        component.set('v.editFormVisible', false);
    },
    closeCreateModal: function(component) {
        component.set('v.createFormVisible', false);
    },
    closeEditModal: function(component) {
        component.set('v.editFormVisible', false);
    },
    setCalendarData: function(component, events, clinicians) {
        component.set("v.filteredEvents", events);
        component.set('v.workers', clinicians);
        component.set('v.filteredClinicians', clinicians);
    },
    resetData: function(component) {
        component.set('v.didClickFilter', false);
        const events = component.get("v.filteredEvents");
        const clinicians = component.get('v.filteredClinicians');

        this.setCalendarData(component, events, clinicians);
        this.reloadCalendar(component);

        component.set('v.isLoading', false);
    },
    reloadData: function(component) {
        component.set('v.isLoading', false);

        const events = component.get("v.totalEvents");
        const clinicians = component.get('v.clinicians');

        this.setCalendarData(component, events, clinicians);
        this.reloadCalendar(component);

        component.set('v.isLoading', false);
    },
    handleSelectEvent: function(component, event) {
        const events = component.get('v.filteredEvents');
        component.set('v.viewEvent', event.extendedProps.eventId);
        component.set('v.eventSelected', events.find(e => e.id === event.extendedProps.eventId));
        component.set('v.editFormVisible', true);
    },
    formatEvents: function(events) {
        let eventArray = [];
        // Using traditional for of loop for faster performance
        for (let i of events) {
            let classNameArray = [];

            if (i.Event_Status__c == 'Pending') {
                classNameArray.push('fc-br-pending');
            } else if (i.Event_Status__c == 'Cancelled') {
                classNameArray.push('fc-br-cancelled');
            }

            if (i.Event_Type__c == 'Out of Office') {
                classNameArray.push('fc-br-outofoffice');
            } else if (i.Event_Type__c == 'Therapy Session') {
                classNameArray.push('fc-br-therapysession');
            } else if (i.Event_Type__c == 'Initial Appointment') {
                classNameArray.push('fc-br-initialappointment');
            } else if (i.Event_Type__c == 'Other PCH') {
                classNameArray.push('fc-br-otherpch');
            } else {
                classNameArray.push('fc-br-internal');
            }

            // Set new properties to event object
            i.classNames = classNameArray;

            if (i.Event_Status__c != 'Cancelled') {
                eventArray.push(i);
            }
        }

        return eventArray;
    },
    reloadCalendar: function(component) {
        const calendar = component.get('v.calendar');
        calendar.refetchEvents();
        calendar.refetchResources();
    },
    loadCalendar: function(component) {
        let viewType = component.get('v.isWeeklyView') ? 'resourceTimelineWeek' : 'resourceTimelineDay';
        let gotodate = component.get('v.isNetxPrev') ? component.get('v.goToNextPrevDate') : component.get('v.goToDate');
       	let m = gotodate == '' ? moment() : moment(gotodate);
        let self = this;
        let calendar = new FullCalendar.Calendar(component.find("calendar").getElement(), {
            schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives',
            header: {
                left: 'prevDay,nextDay currentDay newEvent',
                center: 'title',
                right: 'dayView,weekView'
            },
            customButtons: {
                prevDay: {
                    icon: 'chevron-left',
                    click: function() {
                        let prevSeven = moment(m).subtract(6, 'days');

                        if (component.get('v.isWeeklyView')) {
                            self.prevNextDate(component, calendar, false, 7);
                        } else {
                            if (moment(calendar.getDate()).isSame(prevSeven, 'day')) {
                                self.prevNextDate(component, calendar, false, 1);
                            } else {
                                calendar.prev();
                                self.setActiveClass(component);
                            }
                        }

                        let todayButton = component.find('calendar').getElement().firstChild.firstChild.firstChild.nextSibling;
                        self.setTodayButton(component, moment(calendar.getDate()).format(), todayButton);
                    }
                },
                nextDay: {
                    icon: 'chevron-right',
                    click: function() {
                        let nextSeven = moment(m).add(6, 'days');
                        if (component.get('v.isWeeklyView')) {
                            self.prevNextDate(component, calendar, true, 7);
                        } else {
                            if (moment(calendar.getDate()).isSame(nextSeven, 'day')) {
                                self.prevNextDate(component, calendar, true, 1);
                            } else {
                                calendar.next();
                                self.setActiveClass(component);
                            }
                        }

                        let todayButton = component.find('calendar').getElement().firstChild.firstChild.firstChild.nextSibling;
                        self.setTodayButton(component, moment(calendar.getDate()).format(), todayButton);
                    }
                },
                currentDay: {
                    text: 'today',
                    click: function() {
                        component.set('v.goToDate', '');

                        if (!self.isTodayInBetween(component)) {
                            self.fetchContactWithDate(component, calendar.today());
                        }

                        let todayButton = component.find('calendar').getElement().firstChild.firstChild.firstChild.nextSibling;
                        self.setTodayButton(component, moment().format(), todayButton);
                        self.setActiveClass(component);
                    }
                },
                newEvent: {
                    text: 'New Event',
                    click: function() {
                        component.set('v.createFormVisible', true);
                    }
                },
                dayView: {
                    text: 'day',
                    click: function() {
                        component.set('v.isWeeklyView', false);
                        calendar.changeView('resourceTimelineDay');
                        self.setActiveClass(component);
                    }
                },
                weekView: {
                    text: 'week',
                    click: function() {
                        component.set('v.isWeeklyView', true);
                        calendar.changeView('resourceTimelineWeek');
                        self.setActiveClass(component);
                        let todayButton = component.find('calendar').getElement().firstChild.firstChild.firstChild.nextSibling;
                        self.changeWeeklyDateFormat(component);
                        self.setTodayButton(component, moment().format(), todayButton);
                    }
                },
            },
            defaultView: viewType,
            resourceLabelText: 'Clinicians',
            weekends: true,
            firstDay: 1,
            resourceAreaWidth: "15%",
            slotDuration: '00:15:00',
            minTime: '08:00:00',
            maxTime: '20:15:00',
            height: "auto",
            defaultDate: m.format(),
            selectable : true,
            slotEventOverlap: false,
            navLinks: true, // can click day/week names to navigate views
            weekNumbersWithinDays: true,
            nowIndicator: true,
            eventLimit: true,
            resourceOrder: 'siteName, Name',
            events: function(info, successCallback, failureCallback) {
                let events = component.get('v.filteredEvents');
                successCallback(events);
            },
            weekLabel: 'W',
            eventClick: function(e) {
                self.handleSelectEvent(component, e.event);
            },
            resourceGroupField: 'siteName',
            resources: function(info, successCallback, failureCallback) {
                successCallback(component.get('v.filteredClinicians'));
            },
            plugins:['resourceTimeline', 'timeline', 'timeGrid', 'interaction', 'moment']
        });

        calendar.render();
        component.set('v.calendar', calendar);

        let calendarElement = component.find('calendar').getElement().firstChild;
        let todayButton = calendarElement.firstChild.firstChild.nextSibling;
        let weeklyButton = calendarElement.lastChild.firstChild.lastElementChild;
        let dayButton = calendarElement.lastChild.firstChild.firstElementChild;
        self.setTodayButton(component, moment(calendar.getDate()).format(), todayButton);

        if (component.get('v.isWeeklyView')) { self.changeWeeklyDateFormat(component); }
    },
    /*
     * Manually change the format of the weekly date during week view
     * from mm/dd to dd/mm
     * Reference:
     * https://betterrehab.atlassian.net/browse/BR-55
    */
    changeWeeklyDateFormat: function(component) {
        let slotHeader = component.find('calendar').getElement().lastChild.firstChild.firstChild
                                                    .firstElementChild.firstElementChild.lastElementChild
                                                    .firstElementChild.firstElementChild.firstElementChild
                                                    .firstElementChild.firstElementChild.lastElementChild
                                                    .firstElementChild.children;

		for (let i = 0; i < slotHeader.length; i++) {
            let div = slotHeader[i].firstElementChild.firstElementChild;
            const myArray = div.textContent.split(" ");
            const lastText = myArray[myArray.length - 1];
            const lastArray = lastText.split("/").reverse();
            const reversed = `${lastArray[0]}/${lastArray[lastArray.length - 1]}`;
            div.textContent = `${myArray[0]} ${reversed}`;
        }
    },
    setActiveClass: function(component) {
        let calendarElement = component.find('calendar').getElement().firstChild;
        let weeklyButton = calendarElement.lastChild.firstChild.lastElementChild;
        let dayButton = calendarElement.lastChild.firstChild.firstElementChild;

        if (!component.get('v.isWeeklyView')) {
            dayButton.classList.add('fc-button-active');
            weeklyButton.classList.remove('fc-button-active');
        } else {
            dayButton.classList.remove('fc-button-active');
            weeklyButton.classList.add('fc-button-active');
        }
    },
    inActivityTimer: function(component) {
        let time;
        window.onload = resetTimer;
        document.onmousemove = resetTimer;
        document.onkeyup = resetTimer;

        function willReload() {
            if (!component.get('v.willReload')) component.set('v.willReload', true);
        }

        function resetTimer() {
            clearTimeout(time);
            time = setTimeout(willReload, 900000)
        }
    },
    prevNextDate: function(component, calendar, isNext, numberOfDays) {
        let calendarDate = moment(calendar.getDate());

        if (isNext) {
            component.set('v.goToNextPrevDate', calendarDate.add(numberOfDays, 'days').format());
        } else {
            component.set('v.goToNextPrevDate', calendarDate.subtract(numberOfDays, 'days').format());
        }

        component.set('v.isNetxPrev', true);
        this.fetchContactWithDate(component, component.get('v.goToNextPrevDate'));
        calendar.goToDate(calendar.getDate());
    },
    setTodayButton: function(component, date, todayButton) {
        if (moment().isSame(date, 'day') && this.isTodayInBetween(component)) {
            todayButton.setAttribute('disabled', 'true');
        } else {
            todayButton.removeAttribute('disabled');
        }
    },
    isTodayInBetween: function(component) {
        const calendar = component.get('v.calendar');
        let start = calendar.state.dateProfile.activeRange.start;
        let end = calendar.state.dateProfile.activeRange.end;

        return moment().isBetween(start, end);
    }
})