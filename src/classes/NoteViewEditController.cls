/*
* Class NoteViewEditController
*
* ver 1.0 2012.08.02 Manos Spanoudakis Nefos GmbH
*         NoteViewEditController for the Note View Edit Visualforce Page 
* 
*
*/
public class NoteViewEditController {
    
    public Note__c myNote{get;set;}
    public boolean canEdit{get;set;}
    public boolean isEdit{get;set;}
    public boolean showApproveButton{get;set;}
    public boolean showSubmitForApproveButton{get;set;}

    /*******************************************************************************************************************************
     * ver 1.0 2012.08.02 Manos Spanoudakis Nefos GmbH
     *                    Constructor. If the User is the Owner of the Note, allow him to edit/Approve depending on the Status 
     *                    of the Note
     */
    public NoteViewEditController(Apexpages.Standardcontroller ctrl)
    {
        myNote = (Note__c)ctrl.getRecord();
        
        Id ownerId = myNote.OwnerId; 
        Id userId = Userinfo.getUserId();
        
        showApproveButton=false;
        showSubmitForApproveButton=false;
        if (userId==ownerId)
        {
            if (!myNote.Status__c.equals(Label.Note_Status_Approved))
                canEdit = true;
            if (myNote.Status__c.equals(Label.Note_Status_Draft))
            {
            	showSubmitForApproveButton = true;
            }
            else if (myNote.Status__c.equals(Label.Note_Status_In_Review)) 
            {
                showApproveButton= true;
            }
            
        }
        else
        {
            canEdit=false;
        }
    }
    /*******************************************************************************************************************************

    /*******************************************************************************************************************************
    * ver 1.0 2012.08.02 Manos Spanoudakis
    * 
    */          
    public PageReference editNote()
    {
        isEdit=true;
        return null;
    }       
    /*******************************************************************************************************************************/
    
    /*******************************************************************************************************************************
    * ver 1.0 2012.08.02 Manos Spanoudakis
    *                    Submit the Note for Approval
    * 
    */          
    public PageReference submitForApproval()
    {
        Pagereference pRef = new PageReference('/'+myNote.Id);
        myNote.Status__c = Label.Note_Status_In_Review;
        update myNote; 
        pRef.setRedirect(true);
        return pRef;
    }       
    /*******************************************************************************************************************************/
    
    /*******************************************************************************************************************************
    * ver 1.0 2012.08.02 Manos Spanoudakis
    *                    Submit the Note for Approval
    * 
    */          
    public PageReference approveNote()
    {
        Pagereference pRef = new PageReference('/'+myNote.Id);
        myNote.Status__c = Label.Note_Status_Approved;
        update myNote; 
        pRef.setRedirect(true);
        return pRef;
    }       
    /*******************************************************************************************************************************/
 
}