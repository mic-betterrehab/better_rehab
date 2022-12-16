({
	initRun : function(component, event, helper) {
        console.log('what is modalType? ' + component.get('v.modalType'));
        console.log('what is recurrence type? ' + component.get('v.recurrence'));
        //how to get the body from the map
        //console.log(component.get('v.modalMap'));
        
        //set the body
        helper.generateModalContent(component);
        //this.setBody(component);
        
	},
    
    handleButtonClick : function(component, event, helper) {
        //get the value of the buttons to know what we're dealing with
        console.log('Inside handleButtonClick');
        
        //pass it
        let compEvent = component.getEvent("modalCmpEvent");
        compEvent.setParams({"buttonValue" : event.getSource().get("v.value") });
        compEvent.fire();
       
        
	},    
    
    
})