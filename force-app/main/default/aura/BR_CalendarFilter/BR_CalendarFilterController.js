({    
    clickFilter: function (component, event, helper) {
        const parent = component.get('v.parent');
		parent.filter();    
    }
})