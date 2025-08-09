public with sharing class UnsplashService {

	@AuraEnabled
	public static String findImageUrl(String query){
		// TODO
		return null;
	}

	@TestVisible private static String getKey(){
		return System.Label.Unsplash_Access_Key;
	}

}