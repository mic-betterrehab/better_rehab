public class UpdateClientNDIAFundingTotalsScheduler implements  Schedulable
{
    public void execute(SchedulableContext context)
    {
        UpdateClientNDIAFundingTotalsBatch batch = new UpdateClientNDIAFundingTotalsBatch();
        database.executeBatch(batch,200);
    }
}