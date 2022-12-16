import { LightningElement, api } from 'lwc';

import chartjs from '@salesforce/resourceUrl/ChartJs'; 
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getAllEvents from '@salesforce/apex/AnalyticsController.getEvents';

export default class TeamLeaderDashboard extends LightningElement {

    reportDataFromApex;
    _currentusername;

    _isTL;

    firstdayString;
    lastdayString;

    emptyChart = false;

    weekToDates = new Map();
    weekToDatesTwo;

    loaded;

    @api     
    get currentusername(){
        return this._currentusername;
    }
    
    set currentusername(value){
        this.setAttribute('currentusername', value);
        this._currentusername = value;
    };

    _isTL;

    @api     
    get istl(){
        return this._isTL;
    }
    
    set istl(value){
        this.setAttribute('istl', value);
        this._isTL = value;
    };

    // Declare all your variables here
    error;
    chart;
    chartTwo;
    chartjsInitialized = false;

    // Use rendered callback to update the chart as the page loads - will be called multiple times
    renderedCallback() {

        console.log('Inside rendered Callback teamLeaderDashboard');        

        console.log('start date in rendered Callback: ' + this.start);

        if(this.chartjsInitialized) {
            return;
        }

        this.chartjsInitialized = true;
        
        console.log('this.chartjsInitialized: ' + this.chartjsInitialized);

        Promise.all([
            loadScript(this,chartjs)
        ])
            .then(() => {
                console.log('then load script');
                
                //const canvas = document.createElement('canvas');
                //this.template.querySelector('div.chart').appendChild(canvas);
                const ctx = this.template.querySelector('[data-id="chartOne"]').getContext('2d');
                const ctxTwo = this.template.querySelector('[data-id="chartTwo"]').getContext('2d');
                this.chart = new window.Chart(ctx, this.config);
                this.chartTwo = new window.Chart(ctxTwo, this.configTwo);

                this.getDateRange();
                this.handleEventsData();

            })
            .catch((error) => {
                console.log('catch error');
                console.log(error);
                this.error = error;
            });
    }

    connectedCallback(){
        console.log('Inside connectedCallback teamLeaderDashboard');
    }

    //if you implement this, no error popup will appear, instead it'll be in console
    errorCallback(error, stack){
        console.log('Inside errorCallback teamLeaderDashboard');
        this.error = error;
        console.log(error);
        console.log(stack);
    }
    
    disconnectedCallback(){
        console.log('Inside disconnectedCallback teamLeaderDashboard');
    }

    getDateRange(){
        let curr = new Date; // get current date
        let first = curr.getDate() - curr.getDay();
        let last = first + 27;

        let firstday = new Date(curr.setDate(first));
        let lastday = new Date(curr.setDate(last));

        let firstMonth = firstday.getMonth() + 1;
        let lastMonth = lastday.getMonth() + 1;

        this.firstdayString = firstday.getDate() + '/' + firstMonth + '/' + firstday.getFullYear();
        this.lastdayString = lastday.getDate() + '/' + lastMonth + '/' + lastday.getFullYear();

        //update chart two's legend
        console.log(this.chartTwo.data.datasets); //this works
        this.updateChartTwoLegend(firstday);

    }

    updateChartTwoLegend(startingDate){
        console.log('Inside updateChartTwoLegend');

        Date.prototype.addDays = function (days) {
            const date = new Date(this.valueOf());
            date.setDate(date.getDate() + days);
            return date;
        };

        for(let i = 0; i < 4; i++){
            let dates = [];

            let starting = startingDate.addDays(i * 7);
            let ending = starting.addDays(6);

            dates.push(starting, ending);

            let firstMonth = starting.getMonth() + 1;
            let lastMonth = ending.getMonth() + 1;

            let startString = starting.getDate() + '/' + firstMonth + '/' + starting.getFullYear();
            let endString = ending.getDate() + '/' + lastMonth + '/' + ending.getFullYear();

            let weekRange = startString + ' - ' + endString;

            this.weekToDates.set(weekRange, dates);
        }

        console.log('weekToDates');
        console.log(this.weekToDates);

        this.weekToDatesTwo = this.weekToDates;

        for (let [key, value] of this.weekToDates){
            //now time to add it to chart two's legend

            for(let obj of this.chartTwo.data.datasets){
                if(obj.label !== 'PCH Target' && obj.label === ''){
                    obj.label = key;  
                    break;
                }
            }
        }

        this.chartTwo.update();
    }

