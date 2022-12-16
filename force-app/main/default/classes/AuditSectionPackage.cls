public with sharing class AuditSectionPackage {
    
    public List<AuditQuestionPackage> questions {get;set;}
    
    public String sectionTitle {get;set;}
    public String sectionSubtitle {get;set;}
    public Integer numerator {get;set;}
    public Integer denominator {get;set;}
    public String comments {get;set;}
    public String status {get;set;}
    public String taskName {get;set;}
    
    public AuditSectionPackage(String title, String subtitle) {
        questions = new List<AuditQuestionPackage>();
        this.sectionSubtitle = subtitle;
        this.sectionTitle = title;
        this.numerator = 0;
        this.denominator = 0;
    }
    
    public void addQuestion(Integer questionNumber, String question, Boolean optional, Integer min, Integer max, Boolean autoFail, List<String> hoverOver) {
        questions.add(new AuditQuestionPackage(questionNumber, question, optional, min, max, autoFail, hoverOver));
    }
    
    public void calculateTotals() {
        for (AuditQuestionPackage question : questions) {
            // skip question if it is marked as N/A
            if (question.score == 'N/A') {
                continue;
            }
            
            // auto fail functionality
            //if (question.autoFailQuestion == TRUE && Integer.valueOf(question.score) == 0) {
            //    status = 'DOES NOT CONFORM';
            //}
            
            // increment numerator and denominator if question is tested
            numerator += Integer.valueOf(question.score);
            denominator += question.maxScore;
        }
    }
    
    public String formatQsForDispaly() {
        String formatted = '';
        for (AuditQuestionPackage q : questions) {
            formatted += '    Question ' + q.questionNumber + ': ' + q.question + '\n' + 
                		'    Score: ' + q.score + '/' + q.maxScore + '\n';
        }
        return formatted;
    }
    
    public Double getScore() {
        return Double.valueOf(numerator / denominator);
    }
}