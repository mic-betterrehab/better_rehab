({
	pullData : function(component, selected) {
		return new Promise($A.getCallback(function (resolve, reject){
            var action = component.get("c.pullData");
            
            const start = component.get('v.userInputs.start');
            const end = component.get('v.userInputs.end');
            
            action.setParams({
                selected : selected,
                startDate : start,
                endDate : end
            });
             
            action.setCallback(this, function(response) {
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    return resolve(result);
                    
                } else if (state === "INCOMPLETE") {
                } else if (state === "ERROR") {
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
        }))
	},
    
    prepareData : function (component, data) {
        
        const disciplineObj = {
            'OT' : [],
            'PT' : [],
            'SP' : [],
            'PBS' : []
        };
        
        const clinicians = [];
        
        data.forEach(audit => {
           	//console.log('audit', audit);
            const breakdown = JSON.parse(audit.BreakdownJSON__c);
            const discipline = audit.Clinician__r.Clinician_Discipline__c; 
            
            //breakdown.clinicianId = contact id in prod
            //obj.id = clinicians.id - which is breakdown.clinicianId
            const clinicianDataIndex = clinicians.findIndex(obj => obj.id === breakdown.clinicianId);
            
            if (clinicianDataIndex === -1) {
            	clinicians.push({
                    id : breakdown.clinicianId,
                    name : breakdown.clinicianName,
                    conformed : (breakdown.status === 'CONFORMS' || breakdown.status === 'PASS')  ? 1 : 0,
                    total : 1,
                    discipline : discipline
                });
            } else {
            	let clinicianData = clinicians[clinicianDataIndex];
    			clinicianData.total += 1;
    			if (breakdown.status === 'CONFORMS' || breakdown.status === 'PASS') {
                    clinicianData.conformed += 1;
                }
 				clinicians[clinicianDataIndex] = clinicianData;
			}
            
            switch (discipline) {
                case "Occupational Therapy":
            		disciplineObj['OT'].push(breakdown);
            		break;
                case "Speech Pathology":
            		disciplineObj['SP'].push(breakdown);
            		break;
                case "Physiotherapy":
            		disciplineObj['PT'].push(breakdown);
            		break;
                case "PBS":
            		disciplineObj['PBS'].push(breakdown);
            		break;           
                case "Exercise Physiology":
            		disciplineObj['PT'].push(breakdown);
            		break;
        	}
        });
		
		const disciplineGroups = ['OT', 'SP', 'PT', 'PBS'];
        //const sectionDeepAnalysis = ['Assessment and Goal Setting', 'Outcomes and recommendations'];

        let results = [];
        
		for (const disc of disciplineGroups) {
            results[disc] = {
                'totalAudits' : 0,
                'conformedAudits' : 0,
                'GEN' : {},
                'DEEP' : {},
            }
		}
		
		//iterate through each discipline in the array (there are 4 in total) to get the total number of conformed in each disc
        for (const [disc, arr] of Object.entries(disciplineObj)) {
            const totalAudits = arr.length;
            const conformedAudits = this.getConformed(arr);
            console.log('conformedAudits', conformedAudits);
            
            results[disc]['totalAudits'] = totalAudits;
            results[disc].conformedAudits = conformedAudits;
            
            let sectionsGenAnalysis = [];
            
            //conditionally choose which list to use based on what audit the user clicks on
            if(component.get('v.reportOn') === 'Clinical Audit'){
                sectionsGenAnalysis = ['Assessment and Goal Setting', 'Outcomes and recommendations', 'Clinical Appointments', 'Other reports', 'Clinical Communication', 'Caseload Tracking', 'Complex home mods', 'Behaviour Support Plan'];
            } else if (component.get('v.reportOn') === 'Procedural Audit'){
                sectionsGenAnalysis = ['Risk Assessment', 'Initial Assessment Report', 'Plan Review Report', 'Clinical Notes', 'SDEs', 'Home modifications (OT only)', 'Ortho / HST (Physio only)', 'Behaviour Support Plan (Behaviour Support clinicians only)'];
            }
            
            console.log('sectionsGenAnalysis', sectionsGenAnalysis);
            
            for (const sectionTitle of sectionsGenAnalysis) {                
                const { lostPoints, totalSections } = this.sectionAnalysisGen(arr, sectionTitle);
                results[disc]['GEN'][sectionTitle] = {
                    lostPoints,
                    totalSections,
                };
            };
        };
        
        const finalArr = [];
      	for (const disc in results) {
            let obj = {key : disc, totalAudits : results[disc].totalAudits, conformedAudits : results[disc].conformedAudits};
            let sectionArr = [];
            for (const section in results[disc]['GEN']) {
                let secObj = {key : section, lostPoints : results[disc]['GEN'][section].lostPoints, totalSections : results[disc]['GEN'][section].totalSections};
                sectionArr.push(secObj);
           	}
            obj['GEN'] = sectionArr;
                
            finalArr.push(obj);
        }
        
        console.log(results);
        console.log(clinicians);
        component.set('v.auditDiscPerspData', results);
        component.set('v.auditClinPerspData', clinicians);
        component.set('v.auditSummaryList', finalArr); 
        console.log('finalArr', finalArr);
    },
    
    getConformed : function (arr) {
        const conformed = arr.filter(audit => {
            return audit.status === "CONFORMS" || audit.status === "PASS"; 
        }).length;
        
        const conformedArray = arr.filter(audit => {
            return audit.status === "CONFORMS" || audit.status === "PASS"; 
        });
        
        console.log('conformedArray', conformedArray);
        
		return conformed;        
    },
    
    sectionAnalysisGen : function (arr, sectionName) {        
        const requiredSections = [];
        arr.forEach(audit => {
            const section = audit.sections.find(s => s.title === sectionName);
            requiredSections.push(section);
        });
        
        const totalSections = requiredSections.length;
        const lostPoints = requiredSections.filter(s => {
            return s.numerator != s.denominator;
        }).length;
        
        return { lostPoints , totalSections};
    },
    
    /*
    // can't do this until we get a total score per question in the breakdown json. right now it only has question name and score in there            
    sectionAnalysisDeep : function (arr, sectionName) {
        const questions = {};
        
        arr.forEach(audit => {
            const section = audit.sections.find(s => s.title === sectionName);
            
            
        })
    },*/
})