    @api filterReportDataFromParent(regions, sites){
        this.filterReportData('Non-TL', regions, sites);
        console.log('size of regions: ' + regions.length);
        console.log('size of sites: ' + sites.length);
    }

    // this runs at the load of the page
    // maybe should have a client-side check that will throw an error if data filtered is too big before going to server
    handleEventsData(){
        console.log('Inside handleEventsData'); 

        getAllEvents()
        .then((result) => {
            this.reportDataFromApex = result;
            this.displayChartUponRender(result); 
            this.loaded = true;
        })           
    }
    
    displayChartUponRender(result){
        console.log('Inside displayChartUponRender');
        console.log('is the current user a TL? ' + this._isTL); 
        
        //is the data from apex already complete?
        console.log('content of the result');
        console.log(result);    

        this.loaded = false;

        //if currently logged in user is a TL, immediately filter the data for that TL
        //otherwise, show everyone's data (all better rehab) - might need to review this later
        if(this._isTL){
            this.filterReportData('TL');
        } else {     
            console.log('not a tl so not tl filter');

            //this loop will run per worker
            for(var key in result){
                this.addDataLabelsAndPCH(key);
                this.addDataValuesByEventType(result[key]);
                this.addDataValuesByWeek(result[key]);
                this.chart.update();                
                this.chartTwo.update();                
            }

            /*console.log('Printing dataset of chart 2 in displayChartUponRender: ');
            this.chartTwo.data.datasets.forEach((dataset) => {
                console.log(dataset);
            });*/

            console.log('Checking the array of Therapy Session in displayChartUponRender: ');
            this.chart.data.datasets.forEach((dataset) => {
                if(dataset.label === 'Therapy Session'){
                    console.log(dataset);
                }
            });
        }
    }

    sortFinalData(result){
        console.log('Inside sortFinalData');
        
        //make sure that all arrays are reset to empty
        this.chart.data.labels.length = 0;
        this.chartTwo.data.labels.length = 0;

        this.chart.data.datasets.forEach((dataset) => {
            dataset.data.length = 0;
        });

        this.chartTwo.data.datasets.forEach((dataset) => {
            dataset.data.length = 0;
        });

        //this loop will run per worker
        for(const [key, value] of result.entries()){   
            this.addDataLabelsAndPCH(key);
            this.addDataValuesByEventType(value);
            this.addDataValuesByWeek(value);
            this.chart.update();
            this.chartTwo.update();
        }         

        console.log('Printing dataset of chart 2 in sortFinalData: ');
        this.chartTwo.data.datasets.forEach((dataset) => {
            console.log(dataset);
        });
    }

    addDataLabelsAndPCH(key){
        let workerDetails = JSON.parse(key);

        //console.log('Worker processed now'); 
        //console.log(workerDetails.Name);
        
        //add the worker name on x axis
        this.chart.data.labels.push(workerDetails.Name); //"W1;Rafella Angeline"
        this.chartTwo.data.labels.push(workerDetails.Name); //it's been added but not showing on the UI

        //add the kpi line
        this.chart.data.datasets.forEach((dataset) => {
            if(dataset.label === 'PCH Target' && typeof workerDetails.enrtcr__User__r.KPI__c !== undefined){
                //if the week is filtered, we need to x with diff value
                dataset.data.push(workerDetails.enrtcr__User__r.KPI__c * 4);
            }
        });

        this.chartTwo.data.datasets.forEach((dataset) => {
            if(dataset.label === 'PCH Target' && typeof workerDetails.enrtcr__User__r.KPI__c !== undefined){
                //if the week is filtered, we need to x with diff value
                dataset.data.push(workerDetails.enrtcr__User__r.KPI__c * 4);
            }
        });
    }

