({
    doInit: function(component, event, helper) {
        helper.doInit(component);
    },

    approve: function(component, event, helper) {
        helper.approve(component, helper);
    },
    search: function(component, event, helper) {
        helper.search(component);
    },
    handleRowAction: function(component, event, helper) {
        helper.handleRowAction(component, event);
    },
    updateSelectedRows: function(component, event, helper) {
        helper.updateSelectedRows(component, event);
    },
    sortTable: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
});