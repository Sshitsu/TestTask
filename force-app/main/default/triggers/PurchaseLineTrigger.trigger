trigger PurchaseLineTrigger on PurchaseLine__c (after insert, after update, after delete, after undelete) {
	PurchaseLineTriggerHandler.recalc(Trigger.new, Trigger.old, Trigger.isDelete);
}