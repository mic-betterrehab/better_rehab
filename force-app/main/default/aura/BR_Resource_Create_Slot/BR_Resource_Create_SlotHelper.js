({
	closeModals : function(component) {
		const parent = component.get("v.parent");
		parent.closeModals();
	},
    
    validateCreate : function(component, input) {
        if (input.startDt >= input.endDt) {
            return 'Start time must be less than end time.';
        };
        
        if (!input.resourceId) {
            return 'You must enter a resource.';
        }

        if (!input.clientId) {
            return 'You must enter a client.';
        }
        
        if (!input.userId) {
            return 'You must enter a user.';
        }
        
        if (!input.destinationSiteId) {
            return 'You must enter a destination site.';
        }
        
        return 'isValid';
    },
    
    showToast : function (component, params) {
        // get toast event
        const showToastEvent = component.getEvent('createToast');
        
        showToastEvent.setParams({
            toastParams : JSON.stringify(params)
        });
        
        showToastEvent.fire();
    }
})