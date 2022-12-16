import { LightningElement, track, api } from 'lwc';
import getAllSites from '@salesforce/apex/AnalyticsController.getAllSites';
import USER_ID from '@salesforce/user/Id'; 
import getCurrentUserKPI from '@salesforce/apex/AnalyticsController.getCurrentUserKPI';

export default class FilterDashboard extends LightningElement {
    //chart js trial here
    //value = 'Week 1';
    @track regionSelected = [];
    
    // if you don't use @track here, the options are not appearing in the UI, but you won't be able to print it on the console log
    @track siteOptions = [{
        label: '',
        value: ''
    }];

    @track sitesSelected = [];

    allSites = [];
    isTeamLeader;
    currentUserFullName;

    regionsForChild;
    sitesForChild;

    renderedCallback(){
        console.log('Inside rendered callback in filter');
        this.getSiteOptions();
        this.getCurrentUserDetails();
    }

    getCurrentUserDetails(){
        console.log('Inside get user details');
        getCurrentUserKPI({userId: USER_ID})
        .then((result) => {
            console.log(result);

            this.currentUserFullName = result[0].Name;
            console.log('currentUserFullName: ' + result[0].Name);

            if(result[0].Title == 'Team Leader'){
                this.isTeamLeader = true;
            } else {
                this.isTeamLeader = false;
            }
        })
    }

    get regionOptions() {
        return [
            { label: 'NSW', value: 'NSW' },
            { label: 'ACT', value: 'ACT' },
            { label: 'VIC', value: 'VIC' },
            { label: 'QLD', value: 'QLD' },
            { label: 'WA', value: 'WA' },
            { label: 'SA', value: 'SA' },
        ];

    }

    /*get selectedRegion() {
        return this.regionSelected.length ? this.regionSelected : 'none';
    }*/

    handleRegionChange(e) {
        let previousRegions = this.regionSelected;

        this.regionSelected = e.detail.value;

        this.sortSiteOptions(this.allSites);

        console.log('Inside handleRegionChange, selected sites are: ' + this.regionSelected);
        let newRegions = this.regionSelected; 
        
        //need to have a check if the regionselected length is deducted by 1, that means there is a removal 
        if(previousRegions.length - 1 == newRegions.length){
            this.regionRemoval(previousRegions, newRegions);
        }
        
    }

    regionRemoval(previous, next){
        console.log('Something is removed from regionSelected');
        //find that removed region
        let removedState = '';
        for(const r in previous){
            if(!next.includes(previous[r])){
                console.log(previous[r] + ' was removed!');
                removedState = previous[r];
            }
        }

        let sitesForRemovedState = [];
        //get all the office in that removed state
        for(const a in this.allSites){
            if(this.allSites[a].enrtcr__Business_State__c == removedState){
                sitesForRemovedState.push(this.allSites[a].Name);
            } 
        }

        console.log('sites for removed state: ');
        console.log(sitesForRemovedState);

        //check if the selected ones include the removed

        for(let i = 0; i < this.sitesSelected.length; i++){
            console.log('printing out the sites name currently processed: ' + this.sitesSelected[i]);

            if(sitesForRemovedState.includes(this.sitesSelected[i])){
                //remove the sites
                console.log('This site: ' + this.sitesSelected[i] + ' should be removed');                
                console.log('index of the site: ' + i);
                if (i > -1) {
                    this.sitesSelected.splice(i, 1); // 2nd parameter means remove one item only
                    i--;
                }

            } else {
                console.log('This site: ' + this.sitesSelected[i] + ' is not in the selected list');
            }
        }
    }

    handleSiteChange(e){
        this.sitesSelected = e.detail.value;
    }

    //by default will get all sites (when called from rendered Callback)
    getSiteOptions(){
        //console.log('Inside getSiteOptions');

        getAllSites()
        .then((result) => {
            //empty the array first
            this.allSites.length = 0;
           
            for(let site in result){   
                
                this.allSites.push(result[site]);
            }            
        })
    }

    //looks like every time you click the confirm filter button, the site options + 1
    sortSiteOptions(availableSites){
        //console.log('Inside sortSiteOptions');

        //if a state is removed, u need to remove the sites that are in that state from the sitesSelected array

        //empty the array first
        this.siteOptions.length = 0;

        for(let state in this.regionSelected){

            for(let site in availableSites){                  

                if(this.regionSelected[state] == availableSites[site].enrtcr__Business_State__c){
                    let label = availableSites[site].Name;
                    let value = availableSites[site].Name;
    
                    let optionObject = {label, value};
                    
                    this.siteOptions.push(optionObject);                   
                    
                }    
            }
        } 
    }

    handleConfirmFilter(){
        //firing an child method
        this.template.querySelector("c-team-leader-dashboard").filterReportDataFromParent(this.regionSelected, this.sitesSelected);
    }
     
}