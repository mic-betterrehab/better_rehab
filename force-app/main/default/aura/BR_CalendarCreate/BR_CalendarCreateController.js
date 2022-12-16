({
    /*
     * function to be called after initialisation
   	 */
	scriptsLoaded : function(component, event, helper) {
        console.log('Create form loaded succesfully');

        helper.setRepeatDefaults(component);
        helper.setDefaultWorker(component);

        helper.setLoading(component, false);
        if (component.get('v.isParentMCC')) {
            component.set('v.newEvent.serviceType', 'Internal');
            component.set("v.isPreselected", false);
        } else {
            helper.setDefaultSite(component);
        }
    },

    /*
     * functions to handle field changes in the event creation form
              */
    handleRepeat : function (component, event, helper) {
		component.set("v.repeat", event.getSource().get('v.checked'));
    },

   	handleRepeatTimeChange : function (component, event, helper) {
        console.log('what is v.newEvent.repeatTime: ' + component.get('v.newEvent.repeatTime'));
        //component.set('v.listOfDays', []); //reset the list of days every time the repeat time changes

        //for day limit to 180 days
        if(component.get('v.newEvent.repeatTime') === 'Day') {
            component.set('v.maxDateRepeat', helper.getDate(180));

        } else if(component.get('v.newEvent.repeatTime') === 'Week' || component.get('v.newEvent.repeatTime') === 'Month'){
            //for week and month, limit to 1 year (12 mths)
            component.set('v.maxDateRepeat', helper.getDate(365));
        }
    },

    handleDays : function (component, event, helper) {
        console.log('Inside handleDays');

        console.log(event.target.id, event.target.value, event.target.checked);

        if (event.target.checked) {
            component.get('v.listOfDays').push(event.target.value);
        } else {
            //find the value and remove it from the list
            if(component.get('v.listOfDays').includes(event.target.value)){
                let index = component.get('v.listOfDays').indexOf(event.target.value);
                if(index > -1){
                    component.get('v.listOfDays').splice(index, 1);
                }
            }
        }

        console.log('daysSelected: ' + component.get('v.listOfDays'));
    },

    handleAllDay : function (component, event, helper) {
		component.set("v.allDay", event.getSource().get('v.checked'));
        if (event.getSource().get('v.checked') === true) {
            let time = {'hour': 0, 'minute': 0, 'seconds': 0, 'millisecond': 0};
            let allDay = moment(component.get('v.newEvent.startTime')).set(time).format();

            component.set('v.newEvent.serviceType', 'Out of Office');
            component.set('v.newEvent.startTime', allDay);
            component.set('v.newEvent.endTime', allDay);
        } else {
            component.set('v.newEvent.serviceType', 'Initial Appointment');
            component.set('v.newEvent.startTime', '');
            component.set('v.newEvent.endTime', '');
        }
    },

    handleReEngagement : function (component, event, helper) {
		component.set("v.reengagement", event.getSource().get('v.checked'));
    },

    handleClientChange : function (component, event, helper) {
        if (component.get('v.eventLocation') == 'Home') {
            const clients = JSON.parse(JSON.stringify(component.get('v.clients')));
            if (clients.length > 0) {
                component.set('v.newEvent.Address', clients[0].enrtcr__Other_Address__c);
            } else {
                component.set('v.newEvent.Address', '');
            }
        }
    },

    handleSiteChange : function (component, event, helper) {
        if (component.get('v.eventLocation') == 'Site') {
            const site = JSON.parse(JSON.stringify(component.get('v.site')));
            component.set("v.newEvent.Address", site.enrtcr__Business_Address_1__c);
        }
    },

    handleLocChange : function (component, event, helper) {
        if (component.get('v.eventLocation') == 'Site') {
            var a = component.get('c.handleSiteChange');
            $A.enqueueAction(a);
        } else if (component.get('v.eventLocation') == 'Home') {
            // run client address logic
            var a = component.get('c.handleClientChange');
            $A.enqueueAction(a);
        } else {
            // clear address
            component.set("v.newEvent.Address", '');
        }
    },

    /*
     * functions for buttons on the creation form
              */

    clickReset : function (component, event, helper) {
    	helper.resetForm(component);
    },

    closeModal : function (component, event, helper) {
        component.set('v.calendarClashModalVisible', false);
        helper.resetForm(component);
    },

    clickCreate : function (component, event, helper) {
		console.log('Inside click create');
        let params = event.getParam('arguments');

        //set the default event status to the button's value - Pending or Booked
        // If from MCC
        if (component.get('v.isParentMCC')) {
            component.set('v.eventStatus', params.eventStatus);
        } else {
            //set the default event status to the button's value
            component.set('v.eventStatus',  event.getSource().get("v.value"));
        }


        // step 1: run self validation here
        const resultOfCreateJSON = helper.createJSON(component, component.get('v.eventStatus'));

        helper.setLoading(component, true);

        //step 2: check whether the form is valid or not
        if (resultOfCreateJSON !== 'VALID') {
            console.log('form is NOT valid');
            helper.setLoading(component, false);
            helper.showMyToast('dismissible', 'error', 'Invalid Form!', resultOfCreateJSON);
        } else  {
            //step 3: check for clash
            helper.clashHandler(component).then((result) => {
                //if clash is found, display the modal (aura:if activated)
                if(result.length !== 0){
                    console.log('result.length is NOT 0');

                    //setting the result
                    helper.setLoading(component, false);
                    component.set("v.clashingWorkerClientNames", result);
                    component.set('v.calendarClashModalVisible', true);
                } else {
                    //if no clash is found, directly create the event
                    console.log('result.length is 0');
                    helper.setLoading(component, true);
                    helper.insertEvent(component, component.get('v.eventStatus')).then((res) => { //eventStatus should be set here?
                        helper.resetForm(component);
                        helper.setLoading(component, false);
                        helper.showMyToast('dismissible', 'success', 'Success', "Event/s have been created.");
                    }).catch(err => {
                        console.log(err);
                        helper.setLoading(component, false);
                        helper.showMyToast('dismissible', 'error', 'An error occurred', err);
                    })
                }

            }).catch(err => {
                console.log(err);
                helper.showMyToast('dismissible', 'error', 'An error occurred when trying to find clashing events. Please refresh the page and try again.', err);
            })
         }
    },

    /*
     * other supporting functions
     */
    //will be run when you click "Proceed" on clash modal
    createEvent : function (component, event, helper) {
        helper.setLoading(component, true);
        helper.insertEvent(component, component.get('v.eventStatus')).then((res) => {
            helper.resetForm(component);
            //helper.passEventCalendarObject(component);
            helper.setLoading(component, false);

            helper.showMyToast('dismissible', 'success', 'Success', "Event/s have been created.");
        }).catch(err => {
            console.log(err);
            helper.setLoading(component, false);
            helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        })

       	//set it back to false cause now u have finished
        component.set('v.calendarClashModalVisible', false);
    },

    assignStartEndTime : function(component, event, helper) {
        let dates = event.getParam('arguments');
        if (dates) {
            let start = dates.startDate;
            let end = dates.endDate;

            component.set('v.newEvent.startTime', start);
            component.set('v.newEvent.endTime', end);
        }
    },

    /**
     * MCC functions
    */
    handleSelectedContacts: function(component, event, helper) {
        let params = event.getParam('arguments');
        let contacts = params.searchedContacts;
        let id = params.id;
        let isWorker = params.isWorker;
        // // Add clinician to list
        if (contacts.length > 0) {
            contacts.forEach(object => {
                delete object['enrtcr__Other_Address__c'];
            });
            // Check if pre selected and will add a worker to searchedclinicians
            if (isWorker) {
                if (component.get('v.isPreselected')) {
                    let preselectedWorkers = component.get('v.preSelectedWorkers');
                    const difference = [
                        ...helper.getDifference(preselectedWorkers, contacts),
                        ...helper.getDifference(contacts, preselectedWorkers)
                    ];
                    component.set('v.searchclinicianIds', difference);
                } else {
                    component.set('v.searchclinicianIds', contacts);
                }
            }
        }
        // Remove contact from list
        if (id != '') {
            if (isWorker) {
                let searchedClinicians = component.get('v.searchclinicianIds');
                // Check if removed worker id exist in searched workers and assign new searched workers
                let newSearchedWorkers = searchedClinicians.filter(value => value.Id !== id);
                component.set('v.searchclinicianIds', newSearchedWorkers);
                // Check if pre selected and will remove a worker
                if (component.get('v.isPreselected')) {
                    let preselectedWorkers = component.get('v.preSelectedWorkers');
                    let newPreseleced = preselectedWorkers.filter(value => value.Id !== id);
                    component.set('v.preSelectedWorkers', newPreseleced);
                }
            }
        }
    },

    onPreselect: function(component, event, helper) {
        let workers = component.get('v.workers');
        component.set('v.isPreselected', event.getSource().get('v.checked'));
        let searchclinicianIds = component.get('v.searchclinicianIds');
        let preselectedWorkers = component.get('v.preSelectedWorkers');
        let filteredSearched;
        if (event.getSource().get('v.checked')) {
            console.log(preselectedWorkers)
            if (searchclinicianIds.length > 0) {
                for (let preWorker of preselectedWorkers) {
                    // Check if searched Workers exist in pre-selected workers
                    filteredSearched = searchclinicianIds.filter(value => value.Id !== preWorker.Id);
                }
                // Merge pre-selected workers with searched workers and assign to workers
                component.set('v.workers', [...preselectedWorkers, ...filteredSearched]);
            } else {
                let removeDuplicates = preselectedWorkers.filter((value, index, self) =>
                                            index === self.findIndex(t => ( t.id === value.id ))
                                        )
                // Assign workers to workers
                component.set('v.workers', removeDuplicates);
            }
            console.log(component.get('v.workers'))
        } else {
            if (searchclinicianIds.length > 0) {
                // Assign searched workers to workers
                component.set('v.workers', searchclinicianIds);
            } else {
                // Assign workers to default
                component.set('v.workers', []);
            }
        }
    },
    fillEndDateTime: function(component, event, helper) {
        let startfield = component.find("startdatetime");
        let startdate = startfield.get("v.value").split("T")[0];
        let starttime = startfield.get("v.value").split("T")[1];
        let starthour = starttime.split(":")[0];
        let endhour = parseInt(starthour) + 1;
        let endminandmilisecond = `${starttime.split(":")[1]}:${starttime.split(":")[2]}`;
        let endfield = component.find("enddatetime");

        if (endhour < 10) endhour = `0${endhour}`;

        endfield.set("v.value", `${startdate}T${endhour}:${endminandmilisecond}`);
    }
})