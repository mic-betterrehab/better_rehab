({
    scriptsLoaded: function(component, event, helper) {
        helper.loadCliniciansAndEvents(component);
        helper.inActivityTimer(component, helper);
    },
    // closes and cleans up all modals/subcompoents on the parent
    closeModals: function(component, event, helper) {
        helper.closeCreateModal(component);
        helper.closeEditModal(component);
        component.set('v.willReload', false);
    },
    handleFilter: function(component, event, helper) {
        if (component.get('v.didClickFilter')) {
            helper.resetData(component);
        }

        helper.handleFetchWithFilters(component);
    },
    handleMultiLookup: function(component, event, helper) {
        component.set('v.clinicianId', '');
        let params = event.getParam('arguments');
        let clinicians = params.clinicians;
        let clinicianId = params.clinicianId;

        // Add clinician to filter
        if (clinicians.length > 0) {
            clinicians.forEach(object => {
                delete object['enrtcr__Other_Address__c'];
            });

            component.set('v.searchclinicianIds', clinicians);

            console.log(component.get('v.searchclinicianIds'))
        }

        // Remove clinician from filter
        if (clinicianId != '') {
            let searched = component.get('v.searchclinicianIds');
            let x = searched.filter(value => value.Id != clinicianId);
            component.set('v.searchclinicianIds', x);
        }
    },
    receiveEventCalendarObject: function(component, event, helper) {
        let calendar = component.get('v.calendar');
        helper.closeModals(component);
        component.set('v.isLoading', true);
        calendar.destroy();
        helper.loadCliniciansAndEvents(component);
    },
    willReloadHandler: function(component, event, helper) {
        let calendar = component.get('v.calendar');
        helper.closeModals(component);
        component.set('v.isLoading', true);
        calendar.destroy();
        helper.loadCliniciansAndEvents(component);

        component.set('v.willReload', false);
    },
    handleGoToDate: function(component, event, helper) {
        helper.fetchContactWithDate(component, component.get('v.goToDate'), true);
    },
    clearDate: function(component, event, helper) {
        let gotodate = component.get('v.goToDate');
        component.set('v.goToDate', '');
        const calendar = component.get('v.calendar');
        calendar.destroy();
        const m = moment(gotodate);
        const nextSeven = moment(gotodate).add(6, 'days');
        const prevSeven = moment(gotodate).subtract(6, 'days');

        console.log(m.format(), nextSeven.format(), prevSeven.format())
        // Check if selected date is between seven days from today or seven days ago
        if (!moment().isBetween(prevSeven, nextSeven)) {
            helper.fetchContactWithDate(component, moment());
        } else {
            helper.setCalendarData(component, component.get('v.filteredEvents'), component.get('v.filteredClinicians'));
            helper.loadCalendar(component);
        }
    },
    clearFilter: function(component, event, helper) {
        let site = JSON.parse(JSON.stringify(component.get('v.site')));
        let discipline = component.get('v.discipline');
        let searchclinicianIds = component.get('v.searchclinicianIds');
        let siteComponent = component.find('siteLookup');
        let multiLookup = component.find('multiWorkerLookup');

        console.log((typeof site.Name != 'undefined' || discipline != '' || searchclinicianIds > 0));
        if (typeof site.Name != 'undefined' || discipline != '' || searchclinicianIds > 0) {
            console.log('asdasdas');
            helper.reloadData(component);
        }

        component.set('v.site', {})
        component.set('v.discipline', '');
        component.set('v.searchclinicianIds', []);
        siteComponent.clear();
        multiLookup.clear();
    }
})