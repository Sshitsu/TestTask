public with sharing class UnsplashJsonParser {
	public static String parseJsonAndGetImageUrl(String jsonBody, String imageSize){
		if (String.isBlank(jsonBody)) return null;
		if (String.isBlank(imageSize)) imageSize = 'small';

		Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
		if (root == null || !root.containsKey('results')) return null;

		List<Object> results = (List<Object>) root.get('results');
		if (results == null || results.isEmpty()) return null;

		Map<String, Object> firstResult = (Map<String, Object>) results[0];
		if (firstResult == null || !firstResult.containsKey('urls')) return null;

		Map<String, Object> urls = (Map<String, Object>) firstResult.get('urls');
		if (urls == null) return null;

		return (String) urls.get(imageSize);
	}
}