/**
 * PurchaseLineTrigger
 *
 * Trigger on PurchaseLine__c that runs after DML events
 * to recalculate summary fields on the related Purchase__c record
 *
 * Events handled:
 *   after insert
 *   after update
 *   after delete
 *  after undelete
 *
 * Logic is delegated to PurchaseLineTriggerHandler.recalc()
 */
trigger PurchaseLineTrigger on PurchaseLine__c (after insert, after update, after delete, after undelete) {
	PurchaseLineTriggerHandler.recalc(Trigger.new, Trigger.old, Trigger.isDelete);
}