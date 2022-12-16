({
	// closes all modals in parent component
    doInit : function(component, event, helper) {
        helper.setLoading(component, true);
        helper.loadSlot(component);
	},
    
    // closes all modals in parent component
    closeModal : function(component, event, helper) {
		helper.closeModals(component);
	},
    
    // handles clicking of delete button
    handleDelete : function(component, event, helper) {
        const currentSlot = component.get("v.slot__c");
        
        // check if user has permission to delete
        if (!helper.hasPermission(component, currentSlot)) {
            const params = {
                mode : 'dismissible',
                type : 'error',
                title : 'An error occurred.',
                message : 'You do not have permission to delete.'
            };
            helper.showToast(component, params);
            return;
        }
        
        helper.deleteSlot(component);
    },
    
    // handles clicking of edit button
    handleEdit : function(component, event, helper) {
        const currentSlot = component.get("v.slot__c");
        
        // check if user has permission to update
        if (!helper.hasPermission(component, currentSlot)) {
            const params = {
                mode : 'dismissible',
                type : 'error',
                title : 'An error occurred.',
                message : 'You do not have permission to edit.'
            };
            helper.showToast(component, params);
            return;
        }
        
        const updateDetails = {
            startTime : currentSlot.Start_Time__c,
            endTime : currentSlot.End_Time__c
        };
        component.set('v.updateDetails', updateDetails);
		component.set('v.isViewMode', false);
	},
    
    // handles clicking cancel button
    handleCancelEdit : function(component, event, helper) {
		component.set('v.isViewMode', true);
	},
    
    // handles clicking save button
    handleUpdateSlot : function(component, event, helper) {
		helper.updateSlot(component);
	}
})