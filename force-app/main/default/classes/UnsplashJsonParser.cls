public with sharing class UnsplashJsonParser {
	public static String parseJsonAndGetImageUrl(String body, String sizeKey){
		if(String.isBlank(body)) return null;
		try{
			Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);
		}
	}
}