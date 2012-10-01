trigger Note_CommentTriggers on Note_Comment__c (after insert, after update) {
    
    if (Trigger.isInsert)
    {
        if (Trigger.isAfter)
        {
            Note_CommentTriggerMethods.processInsert(Trigger.new);
        }
    }
    
    if (Trigger.isUpdate)
    {
        if (Trigger.isAfter)
        {
            Note_CommentTriggerMethods.processUpdate(Trigger.new, Trigger.oldMap);
        }  
    }
}