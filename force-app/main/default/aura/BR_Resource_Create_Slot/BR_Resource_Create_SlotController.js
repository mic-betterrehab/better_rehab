({
	doInit : function(component, event, helper) {
        const action = component.get("c.a_init");

        action.setCallback(this, function (res) {
            const state = res.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                const value = res.getReturnValue();
                console.log(value);
                component.set('v.queries', value);
            } else {
                const errors = res.getError();
                const params = {
                    mode : 'dismissible',
                    type : 'error',
                    title : 'An error occurred.',
                    message : 'Failed to initialise create form'
                };

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

    closeModal : function(component, event, helper) {
		helper.closeModals(component);
	},
    
    createSlot : function(component, event, helper) {
        const resource = component.get('v.resource');
        const user = component.get('v.user');
        const site = component.get('v.site');
        const client = component.get('v.client');
        const startTimeString = component.get('v.startTime');
        const endTimeString = component.get('v.endTime');
     	
        const requestObject = {
            resourceId : resource.Id,
            userId : user.Id,
            clientId : client.Id,
            destinationSiteId : site.Id,
            startDt : startTimeString,
            endDt : endTimeString,
        };

        const validationMessage = helper.validateCreate(component, requestObject);
        if (validationMessage !== 'isValid') {
            // create toast details
            const params = {
                mode : 'dismissible',
                type : 'error',
                title : 'An error occurred.',
                message : validationMessage
            };
            helper.showToast(component, params);
            return;
        }
        
        const action = component.get("c.a_createSlot");
        
        const requestString = JSON.stringify(requestObject);

        action.setParams({
            requestObject : requestString
        });
        
        action.setCallback(this, function (res) {
            const state = res.getState();
            console.log(state);
            if (state === 'SUCCESS') {
                const value = res.getReturnValue();
                console.log(value);
                
                const createSlotEvent = component.getEvent('createResourceSlot');
                createSlotEvent.setParams({
                    slot : JSON.stringify(value)
                });
                createSlotEvent.fire();
                helper.closeModals(component);
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
            }
        });
        
        $A.enqueueAction(action);
	},
})