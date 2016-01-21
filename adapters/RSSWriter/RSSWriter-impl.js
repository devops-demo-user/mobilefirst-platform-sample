/*
 *  Licensed Materials - Property of IBM
 *  5725-I43 (C) Copyright IBM Corp. 2011, 2013. All Rights Reserved.
 *  US Government Users Restricted Rights - Use, duplication or
 *  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

/**
 *  WL.Server.invokeHttp(parameters) accepts the following json object as an argument:
 *  
 *  {
 *  	// Mandatory 
 *  	method : 'get' , 'post', 'delete' , 'put' or 'head' 
 *  	path: value,
 *  	
 *  	// Optional 
 *  	returnedContentType: any known mime-type or one of "json", "css", "csv", "plain", "xml", "html"  
 *  	returnedContentEncoding : 'encoding', 
 *  	parameters: {name1: value1, ... }, 
 *  	headers: {name1: value1, ... }, 
 *  	cookies: {name1: value1, ... }, 
 *  	body: { 
 *  		contentType: 'text/xml; charset=utf-8' or similar value, 
 *  		content: stringValue 
 *  	}, 
 *  	transformation: { 
 *  		type: 'default', or 'xslFile', 
 *  		xslFile: fileName 
 *  	} 
 *  } 
 */

/**
 * 
 * @returns json list of items
 */
function getRSSWriters() {
		
	var input = {
	    method : 'get',
	    returnedContentType : 'json',
	    path : 'userInputRequired'
	};
	
	
	return WL.Server.invokeHttp(input);
}

function addRSSWriter(param1) {
	
	var input = {
	    method : 'put',
	    returnedContentType : 'json',
	    path : 'userInputRequired'
	};
	
	
	return WL.Server.invokeHttp(input);
}


function updateRSSWriter(param1) {
	
	var input = {
	    method : 'post',
	    returnedContentType : 'json',
	    path : 'userInputRequired'
	};
	
	
	return WL.Server.invokeHttp(input);
}


function deleteRSSWriter(param1) {
	
	
	var input = {
	    method : 'delete',
	    returnedContentType : 'json',
	    path : 'userInputRequired'
	};
	
	
	return WL.Server.invokeHttp(input);
}


