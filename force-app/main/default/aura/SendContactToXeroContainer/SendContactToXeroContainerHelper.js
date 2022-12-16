/**
 * Created by Enrite Solutions on 14/12/2020.
 */

({
    closeQuickAction: function(component, event, helper){
        let dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }

});