    addDataValuesByEventType(value){
        let eachWorkerDataMap = new Map();
        let eventTypes = ['Therapy Session', 'Initial Appointment', 'Other PCH', 'Internal', 'Out of Office'];
        
        value.map(function(row){

            if(eachWorkerDataMap.has(row.eventType)){                    
                let newValue = eachWorkerDataMap.get(row.eventType) + row.durationInMinutes/60;
                eachWorkerDataMap.set(row.eventType, newValue);
            } else {
                eachWorkerDataMap.set(row.eventType, row.durationInMinutes/60);
            }
        });         

        //now checks for remaining event types that might not be in the map
        for (const type of eventTypes){
            if(!eachWorkerDataMap.has(type)){
                eachWorkerDataMap.set(type, 0);
            }
        }            

        //console.log('What is inside eachWorkerDataMap?');
        //console.log(eachWorkerDataMap);

        for (const typeOfEvent of eachWorkerDataMap.keys()) {

            //this will updates the chart data with the result
            this.chart.data.datasets.forEach((dataset) => {
                if(dataset.label === typeOfEvent){
                    dataset.data.push(eachWorkerDataMap.get(typeOfEvent));
                }
            });
        }    
    }

    addDataValuesByWeek(value){
        console.log('Inside addDataValuesByWeek');
        let eachWorkerDataMap = new Map(); //map of weekRanges (string) - event duration
        //weekToDates

        let tempDateMap = this.weekToDates;

        //row.startDate is a string of 2022-04-21
        //have to parse it to a date object so we can compare
        value.map(function(row){
            let d1 = row.startDate.split("-");
            let date = new Date(d1[0], parseInt(d1[1])-1, d1[2]);  // -1 because months are from 0 to 11
            
            //if the event start time is between the 2 dates
            for(const [key, value] of tempDateMap.entries()){

                if(date >= value[0] && date <= value[1]){
                    //console.log(date + ' is between: ' + key);
                    
                    if(eachWorkerDataMap.has(key)){                    
                        let newValue = eachWorkerDataMap.get(key) + row.durationInMinutes/60;                        
                        eachWorkerDataMap.set(key, newValue);
                    } else {
                        eachWorkerDataMap.set(key, row.durationInMinutes/60);
                    }
                }
            }
        }); 
        
        //now checks for remaining event types that might not be in the map
        for(const [key, value] of tempDateMap.entries()){
            if(!eachWorkerDataMap.has(key)){
                eachWorkerDataMap.set(key, 0);
            }
        }      
        
        for (const weekRange of eachWorkerDataMap.keys()) {

            //this will updates the chart data with the result
            this.chartTwo.data.datasets.forEach((dataset) => {
                if(dataset.label === weekRange){
                    dataset.data.push(eachWorkerDataMap.get(weekRange));
                }
            });
        } 
        
    }

    //filter the data based on the type of filtering needed    
    filterReportData(type, regions, sites){
        console.log('Inside filterReportData');
        let newMapOfReportData = new Map();

        console.log('Type of filtering: ' + type);

        console.log('content of this.reportDataFromApex');
        console.log(this.reportDataFromApex);
        
        // now time to filter the events - pick the data that matches the criteria and assign them to a new map of contact and list of events
        for(let key in this.reportDataFromApex){
            let workerDetails = JSON.parse(key);

            //1. filter for TL - invoked upon rendering if user is a TL
            if(type == 'TL'){
                if(workerDetails.enrtcr__User__r.TeamLeader__c == this._currentusername){
                    console.log('the TL name matches!')
                    newMapOfReportData.set(key, this.reportDataFromApex[key]);
                }
            }

            //2. filter for non TL - invoked when the parent filter is chosen
            if(type == 'Non-TL'){

                //have a check here to make sure only process workers with sites
                if(!workerDetails.hasOwnProperty('enrtcr__Site__c')){
                    //console.log('this person does not have any sites');
                    continue;
                }

                if(sites.length !== 0){
                    if(sites.includes(workerDetails.enrtcr__Site__r.Name)){
                        console.log(`The site matches`);
                        newMapOfReportData.set(key, this.reportDataFromApex[key]);
                    }
                } else {
                    if(regions.length !== 0){
                        if(regions.includes(workerDetails.enrtcr__Site__r.enrtcr__Business_State__c)){
                            console.log(`The regions matches`);
                            newMapOfReportData.set(key, this.reportDataFromApex[key]);
                        }
                    } else {
                        console.log(`The site and regions are both empty`);
                        newMapOfReportData.set(key, this.reportDataFromApex[key]);
                    }
                }
            }
            
        }

        console.log('Size of newMapOfReportData: ' + newMapOfReportData.size);

        //this is what happens if filter chosen contains no data
        if(newMapOfReportData.size == 0){            
            //make sure that all arrays are reset to empty
            this.chart.data.labels.length = 0;
            this.chartTwo.data.labels.length = 0;

            this.chart.data.datasets.forEach((dataset) => {
                dataset.data.length = 0;
            });

            this.chartTwo.data.datasets.forEach((dataset) => {
                dataset.data.length = 0;
            });

            this.chart.update();
            this.chartTwo.update();

            //display the error message here
            this.emptyChart = true;
        } else {
            this.emptyChart = false;
        }

        this.sortFinalData(newMapOfReportData); 
    }

