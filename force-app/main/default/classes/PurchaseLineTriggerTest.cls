@IsTest
private class PurchaseLineTriggerTest {

	@TestSetup
	static void setupData() {
		// Account
		Account acc = new Account(Name = 'Test Account');
		insert acc;

		// Items
		Item__c i1 = new Item__c(Name = 'Item 1', Price__c = 5);
		Item__c i2 = new Item__c(Name = 'Item 2', Price__c = 1.5);
		insert new List<Item__c>{ i1, i2 };

		// Purchase
		Purchase__c p = new Purchase__c(Name = 'P-Setup', ClientId__c = acc.Id);
		insert p;

		// L1
		PurchaseLine__c l1 = new PurchaseLine__c(
				Name = 'L1',
				PurchaseId__c = p.Id,
				ItemId__c = i1.Id,
				Amount__c = 2,
				UnitCost__c = 5
		);
		// L2
		PurchaseLine__c l2 = new PurchaseLine__c(
				Name = 'L2',
				PurchaseId__c = p.Id,
				ItemId__c = i2.Id,
				Amount__c = 3,
				UnitCost__c = 1.5
		);
		insert new List<PurchaseLine__c>{ l1, l2 };
	}

	@IsTest
	static void testInsertRollup() {
		Purchase__c p = [SELECT Id FROM Purchase__c LIMIT 1];
		Item__c i3 = new Item__c(Name = 'Item 3', Price__c = 2);
		insert i3;

		PurchaseLine__c l3 = new PurchaseLine__c(
				Name = 'L3',
				PurchaseId__c = p.Id,
				ItemId__c = i3.Id,
				Amount__c = 1,
				UnitCost__c = 2
		);

		Test.startTest();
		insert l3;
		Test.stopTest();

		p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
		System.assertEquals(6, p.TotalItems__c, 'Should be 6 (2 + 3 + 1)');
		System.assertEquals(16.5, p.GrandTotal__c, 'Should be 16.5 (10 + 4.5 + 2)');
	}

	@IsTest
	static void testUpdateRollup() {
		Purchase__c p = [SELECT Id FROM Purchase__c LIMIT 1];
		PurchaseLine__c l1 = [SELECT Id, Amount__c, UnitCost__c FROM PurchaseLine__c WHERE Name = 'L1' LIMIT 1];

		l1.Amount__c = 4;
		l1.UnitCost__c = 6;

		Test.startTest();
		update l1;
		Test.stopTest();

		p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
		System.assertEquals(7, p.TotalItems__c, 'Should be 7 (4 + 3)');
		System.assertEquals(28.5, p.GrandTotal__c, 'Should be 28.5 (24 + 4.5)');
	}

	@IsTest
	static void testDeleteUndeleteRollup() {
		Purchase__c p = [SELECT Id FROM Purchase__c LIMIT 1];
		PurchaseLine__c l2 = [SELECT Id FROM PurchaseLine__c WHERE Name = 'L2' LIMIT 1];

		Test.startTest();
		delete l2;
		undelete l2;
		Test.stopTest();

		p = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :p.Id];
		System.assertEquals(5, p.TotalItems__c, 'After undelete Should be 5 (2+3)');
		System.assertEquals(14.5, p.GrandTotal__c, 'After undelete Should be 14.5 (10 + 4.5)');
	}
}
