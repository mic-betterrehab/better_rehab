/**
 * Created by Enrite Solutions on 22/08/2019.
 */

@IsTest
private class RetrievePersonalIdentifiersScheduleTest {
    @IsTest
    static void testBehavior() {
        RetrievePersonalIdentifiersSchedule s = new RetrievePersonalIdentifiersSchedule();
        s.execute(null);
    }
}