    config = {

        label: 'Number of Events',
    
        type : 'line',        
    
        data :{
            //modification starts here for stacked bar chart
            datasets :
            [
                {
                    label: 'Therapy Session', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(38,133,64,0.7)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: 'Initial Appointment', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(15,94,163,0.7)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: 'Other PCH', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(116,43,108,0.7)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: 'Internal', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(184,129,89,0.7)'],
                    stack: 'combined',
                    type: 'bar',
                    hidden: true,
                },
                {
                    label: 'Out of Office', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(152,152,152,0.7)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: 'PCH Target', 
                    data: [],
                    backgroundColor: ["#979393",],
                    borderColor: ["#979393",],
                    fill: false,
                },
            ],
            //https://stackoverflow.com/questions/42934608/how-to-create-two-x-axes-label-using-chart-js
            labels: [], //this is the label for each worker name      
            
        },
        options: {
            responsive : false,
            maintainAspectRatio: false,
            scales: {
                //this first axis gonna be the different weeks
                x: {
                    stacked: true,
                },
                y: {
                    beginAtZero: true,
                    stacked: true,
                },
            },      
            animation:{
                animateScale: true,
                animateRotate : true
            },
            plugins: {    
                title: {
                    display: true,
                    text: 'Grouped by Event Type',
                    align: 'start',
                    padding: {
                        top: 10,
                        bottom: 30
                    },
                    font: {
                        size: 14,
                    }
                },            
                legend: {
                    position: 'bottom',                    
                },
                tooltip: {
                    enabled: true,
                    callbacks: {
                            afterLabel: function(context){
                                return ' hours';
                            }, 
                    }
                }
            }
        },      
    };

    configTwo = {

        label: 'Number of Events',
    
        type : 'line',        
    
        data :{
            //modification starts here for stacked bar chart
            datasets :
            [
                {
                    label: '', //this label will be the week
                    data: [],
                    backgroundColor :['rgba(81, 21, 73, 1)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: '', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(81, 21, 73, 0.75)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: '', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(81, 21, 73, 0.5)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: '', //this label is for each stack in 1 bar
                    data: [],
                    backgroundColor :['rgba(81, 21, 73, 0.25)'],
                    stack: 'combined',
                    type: 'bar',
                },
                {
                    label: 'PCH Target', 
                    data: [],
                    backgroundColor: ["#979393",],
                    borderColor: ["#979393",],
                    fill: false,
                },
            ],
            labels: [], //this is the label for each worker name      
            
        },
        options: {
            responsive : false,
            maintainAspectRatio: false,
            scales: {
                //this first axis gonna be the different weeks
                x: {
                    stacked: true,
                },
                y: {
                    beginAtZero: true,
                    stacked: true,
                },
            },      
            animation:{
                animateScale: true,
                animateRotate : true
            },
            plugins: {    
                title: {
                    display: true,
                    text: 'Grouped by Week',
                    align: 'start',
                    padding: {
                        top: 10,
                        bottom: 30
                    },
                    font: {
                        size: 14,
                    }
                },                        
                legend: {
                    position: 'bottom',                    
                },
                tooltip: {
                    enabled: true,
                    callbacks: {
                            afterLabel: function(context){
                                return ' hours';
                            }, 
                    }
                }
            }
        },      
    };

}