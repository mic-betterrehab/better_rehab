import { 
  LightningElement,
  api,
  wire,
  track  } from 'lwc';


import chartjs from '@salesforce/resourceUrl/ChartJs'; 
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import USER_ID from '@salesforce/user/Id'; 

import getUserDetails from '@salesforce/apex/AnalyticsController.getCurrentUserKPI';
import getAggregate from '@salesforce/apex/AnalyticsController.getAggregateEvents';

export default class analyticsLWC extends LightningElement {
    //chart js trial here
    
    // Declare all your variables here
    error;
    chart;
    chartjsInitialized = false;

    // Use rendered callback to update the chart as the page loads - will be called multiple times
    renderedCallback() {

        console.log('Inside rendered Callback');

        if(this.chartjsInitialized) {
            return;
        }

        this.chartjsInitialized = true;
        
        console.log('this.chartjsInitialized: ' + this.chartjsInitialized);

        //Promise.all([
            loadScript(this,chartjs)
        //])
            .then(() => {
                console.log('then load script');
                
                //const canvas = document.createElement('canvas');
                //this.template.querySelector('div.chart').appendChild(canvas);
                const ctx = this.template.querySelector('canvas').getContext('2d'); 
                this.chart = new window.Chart(ctx, this.config);


                this.handleUserKPI();
                this.handleEventsData();

                
                
            })
            .catch((error) => {
                console.log('catch error');
                console.log(error);
                this.error = error;
            });
    }

    connectedCallback(){
        console.log('Inside connectedCallback');
    }

    //if you implement this, no error popup will appear, instead it'll be in console
    errorCallback(error, stack){
        console.log('Inside errorCallback');
        this.error = error;
        console.log(error);
        console.log(stack);
    }

    // call the Apex method IMPERATIVELY here (so we can control when do we call this)
    // using wire service means we are calling the apex method reactively - every time the component is created (even before rendered callback)
    handleUserKPI(){ 
        console.log('Inside handleUserKPI TRIAL');
        getUserDetails({userId: USER_ID})
        .then((result) => {
            this.chart.data.datasets.forEach((dataset) => {
                if(dataset.label === 'PCH Target'){
                    //do it 4 times cause there are 4 weeks
                    dataset.data.push(result[0].KPI__c);
                    dataset.data.push(result[0].KPI__c);
                    dataset.data.push(result[0].KPI__c);
                    dataset.data.push(result[0].KPI__c);
                }
            });

            this.chart.update();
        })
        .catch((error) => { 
            console.log('error in retrieving user details: ');
            console.log(error);
            this.error = error;
        })
    }

    handleEventsData(){
        console.log('Inside handleEventsData TRIAL');
        getAggregate({userId: USER_ID})
        .then((result) => {             

            for(var key in result)
            {
                console.log('Currently in this week range: ' + key);
                this.chart.data.labels.push(key);

                let weekMap = new Map();

                result[key].map(function(row){
                    //this is looping through each event type in 1 week

                    //convert duration in mins to hours before putting to map
                    let hours = row.totalDuration/60;
                    weekMap.set(row.Event_Type__c, hours);
                });
                
                this.updateChart(weekMap);
            }

            this.error=undefined;
        })
        .catch((error) => { 
            console.log('IT IS ERROR IN THE GET AGGREGATE WIRE: ');
            this.error = error;
        })
    }
    
    updateChart(oneWeekMap){
        console.log('Inside updateChart');

        console.log('Content of the week range: ' + oneWeekMap);
        console.log(oneWeekMap);

        for (const type of oneWeekMap.keys()) {

            //this will updates the chart data with the result
            this.chart.data.datasets.forEach((dataset) => {
                if(dataset.label === type){
                    dataset.data.push(oneWeekMap.get(type));
                }
            });
        }    

        this.chart.data.datasets.forEach((dataset) => {
            if(typeof oneWeekMap.get(dataset.label) === 'undefined'){
                dataset.data.push(0);
            }
        });

        this.chart.update();
        
    }


    config = {

        label: 'Number of Events',
    
        type : 'line',
        
    
        data :{
            //modification starts here for stacked bar chart
            datasets :[
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
                    label: 'PCH Target', 
                    data: [],
                    backgroundColor: ["#979393",],
                    borderColor: ["#979393",],
                    fill: false,
                }
            ],
            
            labels: [], //this is the label for each 1 bar           
            
        },
        options: {
            responsive : false,
            //maintainAspectRatio: false,
            scales: {
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
                legend: {
                    //display: false,
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
    

    disconnectedCallback(){
        console.log('Inside disconnectedCallback');
    }
}