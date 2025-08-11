/*
 * UnsplashService
 *
 * Send request to Unsplash API by using UnsplashHttp and then parse reply by using UnsplashJsonParser
 */
public with sharing class UnsplashService {

	public static final String IMAGE_SIZE = 'small';

	@AuraEnabled
	public static String findImageUrl(String query){

		if (String.isBlank(query)) return null;
		String url = buildSearchUrl(query, 1, null);
		HttpRequest request = UnsplashHttp.buildGet(url, getKey());
		HttpResponse response = UnsplashHttp.send(request);
		UnsplashHttp.ensureOk(response);
		return UnsplashJsonParser.parseJsonAndGetImageUrl(response.getBody(), IMAGE_SIZE);
	}

	@AuraEnabled
	public static String findImageUrlByItem(Id itemId){
		if (itemId == null) return null;
		Item__c it = [SELECT Id, Name FROM Item__c WHERE Id = :itemId LIMIT 1];
		return findImageUrl(it.Name);
	}

	@TestVisible
	private static String buildSearchUrl(String query, Integer perPage, String orientation){
		perPage = (perPage == null || perPage < 1 || perPage > 30) ? 1 : perPage;
		String base = 'https://api.unsplash.com/search/photos';
		String u = base
				+ '?query=' + EncodingUtil.urlEncode(query, 'UTF-8')
				+ '&per_page=' + perPage;
		if (!String.isBlank(orientation)) {
			u += '&orientation=' + EncodingUtil.urlEncode(orientation, 'UTF-8');
		}
		return u;
	}


	@TestVisible private static String getKey(){
		return System.Label.Unsplash_Access_Key;
	}


}