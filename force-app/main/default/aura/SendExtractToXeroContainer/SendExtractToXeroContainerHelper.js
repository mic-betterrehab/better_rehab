/**
 * Created by Enrite Solutions on 5/01/2021.
 */

({
    closeQuickAction: function(component, event, helper){
        let dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
});