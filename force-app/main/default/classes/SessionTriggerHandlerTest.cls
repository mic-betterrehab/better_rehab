/**
 * @author Jarrah Nott 
 * @date 14/07/2020
 */

@IsTest
private class SessionTriggerHandlerTest
{
    @IsTest
    static void testBehavior()
    {
        TestLoadData data = new TestLoadData();
        data.LoadRecords();
        data.LoadSessions();

        System.assert(data.testSessions != null && data.testSessions.size() > 0);

        update data.testSessions[0];
    }
}