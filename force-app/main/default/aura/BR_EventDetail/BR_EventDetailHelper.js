({
	getEventDetails : function(component, recordId) {
		return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.getEventMap");
            console.log('1');
            action.setParams({
                recordId : recordId
            });
            console.log('2')
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('get event created date: ' + result);
                    console.log(result);

                    return resolve(result);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    return reject(errors);
                }
            });

            $A.enqueueAction(action);
        }))
	},

    checkBrowser: function(component) {
        var device = $A.get("$Browser.formFactor");
        console.log("You are using a " + device); //device will either be PHONE or DESKTOP
        component.set("v.deviceType", device);
    },

    getRelationship : function (component) {
        console.log('in getRelo');
        return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.getEventRelationship");

            action.setParams({
                eventId : component.get('v.recordId')
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state of getRelo: ' + state);

                if (state === 'SUCCESS') {
                    const res = response.getReturnValue();

                    resolve(res);
                } else {
                    var errors = response.getErrors();
                    reject(errors);
                }
            })
            $A.enqueueAction(action);
        }))
    },

    validateInsertion : function (eventDetails) {

        if (eventDetails.subject === '' || !eventDetails.subject) {
			return 'Invalid event subject.'
        }

        if (eventDetails.subject.length > 250) {
            return 'Event subject must be between 1 and 250 characters.'
        }
        if (eventDetails.endTime < eventDetails.startTime) {
            return 'End time must be ahead of start time.'
        }

        const eventTypes = ['Initial Appointment', 'Therapy Session', 'Other PCH', 'Internal', 'Out of Office'];
        if (!eventTypes.includes(eventDetails.eventType)) {
            return 'Invalid event type provided.'
        }

        return 'VALID';
    },

    showMyToast : function(mode, type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: mode,
            title: title,
            message: message,
            type : type
        });
        toastEvent.fire();
	},

    //this is to update from edit component
	updateEvent : function(component, buttonId) {
        console.log('Inside updateEvent');
        var self = this;
		return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.updateEventEditForm");

            const eventJSON = {
                eventId : component.get("v.eventMap.id"),
                subject : component.get("v.eventMap.subject"),
                startTime : component.get("v.eventMap.start"),
                endTime : component.get("v.eventMap.end"),
                status : component.get("v.eventMap.eventStatus"),
                owner : component.get("v.eventMap.ownerLookup").Id,
                eventType : component.get("v.eventMap.eventType"),
                address : component.get("v.eventMap.address"),
                comments : component.get("v.eventMap.comments"),
                link : component.get("v.eventMap.link"),
                mode : component.get("v.eventMap.mode")
            }

            const isValid = self.validateInsertion(eventJSON); //need to validate in case the user edit the event to be invalid

            if (isValid != 'VALID') {
                self.showMyToast('dismissible', 'error', 'Error!', isValid);
                return new Error(isValid);
            }

            action.setParams({
                updateJSON : JSON.stringify(eventJSON),
                action : buttonId
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    let newEventsMap = new Map();

                    result.forEach((res) => {
                        console.log('res', res);

                        let obj = {
                            'id': res.Id,
                            'start': res.StartDateTime,
                            'end': res.EndDateTime,
                            'status' : res.Event_Status__c,
                        	'title': res.Subject,
                            'ownerid' : res.OwnerId,
                            'eventType' : res.Event_Type__c,
                            'comments' : res.Comments__c,
                            'link' : res.Meeting_Link__c,
                        	'address' : res.Event_Address__c,
                            'classNames' : 'fc-br-' + res.Event_Type__c.replace(/\s/g, '').toLowerCase() + ' ' + 'fc-br-' + res.Event_Status__c.replace(/\s/g, '').toLowerCase()
                    	}

                        newEventsMap.set(obj, 'UPDATED');  //1 event 1 key-value pair
                    })

                    console.log('newEventsMap updateEvent', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    resolve(result);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    console.log(errors);
                    reject(errors);
                }
            })
            $A.enqueueAction(action);
        }))
	},

    handleSelection : function (component) {
        console.log('in change')
        component.set('v.isLoading', true);

        const id = component.get('v.recordId');

        // null or invalid id check
        if (!id || id === "") {
            console.log('change error')
            component.set('v.isErrorView', true);
            component.set('v.isLoadingView', false);
            return 'ERROR';
        }

        component.set('v.detailModalVisible', true);

        this.getEventDetails(component, id).then(res => {
            const tz = component.get('v.tz');
            res.tzStart = this.convertTimeZone(res.start, tz);
            res.tzEnd = this.convertTimeZone(res.end, tz);
            res.tzCreated = this.convertTimeZone(res.createdDate, tz);
            res.tzLastModified = this.convertTimeZone(res.lastModifiedDate, tz);
            console.log('here5');
            component.set('v.eventMap', res);
            component.set('v.isErrorView', false);
            component.set('v.isLoadingView', false);

            if (res.numClients > 10) component.set('v.numberOfClients', 10);
            else component.set('v.numberOfClients', res.numClients);

            if (res.numWorkers > 10) component.set('v.numberOfWorkers', 10);
            else component.set('v.numberOfWorkers', res.numWorkers);
        }).catch(err => {
            console.log(err.message);
            component.set('v.isErrorView', true);
            component.set('v.isLoadingView', false);
        })
    },

    refreshEventMap : function (component, newEventMapList) {
        console.log('Inside refreshEventMap')
   		component.set('v.isLoading', true);

        const tz = component.get('v.tz');

        const currEventMap = component.get('v.eventMap');
        console.log(currEventMap);
        const newEventMap = newEventMapList.find(e => e.Id == currEventMap.id);

        if (!newEventMap) return

        currEventMap.subject = newEventMap.Subject;
        currEventMap.address = newEventMap.Event_Address__c;
        currEventMap.eventType = newEventMap.Event_Type__c;
        currEventMap.ownerLink = newEventMap.OwnerId;
        currEventMap.ownerName = newEventMap.OwnerName;
        currEventMap.eventStatus = newEventMap.Event_Status__c;
        currEventMap.start = newEventMap.StartDateTime;
        currEventMap.tzStart = this.convertTimeZone(newEventMap.StartDateTime, tz);
        currEventMap.end = newEventMap.EndDateTime;
        currEventMap.tzEnd = this.convertTimeZone(newEventMap.EndDateTime, tz);
        currEventMap.createdDate = newEventMap.CreatedDate;
        currEventMap.tzCreate = this.convertTimeZone(newEventMap.CreatedDate, tz);
        currEventMap.lastModifiedDate = newEventMap.LastModifiedDate;
        currEventMap.tzLastModified = this.convertTimeZone(newEventMap.LastModifiedDate, tz);
        currEventMap.link = newEventMap.Meeting_Link__c;
        currEventMap.mode = newEventMap.Mode_of_Delivery__c;

        component.set('v.eventMap', currEventMap);

        component.set('v.isLoading', false);

    },

    getTZofUser : function () {
    	return Intl.DateTimeFormat().resolvedOptions().timeZone;
    },

    getTZList : function (userTZ) {
    	const timezones = ['Australia/Perth', 'Australia/Melbourne', 'Australia/Sydney', 'Pacific/Auckland', 'Australia/Brisbane', 'Australia/Adelaide'];

        return timezones.filter(tz => tz !== userTZ);
    },

    convertTZ : function(date, tzString) {
 	   return new Date((typeof date === "string" ? new Date(date) : date).toLocaleString("en-US", {timeZone: tzString}));
	},

    convertTimeZone : function (date, timeZone) {
        return  moment(date).tz(timeZone).format("dddd, MMMM Do YYYY, h:mm a");
    },

    setLoading : function (component, state) {
        component.set('v.isLoading', state);
    },

    passEventCalendarObject : function(component, eventMap=null) {
        console.log('Inside passEventCalendarObject');

        var compEvent = component.getEvent("createComponentEvent");
        compEvent.setParams({"eventMapFromChild" : eventMap});
        compEvent.fire();
    },


    //this is just a change of status
    bookEvent : function (component) {
        console.log('Inside bookEvent hlper');
        var self = this;
        return new Promise($A.getCallback(function(resolve, reject){
            var action = component.get('c.bookAnEvent');

            const eventId = component.get('v.recordId');

            action.setParams({
                eventId : eventId,
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                console.log('status of bookEvent: ' + state);
                if (state == 'SUCCESS') {
                    let newEventsMap = new Map();
                    newEventsMap.set(eventId, 'BOOKED');
                    console.log('newEventsMap Booked', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    resolve(res);
                } else {
                    var errors = response.getErrors();
                    console.log(errors);
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },

    bookRecurrence : function (component) {
        console.log('inside bookRecurrence')
        var self = this;
        return new Promise($A.getCallback(function(resolve, reject){
            var action = component.get('c.bookARecurrence');

            const eventId = component.get('v.recordId');

            action.setParams({
                eventId : eventId
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                console.log(state);
                console.log(res);
                if (state == 'SUCCESS') {
                    let newEventsMap = new Map();

                    for (const event in res) {
                        const change = res[event];
                        if (change === 'BOOKED') {
                            newEventsMap.set(event, 'BOOKED');
                        }
                    }

                    console.log('newEventsMap Booked Recurring', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    resolve(res);
                } else {
                    var errors = response.getErrors();
                    console.log(errors);
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },

    deleteEvent : function (component) {
        console.log('Inside deleteEvent');
        var self = this;
        return new Promise($A.getCallback(function(resolve, reject){
            var action = component.get('c.deleteAnEvent');

            const eventId = component.get('v.recordId');
            const eventDetail = component.get('v.eventMap');
            const cancellationReason = component.get('v.cancellationReason') + ' | ' + component.get('v.cancellationExtended');
            const reasonEventTypes = ['Initial Appointment', 'Therapy Session'];

            action.setParams({
                eventId : eventId,
                reason : reasonEventTypes.includes(eventDetail.eventType) ? cancellationReason.slice(0,254) : ''
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                console.log('DELETION STATUS: ' + state);
                if (state == 'SUCCESS') {
                    let newEventsMap = new Map();

                    if (res === 'DELETED') {
                        newEventsMap.set(eventId, 'DELETED');

                    } else if (res === 'CANCELLED') {
                    	newEventsMap.set(eventId, 'CANCELLED');
                    }

                    console.log('newEventsMap CANCELLED ONE', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    resolve(res);
                } else {
                    var errors = response.getErrors();
                    console.log(errors);
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },

    deleteRecurrence : function (component) {
        var self = this;
        return new Promise($A.getCallback(function(resolve, reject){
            var action = component.get('c.deleteARecurrence');

            const eventId = component.get('v.recordId');
            const eventDetail = component.get('v.eventMap');
            const cancellationReason = component.get('v.cancellationReason') + ' | ' + component.get('v.cancellationExtended');
            const reasonEventTypes = ['Initial Appointment', 'Therapy Session']
            action.setParams({
                eventId : eventId,
                reason : reasonEventTypes.includes(eventDetail.eventType) ? cancellationReason.slice(0,254) : ''
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                if (state == 'SUCCESS') {
                    let newEventsMap = new Map();
                    console.log('result from delete recur', res);

                    for (const event in res) {
                        const change = res[event];

                        if (change === 'DELETED') {
                            newEventsMap.set(event, 'DELETED');

                        } else if (change === 'CANCELLED') {
                            newEventsMap.set(event, 'CANCELLED');
                        }
                    }
                    console.log('newEventsMap CANCELLED/DELETE RECUR', newEventsMap);
                    self.passEventCalendarObject(component, newEventsMap);

                    resolve(res);
                } else {
                    var errors = response.getErrors();
                    console.log(errors);
                    reject(errors);
                }
            });
            $A.enqueueAction(action);
        }))
    },
})