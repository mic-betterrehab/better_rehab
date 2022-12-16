({
    doInit: function(component) {

        var actions = [
            { label: 'View', name: 'show_details' },
            { label: 'Edit', name: 'edit_details' },
            { label: 'View Service Agreement', name: 'show_sa' }
        ];

        component.set('v.columns', [
            { label: 'Name', fieldName: 'name', type: 'text', sortable: true, initialWidth:120},
            { label: 'Date', fieldName: 'deliveryDate', type: 'date', sortable: true, initialWidth:100},
            { label: 'Client', fieldName: 'clientName', type: 'text', sortable: true, initialWidth:200},
            { label: 'Service Agreement', fieldName: 'saName', type: 'text', sortable: true, initialWidth:150},
            { label: 'Service', fieldName: 'serviceName', type: 'text', sortable: true},
            { label: 'Status', fieldName: 'sdStatus', type: 'text', sortable: true},
            { label: 'Quantity', fieldName: 'quantity', type: 'text', initialWidth:100},
            { label: 'Billed Qty', fieldName: 'totalExtractedQuantity', type: 'text', initialWidth:150},
            // { label: 'Total', fieldName: 'totalCost', type: 'currency', initialWidth:150},
            { label: 'Comments', fieldName: 'comments', type: 'text'},
            { label: 'Worker', fieldName: 'workerName', type: 'text', sortable: true, initialWidth:150},
            { type: 'action', typeAttributes: { rowActions: actions } }
        ]);

        var action = component.get("c.getFormDefaults");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set('v.sites', res.sites);
                component.set('v.startDate', res.startDate);
                component.set('v.endDate', res.endDate);
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);

    },

    approve: function(component, helper) {
        var selectedRecords = component.get('v.selectedSearchResults');

        if (!selectedRecords || selectedRecords.length == 0) {
            alert('At least 1 record must be selected');
            return;
        }
        if (!confirm('Are you sure you want to approve these records?')) {
            return;
        }

        component.set('v.showSpinner', true);
        var approvalRequest = {approvals:selectedRecords};

        var action = component.get("c.approveRecords");
        action.setParam('requestStr', JSON.stringify(approvalRequest));

        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.showSpinner', false);

            var toastEvent = $A.get("e.force:showToast");
            var message = '';
            var type = 'success';
            if (state === "SUCCESS") {
                message = response.getReturnValue();
                helper.search(component);
            } else {
                var errors = response.getError();
                type = 'error';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        message = errors[0].message;
                    } else {
                        message = 'Unknown error'
                    }
                } else {
                    message = "Unknown error";
                }
            }

            toastEvent.setParams({ "message":message, "type":type});
            toastEvent.fire();
        });

        $A.enqueueAction(action);


    },
    search: function(component) {

        var fields = ["startDate", "endDate"];
        var isValid = true;

        console.log(component.get('v.workerId'));
        console.log(component.find('workerId').get('v.value'));

        for (var i=0; i<fields.length; i++) {
            var fieldName = fields[i];
            var fieldComponent = component.find(fieldName);
            console.log(fieldComponent.get('v.value'));
            fieldComponent.showHelpMessageIfInvalid();
            if (!fieldComponent.get('v.validity').valid) {
                isValid = false;
            }
        }

        if (!isValid) return;

        component.set('v.showSpinner', true);
        component.set('v.selectedSearchResults', []);

        var action = component.get("c.getSdRecords");
        action.setParams({
            siteId: component.find('selectedSite').get('v.value'),
            startDate: component.find('startDate').get('v.value'),
            endDate: component.find('endDate').get('v.value'),
            workerId: component.get('v.workerId')
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set('v.showSpinner', false);

            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set('v.showSearchResults', true);
                component.set('v.searchResults', res);
                component.set('v.numberOfResults', res.length);
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);

    },
    handleRowAction: function(component, event) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'show_details':
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": row.id,
                    "isredirect": true,
                    "slideDevName": 'detail'
                });
                navEvt.fire();
                break;
            case 'edit_details':
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    "recordId": row.id
                });
                editRecordEvent.fire();
                break;
            case 'show_sa':
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": row.saId,
                    "isredirect": true,
                    "slideDevName": 'detail'
                });
                navEvt.fire();
                break;

        }
    },
    updateSelectedRows: function(component, event) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedSearchResults', selectedRows);
    },

    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.searchResults");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.searchResults", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ? function(x) {return primer(x[field])} : function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
});