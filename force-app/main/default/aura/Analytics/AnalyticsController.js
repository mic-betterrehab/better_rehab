({
	runAnalytics : function(component, event, helper) {
		const selected = component.get('v.reportOn');
        console.log('v.reportOn', component.get('v.reportOn'));
        helper.pullData(component, selected).then((res) => {
            console.log(res);
            helper.prepareData(component, res);
            component.set('v.resultsToShow', selected);            
        }).catch((err) => {
            console.log(err);
        })
	},
            
    clinicianSummaryObj : function (component, event, helper) {
    	const clinicians = component.get('v.auditClinPerspData');
        const conformed = parseInt(component.find('conformedNum').getElement().value);
        const total = parseInt(component.find('totalNum').getElement().value);

        const allowed = [0,1,2,3,4,5];
        if (total < conformed || !allowed.includes(conformed) || !allowed.includes(total)) {
            component.set('v.clinResMessage', 'Invalid parameters');
            return;
        }
        
        component.set('v.clinResMessage', '');
        
        const matched = clinicians.filter(c => c.conformed === conformed && c.total === total);
        const res = matched.length + ' clinicians conformed'; 
        
        component.set('v.clinResMessage', res);
    }
})