({
    
    insertEventFromParent : function (component){
        console.log('Inside insertEventFromParent');
        const parent = component.get('v.parent');
        parent.insert();
    },
    
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
    
    clashHandler : function(component) {
        var self = this;
        const parent = component.get('v.parent');
        
        return new Promise($A.getCallback(function (resolve, reject){ 
            var action = component.get("c.findClashingWorkerAndClientEvents"); 
            
            console.log('Inside promise for clashHandler helper');
            
            console.log('v.eventDetailsJSONChild in child component: ' + component.get("v.eventDetailsJSONChild"));
            
            action.setParams({
                eventJSON : JSON.stringify(component.get("v.eventDetailsJSONChild")),
                repeatJSON : JSON.stringify(component.get("v.repeatDetailsJSONChild"))
            });
            
            action.setCallback(this, function(response) {
                console.log('Inside setCallback for clashHandler helper');
                
                var state = response.getState();
                console.log('clashHandler helper status = ' + state);
                console.log('clashHandler helper result = ' + response);
                
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();   
                    console.log('Result of setCallback clashHandler helper: ' + result);
                    console.log('Result of setCallback clashHandler helper: ' + result.length);                    
                    
                    resolve(result);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    reject(errors);
                }
            });
            
            $A.enqueueAction(action); 
        }))
    }
})