/**
 * Created by me on 17/07/2019.
 */

public class SessionTaskFactory
{
    public List<Task> tasks = new List<Task>();
    private Map<ID, enrtcr__Session__c> sessionsByID;

    public static void createTasks(Set<ID> sessionIds)
    {
        SessionTaskFactory taskFactory = new SessionTaskFactory();
        taskFactory.createWorkerTasks(sessionIds);
    }

    public static void createTasks(List<enrtcr__Worker_Appointment__c> workerAppointments)
    {
        SessionTaskFactory taskFactory = createInstance(workerAppointments, enrtcr__Worker_Appointment__c.enrtcr__Session__c);
        taskFactory.createWorkerTasks(workerAppointments, true);
    }

    public static void createTasks(List<enrtcr__Client_Appointment__c> clientAppointments)
    {
        SessionTaskFactory taskFactory = createInstance(clientAppointments, enrtcr__Client_Appointment__c.enrtcr__Session__c);
        taskFactory.createWorkerTasks(clientAppointments);
    }

    public static void updateTaskDueDates(Set<ID> sessionIds)
    {
        SessionTaskFactory taskFactory = new SessionTaskFactory();
        taskFactory.updateTasks(sessionIds);
    }

    private static SessionTaskFactory createInstance(List<SObject> records, SObjectField sessionField)
    {
        Set<ID> sessionIds = new Set<ID>();
        for(SObject record : records)
        {
            sessionIds.add((ID)record.get(sessionField));
        }
        SessionTaskFactory taskFactory = new SessionTaskFactory();
        taskFactory.setSessionsByID(sessionIds);
        return taskFactory;
    }

    public void setSessionsByID(Set<ID> sessionIDs)
    {
        sessionsByID = new Map<ID, enrtcr__Session__c>([SELECT ID,
                                                        enrtcr__Start_Date__c,
                                                        enrtcr__Service_Types__c,
                                                        (SELECT ID,
                                                                enrtcr__Client__c
                                                        FROM enrtcr__Client_Appointments__r),
                                                        (SELECT ID,
                                                                enrtcr__Session__c,
                                                                enrtcr__Worker__c,
                                                                Worker_User__c
                                                        FROM enrtcr__Worker_Appointments__r)
                                                FROM    enrtcr__Session__c
                                                WHERE   ID IN :sessionIDs AND
                                                        enrtcr__Start_Date__c != null]);
    }

    public void getWorkerTasks(Map<ID, List<Task>> tasksByWhatId)
    {
        for(Task t : [SELECT ID,
                                WhatId,
                                Subject
                        FROM Task
                        WHERE WhatId IN (SELECT ID
                                        FROM    enrtcr__Worker_Appointment__c
                                        WHERE   enrtcr__Session__c IN :sessionsByID.keySet())])
        {
            if(!tasksByWhatId.containsKey(t.WhatId))
            {
                tasksByWhatId.put(t.WhatId, new List<Task>());
            }
            tasksByWhatId.get(t.WhatId).add(t);
        }
    }

    public void updateTasks(Set<ID> sessionIds)
    {
        setSessionsByID(sessionIds);
        Map<ID, List<Task>> tasksByWhatId = new Map<ID, List<Task>>();
        getWorkerTasks(tasksByWhatId);
        for(ID sessionId : sessionsByID.keySet())
        {
            enrtcr__Session__c session = sessionsByID.get(sessionId);
            for(enrtcr__Worker_Appointment__c workAppt : session.enrtcr__Worker_Appointments__r)
            {
                if(tasksByWhatId.containsKey(workAppt.ID))
                {
                    List<Task> tasksToUpdate = tasksByWhatId.get(workAppt.ID);
                    for(Task t : tasksToUpdate)
                    {
                        t.ActivityDate = getTaskDueDate(t, session);
                    }
                    tasks.addAll(tasksToUpdate);
                }
            }
        }
        update tasks;
    }

    public void createWorkerTasks(Set<ID> sessionIds)
    {
        setSessionsByID(sessionIds);
        for(ID sessionId : sessionsByID.keySet())
        {
            enrtcr__Session__c session = sessionsByID.get(sessionId);
            if(isInitialAssessment(session))
            {
                createWorkerTasks(session.enrtcr__Worker_Appointments__r, false);
            }
        }
        insert tasks;
    }

    public void createWorkerTasks(List<enrtcr__Client_Appointment__c> clientAppointments)
    {
        for(enrtcr__Client_Appointment__c clientApp : clientAppointments)
        {
            enrtcr__Session__c session = sessionsByID.get(clientApp.enrtcr__Session__c);
            if(isInitialAssessment(session))
            {
                for(enrtcr__Worker_Appointment__c workerAppointment : session.enrtcr__Worker_Appointments__r)
                {
                    addTasks(clientApp, workerAppointment, session);
                }
            }
        }
        insert tasks;
    }

    public void createWorkerTasks(List<enrtcr__Worker_Appointment__c> workerAppointments, Boolean insertTasks)
    {
        for(enrtcr__Worker_Appointment__c workerAppointment : workerAppointments)
        {
            enrtcr__Session__c session = sessionsByID.get(workerAppointment.enrtcr__Session__c);
            if(isInitialAssessment(session))
            {
                for(enrtcr__Client_Appointment__c clientApp : session.enrtcr__Client_Appointments__r)
                {
                    addTasks(clientApp, workerAppointment, session);
                }
            }
        }
        if(insertTasks)
        {
            insert tasks;
        }
    }

    private void addTasks(enrtcr__Client_Appointment__c clientApp, enrtcr__Worker_Appointment__c workerAppointment, enrtcr__Session__c session)
    {
        tasks.add(getNewTask(workerAppointment.ID,
                workerAppointment.Worker_User__c,
                clientApp.enrtcr__Client__c,
                'Complete a Summary Report',
                session));
        tasks.add(getNewTask(workerAppointment.ID,
                workerAppointment.Worker_User__c,
                clientApp.enrtcr__Client__c,
                'Complete or Review risk assessment',
                session));
        tasks.add(getNewTask(workerAppointment.ID,
                workerAppointment.Worker_User__c,
                clientApp.enrtcr__Client__c,
                'Send a signed Service Agreement to Admin',
                session));
    }

    private Task getNewTask(ID whatId, ID ownerId, ID clientId, String subject, enrtcr__Session__c session)
    {
        Task t = new Task();
        t.WhatId = whatId;
        t.OwnerId = ownerId;
        t.Subject = subject;
        t.Status = 'Not Started';
        t.Priority = 'Not Started';
        t.enrtcr__Client__c = clientId;
        t.WhoId = clientId;
        t.ActivityDate = getTaskDueDate(t, session);
        return t;
    }

    private Date getTaskDueDate(Task t, enrtcr__Session__c session)
    {
        Date newDate = session.enrtcr__Start_Date__c.date();
        switch on t.Subject
        {
            when 'Complete a Summary Report'
            {
                newDate = newDate.addDays(2);
            }
            when 'Complete or Review risk assessment'
            {
                newDate = newDate.addDays(-2);
            }
            when 'Send a signed Service Agreement to Admin'
            {
                newDate = newDate.addDays(1);
            }
        }
        return newDate;
    }

    private Boolean isInitialAssessment(enrtcr__Session__c session)
    {
        return session != null &&
                session.enrtcr__Service_Types__c != null &&
                session.enrtcr__Service_Types__c.contains('Initial Assessment');
    }

}