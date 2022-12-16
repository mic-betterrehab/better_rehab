({
	initRun : function(component, event, helper) {
        const lookup = component.find('ownerLookup');
        console.log(component.get('v.eventMap'));
        lookup.default();
        
        component.set("v.deviceType", $A.get("$Browser.formFactor"));   
	},
})