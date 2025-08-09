public with sharing class PurchaseLineTriggerHandler {

	public static void recalc(List<PurchaseLine__c> newList, List<PurchaseLine__c> oldList, Boolean isDelete){
		Set<Id> purchaseIds = new Set<Id>();

		if(!isDelete && newList != null){
			for(PurchaseLine__c pl : newList){
				if(pl.PurchaseId__c != null) purchaseIds.add(pl.PurchaseId__c);
			}
		}
		if(oldList != null){
			for(PurchaseLine__c pl : oldList){
				if(pl.PurchaseId__c != null) purchaseIds.add(pl.PurchaseId__c);
			}
		}
		if(purchaseIds.isEmpty()) return;

		// 1) TotalItems
		Map<Id, Integer> totalItemsByPurchase = getTotalItems(purchaseIds);

		// 2) GrandTotal (Amount * UnitCost) — считаем в Apex
		Map<Id, Decimal> grandByPurchase = getGrandTotal(purchaseIds);

		List<Purchase__c> updates = new List<Purchase__c>();

		for(Id pid : purchaseIds){
			Integer ti = totalItemsByPurchase.get(pid);
			Decimal gt = grandByPurchase.get(pid);
			updates.add(new Purchase__c(
					Id = pid,
					TotalItems__c = (ti == null ? 0 : ti),
					GrandTotal__c = (gt == null ? 0 : gt)
			));
		}

		if(!updates.isEmpty()) update updates;
	}

	// Count all Items, which were added to the cart
	private static Map<Id, Integer> getTotalItems(Set<Id> purchaseIds ){
		Map<Id, Integer> totalItemsByPurchase = new Map<Id, Integer>();
		for (AggregateResult ar : [
				SELECT PurchaseId__c pid, SUM(Amount__c) total
				FROM PurchaseLine__c WHERE PurchaseId__c IN :purchaseIds GROUP BY PurchaseId__c
		]){
			totalItemsByPurchase.put((Id)ar.get('pid'), (Integer)ar.get('total'));
		}
		return totalItemsByPurchase;
	}
	// Count the total cost of Items, which were added to the cart
	private static Map<Id, Decimal> getGrandTotal(Set<Id> purchaseIds ){
		Map<Id, Decimal> grandByPurchase = new Map<Id, Decimal>();
		for (PurchaseLine__c pl : [
				SELECT PurchaseId__c, Amount__c, UnitCost__c
				FROM PurchaseLine__c WHERE PurchaseId__c IN :purchaseIds
		]){
			if (pl.PurchaseId__c == null) continue;
			Decimal subtotal = (pl.UnitCost__c == null ? 0 : pl.UnitCost__c) * (pl.Amount__c == null ? 0 : pl.Amount__c);
			grandByPurchase.put(pl.PurchaseId__c, (grandByPurchase.get(pl.PurchaseId__c) == null ? 0 : grandByPurchase.get(pl.PurchaseId__c)) + subtotal);
		}
		return grandByPurchase;
	}

}
