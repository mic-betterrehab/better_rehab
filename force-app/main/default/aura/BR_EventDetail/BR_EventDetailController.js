({

    initRun : function (component, event, helper) {
        const tz = helper.getTZofUser();
        component.set('v.tz', tz);
        const tzs = helper.getTZList(tz);
        component.set('v.allTzs', tzs);
        helper.checkBrowser(component);
    	helper.handleSelection(component);
    },

    onChangeTZ : function (component, event, helper) {
    	const eventMap = component.get('v.eventMap');
        const tzs = helper.getTZList(component.get('v.tz'));
        component.set('v.allTzs', tzs);
        eventMap.tzStart = helper.convertTimeZone(eventMap.start, component.get('v.tz'));
        eventMap.tzEnd = helper.convertTimeZone(eventMap.end, component.get('v.tz'));
        eventMap.tzCreated = helper.convertTimeZone(eventMap.createdDate, component.get('v.tz'));
        eventMap.tzLastModified = helper.convertTimeZone(eventMap.lastModifiedDate, component.get('v.tz'));
        component.set('v.eventMap', eventMap)
        console.log('finished')
    },

	handleSelection : function(component, event, helper) {
        const id = component.get('v.recordId');

        if (id && id !== "") {
            console.log('id is = ' + id)
            helper.handleSelection(component);
        }

	},

    toggleEdit : function (component, event, helper) {
        //if it's currently in view mode, check if the user has access to edit this event
        const parent = component.get('v.parent');
        if (component.get('v.viewMode') == true) {

            helper.getRelationship(component).then(res => {
                console.log(res);
                const allowedRelos = ['owner', 'editors'];
                if (allowedRelos.includes(res)) {
                    component.set('v.viewMode', !component.get('v.viewMode')); //if the user has access, make view mode to be false and show the edit form
                	// if (!component.get('v.isParentMCC')) parent.clickEdit();
                } else {
                    helper.showMyToast('dismissible', 'error', 'Permission denied!', 'You do not have permission to edit this event.'); //if user does not have access, show the alert
                }
            }).catch(err => {
                console.log('error message: ', err);
                  helper.showMyToast('dismissible', 'error', 'An error occurred', err);
            });
        } else {
            //if it's currently not in view mode, that means the user is currently in edit mode and clicked the "Cancel" button and want to show the view mode
            component.set('v.viewMode', !component.get('v.viewMode'));
            // if (!component.get('v.isParentMCC')) parent.clickEdit();
        }
    },

    clickPopOut : function (component, event, helper) {
        let eventMap = component.get('v.eventMap');
        let url = `${window.location.origin}/lightning/r/Event/${eventMap.id}/view`;
        //let url = `${window.location.origin}/lightning/r/Event/${component.get('v.recordId')}/view`;
        window.open(url, '_blank').focus();
    },

    clickDeselect : function (component, event, helper) {
        helper.passEventCalendarObject(component, new Map());
    },

    clickBookOne : function(component, event, helper) {
        console.log('Inside click book all');
        component.set('v.isLoadingView', true);
        component.set('v.bookModalVisible', false);
        helper.bookEvent(component).then((res) => {
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'success', 'Success!', 'Event has been booked in.');

            if (component.get('v.isParentMCC')) {
                const parent = component.get('v.parent');
                helper.passEventCalendarObject(component, new Map());
            }
        }).catch(err => {
            console.log(err);
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        })
    },

    clickBookRecurrence : function(component, event, helper) {
        component.set('v.isLoadingView', true);
        component.set('v.bookModalVisible', false);
    	helper.bookRecurrence(component).then((res) => {
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'success', 'Success!', 'Event Series has been booked in. Any events in the past were unchanged.');
        }).catch(err => {
            console.log(err);
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        })
    },

    clickDeleteOne : function(component, event, helper) {
        component.set('v.isLoadingView', true);
        component.set('v.deleteModalVisible', false);
            helper.deleteEvent(component).then((res) => {
           	component.set('v.isLoadingView', false);
            component.set('v.cancellationReason', '');
            component.set('v.cancellationExtended', '');
            helper.showMyToast('dismissible', 'success', 'Success!', 'Event has been deleted/cancelled.');


            if (component.get('v.isParentMCC')) {
                const parent = component.get('v.parent');
                helper.passEventCalendarObject(component, new Map());
            }
        }).catch(err => {
            console.log(err);
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        })
    },

    clickDeleteRecurrence : function(component, event, helper) {
        component.set('v.isLoadingView', true);
        component.set('v.deleteModalVisible', false);
    	helper.deleteRecurrence(component).then((res) => {
            component.set('v.cancellationReason', '');
            component.set('v.cancellationExtended', '');
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'success', 'Success!', 'Event Series has been deleted. Any events that are apart of the series that were previously booked have been cancelled. Any events in the past are unchanged');
        }).catch(err => {
            console.log(err);
            component.set('v.isLoadingView', false);
            helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        })
    },


    showDeleteModal : function (component, event, helper) {
        console.log('Inside showDeleteModal');

        const e = component.get('v.eventMap');
        if (e.eventStatus === 'Cancelled') {
            helper.showMyToast('dismissible', 'error', 'Error!', 'Cannot delete a cancelled event.');
            return;
        }

        helper.getRelationship(component).then(res => {
            const allowedRelos = ['owner', 'editors'];
            if (allowedRelos.includes(res)) {
        		component.set('v.deleteModalVisible', true);
        	} else {
               	helper.showMyToast('dismissible', 'error', 'Permission denied!', 'You must be the event organiser or have the edit permission to delete an event.');
    		}
        }).catch(err => {
       		helper.showMyToast('dismissible', 'error', 'An error occurred', err);
            component.set('v.event', "{}");
        });
    },

    showBookModal : function (component, event, helper) {
        console.log('Inside showBookModal');

        const e = component.get('v.eventMap');
        if (e.eventStatus === 'Booked') {
            helper.showMyToast('dismissible', 'error', 'Error!', 'Event is already booked.');
            return;
        }

        helper.getRelationship(component).then(res => {
            const allowedRelos = ['owner', 'editors'];
            if (allowedRelos.includes(res)) {
        		component.set('v.bookModalVisible', true);
            } else {
            	helper.showMyToast('dismissible', 'error', 'Permission denied!', 'You must be the event organiser or have the edit permission to book an event.');
        	}
        }).catch(err => {
        	  helper.showMyToast('dismissible', 'error', 'An error occurred', err);
        });
    },

    saveEvent : function (component, event, helper) {
        console.log('inside save event');

        const ev = event.getSource();
        const buttonId = ev.getLocalId();
        const parent = component.get('v.parent');

        helper.updateEvent(component, buttonId).then((res) => {
            console.log('just finished updateEvent')
        }).catch(err => {
            console.log(err);
        });

    },

    closeModal : function(component, event, helper) {
        component.set("v.detailModalVisible", false);
        component.set("v.bookModalVisible", false);
        component.set("v.deleteModalVisible", false);
    },

    print : function (component, event, helper) {
        const ev = component.get('v.eventMap');

        console.log('here');
        console.log(component.get('v.tz'));
        console.log(component.get('v.allTzs'));
        console.log(helper.convertTimeZone(ev.start, 'Australia/Perth'));
        console.log(helper.convertTZ(ev.start, 'Asia/Jakarta').toString());
        console.log(helper.convertTZ(ev.start, 'Australia/Brisbane').toString());
        console.log(helper.convertTZ(ev.start, 'Australia/Perth').toString());

    },
    showMoreClients: function(component, event, helper) {
        let eventMap = component.get('v.eventMap');
        let numberOfClients = component.get('v.numberOfClients');

        if (numberOfClients == 10) {
            component.set('v.showTextClient', 'Show less');
            component.set('v.numberOfClients', eventMap.numClients);
        } else {
            component.set('v.showTextClient', 'Show more');
            component.set('v.numberOfClients', 10);
        }
    },
    showMoreWorkers: function(component, event, helper) {
        let eventMap = component.get('v.eventMap');
        let numberOfWorkers = component.get('v.numberOfWorkers');

        if (numberOfWorkers == 10) {
            component.set('v.showTextWorker', 'Show less');
            component.set('v.numberOfWorkers', eventMap.numWorkers);
        } else {
            component.set('v.showTextWorker', 'Show more');
            component.set('v.numberOfWorkers', 10);
        }
    }
})