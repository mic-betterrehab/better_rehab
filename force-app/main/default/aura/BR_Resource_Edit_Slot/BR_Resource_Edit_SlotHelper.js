({
	loadSlot : function(component) {
		const action = component.get("c.a_getSlot");
        
        const id = component.get('v.slotId');
        
        const requestObject = {
            slotId : id
        };
        
        action.setParams(requestObject);
        action.setCallback(this, function (res) {
            const state = res.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                const value = res.getReturnValue();
                console.log(value);
                const localTimes = {
                    localStartTime : moment(value.Start_Time__c).format("dddd, MMMM Do YYYY, h:mm a"),
                    localEndTime : moment(value.End_Time__c).format("dddd, MMMM Do YYYY, h:mm a")
                };
                
                component.set('v.localTimes', localTimes);
                component.set('v.slot__c', value);
            } else {
                const errors = res.getError();
                const params = {
                    mode : 'dismissible',
                    type : 'error',
                    title : 'An error occurred!',
                    message : 'Could not load slot.'
                };
                
                // get toast event
                const showToastEvent = component.getEvent('createToast');
                
                showToastEvent.setParams({
                    toastParams : JSON.stringify(params)
                });
                
                showToastEvent.fire();
                
                this.closeModals(component);
            }
            this.setLoading(component, false);
        });
        
        $A.enqueueAction(action);
	},
    
    updateSlot : function(component) {
		const action = component.get("c.a_updateSlot");
        
        const id = component.get('v.slotId');
        const updateDetails = component.get('v.updateDetails');
        console.log(JSON.stringify(updateDetails));
        const requestObject = {
            slotId : id,
            startTime : updateDetails.startTime,
            endTime : updateDetails.endTime,
            destinationSite : updateDetails.site ? updateDetails.site.Id : 'NULL'
        };
        
        const requestObject_string = JSON.stringify(requestObject);
        console.log(requestObject_string)
        action.setParams({
            updateJSON : requestObject_string
        });
        
        action.setCallback(this, function (res) {
            const state = res.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                const value = res.getReturnValue();
                
                // fire event to main component
                const argument = JSON.stringify(value);
                console.log(argument);
                const updateSlotEvent = component.getEvent('updateSlot');
                console.log(updateSlotEvent);
                updateSlotEvent.setParams({
                	updatedSlot : argument
                });
                
                updateSlotEvent.fire();
            } else {
                const errors = res.getError();
                let params;
                if (errors.length > 0) {
                    // create toast details
                    params = {
                        mode : 'dismissible',
                        type : 'error',
                        title : 'An error occurred.',
                        message : errors[0].message
                    };
                } else {
                     params = {
                        mode : 'dismissible',
                        type : 'error',
                        title : 'An error occurred.',
                        message : 'An unknown error occured.'
                    };
                }
                
                // get toast event
                const showToastEvent = component.getEvent('createToast');
                
                showToastEvent.setParams({
                    toastParams : JSON.stringify(params)
                });
                
                showToastEvent.fire();
                
                this.setView(component, true)
                
            }
        });
        
        $A.enqueueAction(action);
	},
    
  	deleteSlot : function(component) {
		const action = component.get("c.a_deleteSlot");
        
        const id = component.get('v.slotId');
        
        action.setParams({
            slotId : id
        });
        
        action.setCallback(this, function (res) {
            const state = res.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                const deleteSlotEvent = component.getEvent('deleteResourceSlot');
                console.log(deleteSlotEvent);
                deleteSlotEvent.setParams({
                	slotId : id
                });
                deleteSlotEvent.fire();
            } else {
                const errors = res.getError();
                const params = {
                    mode : 'dismissible',
                    type : 'error',
                    title : 'An error occurred.',
                    message : errors[0].message
                }
                // get toast event
                const showToastEvent = component.getEvent('createToast');
                showToastEvent.setParams({
                    toastParams : JSON.stringify(params)
                });
                showToastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
	},
    
    showToast : function (component, params) {
        // get toast event
        const showToastEvent = component.getEvent('createToast');
        
        showToastEvent.setParams({
            toastParams : JSON.stringify(params)
        });
        
        showToastEvent.fire();
    },
    
    setLoading : function (component, state) {
        component.set('v.isLoading', state);
    },
    
    setView : function (component, state) {
        component.set('v.isViewMode', state);
    },
    
    closeModals : function(component) {
		const parent = component.get("v.parent");
		parent.closeModals();
	},
    
    hasPermission : function (component, slot) {
        const user = component.get('v.user');
        return user.userId === slot.OwnerId || user.permissionLevel === 'SYSADMIN' || user.permissionLevel === 'RESADMIN';
    }
})