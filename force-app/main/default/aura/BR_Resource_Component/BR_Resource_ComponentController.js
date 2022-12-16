({
	scriptsLoaded : function(component, event, helper) {
        helper.loadUser(component);
        helper.loadResources(component);
        //helper.loadCalendar(component);
    },
    
    // closes and cleans up all modals/subcompoents on the parent
    closeModals : function(component, event, helper) {
        helper.closeCreateModal(component);
        helper.closeEditModal(component);
    },
    
    // handle adding the created slot on the front end with data passed from create sub component
    handleCreate : function(component, event, helper) {
        // get the slot information passed in the event
    	const slotStringified = event.getParam('slot');
        
        // parse the json string into a json object
        const slot__c = JSON.parse(slotStringified);
        
        // convert to a full calendar compatible object
        const slot__fc = helper.convertToFCSlot(slot__c);
        
        // add the slot to the global slot list and reload the calendar
        helper.addSlot(component, slot__fc);
        helper.reloadCalendar(component);
        helper.showMyToast('dismissible', 'success', 'Success!', 'Successfully booked in a slot.');
    },
    
    handleShowToast : function(component, event, helper) {
        // get the config for the toast to show (json string)
        const params = event.getParam('toastParams');
        
        // convert json string to an object
        const params_obj = JSON.parse(params);
        
        // fire a toast event
        helper.showMyToast(params_obj.mode, params_obj.type, params_obj.title, params_obj.message);
    },
    
    handleUpdateSlot : function(component, event, helper) {
        // get the config with the new updated slot details (json string)
        const slotInfo = event.getParam('updatedSlot');
		        
        // convert json string to an object
        const slotInfo_obj = JSON.parse(slotInfo);

        // update the slot
        helper.updateSlot(component, slotInfo_obj);
        
        // reload the calendar
        helper.reloadCalendar(component);
        
        // close all modals
        helper.closeEditModal(component);
        
        // show a success message
        helper.showMyToast('dismissible', 'success', 'Success!', 'Successfully updated slot.');
    },
    
    handleDeleteSlot : function(component, event, helper) {
		// get the id of the slot to delete
        const slotId = event.getParam('slotId');

        // delete the slot
        helper.deleteSlot(component, slotId);
        
        // reload the calendar
        helper.reloadCalendar(component);
        
        // close all modals
        helper.closeEditModal(component);
        
        // show a success message
        helper.showMyToast('dismissible', 'success', 'Success!', 'Successfully deleted the slot.');        
    }
})