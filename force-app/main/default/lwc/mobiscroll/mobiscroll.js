import { LightningElement } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MOBISCROLL from '@salesforce/resourceUrl/mobiscroll';

export default class Mobiscroll extends LightningElement {
    renderedCallback() {
        Promise.all([
            loadStyle(this, MOBISCROLL + '/css/mobiscroll.javascript.min.css'),
            // loadScript(this, MOBISCROLL + '/js/mobiscroll.javascript.min.js'),
            loadScript(this, MOBISCROLL + '/js/mobiscroll.javascript.min.js'),
            console.log('Inside promise all after loadScript')
        ]).then(() => {
            console.log('success load script');
            // this.initialize();
        }).catch(error => {
            console.log('there is an error for load script');
            console.error(error, this, document, window);
        });
    }

    initialize() {
        console.log('inside initialise');

        var config = Window.MOBISCROLL.calendar(this.template.querySelector('[data-id="mobiscroll"]'), {
            theme: 'ios',
            themeVariant: 'light',
            clickToCreate: false,
            dragToCreate: false,
            dragToMove: false,
            dragToResize: false,
            eventDelete: false,
            view: {
                calendar: { labels: true }
            },

            onEventClick: function (event, inst) {
                MOBISCROLL.toast({
                    message: event.event.title
                });
            }
        });

        MOBISCROLL.util.http.getJson('https://trial.mobiscroll.com/events/?vers=5', function (events) {
            config.setEvents(events);
        }, 'jsonp');
    }
}