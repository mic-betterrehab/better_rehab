public with sharing class AuditQuestionPackage {
    public Integer questionNumber {get;set;}
    public String question {get;set;}
    public String hoverOver {get;set;}
    public String score {get;set;}
    public Integer maxScore {get;set;}
    public String comments {get;set;}
    public Boolean autoFailQuestion {get;set;}
    
    public List<String> guidelines {get;set;}
    public List<SelectOption> scores {get; set;}
    
    public AuditQuestionPackage(Integer questionNumber, String question, Boolean optional, Integer min, Integer max, Boolean autoFail, List<String> hoverOver) {
        this.questionNumber = questionNumber;
        this.question = question;
        //this.hoverOver = hoverOver;
        this.maxScore = max;
        this.guidelines = hoverOver;
        scores = new List<SelectOption>(); 
        
        this.autoFailQuestion = autoFail;
        
        if (optional == TRUE) {
            scores.add(new SelectOption('N/A', 'N/A'));
        }
		
        Integer i = min;
        while (i <= max) {
           	scores.add(new SelectOption(String.valueOf(i), String.valueOf(i))); 
            i = i + 1;
        }
        
        //setGuidlines();
        
    }
    
    private void setGuidlines() {
        guidelines = new List<String>();
        
        if (this.hoverOver == '') {
        	guidelines.add('No guidelines for this question');
        } else {
            guidelines = this.hoverOver.split(';');
        }
        
    }
}