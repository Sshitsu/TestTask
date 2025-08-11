
/**
 * ItemController
 * Apex controller for working with Item__c, Purchase__c, and PurchaseLines__c objects.
 *
 * Main functionality:
 *  - Retrieve account information
 *  - Get picklist values for filtering
 *  - Search items by multiple filters (name, description, family, type)
 *  - Check user manager permissions
 *  - Create purchases and purchase lines
 *  - Create items with optional automatic image retrieval
 *  - Refresh an item’s image via Unsplash API
 *  */
public with sharing class ItemController {

	// Maximum number of records returned in queries
	private static final Integer MAX_LIMIT = 200;

	/**
	* Retrieves Account information by Id.
	* @param accountId - Account record Id
	* @return Account record with Id, Name, AccountNumber, Industry
	*/
	@AuraEnabled
	public static Account getAccount(Id accountId){
		if(accountId == null) return null;
		return [SELECT
				Id,
				Name,
				AccountNumber,
				Industry
				FROM Account
				WHERE Id = :accountId
		LIMIT 1];
	}

	/**
     * Returns a map of possible picklist values for filtering items.
     * Used in the UI to build search filters.
     * @return Map<String, List<String>> - key: field name, value: list of picklist values
     */
	@AuraEnabled(cacheable=true)
	public static Map<String, List<String>> getPicklistFilters(){
		Map<String, List<String>> res = new Map<String, List<String>>();
		res.put('Type__c', getPicklist('Item__c', 'Type__c'));
		res.put('Family__c', getPicklist('Item__c', 'Family__c'));
		return res;
	}

	// Retrieves picklist values for the specified object and field
	private static List<String> getPicklist(String sObj, String field){
		List<String> vals = new List<String>();
		Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(sObj).getDescribe();
		Schema.DescribeFieldResult f = d.fields.getMap().get(field).getDescribe();
		for (Schema.PicklistEntry e : f.getPicklistValues()) {
			vals.add(e.getValue());
		}
		return vals;
	}

	/**
     * Searches for items by filters.
     * @param searchText - text to search in Name or Description__c
     * @param families - list of selected Family__c value
     * @param types - list of selected Type__c value
     * @return List<Item__c> matching the search criteria
	 * If 0 filters were chosen then just return all Items
     */
	@AuraEnabled(cacheable=true)
	public static List<Item__c> searchItems(String searchText, List<String> families, List<String> types) {

		String nameOrDescriptionTextField = normalize(searchText);

		// We check which filters were chosen
		Boolean byNameOrDescriptionTextField    = (nameOrDescriptionTextField != null);
		Boolean byFamily  = (families != null && !families.isEmpty());
		Boolean byType    = (types    != null && !types.isEmpty());

		// Case 1 - If all fields are empty, we just return all Items (Limit 200)
		if (!byNameOrDescriptionTextField && !byFamily && !byType) {
			return [
					SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c
					FROM Item__c
					ORDER BY Name
					LIMIT :MAX_LIMIT
			];
		}

		// If at least one of filters was chosen, we try to find it
		List<Set<Id>> buckets = new List<Set<Id>>(); // This is a list of Items that match our filters
		if (byNameOrDescriptionTextField)   buckets.add(findByNameOrDescription(nameOrDescriptionTextField));   // Name OR Description_c LIKE nameOrDescriptionTextField
		if (byFamily) buckets.add(findByFamilies(families));  // Family__c IN (families)
		if (byType)   buckets.add(findByTypes(types));        // Type__c   IN (types)

		Set<Id> finalIds = intersectAll(buckets);

		if (finalIds.isEmpty()) return new List<Item__c>();

		// Final result with all filters
		return [
				SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c
				FROM Item__c
				WHERE Id IN :finalIds
				ORDER BY Name
				LIMIT :MAX_LIMIT
		];
	}

	// Normalize the string for query search
	private static String normalize(String s){
		if (s == null) return null;
		String t = s.trim();
		if (t == '') return null;
		return '%' + String.escapeSingleQuotes(t) + '%';
	}

	// Search by name or decription
	private static Set<Id> findByNameOrDescription(String likeExpr){
		Set<Id> ids = new Set<Id>();
		for (Item__c i : [
				SELECT Id FROM Item__c
				WHERE Name LIKE :likeExpr
				OR Description__c LIKE :likeExpr
				LIMIT :MAX_LIMIT
		]) ids.add(i.Id);
		return ids;
	}

	// Search by families
	private static Set<Id> findByFamilies(List<String> families){
		Set<Id> ids = new Set<Id>();
		if (families == null || families.isEmpty()) return ids;
		for (Item__c i : [
				SELECT Id FROM Item__c
				WHERE Family__c IN :families
				LIMIT 1000
		]) ids.add(i.Id);
		return ids;
	}

	// Search by types
	private static Set<Id> findByTypes(List<String> types){
		Set<Id> ids = new Set<Id>();
		if (types == null || types.isEmpty()) return ids;
		for (Item__c i : [
				SELECT Id FROM Item__c
				WHERE Type__c IN :types
				LIMIT 1000
		]) ids.add(i.Id);
		return ids;
	}

	// Intersection of all sets, empty ones ignored
	private static Set<Id> intersectAll(List<Set<Id>> sets){
		Set<Id> acc = new Set<Id>();
		Boolean first = true;
		for (Set<Id> s : sets){
			if (s == null || s.isEmpty()) continue;
			if (first){ acc = new Set<Id>(s); first = false; }
			else      { acc.retainAll(s); }
			if (acc.isEmpty()) break;
		}
		return acc;
	}

	// Check that current user is manager
	@AuraEnabled(cacheable=true)
	public static Boolean isCurrentUserManager(){
		return [
				SELECT IsManager__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
		].IsManager__c;
	}

	// Data structure representing a single cart line
	public class CartLine {
		@AuraEnabled public Id itemId { get; set; }
		@AuraEnabled public Integer amount { get; set; }
		@AuraEnabled public Decimal unitCost { get; set; }
	}
	/**
	* Creates a Purchase__c record and its related PurchaseLine__c records.
	* @param accountId - Id of the client (Account)
	* @param lines - list of cart lines
	* @return Id of the created Purchase__c
	*/
	@AuraEnabled
	public static Id createPurchase(Id accountId, List<CartLine> lines){
		// Chek if accountId is NULL then throw AuraHandledException(AccountId is required)
		if (accountId == null) throw new AuraHandledException('AccountId is required');
		// Chek if lines are NULL pr Empty then throw AuraHandledException(AccountId is required)
		if (lines == null || lines.isEmpty()) throw new AuraHandledException('Cart is empty');

		// Make save before all
		Savepoint sp = Database.setSavepoint();
		// String step this is a value for debug
		String step = 'START';
		try {
			// Insert new Purchase
			step = 'INSERT_PURCHASE';
			Purchase__c pur = new Purchase__c(
					ClientId__c = accountId,

					Name = 'Purchase ' + Datetime.now().format('yyyyMMdd-HHmmss')
			);
			insert pur;

			// Build purchase lines
			step = 'BUILD_LINES';
			List<PurchaseLine__c> pls = new List<PurchaseLine__c>();
			Integer idx = 0;
			for (CartLine l : lines){
				idx++;

				if (l == null) {
					throw new AuraHandledException('Line #' + idx + ': empty line');
				}
				if (l.itemId == null) {
					throw new AuraHandledException('Line #' + idx + ': itemId is required');
				}


				Integer qty;
				try {
					qty = (l.amount == null ? 0 : Integer.valueOf(String.valueOf(l.amount)));
				} catch (Exception convEx) {
					throw new AuraHandledException('Line #' + idx + ': amount is not an integer (' + String.valueOf(l.amount) + ')');
				}
				if (qty <= 0) {
					throw new AuraHandledException('Line #' + idx + ': amount must be > 0 (got ' + qty + ')');
				}

				Decimal price = (l.unitCost == null ? 0 : l.unitCost);

				pls.add(new PurchaseLine__c(
						PurchaseId__c = pur.Id,
						ItemId__c     = l.itemId,
						Amount__c     = qty,
						UnitCost__c   = price,
						Name          = 'Line ' + idx
				));
			}

			step = 'INSERT_LINES';
			Database.SaveResult[] sr = Database.insert(pls, false);
			for (Integer i = 0; i < sr.size(); i++) {
				if (!sr[i].isSuccess()) {
					List<String> msgs = new List<String>();
					for (Database.Error err : sr[i].getErrors()) msgs.add(err.getMessage());
					throw new AuraHandledException('STEP=' + step + ' Line #' + (i+1) + ': ' + String.join(msgs, ' | '));
				}
			}

			return pur.Id;

		} catch (AuraHandledException ahex) {
			Database.rollback(sp);
			throw ahex;
		} catch (DmlException dmlex) {
			Database.rollback(sp);
			List<String> msgs = new List<String>{ 'STEP=' + step };
			for (Integer i = 0; i < dmlex.getNumDml(); i++) msgs.add('[' + i + '] ' + dmlex.getDmlMessage(i));
			throw new AuraHandledException(String.join(msgs, ' | '));
		} catch (Exception ex) {
			Database.rollback(sp);
			throw new AuraHandledException('STEP=' + step + ' ' + ex.getTypeName() + ': ' + String.valueOf(ex.getMessage()));
		}
	}



	/**
     * Creates an Item__c record.
     * If autoImage = true and Image__c is blank, tries to find an image using UnsplashService.
     * @param rec - Item__c record to create
     * @param autoImage - flag to auto-populate the image
     * @return Id of the created Item__c
     */
	@AuraEnabled
	public static Id createItem(Item__c rec, Boolean autoImage){
		if (rec == null || String.isBlank(rec.Name)) {
			throw new AuraHandledException('Name is required');
		}

		if (autoImage == true && String.isBlank(String.valueOf(rec.Image__c))) {
			try {
				String url = UnsplashService.findImageUrl(rec.Name);
				if (!String.isBlank(url)) {
					rec.Image__c = url;
				}
			} catch (Exception e) {

			}
		}
		insert rec;
		return rec.Id;
	}
	/**
   * Refreshes an item's image using UnsplashService.
   * @param itemId - Id of the item
   * @return URL of the new image (null if not found)
   */
	@AuraEnabled
	public static String refreshItemImage(Id itemId){
		if (itemId == null) throw new AuraHandledException('Item Id is required');
		String url = null;
		try {
			url = UnsplashService.findImageUrlByItem(itemId);
		} catch (Exception e) {
			throw new AuraHandledException('Unsplash error: ' + e.getMessage());
		}
		if (!String.isBlank(url)) {
			update new Item__c(Id = itemId, Image__c = url);
		}
		return url;
	}


}