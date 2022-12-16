trigger BR_AssessmentReviewTrigger on enrtcr__Assessment__c (after insert) {
    System.debug('Inside A/R Trigger');
    
    new BR_PlanReviewNew(Trigger.new);
    
}