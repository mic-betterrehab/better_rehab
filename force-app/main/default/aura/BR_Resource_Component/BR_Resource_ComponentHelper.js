({
    /*
     *	loads the logged in users information. Right now all we need is the permission level
     */
	loadUser: function(component) {
    	var action = component.get("c.a_loadUser");

     	action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                const result = response.getReturnValue();
				component.set("v.user", result);
            }
        });
        $A.enqueueAction(action);
    },
    /*
     *	Calls Apex controller to load the resources of a specific site. Gets the site from
     *	the component passed through as a parameter.
     */
	loadResources: function(component) {
    	var action = component.get("c.getResources");

        action.setParams({
            siteId : component.get("v.recordId")
        });

     	action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                const resources = result.resources;
                const slots = result.slots;

                let resourceArr = [];
                let slotsArr = [];

                var self = this;

                resources.forEach(function(key) {
                    resourceArr.push(key);
                });

                slots.forEach(function(key) {
                    slotsArr.push(key);
                });

                component.set("v.totalResources", resourceArr);
                component.set("v.filteredResources", resourceArr);
                component.set("v.totalEvents", slotsArr);

                //this.filterEvents(component);
                this.loadCalendar(component);

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

    // converts a Slot__c sobject to a fullCalender Event Object
    convertToFCSlot : function (slot) {
        return {
            id : slot.Id,
            title : slot.Owner.Name + ' (' + slot.Destination_Site__r.Name + ')',
            start : slot.Start_Time__c,
            end : slot.End_Time__c,
            resourceId : slot.Resource__c,
            ownerId : slot.OwnerId
        }
    },

    convertToSlot__c : function (FCslot) {
        return {
            Id : FCslot.id,
            Start_Time__c : FCslot.start.toGMTString(),
            End_Time__c : FCslot.end.toGMTString(),
            OwnerId : FCslot.extendedProps.ownerId,
            Resource__c : FCslot['_def']['resourceIds'].length > 0 ? FCslot['_def']['resourceIds'][0] : undefined
        }
    },

    // shows a toast pop up
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

    // opens the create modal
    openCreateModal : function (component) {
        component.set('v.createFormVisible', true);
    },

    // opens the edit modal
    openEditModal : function (component) {
        component.set('v.editFormVisible', true);
    },

    // closes the create modal and cleans up sub component
    closeCreateModal : function (component) {
        component.set('v.createFormVisible', false);
        this.resetCreateForm(component);
    },

    // closes the edit modal and cleans up sub component
    closeEditModal : function (component) {
        component.set('v.editFormVisible', false);
        this.resetEditForm(component);
    },

    // resets the creation form
    resetCreateForm : function (component) {
    	// fire off event here and handle in the create sub component to reset all attributes to defaults
    },

    // resets the creation form
    resetEditForm : function (component) {
    	// fire off event here and handle in the edit sub component to reset all attributes to defaults
    },

    updateSlot : function (component, slotObject) {
    	const allSlots = component.get('v.totalEvents');

        const slotIndex = allSlots.findIndex(s => s.id == slotObject.Id);
        const slot = allSlots[slotIndex];

        slot.start = slotObject.Start_Time__c;
        slot.end = slotObject.End_Time__c;
        if (slotObject.Destination_Site__r) {
        	slot.siteId = slotObject.Destination_Site__c;
        	slot.siteName = slotObject.Destination_Site__r.Name;
            slot.title = slotObject.Owner.Name + ' (' + slotObject.Destination_Site__r.Name + ')';
        }
        allSlots[slotIndex] = slot;

        component.set('v.totalEvents', allSlots);
    },

    // adds a slot to the slot list after successful creation
    addSlot : function(component, slot) {
        const slots = component.get('v.totalEvents');
        slots.push(slot);
        component.set('v.totalEvents', slots);
    },

    // delete a slot from the slots list after delete button is clicked
    deleteSlot : function(component, slotId) {
    	const slots = component.get('v.totalEvents');
        const newSlots = slots.filter(s => s.id !== slotId);
        component.set('v.totalEvents', newSlots);
    },

    // handle selecting a slot on the resource view
    handleSelectEvent : function(component, slot) {
        component.set('v.slotSelected', slot.id);
        this.openEditModal(component);
	},

    reloadCalendar : function(component) {
        const calendar = component.get('v.calendar');
        calendar.refetchEvents();
    },

    loadCalendar : function(component) {
       	var m = moment();
        var self = this;
        var calendar = new FullCalendar.Calendar(component.find("calendar").getElement(), {
            header: {
                left: 'prev,next today newSlot',
                center: 'title',
                right: 'resourceTimelineWeek,resourceTimelineMonth'
            },
            customButtons: {
                newSlot: {
                    text: 'New Slot',
                  	click: function() {
                        component.set('v.createFormVisible', true);
                  	}
                }
            },
            defaultView: 'resourceTimelineMonth',
            weekends : true,
            firstDay: 1,
            editable : true,
            droppable : true,
            selectable : true,
            height : 900,
            eventResizableFromStart : true,
            eventDurationEditable : true,
            defaultDate: m.format(),
            navLinks: true, // can click day/week names to navigate views
            weekNumbersWithinDays: true,
            nowIndicator: true,
            eventLimit: true,
            eventClick : function (e) {
                self.handleSelectEvent(component, e.event);
            },
            events: function(info, successCallback, failureCallback) {
                successCallback(component.get('v.totalEvents'));
            },
            resourceGroupField: 'stateName',
            resources : component.get("v.filteredResources"),
            /*resourceColumns : [
                {labelText : 'Resource Type', field: 'type', group : true} , {labelText : 'Tier', field: 'tier'}
            ],*/
            plugins:['resourceTimeline', 'timeline']
        });
        calendar.render();
        component.set('v.calendar', calendar);
    },
})