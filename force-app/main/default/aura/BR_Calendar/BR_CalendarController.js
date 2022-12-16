({
	scriptsLoaded : function(component, event, helper) {
        console.log('Script loaded succesfully');
        helper.setLoading(component, true);
        helper.getResponse(component);
        helper.loadWorker(component).then((res) => {
            component.set('v.loggedInUser', res);
            component.set('v.selectedRecordTypeName', res.Record_Type_Name__c);

            //get the calendar type
            helper.checkCalendarType(component);
            console.log('calendar type: ' + component.get('v.calendarType'));
            helper.setLoading(component, false);

        }).catch((err) => {
            console.log('1')
            console.log(err)
            helper.setLoading(component, false);
        });
    },

    //used to filter events
    filterEvents : function (component, event, helper) {
        helper.filterEvents(component);
        component.set('v.filterModalVisible', false);
        helper.reloadCalendar(component);
    },

    //to close all the modals in br_calendar
    closeModal : function (component, event, helper) {
        component.set('v.eventChangeConfirmation', false);
        helper.reloadCalendar(component);
    },

    //for time change, recurring event modal
    saveDropResizeEvent : function (component, event, helper) {

        component.set('v.eventChangeConfirmation', false);

        console.log('Inside saveDropResizeEvent');

        const buttonId = event.getSource().get("v.value"); //will either get saveOne or saveAll depending on the user clicks
        helper.handleTimeChangeDropResize(component, buttonId);
    },

    //this method is to receive the updated version of an event or new events that were created from any of the child events
    //all child components of BR_Calendar have the corresponding passEventCalendarObject to pass the events from child to BR_Calendar, which will then be processed here
    receiveEventCalendarObject : function (component, event, helper) {
        console.log('Inside receiveEventCalendarObject');

        const eventMapFromChild = event.getParam("eventMapFromChild");
        console.log('eventMapFromChild', eventMapFromChild);

        //iterate over the map
        let allEvents = component.get('v.events');

        eventMapFromChild.forEach((type, event) => {
            if(type === 'CREATED'){
            	allEvents.push(event);

        	} else if(type === 'UPDATED'){

                const eventIndex = allEvents.findIndex(e => e.id === event.id);
                let eventObj = allEvents[eventIndex];
            	console.log('eventObj', eventObj);

            	eventObj.end = event.end;
                eventObj.status = event.status;
                eventObj.eventType = event.eventType;
                eventObj.ownerid = event.ownerid;
                eventObj.start = event.start;
                eventObj.title = event.title;
                eventObj.comments = event.comments;
                eventObj.address = event.address;
                eventObj.link = event.link;
                eventObj.classNames = event.classNames;

            	allEvents[eventIndex] = eventObj;

            } else if(type === 'BOOKED'){

                const eventIndex = allEvents.findIndex(e => e.id === event);
                let eventObj = allEvents[eventIndex];
            	console.log('eventObj', eventObj);

                eventObj.status = 'Booked';
                eventObj.classNames = eventObj.classNames.replace('fc-br-cancelled', ' ').replace('fc-br-pending', ' ');

            	allEvents[eventIndex] = eventObj;

            } else if(type === 'CANCELLED'){

                const eventIndex = allEvents.findIndex(e => e.id === event);
                let eventObj = allEvents[eventIndex];
            	console.log('eventObj', eventObj);

            	eventObj.status = 'Cancelled';
                eventObj.classNames += ' fc-br-cancelled';

            	allEvents[eventIndex] = eventObj;

            } else if(type === 'DELETED'){
            	console.log('deleted');
                //find the event in the events
                allEvents = allEvents.filter(e => e.id != event);
            }

        })

        component.set('v.events', allEvents);

        //make view event empty so create form will appear after every update to list events
        component.set('v.viewEvent', '');

        //call filter events to reset the events to show by default
        helper.filterEvents(component);

        //call reload calendar to load the filtered events
        helper.reloadCalendar(component);
    },


    print : function (component, event, helper) {
        var ele = component.get("v.site");
        console.log(JSON.parse(JSON.stringify(ele)));
        var ele1 = component.get("v.repeat");
        console.log(ele1)

        var ele2 = component.get("v.clients");
        console.log(ele2);

        const calendar = component.get('v.cal');
        console.log(calendar);
        calendar.refetchEvents();

        console.log(component.get("v.workers"));

        let colors = component.get('v.colors');

        console.log(colors.green);

        console.log(component.get('v.statusSelection'));

        console.log(component.get('v.serviceSelection'));
    }



})