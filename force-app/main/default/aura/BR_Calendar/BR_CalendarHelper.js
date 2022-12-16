({
	 getResponse: function(component) {
     	var action = component.get("c.getEvents");
        action.setParams({
            contactId : component.get("v.recordId")
        });

     	action.setCallback(this, function(response) {
            var state = response.getState();

            console.log('Initial Load status = ' + state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                //console.log(result)
                var eventArr = [];
                var self = this;

                result.forEach(function(key) {
                    eventArr.push(self.formEventObject(key, component));
                });
                console.log('finalised forming Events');
                component.set("v.events", eventArr);
                this.filterEvents(component);

                if(this.checkBrowser(component) == 'DESKTOP'){
                    this.loadCalendar(component);
                } else {
                    this.loadCalendarPhone(component);
                }

            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    checkCalendarType: function(component) {
        if(typeof component.get('v.recordId') === "undefined"){
            component.set('v.calendarType', 'My Calendar');
            component.set("v.showForm", true);
        } else {
            console.log('recordId = ' + component.get('v.recordId'));

            if (component.get('v.selectedRecordTypeName') === 'Employee') {
                component.set('v.calendarType', 'Worker Calendar');
                component.set("v.showForm", true);

            } else if (component.get('v.selectedRecordTypeName') === 'Client') {
                component.set('v.calendarType', 'Client Calendar');
                component.set("v.showForm", false);
            }
        }
    },

    checkBrowser: function(component) {
        var device = $A.get("$Browser.formFactor");
        console.log("You are using a " + device); //device will either be PHONE or DESKTOP
        component.set("v.deviceType", device);
        return device;
    },

    setKPI : function (event, component) {
        var week_number = document.getElementsByClassName("fc-week-number")[0].innerText;
        var kpi_period = Math.floor((parseInt(week_number.replace('W ',''))-3)/4  + 1);
        document.getElementsByClassName("fc-week-number")[0].innerText = kpi_period;

    },

    formEventObject : function (event, component) {
        console.log('inside formevent object: ' + event.isRecurrence__c);
        let obj = {
            'id':event.Id,
            'start':event.StartDateTime,
            'end':event.EndDateTime,
            'allDay': event.IsAllDayEvent,
            'status' : event.Event_Status__c,
            'recurrence' : event.isRecurrence__c,
            'recurrenceId' : event.Event_Recurrence__c,
            'ownerid' : event.OwnerId, //is this ownerid compatible with event update class owner?
            'eventType' : event.Event_Type__c,
            'comments' : event.Comments__c,
            'link' : event.Meeting_Link__c,
            'eventLocation' : event.Session_Location__c,
            'mode' : event.Mode_of_Delivery__c,
            'site' : event.enrtcr__Site_Visit__c,
            'address' : event.Event_Address__c,
            'createdDate' : event.CreatedDate,
            'lastModifiedDate' : event.LastModifiedDate

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

    getColor : function (component, serviceType) {
        let colors = component.get('v.colors');

        if (!serviceType) return colors.grey;

        if (serviceType == "Initial Appointment") {return colors.blue;}
        else if ( serviceType == "Therapy Session") {return colors.green;}
        else if (serviceType == "Other PCH") {return colors.purple;}
        else if (serviceType == "Internal") {return colors.orange;}
        else if (serviceType == "Out of Office") {return colors.grey;}

    },

    //to handle selecting the date/time range on the calendar
    handleSelectRange : function (component, event) {

        if(component.get('v.calendarType') == 'My Calendar' || component.get('v.calendarType') == 'Worker Calendar'){
            component.set('v.viewEvent', '');
            let objCompB = component.find('calendarCreateCmp');
            objCompB.passStartEndDateMethod(event.startStr, event.endStr);
        }
    },

    setLoading : function (component, state) {
        component.set('v.isLoading', state);
    },

    filterEvents : function (component) {
        console.log('filter events');
    	const events = component.get('v.events');
        const serviceSelection = component.get('v.serviceSelection');
        const statusSelection = component.get('v.statusSelection');
        const filtered = events.filter(e => serviceSelection.includes(e.eventType) && statusSelection.includes(e.status));
        component.set('v.filteredEvents', filtered);

    },

    //load the currently logged in user
    loadWorker : function (component) {
 		return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.getWorker");

            action.setParams({
                workerId : component.get("v.recordId")
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

	//for updating event time from drop and resize action
    updateEventTime : function (component, event, buttonId) {
        var self = this;
        console.log('Inside updateEventTime');

        const eventJSON = {
            eventId : event.id,
            startTime : event.start,
            endTime : event.end,
        }

        return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.updateEventTime");

            action.setParams({
                updateJSON : JSON.stringify(eventJSON),
                action : buttonId
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('success in updateEvent');
                    console.log(result);

                    const events = component.get('v.events');

                    result.forEach((res) => {
                        const eventIndex = events.findIndex(e => e.id === res.Id);
                        const oldEvent = events[eventIndex];
                        const newEvent = res;

                        oldEvent.start = newEvent.StartDateTime;
                        oldEvent.end = newEvent.EndDateTime;

                        // changing time of an event sets all ERs that were previously booked back to pending. Must update client-side state too.
                        if (oldEvent.status === 'Booked') {
                            oldEvent.status = 'Pending'; //event.Event_Status__c;
                            oldEvent['classNames'] = 'fc-br-' + oldEvent.eventType.replace(/\s/g, '').toLowerCase() + ' fc-br-pending';
                        }

                        console.log('oldEvent after if statement: ');
                        console.log(oldEvent);
                        events[eventIndex] = oldEvent;
                    })

                    component.set('v.events', events);
                	component.set('v.viewEvent', '');
                	self.filterEvents(component);

                    resolve(result);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    console.log(errors);
                    reject(errors);
                }
            })

            /*action.setCallback(this, function(response) {
                var state = response.getState();
                var res = response.getReturnValue();
                if (state === 'SUCCESS') {
                    console.log('updateEventTime Status: ' + state);
                    let events = component.get('v.events');
                    for (const event in res) {
                        const eventIndex = events.findIndex(e => e.id === event);
                        const oldEvent = events[eventIndex];
                        const newEvent = res[event];

                        oldEvent.start = newEvent.StartDateTime;
                        oldEvent.end = newEvent.EndDateTime;

                        // changing time of an event sets all ERs that were previously booked back to pending. Must update client-side state too.
                        if (oldEvent.status === 'Booked') {
                            oldEvent.status = 'Pending'; //event.Event_Status__c;
                            oldEvent['classNames'] = 'fc-br-' + oldEvent.eventType.replace(/\s/g, '').toLowerCase() + ' fc-br-pending';
                        }
                        console.log('oldEvent after if statement: ');
                        console.log(oldEvent);
                        events[eventIndex] = oldEvent;
                    }

                    component.set('v.events', events);
                    component.set('v.viewEvent', '');
                    self.filterEvents(component);
                    resolve(res);
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
            });*/

            $A.enqueueAction(action);
        }))
    },

    reloadCalendar : function(component) {
        console.log('reload calendar');
        const calendar = component.get('v.cal');
        calendar.refetchEvents();
    },

    handleSelectEvent : function (component, event) {
        component.set('v.viewEvent', event.id);

        if(component.get('v.calendarType') == 'Client Calendar' && component.get('v.deviceType') === 'DESKTOP') {
            window.open("https://betterrehab.lightning.force.com/lightning/r/Event/"+ component.get('v.viewEvent') + "/view", '_blank');
        }
    },

    handleTimeChangeDropResize : function(component, buttonId){
        var self = this;

        console.log('inside handleTimeChangeDropResize');
        console.log('v.event'); //so this is empty
        console.log(component.get('v.event'));

        console.log('v.changedEvent'); //this doesnt show what i want??
        console.log(component.get('v.changedEvent'));

        self.updateEventTime(component, component.get('v.changedEvent'), buttonId).then((res) => {
            if (res) {
                component.set('v.viewEvent', ''); //to reset the form to be on createMode
                self.reloadCalendar(component);
                self.showMyToast('dismissible', 'success', 'Success!', "Event(s) time changed. All changed events that were previously booked have been changed to pending. Don't forget to book them in!");
        	}

        	component.set('v.eventChangeConfirmation', false);

        }).catch(err => {
            console.log(err);
            self.showMyToast('dismissible', 'error', 'An error occurred', err);
    	})
    },

    loadCalendar : function(component) {
       	var m = moment();
        var self = this;
        var data = component.get('v.events');
        var calendar = new FullCalendar.Calendar(component.find("calendar").getElement(), {
            header: {
                left: 'prev,next today filter',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,workWeek,timeGridDay,'
            },
            customButtons: {
                filter: {
                    text: 'Filter',
                  	click: function() {
                        component.set('v.filterModalVisible', true);
                  	}
                }
            },
            columnHeaderFormat : {weekday: 'short', day : 'numeric', month : 'short'},
            views: {
                workWeek: {
                    type: 'timeGridWeek',
                    hiddenDays: [0,6],
                    buttonText: 'work week',
                    firstDay: 1

                }
            },
            weekends : true,
            firstDay: 1,
            editable : true,
            droppable : true,
            selectable : true,
            defaultView : 'workWeek',
            scrollTime: '08:00:00',
            slotDuration : '00:15:00',
            slotEventOverlap : false,
            height : 800,
            /*height: window.innerHeight*0.75,*/
            eventResizableFromStart : true,
            eventDurationEditable : true,
            defaultDate: m.format(),
            navLinks: true, // can click day/week names to navigate views
            weekNumbers: true,
            weekNumbersWithinDays: true,
            weekLabel: "KPI W",
            weekNumberCalculation: function(date) {
                // Starting date for BR v2.0
                var kpi_start_date = new Date("Mon Jul 5 2021 00:00:00 GMT+1300");

                var days_since_br2 = (date - kpi_start_date) / (1000 * 3600 * 24);
                var days_since_current_kpi = days_since_br2 % 28;
                var kpi_period = Math.floor(days_since_current_kpi/7) + 1;

                return kpi_period;
            },
            nowIndicator: true,
            eventLimit: true,
            events: function(info, successCallback, failureCallback) {
                successCallback(component.get('v.filteredEvents'));
            },
            select: function (e) {
            	self.handleSelectRange(component, e);
            },
            eventAllow: function(dropInfo, draggedEvent) {
                const user = component.get('v.loggedInUser');

                // If login user is not the owner and does not have diary editor permission, don't let them drag event
                if (draggedEvent.extendedProps.ownerid !== user.userId && user.eventRelationship != 'editors') {
                    self.showMyToast('dismissible', 'error', 'Permission Denied!', 'You do not have permission to update this event');
                    return false;
                }

                if (draggedEvent.extendedProps.status === 'Cancelled') {
                    self.showMyToast('dismissible', 'error', 'Error!', 'Cannot update a cancelled event.');
                    return false;
                }
            	return true;
            },
            eventDrop : function (e) {
                console.log('Inside event drop');

                component.set('v.changedEvent', e.event);
                component.set('v.viewEvent', e.event.id);
                component.set('v.eventChangeConfirmation', true);
            },
            eventClick : function (e) {
                self.handleSelectEvent(component, e.event);
            },
            eventResize : function (e) {
                console.log('Inside event resize');

                component.set('v.changedEvent', e.event);
                console.log(e.event);
                console.log(component.get('v.changedEvent'));
                component.set('v.viewEvent', e.event.id);
                component.set('v.eventChangeConfirmation', true);

            },
            plugins:['dayGrid', 'timeGrid', 'interaction']
        });
        calendar.render();
        component.set('v.cal', calendar);

    },

    loadCalendarPhone : function(component) {
       	var m = moment();
        var self = this;
        var data = component.get('v.events');
        var calendar = new FullCalendar.Calendar(component.find("calendar").getElement(), {
            header: {
                left: 'prev,next, workWeek, timeGridDay'
            },
            columnHeaderFormat : {weekday: 'short', day : 'numeric', month : 'short'},
            views: {
                workWeek: {
                    type: 'timeGridWeek',
                    hiddenDays: [0,6],
                    buttonText: 'work week',
                    firstDay: 1
                },
            },
            weekends : true,
            firstDay: 1,
            editable : false,
            droppable : false,
            eventStartEditable: false,
            eventDurationEditable: false,
            selectable : true,
            longPressDelay: 1,
            defaultView : 'timeGridDay',
            minTime: '08:00:00',
            maxTime: '20:00:00',
            slotDuration : '00:30:00',
            slotEventOverlap : false,
            height : 800,
            eventResizableFromStart : true,
            eventDurationEditable : true,
            defaultDate: m.format(),
            navLinks: true, // can click day/week names to navigate views
            weekNumbers: true,
            weekNumbersWithinDays: true,
            weekLabel: "KPI W",
            weekNumberCalculation: function(date) {
                // Starting date for BR v2.0
                var kpi_start_date = new Date("Mon Jul 5 2021 00:00:00 GMT+1300");

                var days_since_br2 = (date - kpi_start_date) / (1000 * 3600 * 24);
                var days_since_current_kpi = days_since_br2 % 28;
                var kpi_period = Math.floor(days_since_current_kpi/7) + 1;

                return kpi_period;
            },
            nowIndicator: true,
            eventLimit: true,
            events: function(info, successCallback, failureCallback) {
                successCallback(component.get('v.filteredEvents'));
            },
            select: function (e) {
            	self.handleSelectRange(component, e);
            },
            eventAllow: function(dropInfo, draggedEvent) {
                const user = component.get('v.loggedInUser');
                // If login user is not the owner and does not have diary editor permission, don't let them drag event
                if (draggedEvent.extendedProps.ownerid !== user.userId && user.eventRelationship != 'editors') {
                    self.showMyToast('dismissible', 'error', 'Permission Denied!', 'You do not have permission to update this event');
                    return false;
                }

                if (draggedEvent.extendedProps.status === 'Cancelled') {
                    self.showMyToast('dismissible', 'error', 'Error!', 'Cannot update a cancelled event.');
                    return false;
                }


            	return true;
            },
            eventClick : function (e) {
                self.handleSelectEvent(component, e.event);
                console.log('clicking the event');

            },
            eventResize : function (e) {
                alert('You cannot make changes in the mobile app');
                e.revert();
            },
            plugins:['dayGrid', 'timeGrid', 'interaction', 'list']
        });
        calendar.render();
        component.set('v.cal', calendar);
    },


})