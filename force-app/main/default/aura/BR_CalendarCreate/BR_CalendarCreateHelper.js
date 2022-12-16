({
    loadDefaultWorker : function (component) {
        return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.getWorker");
            action.setParams({
                workerId : component.get("v.workerId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var res = response.getReturnValue();
                    resolve(res);
                } else {
                    var errors = response.getError();
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },

    // Returns the element with no match in both array
    getDifference: function (array1, array2) {
        return array1.filter(object1 => {
            return !array2.some(object2 => {
            return object1.id === object2.id;
            });
        });
    },

    setDefaultWorker : function (component) {
        var workerProfile = component.get('v.loggedInUser');
        const worker = {
        	"Id" : component.get('v.isParentMCC') ? workerProfile.Id : workerProfile['id'],
            "Name" : component.get('v.isParentMCC') ? workerProfile.Name : workerProfile['Name']
        };
        component.set('v.workers', [worker]);
    },

    setDefaultSite : function (component) {
        var worker = component.get('v.loggedInUser');

        var site = {
            "Id" : worker['enrtcr__Site__c'],
            "Name" : worker['enrtcr__Site__r.Name'],
            "enrtcr__Business_Address_1__c" :  worker['enrtcr__Site__r.enrtcr__Business_Address_1__c']
        };

        component.set("v.site", site);

        var siteActions = component.find('siteLookup');
        siteActions.default();
    },

    setRepeatDefaults : function (component) {
    	const defaultVal = this.getDate(0);
        component.set('v.newEvent.onDate', defaultVal);
        component.get('v.newEvent.numEvents', 1);
        component.get('v.newEvent.repeatFreq', 1);
        component.set('v.newEvent.repeatTime', 'Day');
        component.set('v.maxDateRepeat', this.getDate(90));
    },

    getDate : function (variance) {
    	var today = new Date();
        today.setDate(today.getDate() + variance);
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();
        return yyyy + '-' + mm + '-' + dd;

        console.log('getDate produces: ' + yyyy + '-' + mm + '-' + dd);
    },

    resetForm : function (component) {
        console.log('Inside reset form');
        component.set('v.newEvent.Name', '');
        component.set('v.newEvent.startTime', '');
        component.set('v.newEvent.endTime', '');
        component.set('v.newEvent.serviceType', 'Therapy Session');
        component.set('v.newEvent.modeofdelivery', 'Face to Face');
        component.set('v.eventLocation', 'Home');
        component.set('v.repeat', false);
        component.set('v.repeatBtn', 'After');
        component.set('v.newEvent.numEvents', '');
        component.set('v.newEvent.repeatFreq', '');
        component.set('v.newEvent.Cancellation_Reason__c', '');
        component.set('v.newEvent.Cancellation_Extended', '');
        component.set('v.clients', []);
        component.set('v.allDay', false);
        component.set('v.reengagement', false);
        component.set('v.newEvent.Comments__c', '');
        component.set('v.meetingLink', '');
        component.set('v.listOfDays', []);
        component.set('v.comments', '');
        component.set('v.newEvent.Address', '');
        this.setRepeatDefaults(component);

        if (!component.get('v.isParentMCC') == undefined) {
            this.setDefaultSite(component);
            this.setDefaultWorker(component);
        }

        console.log('finish reset form');
    },

    createJSON : function(component, status){
        var self = this;
        var action = component.get("c.createEvents");

        let repeatDetails = {
            repeat : component.get('v.repeat'),
            repeatFrequency : component.get('v.newEvent.repeatFreq'),
            repeatTime : component.get('v.newEvent.repeatTime'),
            onAfter : component.get('v.repeatBtn'),
            numberEvents : component.get('v.newEvent.numEvents'),
            onDate : component.get('v.newEvent.onDate'),
            repeatDays : component.get('v.listOfDays')
        },
        eventDetails = {
            subject : component.get("v.newEvent.Name"),
            startTime : component.get("v.newEvent.startTime"),
            endTime : component.get("v.newEvent.endTime"),
            eventType : component.get("v.newEvent.serviceType"),
            clients : JSON.stringify(component.get("v.clients")),
            workers : JSON.stringify(component.get("v.workers")),
            serviceId : 'filler',
            address : component.get("v.newEvent.Address"),
            status : status,
            allDay : component.get("v.allDay"),
            reengagement : component.get("v.reengagement"),
            comments : component.get("v.comments"),
            link : component.get("v.meetingLink"),
            eventLocation : component.get("v.eventLocation"),
            mode : component.get("v.newEvent.modeofdelivery"),
            site : JSON.stringify(component.get("v.site"))

        };

        component.set('v.eventDetailsJSON', eventDetails);
        component.set('v.repeatDetailsJSON', repeatDetails);
        const inputError = self.validateInsertion(component, repeatDetails, eventDetails);

        return inputError;
    },

    validateInsertion : function (component, repeatDetails, eventDetails) {
        if (repeatDetails.repeat) {
            if (!repeatDetails.repeatFrequency || repeatDetails.repeatFrequency === '') {
                return 'Invalid "Repeat Every" field.'
            }

            if (repeatDetails.onAfter === 'After') {
                if (!repeatDetails.numberEvents) {
                    return 'Invalid number of events.'
                }

                if (repeatDetails.numberEvents > 200 || repeatDetails.numberEvents === '') {
                    return 'Number of events must be between 1 and 200.'
                }
            } else if (repeatDetails.onAfter === 'On') {
                if (!repeatDetails.onDate) {
                    return 'Invalid repeat date provided.'
                }

                if (repeatDetails.onDate > component.get('v.maxDateRepeat')) {
                    return 'Recurrence end date must be before ' + moment(component.get('v.maxDateRepeat')).format('DD/MM/YYYY');
                }
            } else {
                return 'Invalid repeat button group selection.'
            }
        }

        if (eventDetails.subject === '' || !eventDetails.subject) {
			return 'Invalid event subject.'
        }

        if (eventDetails.subject.length > 250) {
            return 'Event subject must be between 1 and 250 characters.'
        }

        if (!eventDetails.allDay) {
            if (!eventDetails.startTime || !eventDetails.endTime) {
                return 'No start time or end time provided.'
            }
        }

        const eventTypes = ['Initial Appointment', 'Therapy Session', 'Other PCH', 'Internal', 'Out of Office'];
        if (!eventTypes.includes(eventDetails.eventType)) {
            return 'Invalid event type provided.'
        }

        const workers = JSON.parse(eventDetails.workers);
        if (workers.length === 0) {
            return 'Event requires at least one worker.'
        }

        return 'VALID';
    },

    setLoading : function (component, state) {
        console.log('Inside setLoading');
        component.set('v.isLoading', state);
    },

    showMyToast : function(mode, type, title, message) {
        console.log('inside showmytoast');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: mode,
            title: title,
            message: message,
            type : type
        });
        toastEvent.fire();
	},

     formEventObject : function (event, component) {
        let obj = {
            'id':event.Id,
            'start':event.StartDateTime,
            'end':event.EndDateTime,
            'allDay': event.IsAllDayEvent,
            'status' : event.Event_Status__c,
            'recurrence' : event.isRecurrence__c,
            'recurrenceId' : event.Event_Recurrence__c,
            'ownerid' : event.OwnerId,
            'eventType' : event.Event_Type__c,
            'comments' : event.Comments__c,
            'link' : event.Meeting_Link__c,
            'eventLocation' : event.Session_Location__c,
            'mode' : event.Mode_of_Delivery__c,
            'site' : event.enrtcr__Site_Visit__c
        }

        var event_type_class = event.Event_Type__c.replace(/\s/g, '').toLowerCase();
        var event_status_class = event.Event_Status__c.replace(/\s/g, '').toLowerCase();
        var event_class = '';
        var event_class = event_class.concat('fc-br-', event_type_class, ' ', 'fc-br-', event_status_class);


        obj['classNames'] = event_class;

		var prefix = '';
        if (event.Is_Re_engagement__c) {
            prefix.concat('[R] ')
        }


        var status = (event.Event_Type__c == 'Initial Appointment' || event.Event_Type__c =='Therapy Session') && (event.Event_Status__c == 'Cancelled' || event.Event_Status__c == 'Pending') ? " | " + event.Event_Status__c : "";

        obj['title'] = prefix.concat(event.Subject);

        return obj;
    },

    insertEvent : function (component, status) {
        console.log('Inside insert event');
        console.log(component.get('v.eventStatus'));

        var self = this;
        return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.createEvents");

            action.setParams({
                eventJSON : JSON.stringify(component.get('v.eventDetailsJSON')),
                repeatJSON : JSON.stringify(component.get('v.repeatDetailsJSON')),
                contactPageUser : component.get('v.loggedInUser').enrtcr__User__c
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('Insert event state = ' + state);
                if (state === 'SUCCESS') {
                    var res = response.getReturnValue();

                    //var formattedEvents = [];

                    //for each event in result, make a map of event - "created"

                    let newEventsMap = new Map();

                    for (const ev of res) {
                        if (!ev.Id) reject("Error creating event.");
                        var event = self.formEventObject(ev, component);
                        newEventsMap.set(event, 'CREATED');
                        //formattedEvents.push(event);
                    }

                    console.log('newEventsMap', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    //var events = component.get('v.events');
                    //const newEvents = events.concat(formattedEvents);

                    //component.set('v.events', newEvents);
                    resolve(res);

                } else {
                    var errors = response.getErrors();
                    console.log(errors)
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },

    clashHandler : function(component) {
        console.log('Inside clashHandler helper');

        var self = this;
        //const parent = component.get('v.parent');

        return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.findClashingWorkerAndClientEvents");

            console.log('v.eventDetailsJSON in clashHandler: ');
            console.log(component.get("v.eventDetailsJSON"))

            action.setParams({
                eventJSON : JSON.stringify(component.get('v.eventDetailsJSON')),
                repeatJSON : JSON.stringify(component.get("v.repeatDetailsJSON"))
            });

            action.setCallback(this, function(response) {
                console.log('Inside setCallback for clashHandler helper');

                var state = response.getState();
                console.log('clashHandler helper status = ' + state);
                console.log('clashHandler helper result = ' + response);

                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('Result of setCallback clashHandler helper: ' + result);
                    console.log('Result of setCallback clashHandler helper: ' + result.length);

                    resolve(result);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    reject(errors);
                }
            });

            $A.enqueueAction(action);
        }))
    },

    insert : function(component, helper) {
        this.setLoading(component, true);
        this.insertEvent(component, component.get('v.eventStatus'), helper).then((res) => {
            this.resetForm(component);
            this.passEventCalendarObject(component);
            this.setLoading(component, false);
            this.showMyToast('dismissible', 'success', 'Success', "Event/s have been created.");
        }).catch(err => {
            console.log(err);
            this.setLoading(component, false);
            this.showMyToast('dismissible', 'error', 'An error occurred', err);
        })
        //set it back to false cause now u have finished
        component.set('v.checkClash', false);
    },

	passEventCalendarObject : function(component, eventMap) {
        //to reload calendar in child, you need to pass in the v.events to parent because v.events in child is updated but not in parent
        console.log('Inside passEventCalendarObject', eventMap);
        var compEvent = component.getEvent("createComponentEvent");
        //compEvent.setParams({"events" : component.get('v.events') });
        compEvent.setParams({"eventMapFromChild" : eventMap });
        compEvent.fire();
    },

})