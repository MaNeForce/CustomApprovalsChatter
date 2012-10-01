/*
* Class Note_Comment_TriggerMethods
*
* ver 1.0 2012.07.27 Manos Spanoudakis
*         Note Comment After Insert/Update triggers. 
* 
* Copyright (c) 2012 Nefos GmbH  *
*
*/

public class Note_CommentTriggerMethods {

    /*******************************************************************************************************************************
    * ver 1.0 2012.07.27 Manos Spanoudakis
    *         Method handling the Insert of new Note Comments (after Insert trigger)    
    *         
    *         1) Updates Karma of Related Note
    *         2) Posts to Note's Chatter if there's a comment        
    *       
    */
    public static void processInsert(List <Note_Comment__c> lNewNoteComments)
    {
        Set <Id> sNoteIdsToUpdateKarma = new Set<Id>();
        Set <Id> sNoteIdsToPost = new Set<Id>();
        
        List <Note_Comment__c> lNoteCommentsToUpdateKarma = new List<Note_Comment__c>();
        List <Note_Comment__c> lNoteCommentsToPost = new List<Note_Comment__c>();
        for (Note_Comment__c nNC:lNewNoteComments)
        {
            if (nNC.Karma__c != null)
            {
                sNoteIdsToUpdateKarma.add(nNC.Note__c);
                lNoteCommentsToUpdateKarma.add(nNC);
            }
            
            if (nNC.Comment__c != null)
            {
                lNoteCommentsToPost.add(nNC);
                sNoteIdsToPost.add(nNC.Note__c);
            }
        }
        
        //Update Karma
        updateKarma(lNoteCommentsToUpdateKarma,null,sNoteIdsToUpdateKarma);
        
        //Post To Notes Chatter
        postToNoteChatter(lNoteCommentsToPost,sNoteIdsToPost);
    }
    /*******************************************************************************************************************************

    /*******************************************************************************************************************************
    * ver 1.0 2012.07.27 Manos Spanoudakis
    *         Method handling the Update of Note Comments (after Update trigger)             
    *       
    */
    public static void processUpdate(List <Note_Comment__c> lNewNoteComments, Map <Id,Note_Comment__c> mOldNoteComments)
    {
        Set <Id> sNoteIdsToUpdateKarma = new Set<Id>();
        Set <Id> sNoteIdsToPost = new Set<Id>();
        
        List <Note_Comment__c> lNoteCommentsToUpdateKarma = new List<Note_Comment__c>();
        List <Note_Comment__c> lNoteCommentsToPost = new List<Note_Comment__c>();
        
        Map <Id,String> mOldNoteCommentKarma = new Map<Id,String>();
        
        for (Note_Comment__c nNC:lNewNoteComments)
        { 
            Note_Comment__c oNC= mOldNoteComments.get(nNC.Id);
            //Only if there's an update to the Note Comment Karma
            if (nNC.Karma__c != null 
                && oNC.Karma__c != nNC.Karma__c)
            {
                sNoteIdsToUpdateKarma.add(nNC.Note__c);
                lNoteCommentsToUpdateKarma.add(nNC);
                mOldNoteCommentKarma.put(oNC.Id,oNC.Karma__c);
            }
            
            if (nNC.Comment__c != null 
               && nNC.Comment__c != oNC.Comment__c)
            {
                lNoteCommentsToPost.add(nNC);
                sNoteIdsToPost.add(nNC.Note__c);
            }
        }
        
        updateKarma(lNoteCommentsToUpdateKarma,mOldNoteCommentKarma,sNoteIdsToUpdateKarma);
        
        //Post To Notes Chatter
        postToNoteChatter(lNoteCommentsToPost,sNoteIdsToPost);
    }
    /*******************************************************************************************************************************
    
    /**********************************************    Private Methods   ***********************************************************/
    
    /*******************************************************************************************************************************
    * ver 1.0 2012.07.27 Manos Spanoudakis
    *         Updates the Note Karma based on the input of the Note Comment     
    *         Karma Points are calculated using the Custom Settings (Hierarchy)          
    *       
    */
    private static void updateKarma(List <Note_Comment__c> lNoteComments, Map <Id,String> mOldNoteCommentKarma, Set <Id> sNoteIds)
    {
        //Retrieve the Notes to be updated. 
        Map <Id, Note__c> mNotes = new Map <Id,Note__c> (
                                             [SELECT Id, 
                                                     Karma_Points__c
                                                FROM Note__c
                                               WHERE Id in: sNoteIds]
                                              );
        //Build Karma Points using the Custom Settings 
        Map <String,Integer> mKarmaPoints = new Map <String,Integer>();
        Note_Karma__c nK = Note_Karma__c.getInstance();
        //If there are No Custom Settings then do nothing... 
        //If there is no mapping (shouldn't be the case if Default Organization Level Value is set) there will be no update 
        if (nK != null)
        {
            Map<String, Schema.SObjectField> mFields = Schema.SObjectType.Note_Karma__c.fields.getMap();
            for (String sFieldName:mFields.keySet())
            {
                if (sFieldName.startsWith('points_'))
                {
                    String sKarmaVal = sFieldName.substring('points_'.length(),sFieldName.indexOf('__c')).replace('_',' ');
                    Integer iPoints = Integer.valueOf(nK.get(sFieldName));
                    mKarmaPoints.put(sKarmaVal,iPoints);
                }
            }
        }
        
        //Loop through All the Note Comments and Update the Notes 
        for (Note_Comment__c nC:lNoteComments)
        {
            Note__c n = mNotes.get(nC.Note__c);
            Integer iOldPoints =0;
            //Get Old Karma Points if any
            if (mOldNoteCommentKarma != null)
            {
                String oldKarma = mOldNoteCommentKarma.get(nC.Id);
                if (oldKarma != null)
                {
                    iOldPoints=mKarmaPoints.get(oldKarma.toLowerCase());
                }
            } 
            
            Integer iPoints = mKarmaPoints.get(nC.Karma__c.toLowerCase());
            if (iPoints!=null)
            {
                n.Karma_Points__c = n.Karma_Points__c + iPoints - iOldPoints;
            } 
        }       
        update mNotes.values();
    }
    /*******************************************************************************************************************************
    
    /*******************************************************************************************************************************
    * ver 1.0 2012.07.27 Manos Spanoudakis
    *         For Every insert/update of a Note Comment, a Feed is posted in the Note Chatter        
    *       
    */
    private static void postToNoteChatter(List <Note_Comment__c> lNoteComments, Set <Id> sNoteIds)
    {
        List <FeedItem> lFeedItems = new List <FeedItem>();

        Map <Id, Note__c> mNotes = new Map<Id,Note__c> (
                                            [SELECT Id, 
                                                    Subject__c
                                               FROM Note__c
                                              WHERE Id in: sNoteIds]);

        for (Note_Comment__c nc: lNoteComments)
        {
            FeedItem nFI = new FeedItem();
            nFI.Type='LinkPost';
            nFI.Title = Label.New_Note_Comment_Link_Title+ '\'' + nc.Comment__c.substring(0,math.min(nc.Comment__c.length(),20))+ '...\'';
            nFI.Body = Label.New_Note_Comment_Body;
            nFI.LinkUrl='/'+nc.Id;
            nFI.ParentId = nc.Note__c;
            lFeedItems.add(nFI);
        }
        insert lFeedItems;
    }

}